import AppKit

/// Native desktop blur with click-through hit testing for the surrounding drop view.
final class GlassBackdrop: NSVisualEffectView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        appearance = NSAppearance(named: .aqua)
        wantsLayer = true
        layer?.cornerRadius = 25
        layer?.masksToBounds = true
        alphaValue = 0.68
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// Keeps the artwork above the native backdrop without intercepting input.
final class ArtworkHost: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
