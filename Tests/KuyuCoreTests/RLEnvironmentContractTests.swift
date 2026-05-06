import Testing
@testable import KuyuCore

@Test func environmentActionConvertsDriveIntentToCutOutput() throws {
    let drive = try DriveIntent(index: DriveIndex(0), activation: 0.5)
    let action = EnvironmentAction.driveIntents([drive], corrections: [])

    switch action.cutOutput() {
    case .driveIntents(let drives, let corrections):
        #expect(drives == [drive])
        #expect(corrections.isEmpty)
    case .actuatorValues:
        Issue.record("Expected drive intents")
    }
}

@Test func environmentStepRejectsNonFiniteReward() throws {
    let log = try makeStepLog()
    let observation = EnvironmentObservation(log: log)
    let info = EpisodeInfo(
        scenarioId: try ScenarioID("rl-contract"),
        seed: ScenarioSeed(1),
        configHash: "hash",
        descriptorId: nil,
        policyId: "test",
        stepCount: 1,
        rewardSum: 0,
        failureReason: nil,
        failureTime: nil,
        terminalReason: nil
    )

    #expect(throws: EnvironmentStep.ValidationError.nonFiniteReward) {
        try EnvironmentStep(
            observation: observation,
            reward: .nan,
            done: false,
            truncated: false,
            info: info,
            log: log
        )
    }
}

@Test func rewardDescriptorCarriesStableIdentityAndConfigHash() throws {
    let descriptor = RewardDescriptor(
        id: "dense",
        version: "1",
        configHash: try ConfigHash.hash(["tilt": 1.0, "omega": 0.25])
    )

    #expect(descriptor.id == "dense")
    #expect(descriptor.version == "1")
    #expect(!descriptor.configHash.isEmpty)
}

@Test func physicsOnlyWorldModelAdapterAcceptsIdenticalReferenceStep() throws {
    let log = try makeStepLog()
    let observation = EnvironmentObservation(log: log)
    let info = EpisodeInfo(
        scenarioId: try ScenarioID("rl-adapter"),
        seed: ScenarioSeed(1),
        configHash: "hash",
        rewardDescriptor: RewardDescriptor(id: "dense", version: "1", configHash: "abc"),
        stepCount: 1,
        rewardSum: 1.0
    )
    let step = try EnvironmentStep(
        observation: observation,
        reward: 1.0,
        done: false,
        truncated: true,
        info: info,
        log: log
    )

    let validation = try PhysicsOnlyWorldModelAdapter().validate(predicted: step, reference: step)
    #expect(validation.accepted)
    #expect(validation.residualMax == 0.0)
}

@Test func worldModelAdapterRejectsTerminalMismatch() throws {
    let log = try makeStepLog()
    let observation = EnvironmentObservation(log: log)
    let info = EpisodeInfo(
        scenarioId: try ScenarioID("rl-adapter-reject"),
        seed: ScenarioSeed(1),
        configHash: "hash",
        stepCount: 1,
        rewardSum: 1.0
    )
    let reference = try EnvironmentStep(
        observation: observation,
        reward: 1.0,
        done: false,
        truncated: true,
        info: info,
        log: log
    )
    let predicted = try EnvironmentStep(
        observation: observation,
        reward: 1.0,
        done: true,
        truncated: false,
        info: info,
        log: log
    )
    let prediction = try WorldModelPrediction(step: predicted)

    #expect(throws: WorldModelAdapterRejection.terminalMismatch) {
        try PhysicsOnlyWorldModelAdapter().accept(prediction: prediction, reference: reference)
    }
}

@Test func worldModelAdapterRejectsUncertaintyAboveGate() throws {
    let log = try makeStepLog()
    let observation = EnvironmentObservation(log: log)
    let info = EpisodeInfo(
        scenarioId: try ScenarioID("rl-adapter-uncertainty"),
        seed: ScenarioSeed(1),
        configHash: "hash",
        stepCount: 1,
        rewardSum: 1.0
    )
    let step = try EnvironmentStep(
        observation: observation,
        reward: 1.0,
        done: false,
        truncated: true,
        info: info,
        log: log
    )
    let prediction = try WorldModelPrediction(step: step, uncertainty: 0.2)

    #expect(throws: WorldModelAdapterRejection.uncertaintyExceeded(actual: 0.2, limit: 0.1)) {
        try PhysicsOnlyWorldModelAdapter().accept(
            prediction: prediction,
            reference: step,
            configuration: WorldModelAdapterConfiguration(uncertaintyThreshold: 0.1)
        )
    }
}

@Test func worldModelAdapterRejectsSensorSampleMismatch() throws {
    let referenceLog = try makeStepLog(sensorZ: 1.0)
    let predictedLog = try makeStepLog(sensorZ: 1.25)
    let reference = try makeStep(from: referenceLog)
    let predicted = try makeStep(from: predictedLog)
    let prediction = try WorldModelPrediction(step: predicted)

    #expect(throws: WorldModelAdapterRejection.residualExceeded(actual: 0.25, limit: 0.1)) {
        try PhysicsOnlyWorldModelAdapter().accept(
            prediction: prediction,
            reference: reference,
            configuration: WorldModelAdapterConfiguration(residualThreshold: 0.1)
        )
    }
}

private func makeStepLog() throws -> WorldStepLog {
    try makeStepLog(sensorZ: nil)
}

private func makeStepLog(sensorZ: Double?) throws -> WorldStepLog {
    let time = try WorldTime(stepIndex: 1, time: 0.001)
    let root = RigidBodySnapshot(
        id: "root",
        position: Axis3(x: 0, y: 0, z: 1),
        velocity: Axis3(x: 0, y: 0, z: 0),
        orientation: QuaternionSnapshot(w: 1, x: 0, y: 0, z: 0),
        angularVelocity: Axis3(x: 0, y: 0, z: 0)
    )
    let sensorSamples: [ChannelSample]
    if let sensorZ {
        sensorSamples = try [
            ChannelSample(channelIndex: 6, value: sensorZ, timestamp: time.time)
        ]
    } else {
        sensorSamples = []
    }
    return WorldStepLog(
        time: time,
        events: [],
        sensorSamples: sensorSamples,
        driveIntents: [],
        reflexCorrections: [],
        actuatorValues: [],
        actuatorTelemetry: ActuatorTelemetrySnapshot(channels: []),
        safetyTrace: try SafetyTrace(omegaMagnitude: 0, tiltRadians: 0),
        plantState: PlantStateSnapshot(root: root),
        disturbances: DisturbanceSnapshot(
            forceWorld: Axis3(x: 0, y: 0, z: 0),
            torqueBody: Axis3(x: 0, y: 0, z: 0)
        )
    )
}

private func makeStep(from log: WorldStepLog) throws -> EnvironmentStep {
    let observation = EnvironmentObservation(log: log)
    let info = EpisodeInfo(
        scenarioId: try ScenarioID("rl-adapter-sensor"),
        seed: ScenarioSeed(1),
        configHash: "hash",
        stepCount: 1,
        rewardSum: 1.0
    )
    return try EnvironmentStep(
        observation: observation,
        reward: 1.0,
        done: false,
        truncated: true,
        info: info,
        log: log
    )
}
