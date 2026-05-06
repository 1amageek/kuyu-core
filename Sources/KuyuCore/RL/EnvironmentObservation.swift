public struct EnvironmentObservation: Sendable, Codable, Equatable {
    public let time: WorldTime
    public let sensorSamples: [ChannelSample]
    public let plantState: PlantStateSnapshot
    public let safetyTrace: SafetyTrace
    public let actuatorTelemetry: ActuatorTelemetrySnapshot
    public let disturbances: DisturbanceSnapshot

    public init(
        time: WorldTime,
        sensorSamples: [ChannelSample],
        plantState: PlantStateSnapshot,
        safetyTrace: SafetyTrace,
        actuatorTelemetry: ActuatorTelemetrySnapshot,
        disturbances: DisturbanceSnapshot
    ) {
        self.time = time
        self.sensorSamples = sensorSamples
        self.plantState = plantState
        self.safetyTrace = safetyTrace
        self.actuatorTelemetry = actuatorTelemetry
        self.disturbances = disturbances
    }

    public init(log: WorldStepLog) {
        self.init(
            time: log.time,
            sensorSamples: log.sensorSamples,
            plantState: log.plantState,
            safetyTrace: log.safetyTrace,
            actuatorTelemetry: log.actuatorTelemetry,
            disturbances: log.disturbances
        )
    }
}
