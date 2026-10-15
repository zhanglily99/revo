import AppKit

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
    static let inlet = CGRect(x: 47, y: slotY - 2, width: 146, height: 6)
    static let switchFrame = CGRect(x: 165, y: 181, width: 36, height: 22)
    static let counterFrame = CGRect(x: 114, y: 183, width: 42, height: 18)

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

    /// Circular fillets share tangent directions with the lid and upright sides.
    private static func shoulder(inset: CGFloat = 0) -> CGMutablePath {
        let path = CGMutablePath()
        let left = 23 + inset, right = 217 - inset
        let frontY = 217 + (2 - sqrt(5)) * inset
        let backY = 255 - inset
        let backLeft = 42 + (sqrt(5) - 1) * inset / 2
        let backRight = 240 - backLeft
        path.move(to: CGPoint(x: left, y: 200))
        path.addArc(tangent1End: CGPoint(x: left, y: frontY),
                    tangent2End: CGPoint(x: backLeft, y: backY), radius: 40 - inset)
        path.addArc(tangent1End: CGPoint(x: backLeft, y: backY),
                    tangent2End: CGPoint(x: backRight, y: backY), radius: 20 - inset)
        path.addArc(tangent1End: CGPoint(x: backRight, y: backY),
                    tangent2End: CGPoint(x: right, y: frontY), radius: 20 - inset)
        path.addArc(tangent1End: CGPoint(x: right, y: frontY),
                    tangent2End: CGPoint(x: right, y: 200), radius: 40 - inset)
        path.addLine(to: CGPoint(x: right, y: 200))
        return path
    }

    /// The body and metal head reuse one continuous shoulder contour.
    static var outline: CGPath {
        let path = shoulder()
        path.addLine(to: CGPoint(x: 217, y: 61))
        path.addQuadCurve(to: CGPoint(x: 205, y: 49), control: CGPoint(x: 217, y: 49))
        path.addLine(to: CGPoint(x: 35, y: 49))
        path.addQuadCurve(to: CGPoint(x: 23, y: 61), control: CGPoint(x: 23, y: 49))
        path.closeSubpath()
        return path
    }

    /// The metal terminates in a straight joint above the glass.
    static var headOutline: CGPath {
        let path = shoulder()
        path.addLine(to: CGPoint(x: 217, y: 169))
        path.addLine(to: CGPoint(x: 23, y: 169))
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

        let head = NSBezierPath(cgPath: headOutline)
        gradient(head, [(0xF7F9FB, 1), (0xDCE4EB, 1), (0xC2CDD7, 1)], -90)
        stroke(head, 0x8997A5, 0.72, 0.65)

        NSGraphicsContext.saveGraphicsState()
        head.addClip()
        // The reflection follows the same offset contour, with no independent corner patches.
        let rim = NSBezierPath(cgPath: shoulder(inset: 2.3))
        rim.lineWidth = 1.1
        rim.lineCapStyle = .round
        let context = NSGraphicsContext.current!.cgContext
        context.saveGState()
        context.addPath(rim.cgPath)
        context.setLineWidth(1.1)
        context.setLineCap(.round)
        context.replacePathWithStrokedPath()
        context.clip()
        gradient(NSBezierPath(rect: CGRect(x: 23, y: 200, width: 194, height: 55)),
                 [(0xFFFFFF, 0.74), (0xFFFFFF, 0.45), (0xFFFFFF, 0)], -90)
        context.restoreGState()

        // A broad rolled highlight blends the top into the front without a hard polygon seam.
        let face = NSBezierPath(rect: CGRect(x: 23, y: 169, width: 194, height: 55))
        let faceColors = [color(0xEDF2F6, 0), color(0xEDF2F6, 0.98),
                          color(0xD1DBE4), color(0xDFE6ED)]
        NSGradient(colors: faceColors, atLocations: [0, 0.2, 0.65, 1], colorSpace: .deviceRGB)!
            .draw(in: face, angle: -90)
        context.saveGState()
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        gradient(NSBezierPath(rect: NSRect(x: 23, y: 169, width: 17, height: 48)), [(0xFFFFFF, 0.30), (0xFFFFFF, 0.04), (0xFFFFFF, 0)], 0)
        gradient(NSBezierPath(rect: NSRect(x: 200, y: 169, width: 17, height: 48)), [(0x718494, 0), (0x718494, 0.03), (0x718494, 0.13)], 0)
        context.setBlendMode(.destinationIn)
        NSGradient(colors: [color(0xFFFFFF, 0), color(0xFFFFFF), color(0xFFFFFF)],
                   atLocations: [0, 0.28, 1], colorSpace: .deviceRGB)!
            .draw(in: NSBezierPath(rect: CGRect(x: 23, y: 169, width: 194, height: 48)), angle: -90)
        context.endTransparencyLayer()
        context.restoreGState()
        line(CGPoint(x: 23.5, y: 169.5), CGPoint(x: 216.5, y: 169.5), color: 0x6F8192, alpha: 0.38, width: 0.7)
        text("Revo", NSPoint(x: 45, y: 182), NSFont(name: "Georgia-Italic", size: 17) ?? .systemFont(ofSize: 17), 0x3B4653)
        NSGraphicsContext.restoreGraphicsState()

        drawInlet()
    }

    /// A capsule is foreshortened as a single shape, preserving tangent end arcs.
    /// Applying depth separately to control points would shear the semicircles.
    private static func inletProfile(_ rect: CGRect) -> NSBezierPath {
        let depthScale: CGFloat = 0.62
        let plane = CGRect(x: rect.minX, y: 0, width: rect.width,
                           height: rect.height / depthScale)
        let path = NSBezierPath(roundedRect: plane, xRadius: plane.height / 2,
                                yRadius: plane.height / 2)
        var projection = AffineTransform()
        projection.translate(x: 0, y: rect.minY)
        projection.scale(x: 1, y: depthScale)
        path.transform(using: projection)
        return path
    }

    private static func drawInlet() {
        // A fine machined bevel sits flush with the lid around the recessed aperture.
        let bevel = inletProfile(inlet.insetBy(dx: -0.9, dy: -0.9))
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = color(0x536575, 0.17)
        shadow.shadowBlurRadius = 1.2
        shadow.shadowOffset = NSSize(width: 0, height: -0.5)
        shadow.set()
        fill(bevel, 0xBBC7D1)
        NSGraphicsContext.restoreGraphicsState()
        gradient(bevel, [(0x9CAAB7, 1), (0xE9EEF3, 1), (0xC6D0DA, 1)], -90)
        stroke(bevel, 0x718291, 0.25, 0.35)

        let opening = inletProfile(inlet)
        NSGradient(colors: [color(0x526371), color(0x243541), color(0x3F5362), color(0x8CA0AF)],
                   atLocations: [0, 0.22, 0.58, 1], colorSpace: .deviceRGB)!
            .draw(in: opening, angle: -90)
        NSGraphicsContext.saveGraphicsState()
        opening.addClip()
        gradient(NSBezierPath(rect: CGRect(x: inlet.minX, y: inlet.minY, width: inlet.width, height: 1.5)),
                 [(0xDFEAF1, 0), (0xDFEAF1, 0.48)], -90)
        gradient(NSBezierPath(rect: CGRect(x: inlet.minX, y: inlet.maxY - 0.9, width: inlet.width, height: 0.9)), [(0x12212D, 0.50), (0x12212D, 0)], -90)
        NSGraphicsContext.restoreGraphicsState()
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: CGRect(x: inlet.minX - 2, y: inlet.minY - 2,
                                 width: inlet.width + 4, height: inlet.height / 2 + 2)).addClip()
        stroke(bevel, 0xFFFFFF, 0.65, 0.5)
        NSGraphicsContext.restoreGraphicsState()
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

    /// A recessed, four-digit instrument display keeps the count legible at desktop scale.
    static func counter(count: Int, powered: Bool) -> CGImage {
        raster(counterFrame.size) {
            let bezel = rounded(CGRect(x: 0.5, y: 0.5, width: 41, height: 17), 4)
            gradient(bezel, [(0x8E9CA6, 1), (0xF4F7F9, 1)], -90)
            let screen = rounded(CGRect(x: 1.6, y: 1.7, width: 38.8, height: 14.6), 2.7)
            gradient(screen, [(0x121D1D, 1), (0x283534, 1)], -90)
            stroke(screen, 0x40504F, 0.7, 0.5)
            let digits = String(format: "%04d", max(0, count))
            let pitch = min(7, 32 / CGFloat(digits.count))
            let digitWidth = pitch - 2.4
            let startX = (42 - (CGFloat(digits.count) * pitch - 2.4)) / 2
            let segments: [[Int]] = [[0,1,2,4,5,6], [2,5], [0,2,3,4,6], [0,2,3,5,6],
                                     [1,2,3,5], [0,1,3,5,6], [0,1,3,4,5,6], [0,2,5],
                                     [0,1,2,3,4,5,6], [0,1,2,3,5,6]]
            for (index, character) in digits.enumerated() {
                let x = startX + CGFloat(index) * pitch
                let w = digitWidth
                let endpoints: [(CGPoint, CGPoint)] = [
                    (CGPoint(x:x+0.6,y:13.2), CGPoint(x:x+w-0.6,y:13.2)),
                    (CGPoint(x:x,y:12.4), CGPoint(x:x,y:9.7)),
                    (CGPoint(x:x+w,y:12.4), CGPoint(x:x+w,y:9.7)),
                    (CGPoint(x:x+0.6,y:9), CGPoint(x:x+w-0.6,y:9)),
                    (CGPoint(x:x,y:8.3), CGPoint(x:x,y:5.6)),
                    (CGPoint(x:x+w,y:8.3), CGPoint(x:x+w,y:5.6)),
                    (CGPoint(x:x+0.6,y:4.8), CGPoint(x:x+w-0.6,y:4.8))]
                let active = segments[character.wholeNumberValue ?? 0]
                for (segment, points) in endpoints.enumerated() {
                    line(points.0, points.1, color: powered ? 0xBAE5CE : 0xA6BEB3,
                         alpha: active.contains(segment) ? 0.95 : 0.065, width: 0.7)
                }
            }
            // A faint upper reflection sits behind the digits rather than washing them out.
            line(CGPoint(x:5,y:15.2), CGPoint(x:37,y:15.2), color: 0xFFFFFF, alpha: 0.13, width: 0.5)
        }
    }

    static func shutter() -> CGImage {
        raster(inlet.size) {
            // Translate the exact projected aperture into the shutter's local bitmap.
            NSGraphicsContext.current!.cgContext.translateBy(x: -inlet.minX, y: -inlet.minY)
            let shape = inletProfile(inlet)
            gradient(shape, [(0xA7B4C1, 1), (0xDCE4EB, 1), (0xC0CCD7, 1)], -90)
            line(CGPoint(x: inlet.minX + 4, y: inlet.maxY - 0.5), CGPoint(x: inlet.maxX - 4, y: inlet.maxY - 0.5), color: 0x617485, alpha: 0.52, width: 0.4)
            line(CGPoint(x: inlet.minX + 4, y: inlet.minY + 0.55), CGPoint(x: inlet.maxX - 4, y: inlet.minY + 0.55), color: 0xF5F8FB, alpha: 0.62, width: 0.4)
        }
    }

    /// Silver rim, inset track, and a restrained mint tint when powered.
    static func switchTrack(powered: Bool) -> CGImage {
        raster(switchFrame.size) {
            let rim = rounded(CGRect(x: 0.5, y: 1.5, width: 35, height: 19), 9.5)
            gradient(rim, [(0x83939F, 1), (0xF4F8FA, 1)], -90)
            stroke(rim, 0xFFFFFF, 0.45, 0.5)
            let track = rounded(CGRect(x: 1.6, y: 2.8, width: 32.8, height: 16.4), 8.2)
            gradient(track, powered ? [(0x759C8D, 1), (0xB8D8C7, 1)] :
                     [(0x939FA9, 1), (0xC4CDD4, 1)], -90)
            stroke(track, powered ? 0x597D6B : 0x70808C, 0.37, 0.6)
            line(CGPoint(x:10,y:18.6), CGPoint(x:26,y:18.6), color: 0x344B41, alpha: 0.18, width: 0.7)
        }
    }

    static func switchThumb() -> CGImage {
        raster(NSSize(width: 22, height: 22)) {
            let knob = NSBezierPath(ovalIn: CGRect(x: 3, y: 3.4, width: 16, height: 16))
            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow(); shadow.shadowColor = color(0x253340, 0.32)
            shadow.shadowBlurRadius = 1.5; shadow.shadowOffset = NSSize(width: 0, height: -1.2); shadow.set()
            fill(knob, 0xB3BFC8)
            NSGraphicsContext.restoreGraphicsState()
            gradient(knob, [(0xFFFFFF, 1), (0xF2F5F7, 1), (0xB8C4CE, 1)], -90)
            stroke(knob, 0xFFFFFF, 0.75, 0.6)
            gradient(NSBezierPath(ovalIn: CGRect(x: 4.3, y: 5, width: 13.4, height: 13.2)),
                     [(0xFFFFFF, 1), (0xE4EBF0, 1)], -90)
        }
    }

    static func button() -> CGImage {
        raster(switchFrame.size) {
            let ctx = NSGraphicsContext.current!.cgContext
            ctx.draw(switchTrack(powered: false), in: CGRect(origin: .zero, size: switchFrame.size))
            ctx.draw(switchThumb(), in: CGRect(x: -1, y: 0, width: 22, height: 22))
        }
    }
}
