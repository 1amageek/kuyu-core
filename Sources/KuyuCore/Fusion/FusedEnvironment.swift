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

    /// Predict future fused states by advancing analytical physics at every step.
    ///
    /// This is the physics-aware imagination path: the world model receives an
    /// analytical prediction for each future action instead of rolling out by
    /// accumulating residuals alone.
    public mutating func predictFuture(
        actions: [[ActuatorValue]],
        dt: TimeInterval,
        startTime: WorldTime
    ) throws -> [FusedState<A.State>] {
        var time = startTime
        var states: [FusedState<A.State>] = []
        states.reserveCapacity(actions.count)

        for action in actions {
            time = try time.advanced(by: dt)
            let physicsState = try analyticalModel.predict(action: action, dt: dt)
            let observations = try sensorField.sample(time: time)
            let output = try worldModel.infer(
                physicsPrediction: physicsState,
                sensorObservations: observations,
                action: action,
                dt: dt
            )
            states.append(FusedState(physics: physicsState, worldModelOutput: output))
        }

        return states
    }

    /// Reset both analytical model and world model.
    public mutating func reset() throws {
        try analyticalModel.reset()
        try worldModel.reset()
    }
}
