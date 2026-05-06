public protocol RewardFunction: Sendable {
    associatedtype Scenario: Sendable

    var descriptor: RewardDescriptor { get }

    func reward(
        scenario: Scenario,
        log: WorldStepLog,
        failure: FailureEvent?,
        truncated: Bool
    ) throws -> Double
}
