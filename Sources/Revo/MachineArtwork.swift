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
    static let glassFrame = CGRect(x: 23, y: 49, width: 194, height: 93)
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

    /// The head includes its bevels and end caps; every interior pixel is opaque.
    static var headOutline: CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 46, y: 205))
        path.addLine(to: CGPoint(x: 194, y: 205))
        path.addQuadCurve(to: CGPoint(x: 201, y: 200), control: CGPoint(x: 199, y: 205))
        path.addLine(to: CGPoint(x: 215, y: 172))
        path.addQuadCurve(to: CGPoint(x: 217, y: 163), control: CGPoint(x: 217, y: 168))
        path.addLine(to: CGPoint(x: 217, y: 149))
        path.addQuadCurve(to: CGPoint(x: 207, y: 139), control: CGPoint(x: 217, y: 139))
        path.addLine(to: CGPoint(x: 33, y: 139))
        path.addQuadCurve(to: CGPoint(x: 23, y: 149), control: CGPoint(x: 23, y: 139))
        path.addLine(to: CGPoint(x: 23, y: 163))
        path.addQuadCurve(to: CGPoint(x: 25, y: 172), control: CGPoint(x: 23, y: 168))
        path.addLine(to: CGPoint(x: 39, y: 200))
        path.addQuadCurve(to: CGPoint(x: 46, y: 205), control: CGPoint(x: 41, y: 205))
        path.closeSubpath()
        return path
    }

    /// The glass material stops beneath the solid metal head.
    static var glassOutline: CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 23, y: 142))
        path.addLine(to: CGPoint(x: 217, y: 142))
        path.addLine(to: CGPoint(x: 217, y: 67))
        path.addQuadCurve(to: CGPoint(x: 199, y: 49), control: CGPoint(x: 217, y: 49))
        path.addLine(to: CGPoint(x: 41, y: 49))
        path.addQuadCurve(to: CGPoint(x: 23, y: 67), control: CGPoint(x: 23, y: 49))
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

        // Fill the complete head first, including the formerly clear perimeter.
        let head = NSBezierPath(cgPath: headOutline)
        gradient(head, [(0xC4CED8, 1), (0xE6ECF1, 1), (0xA6B2BF, 1)], -90)
        stroke(head, 0x8997A5, 0.85, 0.7)

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
        gradient(rounded(NSRect(x: 26, y: 64, width: 8, height: 74), 4), [(0xFFFFFF, 0.94), (0xA7B3C2, 0.05), (0xFFFFFF, 0.40)], 0)
        gradient(rounded(NSRect(x: 207, y: 64, width: 7, height: 74), 3.5), [(0xFFFFFF, 0.24), (0x778797, 0.32), (0xFFFFFF, 0.78)], 0)
        line(CGPoint(x: 25, y: 68), CGPoint(x: 25, y: 137), color: 0xFFFFFF, alpha: 0.88, width: 1)
        line(CGPoint(x: 215, y: 68), CGPoint(x: 215, y: 137), color: 0xFFFFFF, alpha: 0.72, width: 0.8)
        gradient(rounded(NSRect(x: 39, y: 51, width: 162, height: 9), 4.5), [(0xFFFFFF, 0.25), (0x81909F, 0.30), (0xFFFFFF, 0.92)])
        line(CGPoint(x: 42, y: 55), CGPoint(x: 198, y: 55), color: 0xFFFFFF, alpha: 0.85, width: 0.8)
        gradient(rounded(NSRect(x: 43, y: 63, width: 154, height: 5), 2.5), [(0xB2BECC, 0.20), (0xFFFFFF, 0.56)])
        line(CGPoint(x: 43, y: 62), CGPoint(x: 197, y: 62), color: 0x8594A4, alpha: 0.22, width: 0.6)
    }

    private static func drawGlass() {
        let front = NSBezierPath(cgPath: glassOutline)
        NSGraphicsContext.saveGraphicsState()
        front.addClip()
        // A clear center and denser perimeter give the pane a rounded liquid meniscus.
        gradient(front, [(0xFFFFFF, 0.16), (0xE4EFF9, 0.015), (0xFFFFFF, 0.06), (0xFFFFFF, 0.22)], -83)
        stroke(rounded(NSRect(x: 24, y: 50, width: 192, height: 109), 18), 0xFFFFFF, 0.78, 1.5)
        stroke(rounded(NSRect(x: 27, y: 53, width: 186, height: 105), 16), 0x718699, 0.23, 1.1)
        stroke(rounded(NSRect(x: 30, y: 56, width: 180, height: 100), 14), 0xFFFFFF, 0.57, 1.3)
        stroke(rounded(NSRect(x: 33, y: 59, width: 174, height: 96), 13), 0xFFFFFF, 0.16, 3.5)

        // Broad, low-contrast reflections merge into the clear center.
        let reflection = NSBezierPath()
        reflection.move(to: CGPoint(x: 24, y: 138))
        reflection.curve(to: CGPoint(x: 79, y: 138), controlPoint1: CGPoint(x: 43, y: 131), controlPoint2: CGPoint(x: 55, y: 132))
        reflection.curve(to: CGPoint(x: 153, y: 54), controlPoint1: CGPoint(x: 93, y: 103), controlPoint2: CGPoint(x: 128, y: 69))
        reflection.line(to: CGPoint(x: 119, y: 54))
        reflection.curve(to: CGPoint(x: 24, y: 123), controlPoint1: CGPoint(x: 93, y: 81), controlPoint2: CGPoint(x: 44, y: 118))
        reflection.close()
        gradient(reflection, [(0xFFFFFF, 0.20), (0xFFFFFF, 0.015)], -48)
        gradient(rounded(NSRect(x: 28, y: 65, width: 12, height: 80), 6), [(0xFFFFFF, 0.04), (0xFFFFFF, 0.58), (0xB8D1E6, 0.10), (0xFFFFFF, 0.02)], 0)
        gradient(rounded(NSRect(x: 200, y: 65, width: 12, height: 80), 6), [(0xFFFFFF, 0.015), (0x98AFC3, 0.20), (0xFFFFFF, 0.70), (0xFFFFFF, 0.03)], 0)
        gradient(rounded(NSRect(x: 40, y: 53, width: 160, height: 10), 5), [(0xFFFFFF, 0.06), (0xC4D8E9, 0.25), (0xFFFFFF, 0.77), (0xFFFFFF, 0.02)])
        line(CGPoint(x: 44, y: 55), CGPoint(x: 193, y: 55), color: 0xFFFFFF, alpha: 0.84, width: 1)
        // A narrow contact shadow separates the solid head from the glass below it.
        gradient(rounded(NSRect(x: 30, y: 132, width: 180, height: 9), 4), [(0x536779, 0.16), (0x536779, 0)], -90)
        NSGraphicsContext.restoreGraphicsState()
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
