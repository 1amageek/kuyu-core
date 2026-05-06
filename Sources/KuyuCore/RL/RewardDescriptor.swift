public struct RewardDescriptor: Sendable, Codable, Equatable {
    public let id: String
    public let version: String
    public let configHash: String

    public init(id: String, version: String, configHash: String) {
        self.id = id
        self.version = version
        self.configHash = configHash
    }
}
