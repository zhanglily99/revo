import AppKit

final class RevoPanel: NSPanel {
    static let size = MachineArtwork.size
    init() {
        super.init(contentRect: NSRect(origin: .zero, size: Self.size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false; backgroundColor = .clear; level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isMovableByWindowBackground = false; hasShadow = false; hidesOnDeactivate = false
        contentView = RevoView(frame: NSRect(origin: .zero, size: Self.size))
    }
    func placeAtDefaultCorner() {
        if let saved = UserDefaults.standard.string(forKey: "panelOrigin") {
            let origin = NSPointFromString(saved)
            let proposed = NSRect(origin: origin, size: Self.size)
            if NSScreen.screens.contains(where: { $0.visibleFrame.contains(proposed) }) { setFrameOrigin(origin); return }
        }
        guard let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        setFrameOrigin(NSPoint(x: f.maxX - Self.size.width - 18, y: f.minY + 12))
    }
    func savePosition() { UserDefaults.standard.set(NSStringFromPoint(frame.origin), forKey: "panelOrigin") }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
