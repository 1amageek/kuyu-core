public struct EpisodeInfo: Sendable, Codable, Equatable {
    public let scenarioId: ScenarioID
    public let seed: ScenarioSeed
    public let configHash: String
    public let robotManifestID: String?
    public let policyId: String?
    public let rewardDescriptor: RewardDescriptor?
    public let stepCount: Int
    public let rewardSum: Double
    public let failureReason: FailureReason?
    public let failureTime: Double?
    public let terminalReason: String?

    public init(
        scenarioId: ScenarioID,
        seed: ScenarioSeed,
        configHash: String,
        robotManifestID: String? = nil,
        policyId: String? = nil,
        rewardDescriptor: RewardDescriptor? = nil,
        stepCount: Int,
        rewardSum: Double,
        failureReason: FailureReason? = nil,
        failureTime: Double? = nil,
        terminalReason: String? = nil
    ) {
        self.scenarioId = scenarioId
        self.seed = seed
        self.configHash = configHash
        self.robotManifestID = robotManifestID
        self.policyId = policyId
        self.rewardDescriptor = rewardDescriptor
        self.stepCount = stepCount
        self.rewardSum = rewardSum
        self.failureReason = failureReason
        self.failureTime = failureTime
        self.terminalReason = terminalReason
    }
}
