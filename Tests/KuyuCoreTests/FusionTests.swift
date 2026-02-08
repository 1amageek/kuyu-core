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
