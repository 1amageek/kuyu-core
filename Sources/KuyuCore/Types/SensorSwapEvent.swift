
public struct SensorSwapEvent: Sendable, Codable, Equatable {
    public enum SwapKind: String, Sendable, Codable, Equatable {
        case swapUnit
        case calibShift
        case driftChange
        case dropoutBurst
        case latencyChange
        case bandwidthChange
    }

    public enum ValidationError: Error, Equatable {
        case nonFinite
        case negative
    }

    public let kind: SwapKind
    public let startTime: Double
    public let duration: Double
    public let targetChannels: [UInt32]
    public let gainScale: Double
    public let biasShift: Double
    public let noiseScale: Double
    public let dropoutProbability: Double
    public let delayShiftSteps: Int
    /// First-order low-pass bandwidth modifier as a fraction of full bandwidth.
    /// `1.0` keeps the signal unfiltered; values in `(0, 1)` attenuate high-frequency
    /// content (smaller = stronger low-pass). This is the A1 sensor `bandwidth` range.
    public let bandwidthScale: Double

    public init(
        kind: SwapKind,
        startTime: Double,
        duration: Double,
        targetChannels: [UInt32],
        gainScale: Double,
        biasShift: Double,
        noiseScale: Double,
        dropoutProbability: Double,
        delayShiftSteps: Int,
        bandwidthScale: Double = 1.0
    ) throws {
        guard startTime.isFinite, duration.isFinite, gainScale.isFinite, biasShift.isFinite,
              noiseScale.isFinite, dropoutProbability.isFinite, bandwidthScale.isFinite else {
            throw ValidationError.nonFinite
        }
        guard startTime >= 0, duration >= 0, gainScale > 0, noiseScale > 0, bandwidthScale > 0 else {
            throw ValidationError.negative
        }
        self.kind = kind
        self.startTime = startTime
        self.duration = duration
        self.targetChannels = targetChannels
        self.gainScale = gainScale
        self.biasShift = biasShift
        self.noiseScale = noiseScale
        self.dropoutProbability = min(max(dropoutProbability, 0.0), 1.0)
        self.delayShiftSteps = delayShiftSteps
        self.bandwidthScale = min(max(bandwidthScale, 0.0001), 1.0)
    }

    private enum CodingKeys: String, CodingKey {
        case kind, startTime, duration, targetChannels, gainScale, biasShift
        case noiseScale, dropoutProbability, delayShiftSteps, bandwidthScale
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Backward compatible: artifacts written before bandwidth modeling omit this key.
        try self.init(
            kind: try container.decode(SwapKind.self, forKey: .kind),
            startTime: try container.decode(Double.self, forKey: .startTime),
            duration: try container.decode(Double.self, forKey: .duration),
            targetChannels: try container.decode([UInt32].self, forKey: .targetChannels),
            gainScale: try container.decode(Double.self, forKey: .gainScale),
            biasShift: try container.decode(Double.self, forKey: .biasShift),
            noiseScale: try container.decode(Double.self, forKey: .noiseScale),
            dropoutProbability: try container.decode(Double.self, forKey: .dropoutProbability),
            delayShiftSteps: try container.decode(Int.self, forKey: .delayShiftSteps),
            bandwidthScale: try container.decodeIfPresent(Double.self, forKey: .bandwidthScale) ?? 1.0
        )
    }
}
