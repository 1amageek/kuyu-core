public protocol KuyuEnvironment {
    associatedtype Scenario: Sendable

    mutating func reset(seed: ScenarioSeed, scenario: Scenario) throws -> EnvironmentObservation
    mutating func step(action: EnvironmentAction) throws -> EnvironmentStep
}
