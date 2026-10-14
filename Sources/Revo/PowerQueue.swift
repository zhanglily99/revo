/// A session-only power interlock shared by drop acceptance and job dispatch.
/// Switching off discards waiting jobs; they are never replayed on the next start.
struct PowerQueue<Element> {
    private(set) var isPoweredOn = false
    private var pending: [Element] = []
    var isEmpty: Bool { pending.isEmpty }

    mutating func setPower(_ enabled: Bool) {
        isPoweredOn = enabled
        if !enabled { pending.removeAll() }
    }

    @discardableResult
    mutating func append(contentsOf elements: [Element]) -> Bool {
        guard isPoweredOn, !elements.isEmpty else { return false }
        pending.append(contentsOf: elements)
        return true
    }

    mutating func takeNext() -> Element? {
        guard isPoweredOn, !pending.isEmpty else { return nil }
        return pending.removeFirst()
    }
}
