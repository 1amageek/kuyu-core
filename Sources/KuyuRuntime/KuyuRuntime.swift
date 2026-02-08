import KuyuCore
import Logging
import Configuration

/// Runtime utilities for Kuyu simulation environment.
/// Provides logging and configuration infrastructure on top of KuyuCore.
public enum KuyuRuntimeBootstrap {
    /// Initialize the Kuyu runtime with default logging and configuration.
    public static func bootstrap(logLevel: Logger.Level = .info) {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = logLevel
            return handler
        }
    }
}
