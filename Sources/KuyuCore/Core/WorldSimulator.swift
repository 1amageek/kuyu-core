import Foundation

public struct WorldSimulator<
    Disturbance: DisturbanceField,
    Actuator: ActuatorEngine,
    Plant: PlantEngine,
    Sensor: SensorField,
    Cut: CutInterface,
    Nerve: MotorNerveEndpoint
> {
    public var config: SimulationConfig
    public var disturbance: Disturbance
    public var actuator: Actuator
    public var plant: Plant
    public var sensor: Sensor
    public var cut: Cut
    public var motorNerve: Nerve?

    private var time: WorldTime
    private var lastCutObservabilityEvents: CutObservabilityEvents

    public init(
        config: SimulationConfig,
        disturbance: Disturbance,
        actuator: Actuator,
        plant: Plant,
        sensor: Sensor,
        cut: Cut,
        motorNerve: Nerve? = nil
    ) throws {
        self.config = config
        self.disturbance = disturbance
        self.actuator = actuator
        self.plant = plant
        self.sensor = sensor
        self.cut = cut
        self.motorNerve = motorNerve
        self.time = try WorldTime(stepIndex: 0, time: 0.0)
        self.lastCutObservabilityEvents = CutObservabilityEvents()
    }

    @MainActor
    public mutating func run(
        control: SimulationControl? = nil,
        telemetry: ((WorldStepLog) -> Void)? = nil,
        failureCheck: ((WorldStepLog) -> FailureEvent?)? = nil
    ) async throws -> SimulationLog {
        let dt = config.scenario.timeStep.delta
        let steps = Int((config.scenario.duration / dt).rounded(.down))
        var logs: [WorldStepLog] = []
        logs.reserveCapacity(steps + 1)
        let configHash = try ConfigHash.hash(config)
        var failureEvent: FailureEvent?
        var plannerDecisions: [PlannerDecisionLog] = []
        var adapterMappings: [AdapterMappingLog] = []
        var memoryRecalls: [MemoryRecallLog] = []
        var upwardSummaries: [UpwardSummaryLog] = []
        var arbitrationOutcomes: [ArbitrationOutcomeLog] = []
        var fallbackTransitions: [FallbackTransitionLog] = []
        var latencyBudgetViolations: [LatencyBudgetViolation] = []
        var incidents: [IncidentSummaryLog] = []

        for _ in 0..<steps {
            if let control {
                try await control.checkpoint()
            }
            let log = try step(deltaTime: dt)
            telemetry?(log)
            logs.append(log)
            plannerDecisions.append(contentsOf: lastCutObservabilityEvents.plannerDecisions)
            adapterMappings.append(contentsOf: lastCutObservabilityEvents.adapterMappings)
            memoryRecalls.append(contentsOf: lastCutObservabilityEvents.memoryRecalls)
            fallbackTransitions.append(contentsOf: lastCutObservabilityEvents.fallbackTransitions)
            latencyBudgetViolations.append(contentsOf: lastCutObservabilityEvents.latencyBudgetViolations)
            upwardSummaries.append(makeUpwardSummaryLog(from: log))
            if let arbitration = makeArbitrationOutcomeLog(from: log) {
                arbitrationOutcomes.append(arbitration)
            }
            if failureEvent == nil, let failureCheck, let event = failureCheck(log) {
                failureEvent = event
                incidents.append(
                    IncidentSummaryLog(
                        scenarioID: config.scenario.id.rawValue,
                        seed: config.scenario.seed.rawValue,
                        reason: event.reason.rawValue,
                        time: event.time
                    )
                )
                break
            }
            if (log.time.stepIndex % 20) == 0 {
                await Task.yield()
            }
        }

        let observability = ObservabilityLogBundle(
            plannerDecisions: plannerDecisions,
            adapterMappings: adapterMappings,
            memoryRecalls: memoryRecalls,
            upwardSummaries: upwardSummaries,
            arbitrationOutcomes: arbitrationOutcomes,
            fallbackTransitions: fallbackTransitions,
            latencyBudgetViolations: latencyBudgetViolations,
            incidents: incidents
        )

        return SimulationLog(
            scenarioId: config.scenario.id,
            seed: config.scenario.seed,
            timeStep: config.scenario.timeStep,
            determinism: config.determinism,
            configHash: configHash,
            events: logs,
            failureReason: failureEvent?.reason,
            failureTime: failureEvent?.time,
            observability: observability.isEmpty ? nil : observability
        )
    }

    public mutating func step(deltaTime: TimeInterval) throws -> WorldStepLog {
        time = try time.advanced(by: deltaTime)
        lastCutObservabilityEvents = CutObservabilityEvents()
        var events: [ExecutionEvent] = []

        events.append(.timeAdvance)

        try disturbance.update(time: time)
        events.append(.disturbanceUpdate)

        if config.schedule.actuator.isDue(stepIndex: time.stepIndex) {
            try actuator.update(time: time)
            events.append(.actuatorUpdate)
        }

        try plant.integrate(time: time)
        events.append(.plantIntegrate)

        var samples: [ChannelSample] = []
        if config.schedule.sensor.isDue(stepIndex: time.stepIndex) {
            samples = try sensor.sample(time: time)
            events.append(.sensorSample)
        }

        var output: CutOutput?
        var driveIntents: [DriveIntent] = []
        var reflexCorrections: [ReflexCorrection] = []
        var motorNerveTrace: MotorNerveTrace?
        if config.schedule.cut.isDue(stepIndex: time.stepIndex) {
            output = try cut.update(samples: samples, time: time)
            events.append(.cutUpdate)
            lastCutObservabilityEvents = consumeCutObservabilityEvents()
        }

        var values: [ActuatorValue] = []
        if let output {
            switch output {
            case .actuatorValues(let direct):
                values = direct
            case .driveIntents(let drives, let corrections):
                driveIntents = drives
                reflexCorrections = corrections
                if config.schedule.motorNerve?.isDue(stepIndex: time.stepIndex) == true, var nerve = motorNerve {
                    let telemetry = MotorNerveTelemetry(actuatorTelemetry: actuator.telemetrySnapshot())
                    values = try nerve.update(
                        input: drives,
                        corrections: corrections,
                        telemetry: telemetry,
                        time: time
                    )
                    if let traceProvider = nerve as? MotorNerveTraceProvider {
                        motorNerveTrace = traceProvider.lastTrace
                    }
                    motorNerve = nerve
                    events.append(.motorNerveUpdate)
                }
            }
        }

        if !values.isEmpty {
            try actuator.apply(values: values, time: time)
            events.append(.applyCommands)
        }

        events.append(.logging)
        events.append(.replayCheck)

        let safetyTrace = plant.safetyTrace()
        let plantState = plant.snapshot()
        let disturbanceSnapshot = disturbance.snapshot()

        return WorldStepLog(
            time: time,
            events: events,
            sensorSamples: samples,
            driveIntents: driveIntents,
            reflexCorrections: reflexCorrections,
            actuatorValues: values,
            actuatorTelemetry: actuator.telemetrySnapshot(),
            motorNerveTrace: motorNerveTrace,
            safetyTrace: safetyTrace,
            plantState: plantState,
            disturbances: disturbanceSnapshot
        )
    }

    private mutating func consumeCutObservabilityEvents() -> CutObservabilityEvents {
        guard var provider = cut as? any CutObservabilityProviding else {
            return CutObservabilityEvents()
        }
        let events = provider.consumeCutObservabilityEvents()
        if let updatedCut = provider as? Cut {
            cut = updatedCut
        }
        return events
    }

    private func makeUpwardSummaryLog(from log: WorldStepLog) -> UpwardSummaryLog {
        let maxDriveMagnitude = log.driveIntents.map { abs($0.activation) }.max() ?? 0.0
        let normalizedTilt = clamp(log.safetyTrace.tiltRadians / (.pi / 2.0))
        let normalizedOmega = clamp(log.safetyTrace.omegaMagnitude / 20.0)
        let risk = max(normalizedTilt, normalizedOmega)

        let disturbanceMagnitude = axisMagnitude(log.disturbances.forceWorld) + axisMagnitude(log.disturbances.torqueBody)
        let uncertainty = clamp(disturbanceMagnitude)
        let constraintPressure = constraintPressure(from: log.reflexCorrections)
        let recoveryState = clamp(1.0 - max(risk, constraintPressure))

        return UpwardSummaryLog(
            time: log.time.time,
            salience: clamp(maxDriveMagnitude),
            risk: risk,
            uncertainty: uncertainty,
            constraintPressure: constraintPressure,
            recoveryState: recoveryState
        )
    }

    private func makeArbitrationOutcomeLog(from log: WorldStepLog) -> ArbitrationOutcomeLog? {
        guard !log.driveIntents.isEmpty || !log.reflexCorrections.isEmpty else {
            return nil
        }

        let channelCount = max(
            (log.driveIntents.map { Int($0.index.rawValue) }.max() ?? -1) + 1,
            (log.reflexCorrections.map { Int($0.driveIndex.rawValue) }.max() ?? -1) + 1
        )
        guard channelCount > 0 else { return nil }

        var coreDrive = [Double](repeating: 0.0, count: channelCount)
        for drive in log.driveIntents {
            coreDrive[Int(drive.index.rawValue)] = drive.activation
        }

        var clampByIndex = [Double](repeating: 1.0, count: channelCount)
        var dampingByIndex = [Double](repeating: 0.0, count: channelCount)
        var deltaByIndex = [Double](repeating: 0.0, count: channelCount)
        for correction in log.reflexCorrections {
            let index = Int(correction.driveIndex.rawValue)
            clampByIndex[index] *= correction.clampMultiplier
            dampingByIndex[index] = min(1.0, dampingByIndex[index] + correction.damping)
            deltaByIndex[index] += correction.delta
        }

        var merged = [Double](repeating: 0.0, count: channelCount)
        var reflexClamp = [Double](repeating: 1.0, count: channelCount)
        for index in 0..<channelCount {
            let damped = coreDrive[index] * (1.0 - dampingByIndex[index])
            merged[index] = damped * clampByIndex[index] + deltaByIndex[index]
            reflexClamp[index] = clampByIndex[index]
        }

        return ArbitrationOutcomeLog(
            time: log.time.time,
            descending: coreDrive,
            coreDrive: coreDrive,
            reflexClamp: reflexClamp,
            mergedDrive: merged
        )
    }

    private func constraintPressure(from corrections: [ReflexCorrection]) -> Double {
        guard !corrections.isEmpty else { return 0.0 }
        let pressure = corrections.reduce(0.0) { partial, correction in
            partial + (1.0 - correction.clampMultiplier) + correction.damping + abs(correction.delta)
        }
        return clamp(pressure / Double(corrections.count))
    }

    private func axisMagnitude(_ axis: Axis3) -> Double {
        let value = sqrt((axis.x * axis.x) + (axis.y * axis.y) + (axis.z * axis.z))
        if !value.isFinite { return 0.0 }
        return value
    }

    private func clamp(_ value: Double) -> Double {
        if !value.isFinite { return 0.0 }
        return min(max(value, 0.0), 1.0)
    }
}
