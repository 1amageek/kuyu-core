import Testing
@testable import KuyuCore

// MARK: - Test Helpers

struct TestAnalyticalState: AnalyticalState {
    let values: [Float]

    var dimensions: Int { values.count }

    func toArray() -> [Float] { values }

    func toPlantStateSnapshot() -> PlantStateSnapshot {
        PlantStateSnapshot(
            root: RigidBodySnapshot(
                id: "test",
                position: Axis3(x: 0, y: 0, z: 0),
                velocity: Axis3(x: 0, y: 0, z: 0),
                orientation: QuaternionSnapshot(w: 1, x: 0, y: 0, z: 0),
                angularVelocity: Axis3(x: 0, y: 0, z: 0)
            )
        )
    }
}

struct TestAnalyticalModel: AnalyticalModel {
    var currentState: TestAnalyticalState

    mutating func predict(action: [ActuatorValue], dt: Double) throws -> TestAnalyticalState {
        let delta = Float(action.first?.value ?? 0)
        currentState = TestAnalyticalState(values: currentState.values.map { $0 + delta })
        return currentState
    }

    mutating func reset() throws {
        currentState = TestAnalyticalState(values: [0, 0])
    }
}

struct EmptySensorField: SensorField {
    var sampledTimes: [WorldTime] = []

    mutating func sample(time: WorldTime) throws -> [ChannelSample] {
        sampledTimes.append(time)
        return []
    }
}

struct RecordingWorldModel: PhysicsAwareWorldModelProtocol {
    var physicsInputs: [[Float]] = []

    mutating func infer(
        physicsPrediction: some AnalyticalState,
        sensorObservations: [ChannelSample],
        action: [ActuatorValue],
        dt: Double
    ) throws -> WorldModelOutput {
        let values = physicsPrediction.toArray()
        physicsInputs.append(values)
        return .identity(physicsDimensions: values.count)
    }

    mutating func predictFuture(
        steps: Int,
        actions: [[ActuatorValue]]
    ) throws -> [WorldModelOutput] {
        (0..<steps).map { _ in .identity(physicsDimensions: 2) }
    }

    mutating func predictFuture(
        physicsPredictions: [[Float]],
        actions: [[ActuatorValue]],
        dt: Double
    ) throws -> [WorldModelOutput] {
        try physicsPredictions.map { values in
            try WorldModelOutput(residual: values, extensions: [], uncertainty: [])
        }
    }

    mutating func reset() throws {
        physicsInputs.removeAll()
    }
}

// MARK: - WorldModelOutput Tests

@Test func worldModelOutputIdentityHasZeroResidual() {
    let output = WorldModelOutput.identity(physicsDimensions: 13)
    #expect(output.residual.count == 13)
    #expect(output.residual.allSatisfy { $0 == 0 })
    #expect(output.extensions.isEmpty)
    #expect(output.uncertainty.isEmpty)
}

// MARK: - FusedState Tests

@Test func fusedStateCorrectedStateEqualsPhysicsWhenResidualZero() throws {
    let physics = TestAnalyticalState(values: [1.0, 2.0, 3.0])
    let output = WorldModelOutput.identity(physicsDimensions: 3)
    let fused = FusedState(physics: physics, worldModelOutput: output)

    #expect(try fused.correctedState() == [1.0, 2.0, 3.0])
    #expect(fused.extensionState.isEmpty)
}

@Test func fusedStateCorrectedStateAppliesResidual() throws {
    let physics = TestAnalyticalState(values: [1.0, 2.0, 3.0])
    let output = try WorldModelOutput(
        residual: [0.1, -0.2, 0.3],
        extensions: [0.5, 0.6],
        uncertainty: [0.9, 0.8]
    )
    let fused = FusedState(physics: physics, worldModelOutput: output)

    let corrected = try fused.correctedState()
    #expect(corrected.count == 3)
    #expect(abs(corrected[0] - 1.1) < 1e-6)
    #expect(abs(corrected[1] - 1.8) < 1e-6)
    #expect(abs(corrected[2] - 3.3) < 1e-6)

    #expect(fused.extensionState == [0.5, 0.6])
    #expect(fused.uncertaintyState == [0.9, 0.8])
}

@Test func fusedStateCorrectedStateThrowsOnDimensionMismatch() throws {
    let physics = TestAnalyticalState(values: [1.0, 2.0, 3.0])
    let output = try WorldModelOutput(
        residual: [0.1, -0.2],  // 2 dims vs 3 physics dims
        extensions: [],
        uncertainty: []
    )
    let fused = FusedState(physics: physics, worldModelOutput: output)

    #expect(throws: FusedState<TestAnalyticalState>.FusedStateError.self) {
        try fused.correctedState()
    }
}

@Test func fusedEnvironmentPredictFutureUsesLocalPhysicsPriorWithoutSamplingSensors() throws {
    let environment = FusedEnvironment(
        analyticalModel: TestAnalyticalModel(currentState: TestAnalyticalState(values: [0, 10])),
        worldModel: RecordingWorldModel(),
        sensorField: EmptySensorField()
    )
    let actions = [
        [try ActuatorValue(index: ActuatorIndex(0), value: 1)],
        [try ActuatorValue(index: ActuatorIndex(0), value: 2)],
    ]

    let states = try environment.predictFuture(
        actions: actions,
        dt: 0.1,
        startTime: try WorldTime(stepIndex: 0, time: 0)
    )

    #expect(states.map { $0.physics.toArray() } == [[1, 11], [3, 13]])
    #expect(states.map { $0.worldModelOutput.residual } == [[1, 11], [3, 13]])
    #expect(environment.analyticalModel.currentState.toArray() == [0, 10])
    #expect(environment.sensorField.sampledTimes.isEmpty)
}

@Test func worldModelOutputRejectsNonFiniteResidual() {
    #expect(throws: WorldModelOutput.ValidationError.self) {
        try WorldModelOutput(residual: [1.0, Float.nan], extensions: [], uncertainty: [])
    }
}

@Test func worldModelOutputRejectsNonFiniteExtension() {
    #expect(throws: WorldModelOutput.ValidationError.self) {
        try WorldModelOutput(residual: [], extensions: [Float.infinity], uncertainty: [])
    }
}

// MARK: - IdentityWorldModel Tests

@Test func identityWorldModelProducesZeroResidual() throws {
    var model = IdentityWorldModel(physicsDimensions: 13)
    let state = TestAnalyticalState(values: Array(repeating: 1.0, count: 13))

    let output = try model.infer(
        physicsPrediction: state,
        sensorObservations: [],
        action: [],
        dt: 0.005
    )

    #expect(output.residual.count == 13)
    #expect(output.residual.allSatisfy { $0 == 0 })
    #expect(output.extensions.isEmpty)
    #expect(output.uncertainty.isEmpty)
}

@Test func identityWorldModelPredictFutureProducesZeroResiduals() throws {
    var model = IdentityWorldModel(physicsDimensions: 4)

    let outputs = try model.predictFuture(steps: 5, actions: [])
    #expect(outputs.count == 5)
    for output in outputs {
        #expect(output.residual == Array(repeating: Float(0), count: 4))
        #expect(output.extensions.isEmpty)
    }
}

@Test func identityWorldModelPhysicsAwarePredictFutureMatchesPhysicsDimensions() throws {
    var model = IdentityWorldModel(physicsDimensions: 4)

    let outputs = try model.predictFuture(
        physicsPredictions: [[1, 2], [3, 4, 5]],
        actions: [[], []],
        dt: 0.01
    )

    #expect(outputs.map { $0.residual.count } == [2, 3])
    #expect(outputs.allSatisfy { $0.residual.allSatisfy { $0 == 0 } })
}
