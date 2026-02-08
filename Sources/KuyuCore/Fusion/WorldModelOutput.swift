/// Output from a world model. Does not modify physics — provides corrections and extensions.
public struct WorldModelOutput: Sendable, Equatable {

    public enum ValidationError: Error, Equatable {
        case nonFiniteResidual(index: Int)
        case nonFiniteExtension(index: Int)
        case nonFiniteUncertainty(index: Int)
    }

    /// Additive corrections to physics prediction (same dimension space).
    /// residual[i] is an additive correction to physics_state[i].
    /// When untrained: all zeros.
    public let residual: [Float]

    /// Additional dimensions not present in physics model
    /// (environment context, adaptation vector, uncertainty estimates).
    /// Dimension count is determined by the WorldModel design.
    public let extensions: [Float]

    /// Per-dimension confidence estimates for residual + extensions.
    public let uncertainty: [Float]

    public init(residual: [Float], extensions: [Float], uncertainty: [Float]) throws {
        for (i, v) in residual.enumerated() {
            guard v.isFinite else { throw ValidationError.nonFiniteResidual(index: i) }
        }
        for (i, v) in extensions.enumerated() {
            guard v.isFinite else { throw ValidationError.nonFiniteExtension(index: i) }
        }
        for (i, v) in uncertainty.enumerated() {
            guard v.isFinite else { throw ValidationError.nonFiniteUncertainty(index: i) }
        }
        self.residual = residual
        self.extensions = extensions
        self.uncertainty = uncertainty
    }

    /// Identity output with no corrections and no extensions.
    public static func identity(physicsDimensions: Int) -> WorldModelOutput {
        // Safe: all values are literal zeros (always finite).
        WorldModelOutput(
            uncheckedResidual: Array(repeating: 0, count: physicsDimensions),
            extensions: [],
            uncertainty: []
        )
    }

    /// Internal unchecked initializer for known-safe values.
    init(uncheckedResidual: [Float], extensions: [Float], uncertainty: [Float]) {
        self.residual = uncheckedResidual
        self.extensions = extensions
        self.uncertainty = uncertainty
    }
}
