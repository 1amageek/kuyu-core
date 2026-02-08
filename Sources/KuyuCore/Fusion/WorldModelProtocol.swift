import Foundation

/// World model protocol. Receives physics predictions and produces corrections + extensions.
/// Physics predictions are NEVER modified. Information is added on top.
public protocol WorldModelProtocol: Sendable {
    /// Compute residual corrections and latent extensions
    /// from physics prediction + sensor observations.
    mutating func infer(
        physicsPrediction: some AnalyticalState,
        sensorObservations: [ChannelSample],
        action: [ActuatorValue],
        dt: TimeInterval
    ) throws -> WorldModelOutput

    /// Predict future steps for imagination-based RL.
    mutating func predictFuture(
        steps: Int,
        actions: [[ActuatorValue]]
    ) throws -> [WorldModelOutput]

    /// Reset internal state.
    mutating func reset() throws
}
