import AppKit

/// Live desktop diffusion is confined to the lower liquid-glass enclosure.
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
        mask.path = MachineArtwork.glassOutline.copy(using: &local)
        layer?.mask = mask
        layer?.masksToBounds = true
        alphaValue = 0.22
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// Keeps the artwork above the native backdrop without intercepting input.
final class ArtworkHost: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
