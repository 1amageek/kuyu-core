public struct CutObservabilityEvents: Sendable, Codable, Equatable {
    public let plannerDecisions: [PlannerDecisionLog]
    public let adapterMappings: [AdapterMappingLog]
    public let memoryRecalls: [MemoryRecallLog]
    public let fallbackTransitions: [FallbackTransitionLog]
    public let latencyBudgetViolations: [LatencyBudgetViolation]

    public init(
        plannerDecisions: [PlannerDecisionLog] = [],
        adapterMappings: [AdapterMappingLog] = [],
        memoryRecalls: [MemoryRecallLog] = [],
        fallbackTransitions: [FallbackTransitionLog] = [],
        latencyBudgetViolations: [LatencyBudgetViolation] = []
    ) {
        self.plannerDecisions = plannerDecisions
        self.adapterMappings = adapterMappings
        self.memoryRecalls = memoryRecalls
        self.fallbackTransitions = fallbackTransitions
        self.latencyBudgetViolations = latencyBudgetViolations
    }

    public var isEmpty: Bool {
        plannerDecisions.isEmpty
            && adapterMappings.isEmpty
            && memoryRecalls.isEmpty
            && fallbackTransitions.isEmpty
            && latencyBudgetViolations.isEmpty
    }
}

public protocol CutObservabilityProviding: CutInterface {
    mutating func consumeCutObservabilityEvents() -> CutObservabilityEvents
}
