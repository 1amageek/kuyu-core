/// Per-step safety cost signal for constrained RL (CMDP) training.
///
/// A cost function is the constraint-side counterpart of `RewardFunction`:
/// it returns a non-negative scalar measuring how close the step came to
/// violating the safety envelope. Constrained policy optimization (e.g.
/// PPO-Lagrangian) bounds the expectation of this signal instead of folding
/// safety penalties into the reward.
public protocol CostFunction: Sendable {
    associatedtype Scenario: Sendable

    var descriptor: CostDescriptor { get }

    func cost(
        scenario: Scenario,
        log: WorldStepLog,
        failure: FailureEvent?,
        truncated: Bool
    ) throws -> Double
}
