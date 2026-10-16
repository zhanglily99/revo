import AppKit

/// A small template mark stays legible in both light and dark menu bars.
enum MenuBarIcon {
    static func image() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()
            let bin = NSBezierPath(roundedRect: CGRect(x: 3, y: 2, width: 12, height: 11), xRadius: 2, yRadius: 2)
            bin.lineWidth = 1.25; bin.stroke()
            NSColor.black.setFill()
            NSBezierPath(roundedRect: CGRect(x: 1.5, y: 10.5, width: 15, height: 5), xRadius: 1.6, yRadius: 1.6).fill()
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current?.cgContext.setBlendMode(.clear)
            NSBezierPath(roundedRect: CGRect(x: 4, y: 12.5, width: 10, height: 0.9), xRadius: 0.45, yRadius: 0.45).fill()
            NSGraphicsContext.restoreGraphicsState()
            NSColor.black.setStroke()
            for (x, y, tilt) in [(6.0, 5.0, 0.7), (9.0, 4.0, -0.6), (12.0, 5.5, 0.5)] {
                let scrap = NSBezierPath()
                scrap.move(to: CGPoint(x: x, y: y))
                scrap.line(to: CGPoint(x: x + tilt, y: y + 2.5))
                scrap.lineWidth = 1; scrap.lineCapStyle = .round; scrap.stroke()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Revo"
        return image
    }
}
