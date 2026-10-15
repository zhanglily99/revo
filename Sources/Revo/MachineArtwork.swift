import AppKit

/// An opaque aluminum head sits above a clear enclosure with refractive edges.
/// The aperture and animation masks share the same physical coordinates.
enum MachineArtwork {
    static let size = NSSize(width: 240, height: 280)
    static let slotY: CGFloat = 178
    static let paperWidth: CGFloat = 90
    static let paperHeight: CGFloat = 94
    static let window = CGRect(x: 43, y: 62, width: 154, height: 77)
    static let shell = CGRect(x: 23, y: 49, width: 194, height: 156)
    static let inlet = CGRect(x: 47, y: slotY - 3, width: 146, height: 7)
    static let switchFrame = CGRect(x: 162, y: 141, width: 40, height: 24)

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

    /// One silhouette keeps the native backdrop inside the sloped glass enclosure.
    static var outline: CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 46, y: 205))
        path.addLine(to: CGPoint(x: 194, y: 205))
        path.addQuadCurve(to: CGPoint(x: 201, y: 200), control: CGPoint(x: 199, y: 205))
        path.addLine(to: CGPoint(x: 215, y: 172))
        path.addQuadCurve(to: CGPoint(x: 217, y: 163), control: CGPoint(x: 217, y: 168))
        path.addLine(to: CGPoint(x: 217, y: 67))
        path.addQuadCurve(to: CGPoint(x: 199, y: 49), control: CGPoint(x: 217, y: 49))
        path.addLine(to: CGPoint(x: 41, y: 49))
        path.addQuadCurve(to: CGPoint(x: 23, y: 67), control: CGPoint(x: 23, y: 49))
        path.addLine(to: CGPoint(x: 23, y: 163))
        path.addQuadCurve(to: CGPoint(x: 25, y: 172), control: CGPoint(x: 23, y: 168))
        path.addLine(to: CGPoint(x: 39, y: 200))
        path.addQuadCurve(to: CGPoint(x: 46, y: 205), control: CGPoint(x: 41, y: 205))
        path.closeSubpath()
        return path
    }

    private static func drawBody() {
        let outer = NSBezierPath(cgPath: outline)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow(); shadow.shadowColor = color(0x192535, 0.23)
        shadow.shadowBlurRadius = 11; shadow.shadowOffset = NSSize(width: 0, height: -7); shadow.set()
        fill(outer, 0xD4DCE4, 0.035)
        NSGraphicsContext.restoreGraphicsState()
        gradient(outer, [(0xFFFFFF, 0.15), (0xE5EDF6, 0.015), (0xA8B3C1, 0.035), (0xFFFFFF, 0.12)], -25)
        stroke(outer, 0x6C7A8B, 0.38, 0.9)

        // The opaque aluminum top recedes toward the narrower back edge.
        let top = NSBezierPath()
        top.move(to: CGPoint(x: 27, y: 167))
        top.line(to: CGPoint(x: 41, y: 199))
        top.curve(to: CGPoint(x: 47, y: 203), controlPoint1: CGPoint(x: 42, y: 202), controlPoint2: CGPoint(x: 44, y: 203))
        top.line(to: CGPoint(x: 193, y: 203))
        top.curve(to: CGPoint(x: 199, y: 199), controlPoint1: CGPoint(x: 196, y: 203), controlPoint2: CGPoint(x: 198, y: 202))
        top.line(to: CGPoint(x: 213, y: 167)); top.close()
        gradient(top, [(0xFFFFFF, 1), (0xE1E8EF, 1), (0xB9C5D0, 1), (0xF8FBFE, 1)], -83)
        stroke(top, 0xFFFFFF, 0.96, 1.1)
        line(CGPoint(x: 48, y: 200), CGPoint(x: 192, y: 200), color: 0xFFFFFF, alpha: 0.95)
        line(CGPoint(x: 30, y: 168), CGPoint(x: 43, y: 197), color: 0xFFFFFF, alpha: 0.85, width: 1.7)
        line(CGPoint(x: 210, y: 168), CGPoint(x: 197, y: 197), color: 0x738495, alpha: 0.4, width: 1.3)

        // The front fascia sits below the top seam, with a soft aluminum sheen.
        let cassette = rounded(NSRect(x: 29, y: 139, width: 182, height: 29), 8)
        gradient(cassette, [(0xFFFFFF, 1), (0xDFE6ED, 1), (0xADB9C5, 1), (0xE5ECF3, 1)], -90)
        stroke(cassette, 0xFFFFFF, 0.78, 0.7)
        line(CGPoint(x: 34, y: 166), CGPoint(x: 206, y: 166), color: 0x617180, alpha: 0.35, width: 0.6)
        line(CGPoint(x: 38, y: 139), CGPoint(x: 202, y: 139), color: 0x6F8192, alpha: 0.35, width: 0.7)
        text("Revo", NSPoint(x: 45, y: 143), NSFont(name: "Georgia-Italic", size: 17) ?? .systemFont(ofSize: 17), 0x3B4653)

        // The inlet and shutter share geometry with the paper clipping plane.
        let lip = rounded(inlet.insetBy(dx: -4, dy: -3), 6.5)
        gradient(lip, [(0x82919F, 0.9), (0xFFFFFF, 1), (0x9EAAB7, 0.9), (0xFFFFFF, 1)])
        gradient(rounded(inlet, 3.5), [(0x121C25, 1), (0x3C4A58, 1)])
        line(CGPoint(x: 52, y: inlet.minY), CGPoint(x: 188, y: inlet.minY), color: 0xF4FAFF, alpha: 0.9, width: 0.7)

        // Thick clear side rails carry the upper-left light down the front face.
        gradient(rounded(NSRect(x: 26, y: 64, width: 8, height: 97), 4), [(0xFFFFFF, 0.94), (0xA7B3C2, 0.05), (0xFFFFFF, 0.40)], 0)
        gradient(rounded(NSRect(x: 207, y: 64, width: 7, height: 97), 3.5), [(0xFFFFFF, 0.24), (0x778797, 0.32), (0xFFFFFF, 0.78)], 0)
        line(CGPoint(x: 25, y: 68), CGPoint(x: 25, y: 161), color: 0xFFFFFF, alpha: 0.88, width: 1)
        line(CGPoint(x: 215, y: 68), CGPoint(x: 215, y: 161), color: 0xFFFFFF, alpha: 0.72, width: 0.8)
        gradient(rounded(NSRect(x: 39, y: 51, width: 162, height: 9), 4.5), [(0xFFFFFF, 0.25), (0x81909F, 0.30), (0xFFFFFF, 0.92)])
        line(CGPoint(x: 42, y: 55), CGPoint(x: 198, y: 55), color: 0xFFFFFF, alpha: 0.85, width: 0.8)
        gradient(rounded(NSRect(x: 43, y: 63, width: 154, height: 5), 2.5), [(0xB2BECC, 0.20), (0xFFFFFF, 0.56)])
        line(CGPoint(x: 43, y: 62), CGPoint(x: 197, y: 62), color: 0x8594A4, alpha: 0.22, width: 0.6)
    }

    private static func drawGlass() {
        let front = rounded(NSRect(x: 34, y: 61, width: 172, height: 78), 17)
        gradient(front, [(0xEAF3FD, 0.01), (0xFFFFFF, 0.025), (0xFFFFFF, 0.08)])
        NSGraphicsContext.saveGraphicsState(); front.addClip()
        let reflection = NSBezierPath()
        reflection.move(to: CGPoint(x: 36, y: 139)); reflection.line(to: CGPoint(x: 69, y: 139))
        reflection.line(to: CGPoint(x: 128, y: 61)); reflection.line(to: CGPoint(x: 102, y: 61)); reflection.close()
        gradient(reflection, [(0xFFFFFF, 0.10), (0xFFFFFF, 0.005)], -65)
        NSGraphicsContext.restoreGraphicsState()
        line(CGPoint(x: 36, y: 78), CGPoint(x: 36, y: 130), color: 0xFFFFFF, alpha: 0.48, width: 0.7)
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
