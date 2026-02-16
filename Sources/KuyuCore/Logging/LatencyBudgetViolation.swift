import Foundation

public struct LatencyBudgetViolation: Sendable, Codable, Equatable {
    public enum ValidationError: Error, Equatable {
        case empty(String)
        case nonFinite(String)
        case invalidRange(String)
    }

    public let path: String
    public let budgetMs: Double
    public let observedMs: Double
    public let time: Double
    public let reason: String

    public init(
        path: String,
        budgetMs: Double,
        observedMs: Double,
        time: Double,
        reason: String
    ) throws {
        if path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.empty("path")
        }
        if reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.empty("reason")
        }

        guard budgetMs.isFinite else {
            throw ValidationError.nonFinite("budgetMs")
        }
        guard observedMs.isFinite else {
            throw ValidationError.nonFinite("observedMs")
        }
        guard time.isFinite else {
            throw ValidationError.nonFinite("time")
        }

        if budgetMs <= 0 {
            throw ValidationError.invalidRange("budgetMs")
        }
        if observedMs < 0 {
            throw ValidationError.invalidRange("observedMs")
        }
        if time < 0 {
            throw ValidationError.invalidRange("time")
        }

        self.path = path
        self.budgetMs = budgetMs
        self.observedMs = observedMs
        self.time = time
        self.reason = reason
    }
}
