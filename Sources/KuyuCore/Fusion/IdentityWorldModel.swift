import Foundation

/// Identity world model: residual=0, extensions=empty.
/// Produces no corrections and no extensions.
/// FusedEnvironment with IdentityWorldModel is numerically identical to existing Kuyu.
public struct IdentityWorldModel: WorldModelProtocol {
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

    public mutating func reset() throws {}
}
