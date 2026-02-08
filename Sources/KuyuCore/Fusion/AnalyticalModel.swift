import Foundation

/// Analytical model protocol. Solves ODE x' = f(x, u).
/// The boundary is defined by the domain of f.
/// Phenomena not included in f are not computed.
public protocol AnalyticalModel {
    associatedtype State: AnalyticalState

    /// Integrate ODE for one step.
    mutating func predict(action: [ActuatorValue], dt: TimeInterval) throws -> State

    /// Current analytical state.
    var currentState: State { get }

    /// Reset to initial state.
    mutating func reset() throws
}
