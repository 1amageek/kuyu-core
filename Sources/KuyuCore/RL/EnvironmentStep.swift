public struct EnvironmentStep: Sendable, Codable, Equatable {
    public enum ValidationError: Error, Equatable {
        case nonFiniteReward
    }

    public let observation: EnvironmentObservation
    public let reward: Double
    public let done: Bool
    public let truncated: Bool
    public let info: EpisodeInfo
    public let log: WorldStepLog

    public init(
        observation: EnvironmentObservation,
        reward: Double,
        done: Bool,
        truncated: Bool,
        info: EpisodeInfo,
        log: WorldStepLog
    ) throws {
        guard reward.isFinite else { throw ValidationError.nonFiniteReward }
        self.observation = observation
        self.reward = reward
        self.done = done
        self.truncated = truncated
        self.info = info
        self.log = log
    }
}
