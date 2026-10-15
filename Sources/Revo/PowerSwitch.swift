import AppKit
import QuartzCore

/// Native button tracking and accessibility with a compact, machined switch surface.
final class PowerSwitch: NSButton {
    private let track = CALayer()
    private let thumb = CALayer()
    private let offImage = MachineArtwork.switchTrack(powered: false)
    private let onImage = MachineArtwork.switchTrack(powered: true)
    private var powered = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        setButtonType(.momentaryChange)
        isTransparent = true
        title = ""
        isBordered = false
        focusRingType = .none
        wantsLayer = true
        track.frame = bounds
        track.contents = offImage
        layer?.addSublayer(track)
        thumb.frame = CGRect(x: -1, y: 0, width: 22, height: 22)
        thumb.contents = MachineArtwork.switchThumb()
        layer?.addSublayer(thumb)
        setAccessibilityRole(NSAccessibility.Role(rawValue: "AXSwitch"))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
    override func draw(_ dirtyRect: NSRect) { }
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() { }
    override var mouseDownCanMoveWindow: Bool { false }

    func setPower(_ enabled: Bool, animated: Bool) {
        state = enabled ? .on : .off
        setAccessibilityValue(NSNumber(value: enabled))
        guard enabled != powered else { return }
        powered = enabled
        let from = thumb.presentation()?.position ?? thumb.position
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        track.contents = enabled ? onImage : offImage
        thumb.position = CGPoint(x: enabled ? 26 : 10, y: 11)
        CATransaction.commit()
        thumb.removeAnimation(forKey: "slide")
        guard animated else { return }
        let slide = CABasicAnimation(keyPath: "position")
        slide.fromValue = NSValue(point: from)
        slide.toValue = NSValue(point: thumb.position)
        slide.duration = 0.18
        slide.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1)
        thumb.add(slide, forKey: "slide")
        let tint = CATransition(); tint.type = .fade; tint.duration = 0.18
        track.add(tint, forKey: "tint")
    }

    override func mouseDown(with event: NSEvent) {
        CATransaction.begin(); CATransaction.setDisableActions(true)
        thumb.transform = CATransform3DMakeScale(0.96, 0.96, 1)
        CATransaction.commit()
        super.mouseDown(with: event)
        CATransaction.begin(); CATransaction.setDisableActions(true)
        thumb.transform = CATransform3DIdentity
        CATransaction.commit()
    }
}
