public struct WorldModelAdapterConfiguration: Sendable, Codable, Equatable {
    public let residualThreshold: Double
    public let uncertaintyThreshold: Double

    public init(
        residualThreshold: Double = 1e-9,
        uncertaintyThreshold: Double = 0.5
    ) {
        self.residualThreshold = residualThreshold
        self.uncertaintyThreshold = uncertaintyThreshold
    }
}

public enum WorldModelAdapterRejection: Error, Sendable, Codable, Equatable {
    case nonFinitePrediction
    case uncertaintyExceeded(actual: Double, limit: Double)
    case terminalMismatch
    case residualExceeded(actual: Double, limit: Double)
}

public struct WorldModelPrediction: Sendable, Codable, Equatable {
    public let step: EnvironmentStep
    public let uncertainty: Double

    public init(step: EnvironmentStep, uncertainty: Double = 0.0) throws {
        guard uncertainty.isFinite else { throw WorldModelAdapterRejection.nonFinitePrediction }
        self.step = step
        self.uncertainty = uncertainty
    }
}

public struct WorldModelAdapterValidation: Sendable, Codable, Equatable {
    public let accepted: Bool
    public let residualMax: Double
    public let uncertainty: Double
    public let reason: String?

    public init(
        accepted: Bool,
        residualMax: Double,
        uncertainty: Double = 0.0,
        reason: String? = nil
    ) {
        self.accepted = accepted
        self.residualMax = residualMax
        self.uncertainty = uncertainty
        self.reason = reason
    }
}

public protocol WorldModelEnvironmentAdapter: Sendable {
    func predict(reference: EnvironmentStep) throws -> WorldModelPrediction
    func validate(predicted: EnvironmentStep, reference: EnvironmentStep) throws -> WorldModelAdapterValidation
    func validate(
        prediction: WorldModelPrediction,
        reference: EnvironmentStep,
        configuration: WorldModelAdapterConfiguration
    ) throws -> WorldModelAdapterValidation
    func accept(
        prediction: WorldModelPrediction,
        reference: EnvironmentStep,
        configuration: WorldModelAdapterConfiguration
    ) throws -> EnvironmentStep
}

public struct PhysicsOnlyWorldModelAdapter: WorldModelEnvironmentAdapter {
    public init() {}

    public func predict(reference: EnvironmentStep) throws -> WorldModelPrediction {
        try WorldModelPrediction(step: reference, uncertainty: 0.0)
    }

    public func validate(predicted: EnvironmentStep, reference: EnvironmentStep) throws -> WorldModelAdapterValidation {
        try validate(
            prediction: WorldModelPrediction(step: predicted, uncertainty: 0.0),
            reference: reference,
            configuration: WorldModelAdapterConfiguration()
        )
    }

    public func validate(
        prediction: WorldModelPrediction,
        reference: EnvironmentStep,
        configuration: WorldModelAdapterConfiguration = WorldModelAdapterConfiguration()
    ) throws -> WorldModelAdapterValidation {
        guard prediction.step.reward.isFinite else {
            throw WorldModelAdapterRejection.nonFinitePrediction
        }
        guard prediction.uncertainty <= configuration.uncertaintyThreshold else {
            throw WorldModelAdapterRejection.uncertaintyExceeded(
                actual: prediction.uncertainty,
                limit: configuration.uncertaintyThreshold
            )
        }
        guard prediction.step.done == reference.done && prediction.step.truncated == reference.truncated else {
            throw WorldModelAdapterRejection.terminalMismatch
        }
        let residualMax = maxResidual(prediction.step.observation, reference.observation)
        guard residualMax <= configuration.residualThreshold else {
            throw WorldModelAdapterRejection.residualExceeded(
                actual: residualMax,
                limit: configuration.residualThreshold
            )
        }
        return WorldModelAdapterValidation(
            accepted: true,
            residualMax: residualMax,
            uncertainty: prediction.uncertainty
        )
    }

    public func accept(
        prediction: WorldModelPrediction,
        reference: EnvironmentStep,
        configuration: WorldModelAdapterConfiguration = WorldModelAdapterConfiguration()
    ) throws -> EnvironmentStep {
        _ = try validate(prediction: prediction, reference: reference, configuration: configuration)
        return prediction.step
    }

    private func maxResidual(_ lhs: EnvironmentObservation, _ rhs: EnvironmentObservation) -> Double {
        let lhsVector = observationVector(lhs)
        let rhsVector = observationVector(rhs)
        guard lhsVector.count == rhsVector.count else { return .infinity }
        return zip(lhsVector, rhsVector).reduce(0.0) { partial, pair in
            max(partial, abs(pair.0 - pair.1))
        }
    }

    private func observationVector(_ observation: EnvironmentObservation) -> [Double] {
        let root = observation.plantState.root
        let sensorVector = observation.sensorSamples
            .sorted { lhs, rhs in lhs.channelIndex < rhs.channelIndex }
            .flatMap { sample in
                [Double(sample.channelIndex), sample.value, sample.timestamp]
            }
        return [
            observation.time.time,
            root.position.x, root.position.y, root.position.z,
            root.velocity.x, root.velocity.y, root.velocity.z,
            root.orientation.w, root.orientation.x, root.orientation.y, root.orientation.z,
            root.angularVelocity.x, root.angularVelocity.y, root.angularVelocity.z,
            observation.safetyTrace.omegaMagnitude,
            observation.safetyTrace.tiltRadians
        ] + sensorVector
    }
}
