import Foundation

/// World model protocol for prior-only rollout anchored to analytical physics.
public protocol PhysicsAwareWorldModelProtocol: WorldModelProtocol {
    /// Predict future outputs from a precomputed analytical physics trajectory.
    ///
    /// Implementations must use prior/imagination dynamics and must not consume
    /// future sensor observations. `physicsPredictions` and `actions` describe
    /// the same horizon and must have identical counts.
    mutating func predictFuture(
        physicsPredictions: [[Float]],
        actions: [[ActuatorValue]],
        dt: TimeInterval
    ) throws -> [WorldModelOutput]
}
