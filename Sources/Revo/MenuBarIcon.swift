import AppKit

/// A small template mark stays legible in both light and dark menu bars.
enum MenuBarIcon {
    static func image() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()
            // Every contour uses one weight, including the inlet and paper strips.
            let head = NSBezierPath(roundedRect: CGRect(x: 1.75, y: 9.75, width: 14.5, height: 5.5), xRadius: 1.65, yRadius: 1.65)
            let bin = NSBezierPath()
            bin.move(to: CGPoint(x: 3.25, y: 9.75))
            bin.line(to: CGPoint(x: 3.25, y: 4.25))
            bin.curve(to: CGPoint(x: 4.75, y: 2.75), controlPoint1: CGPoint(x: 3.25, y: 3.42), controlPoint2: CGPoint(x: 3.92, y: 2.75))
            bin.line(to: CGPoint(x: 13.25, y: 2.75))
            bin.curve(to: CGPoint(x: 14.75, y: 4.25), controlPoint1: CGPoint(x: 14.08, y: 2.75), controlPoint2: CGPoint(x: 14.75, y: 3.42))
            bin.line(to: CGPoint(x: 14.75, y: 9.75))

            let details = NSBezierPath()
            details.move(to: CGPoint(x: 5.25, y: 12.5))
            details.line(to: CGPoint(x: 12.75, y: 12.5))
            for x in [6.0, 9.0, 12.0] {
                details.move(to: CGPoint(x: x, y: 7.25))
                details.line(to: CGPoint(x: x, y: 5.25))
            }
            for path in [head, bin, details] {
                path.lineWidth = 1.35
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.stroke()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Revo"
        return image
    }
}
