import Foundation

/// Identity world model: residual=0, extensions=empty.
/// Produces no corrections and no extensions.
/// FusedEnvironment with IdentityWorldModel is numerically identical to existing Kuyu.
public struct IdentityWorldModel: PhysicsAwareWorldModelProtocol {
    public enum IdentityWorldModelError: Error, Equatable {
        case physicsPredictionCountMismatch(expected: Int, actual: Int)
    }

    private let physicsDimensions: Int

    public init(physicsDimensions: Int) {
        self.physicsDimensions = physicsDimensions
    }

    public mutating func infer(
        physicsPrediction: some AnalyticalState,
        sensorObservations: [ChannelSample],
        action: [ActuatorValue],
        dt: TimeInterval
    ) throws -> WorldModelOutput {
        .identity(physicsDimensions: physicsDimensions)
    }

    public mutating func predictFuture(
        steps: Int,
        actions: [[ActuatorValue]]
    ) throws -> [WorldModelOutput] {
        (0..<steps).map { _ in .identity(physicsDimensions: physicsDimensions) }
    }

    public func predictFuture(
        physicsPredictions: [[Float]],
        actions: [[ActuatorValue]],
        dt: TimeInterval
    ) throws -> [WorldModelOutput] {
        guard physicsPredictions.count == actions.count else {
            throw IdentityWorldModelError.physicsPredictionCountMismatch(
                expected: actions.count,
                actual: physicsPredictions.count
            )
        }
        return physicsPredictions.map { values in
            WorldModelOutput.identity(physicsDimensions: values.count)
        }
    }

    public mutating func reset() throws {}
}
