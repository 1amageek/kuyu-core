/// Errors raised by fused environment composition.
public enum FusedEnvironmentError: Error, Equatable {
    case worldModelFutureCountMismatch(expected: Int, actual: Int)
}
