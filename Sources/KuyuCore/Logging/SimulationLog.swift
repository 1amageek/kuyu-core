public struct SimulationLog: Sendable, Codable, Equatable {
    public let scenarioId: ScenarioID
    public let seed: ScenarioSeed
    public let timeStep: TimeStep
    public let determinism: DeterminismConfig
    public let configHash: String
    public let events: [WorldStepLog]
    public let failureReason: FailureReason?
    public let failureTime: Double?
    public let observability: ObservabilityLogBundle?
    /// Scheduled swap/HF stress events for this run (A1 "Event schedule + seed" log).
    /// Optional for backward compatibility with logs written before scheduling.
    public let eventSchedule: StressEventSchedule?

    public init(
        scenarioId: ScenarioID,
        seed: ScenarioSeed,
        timeStep: TimeStep,
        determinism: DeterminismConfig,
        configHash: String,
        events: [WorldStepLog],
        failureReason: FailureReason? = nil,
        failureTime: Double? = nil,
        observability: ObservabilityLogBundle? = nil,
        eventSchedule: StressEventSchedule? = nil
    ) {
        self.scenarioId = scenarioId
        self.seed = seed
        self.timeStep = timeStep
        self.determinism = determinism
        self.configHash = configHash
        self.events = events
        self.failureReason = failureReason
        self.failureTime = failureTime
        self.observability = observability
        self.eventSchedule = eventSchedule
    }

    /// Returns a copy with the stress-event schedule attached.
    public func withEventSchedule(_ schedule: StressEventSchedule) -> SimulationLog {
        SimulationLog(
            scenarioId: scenarioId,
            seed: seed,
            timeStep: timeStep,
            determinism: determinism,
            configHash: configHash,
            events: events,
            failureReason: failureReason,
            failureTime: failureTime,
            observability: observability,
            eventSchedule: schedule
        )
    }
}
