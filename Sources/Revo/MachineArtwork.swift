import AppKit
import CoreText

/// An opaque aluminum head sits above a clear enclosure with refractive edges.
/// The aperture and animation masks share the same physical coordinates.
enum MachineArtwork {
    static let size = NSSize(width: 240, height: 330)
    static let slotY: CGFloat = 228
    static let paperWidth: CGFloat = 90
    static let paperHeight: CGFloat = 94
    static let window = CGRect(x: 43, y: 62, width: 154, height: 107)
    static let shell = CGRect(x: 23, y: 49, width: 194, height: 206)
    static let glassFrame = CGRect(x: 23, y: 49, width: 194, height: 120)
    static let inlet = CGRect(x: 47, y: slotY - 3, width: 146, height: 7)
    static let switchFrame = CGRect(x: 162, y: 180, width: 40, height: 24)

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
        path.move(to: CGPoint(x: 56, y: 255))
        path.addLine(to: CGPoint(x: 184, y: 255))
        path.addCurve(to: CGPoint(x: 202, y: 243), control1: CGPoint(x: 195, y: 255), control2: CGPoint(x: 198, y: 252))
        path.addLine(to: CGPoint(x: 211, y: 225))
        path.addCurve(to: CGPoint(x: 217, y: 207), control1: CGPoint(x: 216, y: 217), control2: CGPoint(x: 217, y: 213))
        path.addLine(to: CGPoint(x: 217, y: 61))
        path.addQuadCurve(to: CGPoint(x: 205, y: 49), control: CGPoint(x: 217, y: 49))
        path.addLine(to: CGPoint(x: 35, y: 49))
        path.addQuadCurve(to: CGPoint(x: 23, y: 61), control: CGPoint(x: 23, y: 49))
        path.addLine(to: CGPoint(x: 23, y: 207))
        path.addCurve(to: CGPoint(x: 29, y: 225), control1: CGPoint(x: 23, y: 213), control2: CGPoint(x: 24, y: 217))
        path.addLine(to: CGPoint(x: 38, y: 243))
        path.addCurve(to: CGPoint(x: 56, y: 255), control1: CGPoint(x: 42, y: 252), control2: CGPoint(x: 45, y: 255))
        path.closeSubpath()
        return path
    }

    /// The head includes its bevels and end caps; every interior pixel is opaque.
    static var headOutline: CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 56, y: 255))
        path.addLine(to: CGPoint(x: 184, y: 255))
        path.addCurve(to: CGPoint(x: 202, y: 243), control1: CGPoint(x: 195, y: 255), control2: CGPoint(x: 198, y: 252))
        path.addLine(to: CGPoint(x: 211, y: 225))
        path.addCurve(to: CGPoint(x: 217, y: 207), control1: CGPoint(x: 216, y: 217), control2: CGPoint(x: 217, y: 213))
        path.addLine(to: CGPoint(x: 217, y: 169))
        path.addLine(to: CGPoint(x: 23, y: 169))
        path.addLine(to: CGPoint(x: 23, y: 207))
        path.addCurve(to: CGPoint(x: 29, y: 225), control1: CGPoint(x: 23, y: 213), control2: CGPoint(x: 24, y: 217))
        path.addLine(to: CGPoint(x: 38, y: 243))
        path.addCurve(to: CGPoint(x: 56, y: 255), control1: CGPoint(x: 42, y: 252), control2: CGPoint(x: 45, y: 255))
        path.closeSubpath()
        return path
    }

    /// The glass material stops beneath the solid metal head.
    static var glassOutline: CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 23, y: 169))
        path.addLine(to: CGPoint(x: 217, y: 169))
        path.addLine(to: CGPoint(x: 217, y: 61))
        path.addQuadCurve(to: CGPoint(x: 205, y: 49), control: CGPoint(x: 217, y: 49))
        path.addLine(to: CGPoint(x: 35, y: 49))
        path.addQuadCurve(to: CGPoint(x: 23, y: 61), control: CGPoint(x: 23, y: 49))
        path.closeSubpath()
        return path
    }

    /// Depth edges converge on the same point as the metal top plane.
    private static let vanishingPoint = CGPoint(x: 120, y: 407)
    private static func recede(_ point: CGPoint, depth: CGFloat = 1) -> CGPoint {
        let scale = 1 - 0.19 * depth
        return CGPoint(x: vanishingPoint.x + (point.x - vanishingPoint.x) * scale,
                       y: vanishingPoint.y + (point.y - vanishingPoint.y) * scale)
    }

    static func floorPoint(horizontal: CGFloat, depth: CGFloat) -> CGPoint {
        recede(CGPoint(x: 31 + 178 * horizontal, y: 59), depth: depth)
    }

    private static func polygon(_ points: [CGPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.line(to: point) }
        path.close()
        return path
    }

    private static func roundedPolygon(_ points: [CGPoint], radius: CGFloat) -> NSBezierPath {
        let path = CGMutablePath()
        for index in points.indices {
            let corner = points[index]
            let previous = points[(index + points.count - 1) % points.count]
            let next = points[(index + 1) % points.count]
            func tangent(toward point: CGPoint) -> CGPoint {
                let dx = point.x - corner.x, dy = point.y - corner.y
                let distance = hypot(dx, dy)
                let fraction = min(radius / distance, 0.5)
                return CGPoint(x: corner.x + dx * fraction, y: corner.y + dy * fraction)
            }
            let entry = tangent(toward: previous), exit = tangent(toward: next)
            if index == points.startIndex { path.move(to: entry) } else { path.addLine(to: entry) }
            path.addQuadCurve(to: exit, control: corner)
        }
        path.closeSubpath()
        return NSBezierPath(cgPath: path)
    }

    private static func drawGlassInterior() {
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(cgPath: glassOutline).addClip()
        let left = CGPoint(x: 27, y: 54), right = CGPoint(x: 213, y: 54)
        let backLeft = recede(left), backRight = recede(right)
        let topLeft = CGPoint(x: 27, y: 169), topRight = CGPoint(x: 213, y: 169)

        // Rear uprights and side walls are visible through the front pane.
        gradient(polygon([left, backLeft, recede(topLeft), topLeft]),
                 [(0xD1E1EE, 0.10), (0xFFFFFF, 0.035), (0xFFFFFF, 0.22)], 0)
        gradient(polygon([right, backRight, recede(topRight), topRight]),
                 [(0x849CAF, 0.14), (0xE6F1FA, 0.035), (0xFFFFFF, 0.16)], 0)
        line(backLeft, recede(topLeft), color: 0x7E94A7, alpha: 0.23, width: 0.65)
        line(backRight, recede(topRight), color: 0x7E94A7, alpha: 0.26, width: 0.65)
        line(CGPoint(x: backLeft.x + 1.2, y: backLeft.y), recede(CGPoint(x: 29, y: 169)), color: 0xFFFFFF, alpha: 0.56, width: 1)
        line(CGPoint(x: backRight.x - 1.2, y: backRight.y), recede(CGPoint(x: 211, y: 169)), color: 0xFFFFFF, alpha: 0.46, width: 0.8)

        // The bottom is a receding plane, with its back edge higher and narrower.
        let floor = roundedPolygon([left, right, backRight, backLeft], radius: 5)
        gradient(floor, [(0xD6E4EF, 0.13), (0xFFFFFF, 0.05), (0xFFFFFF, 0.31)], -90)
        stroke(floor, 0x7A91A4, 0.21, 0.8)
        let innerLeft = CGPoint(x: 29, y: 56), innerRight = CGPoint(x: 211, y: 56)
        let innerFloor = roundedPolygon([innerLeft, innerRight, recede(innerRight), recede(innerLeft)], radius: 5)
        stroke(innerFloor, 0xFFFFFF, 0.66, 1.1)
        stroke(innerFloor, 0xFFFFFF, 0.12, 3.2)
        NSGraphicsContext.restoreGraphicsState()
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

        drawGlassInterior()

        // Fill the complete head first, including the formerly clear perimeter.
        let head = NSBezierPath(cgPath: headOutline)
        gradient(head, [(0xC4CED8, 1), (0xE6ECF1, 1), (0xA6B2BF, 1)], -90)
        stroke(head, 0x8997A5, 0.85, 0.7)

        // A softly rolled shoulder joins the receding lid to the front face.
        let top = NSBezierPath()
        top.move(to: CGPoint(x: 27, y: 217))
        top.curve(to: CGPoint(x: 42, y: 245), controlPoint1: CGPoint(x: 29, y: 225), controlPoint2: CGPoint(x: 36, y: 238))
        top.curve(to: CGPoint(x: 57, y: 252), controlPoint1: CGPoint(x: 46, y: 251), controlPoint2: CGPoint(x: 49, y: 252))
        top.line(to: CGPoint(x: 183, y: 252))
        top.curve(to: CGPoint(x: 198, y: 245), controlPoint1: CGPoint(x: 191, y: 252), controlPoint2: CGPoint(x: 194, y: 251))
        top.curve(to: CGPoint(x: 213, y: 217), controlPoint1: CGPoint(x: 204, y: 238), controlPoint2: CGPoint(x: 211, y: 225))
        top.close()
        gradient(top, [(0xF8FAFC, 1), (0xDFE6ED, 1), (0xBCC8D3, 1)], -86)
        let topHighlight = NSBezierPath()
        topHighlight.move(to: CGPoint(x: 29, y: 220))
        topHighlight.curve(to: CGPoint(x: 44, y: 245), controlPoint1: CGPoint(x: 33, y: 232), controlPoint2: CGPoint(x: 39, y: 240))
        topHighlight.curve(to: CGPoint(x: 58, y: 252), controlPoint1: CGPoint(x: 48, y: 251), controlPoint2: CGPoint(x: 51, y: 252))
        topHighlight.line(to: CGPoint(x: 182, y: 252))
        stroke(topHighlight, 0xFFFFFF, 0.67, 1.1)

        // This is the full structural face, with no inset plate or decorative capsule.
        let face = NSBezierPath()
        face.move(to: CGPoint(x: 23, y: 217))
        face.line(to: CGPoint(x: 217, y: 217))
        face.line(to: CGPoint(x: 217, y: 169))
        face.line(to: CGPoint(x: 23, y: 169))
        face.close()
        NSGraphicsContext.saveGraphicsState()
        head.addClip()
        gradient(face, [(0xE7EDF2, 1), (0xCAD4DE, 1), (0xDFE6ED, 1)], -90)
        gradient(NSBezierPath(rect: NSRect(x: 23, y: 169, width: 17, height: 48)), [(0xFFFFFF, 0.40), (0xFFFFFF, 0.06), (0xFFFFFF, 0)], 0)
        gradient(NSBezierPath(rect: NSRect(x: 200, y: 169, width: 17, height: 48)), [(0x718494, 0), (0x718494, 0.04), (0x718494, 0.17)], 0)
        gradient(NSBezierPath(rect: NSRect(x: 24, y: 212, width: 192, height: 7)), [(0xFFFFFF, 0), (0xFFFFFF, 0.48), (0xFFFFFF, 0)], -90)
        line(CGPoint(x: 23.5, y: 169.5), CGPoint(x: 216.5, y: 169.5), color: 0x6F8192, alpha: 0.38, width: 0.7)
        text("Revo", NSPoint(x: 45, y: 182), NSFont(name: "Georgia-Italic", size: 17) ?? .systemFont(ofSize: 17), 0x3B4653)
        NSGraphicsContext.restoreGraphicsState()

        // The inlet and shutter share geometry with the paper clipping plane.
        let lip = rounded(inlet.insetBy(dx: -4, dy: -3), 6.5)
        gradient(lip, [(0x82919F, 0.9), (0xFFFFFF, 1), (0x9EAAB7, 0.9), (0xFFFFFF, 1)])
        gradient(rounded(inlet, 3.5), [(0x121C25, 1), (0x3C4A58, 1)])
        line(CGPoint(x: 52, y: inlet.minY), CGPoint(x: 188, y: inlet.minY), color: 0xF4FAFF, alpha: 0.9, width: 0.7)

    }

    private static func drawGlass() {
        let front = NSBezierPath(cgPath: glassOutline)
        NSGraphicsContext.saveGraphicsState()
        front.addClip()
        // Front edges stay vertical; depth belongs to the side walls and floor behind them.
        gradient(front, [(0xFFFFFF, 0.11), (0xE4EFF9, 0.015), (0xFFFFFF, 0.04), (0xFFFFFF, 0.15)], -83)
        let rim = NSBezierPath()
        rim.move(to: CGPoint(x: 24.5, y: 169))
        rim.line(to: CGPoint(x: 24.5, y: 62))
        rim.curve(to: CGPoint(x: 36, y: 50.5), controlPoint1: CGPoint(x: 24.5, y: 53), controlPoint2: CGPoint(x: 27.5, y: 50.5))
        rim.line(to: CGPoint(x: 204, y: 50.5))
        rim.curve(to: CGPoint(x: 215.5, y: 62), controlPoint1: CGPoint(x: 212.5, y: 50.5), controlPoint2: CGPoint(x: 215.5, y: 53))
        rim.line(to: CGPoint(x: 215.5, y: 169))
        stroke(rim, 0xFFFFFF, 0.16, 4.5)
        stroke(rim, 0xFFFFFF, 0.83, 1.3)
        line(CGPoint(x: 29, y: 58), CGPoint(x: 29, y: 168), color: 0x9BB0C2, alpha: 0.25, width: 0.65)
        line(CGPoint(x: 211, y: 58), CGPoint(x: 211, y: 168), color: 0x8FA5B9, alpha: 0.28, width: 0.65)

        // Broad, low-contrast reflections merge into the clear center.
        let reflection = NSBezierPath()
        reflection.move(to: CGPoint(x: 24, y: 168))
        reflection.curve(to: CGPoint(x: 79, y: 168), controlPoint1: CGPoint(x: 43, y: 161), controlPoint2: CGPoint(x: 55, y: 162))
        reflection.curve(to: CGPoint(x: 153, y: 54), controlPoint1: CGPoint(x: 93, y: 103), controlPoint2: CGPoint(x: 128, y: 69))
        reflection.line(to: CGPoint(x: 119, y: 54))
        reflection.curve(to: CGPoint(x: 24, y: 153), controlPoint1: CGPoint(x: 93, y: 81), controlPoint2: CGPoint(x: 44, y: 128))
        reflection.close()
        gradient(reflection, [(0xFFFFFF, 0.20), (0xFFFFFF, 0.015)], -48)
        gradient(rounded(NSRect(x: 28, y: 65, width: 7, height: 110), 3.5), [(0xFFFFFF, 0.04), (0xFFFFFF, 0.58), (0xB8D1E6, 0.10), (0xFFFFFF, 0.02)], 0)
        gradient(rounded(NSRect(x: 205, y: 65, width: 7, height: 110), 3.5), [(0xFFFFFF, 0.015), (0x98AFC3, 0.20), (0xFFFFFF, 0.70), (0xFFFFFF, 0.03)], 0)
        gradient(rounded(NSRect(x: 30, y: 51, width: 180, height: 6), 2), [(0xFFFFFF, 0.06), (0xC4D8E9, 0.25), (0xFFFFFF, 0.77), (0xFFFFFF, 0.02)])
        line(CGPoint(x: 31, y: 53), CGPoint(x: 209, y: 53), color: 0xFFFFFF, alpha: 0.84, width: 1)
        // A narrow contact shadow separates the solid head from the glass below it.
        gradient(NSBezierPath(rect: NSRect(x: 23, y: 161, width: 194, height: 8)), [(0x536779, 0.16), (0x536779, 0)], -90)
        NSGraphicsContext.restoreGraphicsState()
    }

    /// Center the visible glyphs, rather than the font's line box, on the control axis.
    static func powerLabel(isPoweredOn: Bool) -> CGImage {
        let labelSize = NSSize(width: 37, height: 15)
        return raster(labelSize) {
            let font = NSFont.systemFont(ofSize: 8, weight: .semibold)
            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil),
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): color(0x465361).cgColor
            ]
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: isPoweredOn ? "ON" : "OFF", attributes: attributes))
            let ink = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
            let context = NSGraphicsContext.current!.cgContext
            context.textMatrix = .identity
            context.textPosition = CGPoint(x: -ink.minX, y: (labelSize.height - ink.height) / 2 - ink.minY)
            CTLineDraw(line, context)
        }
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
