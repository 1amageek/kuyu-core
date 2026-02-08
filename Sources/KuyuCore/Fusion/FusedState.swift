/// Fused state: composition of physics + correction + extension.
/// Physics is preserved as-is. Never mixed or overwritten.
public struct FusedState<S: AnalyticalState>: Sendable {

    public enum FusedStateError: Error, Equatable {
        case residualDimensionMismatch(physicsDimensions: Int, residualDimensions: Int)
    }

    /// Physics model prediction (never modified).
    public let physics: S

    /// World model output (residual corrections + latent extensions).
    public let worldModelOutput: WorldModelOutput

    public init(physics: S, worldModelOutput: WorldModelOutput) {
        self.physics = physics
        self.worldModelOutput = worldModelOutput
    }

    /// Corrected physics state (= physics + residual).
    /// For ascending Type P + R channels to the controller.
    /// Throws if residual dimensions do not match physics dimensions.
    public func correctedState() throws -> [Float] {
        let base = physics.toArray()
        let residual = worldModelOutput.residual
        guard base.count == residual.count else {
            throw FusedStateError.residualDimensionMismatch(
                physicsDimensions: base.count,
                residualDimensions: residual.count
            )
        }
        return zip(base, residual).map { $0 + $1 }
    }

    /// Extension state (dimensions not present in physics).
    /// For ascending Type E channels to the controller.
    public var extensionState: [Float] {
        worldModelOutput.extensions
    }

    /// Uncertainty per dimension.
    public var uncertaintyState: [Float] {
        worldModelOutput.uncertainty
    }
}
