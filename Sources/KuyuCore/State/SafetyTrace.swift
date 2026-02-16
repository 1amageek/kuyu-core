import simd

public struct SafetyTrace: Sendable, Codable, Equatable {
    public enum ValidationError: Error, Equatable {
        case nonFiniteOmegaMagnitude
        case negativeOmegaMagnitude
        case nonFiniteTiltRadians
        case tiltRadiansOutOfRange
    }

    public let omegaMagnitude: Double
    public let tiltRadians: Double

    public init(omegaMagnitude: Double, tiltRadians: Double) throws {
        guard omegaMagnitude.isFinite else { throw ValidationError.nonFiniteOmegaMagnitude }
        guard omegaMagnitude >= 0 else { throw ValidationError.negativeOmegaMagnitude }
        guard tiltRadians.isFinite else { throw ValidationError.nonFiniteTiltRadians }
        guard tiltRadians >= 0, tiltRadians <= .pi else { throw ValidationError.tiltRadiansOutOfRange }
        self.omegaMagnitude = omegaMagnitude
        self.tiltRadians = tiltRadians
    }

    public init(root: RigidBodySnapshot) {
        let omegaMagnitude = simd_length(root.angularVelocity.simd)
        let bodyZ = root.orientation.act(SIMD3<Double>(0, 0, 1))
        let dot = max(-1.0, min(1.0, simd_dot(bodyZ, SIMD3<Double>(0, 0, 1))))
        let tilt = acos(dot)
        do {
            try self.init(omegaMagnitude: omegaMagnitude, tiltRadians: tilt)
        } catch {
            preconditionFailure("SafetyTrace from RigidBodySnapshot produced invalid values: \(error)")
        }
    }
}
