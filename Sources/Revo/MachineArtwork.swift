import AppKit

/// Translucent glass edges sit above a live, native desktop backdrop.
/// The aperture and animation masks share the same physical coordinates.
enum MachineArtwork {
    static let size = NSSize(width: 240, height: 280)
    static let slotY: CGFloat = 192
    static let paperWidth: CGFloat = 66
    static let paperHeight: CGFloat = 80
    static let window = CGRect(x: 43, y: 86, width: 154, height: 65)
    static let shell = CGRect(x: 23, y: 49, width: 194, height: 164)
    static let switchFrame = CGRect(x: 155, y: 60, width: 40, height: 24)

    static func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
        NSColor(calibratedRed: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: alpha)
    }

    static func image(glass: Bool = false) -> CGImage {
        raster(size) { if glass { drawGlass() } else { drawBody() } }
    }

    private static func raster(_ size: NSSize, draw: () -> Void) -> CGImage {
        let scale: CGFloat = 3
        let ctx = CGContext(data: nil, width: Int(size.width * scale), height: Int(size.height * scale), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.scaleBy(x: scale, y: scale)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        draw()
        NSGraphicsContext.restoreGraphicsState()
        return ctx.makeImage()!
    }

    private static func rounded(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    }
    private static func fill(_ path: NSBezierPath, _ hex: UInt32, _ alpha: CGFloat = 1) {
        color(hex, alpha).setFill(); path.fill()
    }
    private static func stroke(_ path: NSBezierPath, _ hex: UInt32, _ alpha: CGFloat = 1, _ width: CGFloat = 1) {
        color(hex, alpha).setStroke(); path.lineWidth = width; path.stroke()
    }
    private static func gradient(_ path: NSBezierPath, _ stops: [(UInt32, CGFloat)], _ angle: CGFloat = -90) {
        NSGradient(colors: stops.map { color($0.0, $0.1) })!.draw(in: path, angle: angle)
    }
    private static func text(_ string: String, _ point: NSPoint, _ font: NSFont, _ hex: UInt32) {
        (string as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color(hex)])
    }
    private static func line(_ from: CGPoint, _ to: CGPoint, color hex: UInt32, alpha: CGFloat, width: CGFloat = 1) {
        let p = NSBezierPath(); p.move(to: from); p.line(to: to); p.lineCapStyle = .round
        stroke(p, hex, alpha, width)
    }

    private static func drawBody() {
        let outer = rounded(shell, 25)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow(); shadow.shadowColor = color(0x192535, 0.24)
        shadow.shadowBlurRadius = 13; shadow.shadowOffset = NSSize(width: 0, height: -7); shadow.set()
        fill(outer, 0xD4DCE4, 0.15)
        NSGraphicsContext.restoreGraphicsState()

        // A clear, thick perimeter. Its center remains translucent to the desktop.
        gradient(outer, [(0xFFFFFF, 0.30), (0xE5EDF6, 0.08), (0xA8B3C1, 0.18), (0xFFFFFF, 0.38)], -25)
        stroke(outer, 0x6C7A8B, 0.30, 0.8)
        stroke(rounded(shell.insetBy(dx: 1.4, dy: 1.4), 24), 0xFFFFFF, 0.92, 1.4)
        stroke(rounded(shell.insetBy(dx: 4.2, dy: 4.2), 21), 0x8F9BAB, 0.22, 0.7)
        stroke(rounded(shell.insetBy(dx: 5.6, dy: 5.6), 20), 0xFFFFFF, 0.60, 0.8)

        // Side walls catch narrow reflections, leaving an uninterrupted glass front.
        gradient(rounded(NSRect(x: 26, y: 69, width: 8, height: 113), 4), [(0xFFFFFF, 0.78), (0xA7B3C2, 0.05), (0xFFFFFF, 0.28)], 0)
        gradient(rounded(NSRect(x: 207, y: 69, width: 7, height: 113), 3.5), [(0xFFFFFF, 0.20), (0x778797, 0.24), (0xFFFFFF, 0.72)], 0)
        gradient(rounded(NSRect(x: 40, y: 51, width: 160, height: 9), 4.5), [(0xFFFFFF, 0.20), (0x81909F, 0.27), (0xFFFFFF, 0.85)])
        line(CGPoint(x: 45, y: 57), CGPoint(x: 195, y: 57), color: 0xFFFFFF, alpha: 0.8, width: 0.8)

        // The aluminum cutter cassette is visible through the upper glass.
        let cassette = rounded(NSRect(x: 40, y: 153, width: 160, height: 48), 16)
        gradient(cassette, [(0xFFFFFF, 0.95), (0xE3E8EE, 0.90), (0xB3BEC9, 0.70), (0xF6F9FC, 0.92)], -72)
        stroke(cassette, 0xFFFFFF, 0.85, 0.8)
        line(CGPoint(x: 54, y: 153), CGPoint(x: 186, y: 153), color: 0x667887, alpha: 0.28, width: 0.7)
        text("Revo", NSPoint(x: 48, y: 165), .systemFont(ofSize: 13, weight: .semibold), 0x3B4653)
        text("a little less.", NSPoint(x: 130, y: 167), .systemFont(ofSize: 7, weight: .medium), 0x7B8793)

        // The top has a shallow perspective and a clear machined edge.
        let top = NSBezierPath()
        top.move(to: CGPoint(x: 28, y: 185))
        top.curve(to: CGPoint(x: 42, y: 212), controlPoint1: CGPoint(x: 28, y: 201), controlPoint2: CGPoint(x: 33, y: 211))
        top.curve(to: CGPoint(x: 198, y: 212), controlPoint1: CGPoint(x: 86, y: 216), controlPoint2: CGPoint(x: 158, y: 216))
        top.curve(to: CGPoint(x: 212, y: 185), controlPoint1: CGPoint(x: 207, y: 211), controlPoint2: CGPoint(x: 212, y: 200))
        top.curve(to: CGPoint(x: 28, y: 185), controlPoint1: CGPoint(x: 156, y: 182), controlPoint2: CGPoint(x: 82, y: 182)); top.close()
        gradient(top, [(0xFFFFFF, 0.70), (0xC1CBD5, 0.26), (0xFFFFFF, 0.68)])
        stroke(top, 0xFFFFFF, 0.95, 0.9)
        let lip = rounded(NSRect(x: 43, y: 186, width: 154, height: 13), 6.5)
        gradient(lip, [(0x74828F, 0.8), (0xFBFDFF, 0.95), (0x8B97A3, 0.8), (0xFFFFFF, 0.95)])
        gradient(rounded(NSRect(x: 47, y: 189, width: 146, height: 7), 3.5), [(0x161F26, 1), (0x36434D, 1)])
        line(CGPoint(x: 52, y: 189), CGPoint(x: 188, y: 189), color: 0xF0F7FF, alpha: 0.7, width: 0.6)

        // A translucent bottom ledge catches the paper fragments.
        gradient(rounded(NSRect(x: 43, y: 87, width: 154, height: 5), 2.5), [(0xB2BECC, 0.20), (0xFFFFFF, 0.56)])
        line(CGPoint(x: 43, y: 86), CGPoint(x: 197, y: 86), color: 0x8594A4, alpha: 0.22, width: 0.6)
    }

    private static func drawGlass() {
        let front = rounded(NSRect(x: 34, y: 61, width: 172, height: 94), 17)
        gradient(front, [(0xEAF3FD, 0.04), (0xFFFFFF, 0.10), (0xFFFFFF, 0.30)])
        NSGraphicsContext.saveGraphicsState(); front.addClip()
        let reflection = NSBezierPath()
        reflection.move(to: CGPoint(x: 36, y: 155)); reflection.line(to: CGPoint(x: 69, y: 155))
        reflection.line(to: CGPoint(x: 128, y: 61)); reflection.line(to: CGPoint(x: 102, y: 61)); reflection.close()
        gradient(reflection, [(0xFFFFFF, 0.22), (0xFFFFFF, 0.01)], -65)
        NSGraphicsContext.restoreGraphicsState()
        line(CGPoint(x: 36, y: 78), CGPoint(x: 36, y: 145), color: 0xFFFFFF, alpha: 0.48, width: 0.7)
    }

    static func shutter() -> CGImage {
        raster(NSSize(width: 146, height: 7)) {
            let shape = rounded(NSRect(x: 0, y: 0, width: 146, height: 7), 3.5)
            gradient(shape, [(0xB0BBC6, 1), (0xF7FAFD, 1), (0xBBC6D1, 1)])
            line(CGPoint(x: 5, y: 5.5), CGPoint(x: 141, y: 5.5), color: 0xFFFFFF, alpha: 0.8, width: 0.5)
        }
    }

    /// A static off switch for the exported icon; the running app uses NSSwitch.
    static func button() -> CGImage {
        raster(NSSize(width: 40, height: 24)) {
            gradient(rounded(NSRect(x: 1, y: 2, width: 38, height: 20), 10), [(0x9AA6B3, 0.8), (0xD1D9E1, 0.8)])
            stroke(rounded(NSRect(x: 1, y: 2, width: 38, height: 20), 10), 0xFFFFFF, 0.8, 0.6)
            gradient(NSBezierPath(ovalIn: NSRect(x: 3, y: 4, width: 16, height: 16)), [(0xFFFFFF, 1), (0xEEF2F7, 1)])
        }
    }
}
