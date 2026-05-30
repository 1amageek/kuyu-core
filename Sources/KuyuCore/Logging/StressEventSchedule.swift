/// The swap/HF stress events scheduled for a run, recorded in the simulation log so
/// that downstream tooling and the visual inspector can show the event timeline.
/// Satisfies the A1 "Required Logs: Event schedule + seed" requirement.
public struct StressEventSchedule: Sendable, Codable, Equatable {
    public let swapEvents: [SwapEvent]
    public let hfEvents: [HFStressEvent]

    public init(swapEvents: [SwapEvent], hfEvents: [HFStressEvent]) {
        self.swapEvents = swapEvents
        self.hfEvents = hfEvents
    }

    public var isEmpty: Bool { swapEvents.isEmpty && hfEvents.isEmpty }
}
