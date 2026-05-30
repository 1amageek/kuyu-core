
public struct ActuatorSwapEvent: Sendable, Codable, Equatable {
    public enum SwapKind: String, Sendable, Codable, Equatable {
        case swapUnit
        case gainShift
        case lagShift
        case maxOutputShift
        case deadzoneShift
        case rateLimitShift
        case asymmetryShift
    }

    public enum ValidationError: Error, Equatable {
        case nonFinite
        case negative
    }

    public let kind: SwapKind
    public let startTime: Double
    public let duration: Double
    public let motorIndex: UInt32
    public let gainScale: Double
    public let lagScale: Double
    public let maxOutputScale: Double
    public let deadzoneShift: Double
    /// Per-step slew limit as a fraction of full-scale output reachable in one Δt.
    /// `1.0` (or greater) disables rate limiting; values in `(0, 1)` clamp the
    /// per-step command change. This is the A1 actuator `rate_limit` range.
    public let rateLimitScale: Double
    /// Rising-edge gain asymmetry. `1.0` is symmetric; values in `(0, 1)` make the
    /// actuator respond more slowly to increasing commands than to decreasing ones.
    /// This is the A1 actuator `asymmetry` range.
    public let asymmetryScale: Double

    public init(
        kind: SwapKind,
        startTime: Double,
        duration: Double,
        motorIndex: UInt32,
        gainScale: Double,
        lagScale: Double,
        maxOutputScale: Double,
        deadzoneShift: Double,
        rateLimitScale: Double = 1.0,
        asymmetryScale: Double = 1.0
    ) throws {
        guard startTime.isFinite, duration.isFinite, gainScale.isFinite,
              lagScale.isFinite, maxOutputScale.isFinite, deadzoneShift.isFinite,
              rateLimitScale.isFinite, asymmetryScale.isFinite else {
            throw ValidationError.nonFinite
        }
        guard startTime >= 0, duration >= 0, gainScale > 0, lagScale > 0, maxOutputScale > 0,
              rateLimitScale > 0, asymmetryScale > 0 else {
            throw ValidationError.negative
        }
        self.kind = kind
        self.startTime = startTime
        self.duration = duration
        self.motorIndex = motorIndex
        self.gainScale = gainScale
        self.lagScale = lagScale
        self.maxOutputScale = maxOutputScale
        self.deadzoneShift = deadzoneShift
        self.rateLimitScale = rateLimitScale
        self.asymmetryScale = asymmetryScale
    }

    private enum CodingKeys: String, CodingKey {
        case kind, startTime, duration, motorIndex, gainScale, lagScale
        case maxOutputScale, deadzoneShift, rateLimitScale, asymmetryScale
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Backward compatible: artifacts written before rate-limit/asymmetry modeling omit these keys.
        try self.init(
            kind: try container.decode(SwapKind.self, forKey: .kind),
            startTime: try container.decode(Double.self, forKey: .startTime),
            duration: try container.decode(Double.self, forKey: .duration),
            motorIndex: try container.decode(UInt32.self, forKey: .motorIndex),
            gainScale: try container.decode(Double.self, forKey: .gainScale),
            lagScale: try container.decode(Double.self, forKey: .lagScale),
            maxOutputScale: try container.decode(Double.self, forKey: .maxOutputScale),
            deadzoneShift: try container.decode(Double.self, forKey: .deadzoneShift),
            rateLimitScale: try container.decodeIfPresent(Double.self, forKey: .rateLimitScale) ?? 1.0,
            asymmetryScale: try container.decodeIfPresent(Double.self, forKey: .asymmetryScale) ?? 1.0
        )
    }
}
