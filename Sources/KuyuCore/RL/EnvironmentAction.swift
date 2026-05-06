public enum EnvironmentAction: Sendable, Codable, Equatable {
    case driveIntents([DriveIntent], corrections: [ReflexCorrection] = [])
    case actuatorValues([ActuatorValue])

    public var driveIntents: [DriveIntent] {
        switch self {
        case .driveIntents(let drives, _):
            return drives
        case .actuatorValues:
            return []
        }
    }

    public var actuatorValues: [ActuatorValue] {
        switch self {
        case .driveIntents:
            return []
        case .actuatorValues(let values):
            return values
        }
    }

    public func cutOutput() -> CutOutput {
        switch self {
        case .driveIntents(let drives, let corrections):
            return .driveIntents(drives, corrections: corrections)
        case .actuatorValues(let values):
            return .actuatorValues(values)
        }
    }
}
