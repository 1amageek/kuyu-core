public struct PlannerDecisionLog: Sendable, Codable, Equatable {
    public let time: Double
    public let plannerID: String
    public let decision: String
    public let descendingSnapshot: [Double]

    public init(time: Double, plannerID: String, decision: String, descendingSnapshot: [Double]) {
        self.time = time
        self.plannerID = plannerID
        self.decision = decision
        self.descendingSnapshot = descendingSnapshot
    }
}

public struct AdapterMappingLog: Sendable, Codable, Equatable {
    public let time: Double
    public let adapterID: String
    public let fromDomain: String
    public let toDomain: String
    public let mappedChannels: [String]

    public init(
        time: Double,
        adapterID: String,
        fromDomain: String,
        toDomain: String,
        mappedChannels: [String]
    ) {
        self.time = time
        self.adapterID = adapterID
        self.fromDomain = fromDomain
        self.toDomain = toDomain
        self.mappedChannels = mappedChannels
    }
}

public struct MemoryRecallLog: Sendable, Codable, Equatable {
    public let time: Double
    public let task: String
    public let morphology: String
    public let scenarioID: String
    public let seed: UInt64
    public let appliedDescendingChannels: [String]

    public init(
        time: Double,
        task: String,
        morphology: String,
        scenarioID: String,
        seed: UInt64,
        appliedDescendingChannels: [String]
    ) {
        self.time = time
        self.task = task
        self.morphology = morphology
        self.scenarioID = scenarioID
        self.seed = seed
        self.appliedDescendingChannels = appliedDescendingChannels
    }
}

public struct UpwardSummaryLog: Sendable, Codable, Equatable {
    public let time: Double
    public let salience: Double
    public let risk: Double
    public let uncertainty: Double
    public let constraintPressure: Double
    public let recoveryState: Double

    public init(
        time: Double,
        salience: Double,
        risk: Double,
        uncertainty: Double,
        constraintPressure: Double,
        recoveryState: Double
    ) {
        self.time = time
        self.salience = salience
        self.risk = risk
        self.uncertainty = uncertainty
        self.constraintPressure = constraintPressure
        self.recoveryState = recoveryState
    }
}

public struct ArbitrationOutcomeLog: Sendable, Codable, Equatable {
    public let time: Double
    public let descending: [Double]
    public let coreDrive: [Double]
    public let reflexClamp: [Double]
    public let mergedDrive: [Double]

    public init(
        time: Double,
        descending: [Double],
        coreDrive: [Double],
        reflexClamp: [Double],
        mergedDrive: [Double]
    ) {
        self.time = time
        self.descending = descending
        self.coreDrive = coreDrive
        self.reflexClamp = reflexClamp
        self.mergedDrive = mergedDrive
    }
}

public struct FallbackTransitionLog: Sendable, Codable, Equatable {
    public let time: Double
    public let from: String
    public let to: String
    public let reason: String

    public init(time: Double, from: String, to: String, reason: String) {
        self.time = time
        self.from = from
        self.to = to
        self.reason = reason
    }
}

public struct IncidentSummaryLog: Sendable, Codable, Equatable {
    public let scenarioID: String
    public let seed: UInt64
    public let reason: String
    public let time: Double

    public init(scenarioID: String, seed: UInt64, reason: String, time: Double) {
        self.scenarioID = scenarioID
        self.seed = seed
        self.reason = reason
        self.time = time
    }
}

public struct ObservabilityLogBundle: Sendable, Codable, Equatable {
    public let plannerDecisions: [PlannerDecisionLog]
    public let adapterMappings: [AdapterMappingLog]
    public let memoryRecalls: [MemoryRecallLog]
    public let upwardSummaries: [UpwardSummaryLog]
    public let arbitrationOutcomes: [ArbitrationOutcomeLog]
    public let fallbackTransitions: [FallbackTransitionLog]
    public let latencyBudgetViolations: [LatencyBudgetViolation]
    public let incidents: [IncidentSummaryLog]

    public init(
        plannerDecisions: [PlannerDecisionLog] = [],
        adapterMappings: [AdapterMappingLog] = [],
        memoryRecalls: [MemoryRecallLog] = [],
        upwardSummaries: [UpwardSummaryLog] = [],
        arbitrationOutcomes: [ArbitrationOutcomeLog] = [],
        fallbackTransitions: [FallbackTransitionLog] = [],
        latencyBudgetViolations: [LatencyBudgetViolation] = [],
        incidents: [IncidentSummaryLog] = []
    ) {
        self.plannerDecisions = plannerDecisions
        self.adapterMappings = adapterMappings
        self.memoryRecalls = memoryRecalls
        self.upwardSummaries = upwardSummaries
        self.arbitrationOutcomes = arbitrationOutcomes
        self.fallbackTransitions = fallbackTransitions
        self.latencyBudgetViolations = latencyBudgetViolations
        self.incidents = incidents
    }

    public var isEmpty: Bool {
        plannerDecisions.isEmpty
            && adapterMappings.isEmpty
            && memoryRecalls.isEmpty
            && upwardSummaries.isEmpty
            && arbitrationOutcomes.isEmpty
            && fallbackTransitions.isEmpty
            && latencyBudgetViolations.isEmpty
            && incidents.isEmpty
    }
}
