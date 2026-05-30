import Foundation
import Testing
@testable import KuyuCore

@Test func actuatorSwapEventDecoderUsesValidatedInitializer() throws {
    let invalid = Data("""
    {
      "kind": "rateLimitShift",
      "startTime": 0.1,
      "duration": 0.2,
      "motorIndex": 0,
      "gainScale": 1.0,
      "lagScale": 1.0,
      "maxOutputScale": 1.0,
      "deadzoneShift": 0.0,
      "rateLimitScale": -0.5,
      "asymmetryScale": 1.0
    }
    """.utf8)

    #expect(throws: ActuatorSwapEvent.ValidationError.self) {
        try JSONDecoder().decode(ActuatorSwapEvent.self, from: invalid)
    }
}

@Test func actuatorSwapEventDecoderDefaultsLegacyModifierFields() throws {
    let legacy = Data("""
    {
      "kind": "gainShift",
      "startTime": 0.1,
      "duration": 0.2,
      "motorIndex": 0,
      "gainScale": 0.9,
      "lagScale": 1.0,
      "maxOutputScale": 1.0,
      "deadzoneShift": 0.0
    }
    """.utf8)

    let event = try JSONDecoder().decode(ActuatorSwapEvent.self, from: legacy)
    #expect(event.rateLimitScale == 1.0)
    #expect(event.asymmetryScale == 1.0)
}

@Test func sensorSwapEventDecoderUsesValidatedInitializer() throws {
    let invalid = Data("""
    {
      "kind": "bandwidthChange",
      "startTime": 0.1,
      "duration": 0.2,
      "targetChannels": [0, 1],
      "gainScale": 1.0,
      "biasShift": 0.0,
      "noiseScale": 1.0,
      "dropoutProbability": 0.0,
      "delayShiftSteps": 0,
      "bandwidthScale": -0.2
    }
    """.utf8)

    #expect(throws: SensorSwapEvent.ValidationError.self) {
        try JSONDecoder().decode(SensorSwapEvent.self, from: invalid)
    }
}

@Test func sensorSwapEventDecoderDefaultsLegacyBandwidthScale() throws {
    let legacy = Data("""
    {
      "kind": "calibShift",
      "startTime": 0.1,
      "duration": 0.2,
      "targetChannels": [0, 1],
      "gainScale": 1.0,
      "biasShift": 0.0,
      "noiseScale": 1.0,
      "dropoutProbability": 0.0,
      "delayShiftSteps": 0
    }
    """.utf8)

    let event = try JSONDecoder().decode(SensorSwapEvent.self, from: legacy)
    #expect(event.bandwidthScale == 1.0)
}
