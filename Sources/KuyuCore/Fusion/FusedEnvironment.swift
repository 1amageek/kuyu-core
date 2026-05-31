import Foundation

/// Fused environment. Composes an AnalyticalModel, a WorldModelProtocol, and a SensorField.
///
/// Step sequence:
/// 1. Physics computes (ODE integration)
/// 2. Sensors sample
/// 3. World model computes corrections + extensions (receives physics prediction as input)
/// 4. FusedState is constructed (physics preserved as-is)
public struct FusedEnvironment<A: AnalyticalModel, W: WorldModelProtocol, S: SensorField> {
    public var analyticalModel: A
    public var worldModel: W
    public var sensorField: S

    public init(
        analyticalModel: A,
        worldModel: W,
        sensorField: S
    ) {
        self.analyticalModel = analyticalModel
        self.worldModel = worldModel
        self.sensorField = sensorField
    }

    /// Execute one environment step.
    /// Returns a FusedState containing the untouched physics prediction
    /// plus world model corrections and extensions.
    public mutating func step(
        action: [ActuatorValue],
        dt: TimeInterval,
        time: WorldTime
    ) throws -> FusedState<A.State> {
        // 1. Physics computes (ODE integration)
        let physicsState = try analyticalModel.predict(action: action, dt: dt)

        // 2. Sensors sample
        let observations = try sensorField.sample(time: time)

        // 3. World model computes corrections + extensions
        let wmOutput = try worldModel.infer(
            physicsPrediction: physicsState,
            sensorObservations: observations,
            action: action,
            dt: dt
        )

        // 4. Construct fused state (physics preserved as-is)
        return FusedState(physics: physicsState, worldModelOutput: wmOutput)
    }

    /// Reset both analytical model and world model.
    public mutating func reset() throws {
        try analyticalModel.reset()
        try worldModel.reset()
    }
}

extension FusedEnvironment where W: PhysicsAwareWorldModelProtocol {
    /// Predict future fused states by advancing analytical physics on local copies.
    ///
    /// This is the physics-aware imagination path. It does not sample future
    /// sensors and it does not mutate the live analytical model or world model.
    public func predictFuture(
        actions: [[ActuatorValue]],
        dt: TimeInterval,
        startTime: WorldTime
    ) throws -> [FusedState<A.State>] {
        var analyticalModel = self.analyticalModel
        var time = startTime
        var physicsStates: [A.State] = []
        physicsStates.reserveCapacity(actions.count)

        for action in actions {
            time = try time.advanced(by: dt)
            physicsStates.append(try analyticalModel.predict(action: action, dt: dt))
        }

        let outputs = try worldModel.predictFuture(
            physicsPredictions: physicsStates.map { $0.toArray() },
            actions: actions,
            dt: dt
        )
        guard outputs.count == physicsStates.count else {
            throw FusedEnvironmentError.worldModelFutureCountMismatch(
                expected: physicsStates.count,
                actual: outputs.count
            )
        }

        return zip(physicsStates, outputs).map { physicsState, output in
            FusedState(physics: physicsState, worldModelOutput: output)
        }
    }
}
