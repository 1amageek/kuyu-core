import Testing
@testable import KuyuCore

@Test func safetyTraceAcceptsValidValues() throws {
    let trace = try SafetyTrace(omegaMagnitude: 1.0, tiltRadians: 0.5)
    #expect(trace.omegaMagnitude == 1.0)
    #expect(trace.tiltRadians == 0.5)
}

@Test func safetyTraceAcceptsZeroBoundary() throws {
    let trace = try SafetyTrace(omegaMagnitude: 0.0, tiltRadians: 0.0)
    #expect(trace.omegaMagnitude == 0.0)
    #expect(trace.tiltRadians == 0.0)
}

@Test func safetyTraceAcceptsPiBoundary() throws {
    let trace = try SafetyTrace(omegaMagnitude: 0.0, tiltRadians: .pi)
    #expect(trace.tiltRadians == .pi)
}

@Test func safetyTraceRejectsNegativeOmega() {
    #expect(throws: SafetyTrace.ValidationError.negativeOmegaMagnitude) {
        try SafetyTrace(omegaMagnitude: -1.0, tiltRadians: 0.0)
    }
}

@Test func safetyTraceRejectsNaNOmega() {
    #expect(throws: SafetyTrace.ValidationError.nonFiniteOmegaMagnitude) {
        try SafetyTrace(omegaMagnitude: .nan, tiltRadians: 0.0)
    }
}

@Test func safetyTraceRejectsInfinityOmega() {
    #expect(throws: SafetyTrace.ValidationError.nonFiniteOmegaMagnitude) {
        try SafetyTrace(omegaMagnitude: .infinity, tiltRadians: 0.0)
    }
}

@Test func safetyTraceRejectsNaNTilt() {
    #expect(throws: SafetyTrace.ValidationError.nonFiniteTiltRadians) {
        try SafetyTrace(omegaMagnitude: 0.0, tiltRadians: .nan)
    }
}

@Test func safetyTraceRejectsNegativeTilt() {
    #expect(throws: SafetyTrace.ValidationError.tiltRadiansOutOfRange) {
        try SafetyTrace(omegaMagnitude: 0.0, tiltRadians: -0.1)
    }
}

@Test func safetyTraceRejectsTiltExceedingPi() {
    #expect(throws: SafetyTrace.ValidationError.tiltRadiansOutOfRange) {
        try SafetyTrace(omegaMagnitude: 0.0, tiltRadians: .pi + 0.01)
    }
}
