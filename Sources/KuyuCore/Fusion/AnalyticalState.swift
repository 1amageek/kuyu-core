/// Analytical state produced by a physics model.
/// Contains all variables that the ODE computes.
public protocol AnalyticalState: Sendable {
    /// Number of state dimensions (varies by physics model choice).
    var dimensions: Int { get }

    /// Export as flat Float array for ML pipeline consumption.
    func toArray() -> [Float]

    /// Convert to debug-friendly snapshot.
    func toPlantStateSnapshot() -> PlantStateSnapshot
}
