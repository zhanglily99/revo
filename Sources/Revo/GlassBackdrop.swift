import AppKit

/// A native solid backdrop used only when Reduce Transparency is enabled.
final class GlassBackdrop: NSVisualEffectView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        appearance = NSAppearance(named: .aqua)
        wantsLayer = true
        let mask = CAShapeLayer()
        var local = CGAffineTransform(translationX: -frame.minX, y: -frame.minY)
        mask.path = MachineArtwork.outline.copy(using: &local)
        layer?.mask = mask
        layer?.masksToBounds = true
        alphaValue = 0
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// Keeps the artwork above the native backdrop without intercepting input.
final class ArtworkHost: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
