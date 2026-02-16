import Foundation
import Testing
@testable import KuyuCore

@Test func observabilityBundleSupportsPlannerMemoryFallbackAndArbitrationFields() throws {
    let bundle = ObservabilityLogBundle(
        plannerDecisions: [
            PlannerDecisionLog(
                time: 0.10,
                plannerID: "planner.default",
                decision: "hold-heading",
                descendingSnapshot: [0.2, -0.1]
            )
        ],
        adapterMappings: [
            AdapterMappingLog(
                time: 0.10,
                adapterID: "adapter.asc",
                fromDomain: "multimodal",
                toDomain: "ascending",
                mappedChannels: ["imu.ax", "imu.az"]
            )
        ],
        memoryRecalls: [
            MemoryRecallLog(
                time: 0.10,
                task: "recover",
                morphology: "quad",
                scenarioID: "SCN-1",
                seed: 7,
                appliedDescendingChannels: ["desc.bias.roll"]
            )
        ],
        upwardSummaries: [
            UpwardSummaryLog(
                time: 0.10,
                salience: 0.7,
                risk: 0.3,
                uncertainty: 0.2,
                constraintPressure: 0.4,
                recoveryState: 0.8
            )
        ],
        arbitrationOutcomes: [
            ArbitrationOutcomeLog(
                time: 0.10,
                descending: [0.1, 0.1],
                coreDrive: [0.6, 0.5],
                reflexClamp: [0.8, 1.0],
                mergedDrive: [0.48, 0.5]
            )
        ],
        fallbackTransitions: [
            FallbackTransitionLog(
                time: 0.11,
                from: "planner.default",
                to: "hold-last",
                reason: "planner-timeout"
            )
        ],
        latencyBudgetViolations: [
            try LatencyBudgetViolation(
                path: "reflexPath",
                budgetMs: 2.0,
                observedMs: 2.8,
                time: 0.11,
                reason: "scheduler-jitter"
            )
        ],
        incidents: [
            IncidentSummaryLog(
                scenarioID: "SCN-1",
                seed: 7,
                reason: "ground-violation",
                time: 1.20
            )
        ]
    )

    #expect(bundle.plannerDecisions.count == 1)
    #expect(bundle.memoryRecalls.first?.scenarioID == "SCN-1")
    #expect(bundle.upwardSummaries.first?.risk == 0.3)
    #expect(bundle.arbitrationOutcomes.first?.mergedDrive == [0.48, 0.5])
    #expect(bundle.fallbackTransitions.first?.reason == "planner-timeout")
    #expect(bundle.latencyBudgetViolations.first?.path == "reflexPath")
}

@Test func simulationLogRoundTripPreservesObservabilityBundle() throws {
    let observability = ObservabilityLogBundle(
        upwardSummaries: [
            UpwardSummaryLog(
                time: 0.0,
                salience: 0.5,
                risk: 0.1,
                uncertainty: 0.2,
                constraintPressure: 0.3,
                recoveryState: 0.9
            )
        ]
    )
    let log = try makeLog(observability: observability)

    let encoded = try JSONEncoder().encode(log)
    let decoded = try JSONDecoder().decode(SimulationLog.self, from: encoded)

    #expect(decoded.observability?.upwardSummaries.count == 1)
    #expect(decoded.observability?.upwardSummaries.first?.recoveryState == 0.9)
}

@Test func simulationLogOmitsObservabilityWhenUnset() throws {
    let log = try makeLog(observability: nil)
    let encoded = try JSONEncoder().encode(log)
    let payload = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

    #expect(payload?["observability"] == nil)

    let decoded = try JSONDecoder().decode(SimulationLog.self, from: encoded)
    #expect(decoded.observability == nil)
}

private func makeLog(observability: ObservabilityLogBundle?) throws -> SimulationLog {
    SimulationLog(
        scenarioId: try ScenarioID("OBS-SCN"),
        seed: ScenarioSeed(10),
        timeStep: try TimeStep(delta: 0.01),
        determinism: try DeterminismConfig(tier: .tier0, tier1Tolerance: nil),
        configHash: "cfg-obs",
        events: [try makeStep()],
        failureReason: nil,
        failureTime: nil,
        observability: observability
    )
}

private func makeStep() throws -> WorldStepLog {
    let root = RigidBodySnapshot(
        id: "root",
        position: Axis3(x: 0, y: 0, z: 0),
        velocity: Axis3(x: 0, y: 0, z: 0),
        orientation: QuaternionSnapshot(w: 1, x: 0, y: 0, z: 0),
        angularVelocity: Axis3(x: 0, y: 0, z: 0)
    )
    return WorldStepLog(
        time: try WorldTime(stepIndex: 0, time: 0.0),
        events: [.timeAdvance, .logging],
        sensorSamples: [],
        driveIntents: [],
        reflexCorrections: [],
        actuatorValues: [],
        actuatorTelemetry: ActuatorTelemetrySnapshot(channels: []),
        safetyTrace: try SafetyTrace(omegaMagnitude: 0.0, tiltRadians: 0.0),
        plantState: PlantStateSnapshot(root: root),
        disturbances: DisturbanceSnapshot(
            forceWorld: Axis3(x: 0, y: 0, z: 0),
            torqueBody: Axis3(x: 0, y: 0, z: 0)
        )
    )
}
