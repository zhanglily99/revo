import AppKit

/// All coordinates are shared with the paper masks; no baked-in product image.
enum MachineArtwork {
    static let size = NSSize(width: 240, height: 280)
    static let slotY: CGFloat = 192
    static let paperWidth: CGFloat = 66
    static let paperHeight: CGFloat = 80
    static let window = CGRect(x: 43, y: 83, width: 154, height: 63)

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
    private static func gradient(_ path: NSBezierPath, _ colors: [UInt32], _ angle: CGFloat = -90) {
        NSGradient(colors: colors.map { color($0) })!.draw(in: path, angle: angle)
    }
    private static func text(_ string: String, _ point: NSPoint, _ font: NSFont, _ hex: UInt32) {
        (string as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color(hex)])
    }
    private static func path(_ points: [CGPoint]) -> NSBezierPath {
        let p = NSBezierPath(); p.move(to: points[0]); points.dropFirst().forEach { p.line(to: $0) }; p.close(); return p
    }

    private static func drawBody() {
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow(); shadow.shadowColor = color(0x202A20, 0.30)
        shadow.shadowBlurRadius = 12; shadow.shadowOffset = NSSize(width: 0, height: -7); shadow.set()
        fill(rounded(NSRect(x: 23, y: 52, width: 194, height: 121), 24), 0x6D815C)
        NSGraphicsContext.restoreGraphicsState()

        // Rubber feet, polished lower rim, and the enamel chassis.
        fill(rounded(NSRect(x: 37, y: 46, width: 30, height: 10), 4), 0x31372D)
        fill(rounded(NSRect(x: 173, y: 46, width: 30, height: 10), 4), 0x31372D)
        let rim = rounded(NSRect(x: 19, y: 53, width: 202, height: 127), 26)
        gradient(rim, [0xD9DDD2, 0x636A5F, 0xE9EAE1, 0x7F8778]); stroke(rim, 0x3E4938, 0.65)
        let body = rounded(NSRect(x: 19, y: 59, width: 202, height: 135), 25)
        gradient(body, [0xCBDFA9, 0xB4D18E, 0x98B775, 0x8AA76B], -12)
        stroke(body, 0x6C8555, 0.7, 0.8)
        stroke(rounded(NSRect(x: 22, y: 62, width: 196, height: 132), 23), 0xF3FFDB, 0.45, 0.8)
        let side = path([CGPoint(x: 201, y: 66), CGPoint(x: 214, y: 74), CGPoint(x: 216, y: 167), CGPoint(x: 201, y: 178)])
        fill(side, 0x577146, 0.13)

        // Recessed smoke glass, with a dark cavity behind the falling strips.
        let bezel = rounded(NSRect(x: 39, y: 79, width: 162, height: 71), 13)
        gradient(bezel, [0x647B51, 0xDCEBC0]); stroke(bezel, 0x668052, 0.6)
        let cavity = rounded(window, 10)
        gradient(cavity, [0x29372E, 0x455643, 0x64765A]); stroke(cavity, 0x1F2B23, 0.8)
        fill(rounded(NSRect(x: 48, y: 87, width: 144, height: 3), 1.5), 0x99AA7A, 0.22)

        // The top is a distinct cream enamel lid, slightly deeper at the back.
        let lid = NSBezierPath()
        lid.move(to: CGPoint(x: 20, y: 176))
        lid.curve(to: CGPoint(x: 39, y: 213), controlPoint1: CGPoint(x: 18, y: 195), controlPoint2: CGPoint(x: 24, y: 211))
        lid.curve(to: CGPoint(x: 201, y: 213), controlPoint1: CGPoint(x: 80, y: 218), controlPoint2: CGPoint(x: 164, y: 218))
        lid.curve(to: CGPoint(x: 220, y: 176), controlPoint1: CGPoint(x: 216, y: 211), controlPoint2: CGPoint(x: 222, y: 190))
        lid.curve(to: CGPoint(x: 202, y: 160), controlPoint1: CGPoint(x: 220, y: 166), controlPoint2: CGPoint(x: 214, y: 160))
        lid.line(to: CGPoint(x: 38, y: 160))
        lid.curve(to: CGPoint(x: 20, y: 176), controlPoint1: CGPoint(x: 26, y: 160), controlPoint2: CGPoint(x: 20, y: 166)); lid.close()
        NSGraphicsContext.saveGraphicsState()
        let lidShadow = NSShadow(); lidShadow.shadowBlurRadius = 2; lidShadow.shadowOffset = NSSize(width: 0, height: -3); lidShadow.shadowColor = color(0x34402C, 0.6); lidShadow.set()
        fill(lid, 0xCACBC1); NSGraphicsContext.restoreGraphicsState()
        gradient(lid, [0xF9F8F0, 0xECEDE4, 0xDEDED3]); stroke(lid, 0xFFFFFF, 0.9, 1)

        // Metal inlet lip. The paper mask ends precisely at this dark aperture.
        let inlet = rounded(NSRect(x: 43, y: 186, width: 154, height: 12), 6)
        gradient(inlet, [0x969D8E, 0xFDFCF3]); stroke(inlet, 0xA8AEA0, 0.7, 0.7)
        gradient(rounded(NSRect(x: 46, y: 188, width: 148, height: 7), 3.5), [0x141D18, 0x414D3A])
        fill(rounded(NSRect(x: 50, y: 188, width: 140, height: 1), 0.5), 0x8EA277, 0.8)
        text("Revo", NSPoint(x: 43, y: 164), NSFont(name: "Georgia-Italic", size: 17) ?? .systemFont(ofSize: 17), 0x4E5947)
        text("a little less.", NSPoint(x: 99, y: 168), .systemFont(ofSize: 7, weight: .medium), 0x8D9485)

        // Inlaid maker's plate and two slotted screws.
        let plate = rounded(NSRect(x: 94, y: 62, width: 52, height: 12), 6)
        gradient(plate, [0xE2E5D6, 0xA3B18E]); stroke(plate, 0x647857, 0.65, 0.6)
        text("REVO", NSPoint(x: 110, y: 64), .systemFont(ofSize: 7, weight: .medium), 0x4B6042)
        for x: CGFloat in [31, 209] {
            gradient(NSBezierPath(ovalIn: NSRect(x: x - 2, y: 66, width: 4, height: 4)), [0xDFE6D0, 0x7E8F6B])
            let line = NSBezierPath(); line.move(to: CGPoint(x: x - 1, y: 67)); line.line(to: CGPoint(x: x + 1, y: 69)); stroke(line, 0x5F7050, 0.8, 0.6)
        }
    }

    private static func drawGlass() {
        let glass = rounded(window, 10)
        fill(glass, 0xCBD8B6, 0.08)
        NSGraphicsContext.saveGraphicsState(); glass.addClip()
        fill(path([CGPoint(x: 48, y: 145), CGPoint(x: 81, y: 145), CGPoint(x: 111, y: 83), CGPoint(x: 94, y: 83)]), 0xF3FFDD, 0.07)
        fill(path([CGPoint(x: 86, y: 146), CGPoint(x: 90, y: 146), CGPoint(x: 120, y: 83), CGPoint(x: 117, y: 83)]), 0xFFFFFF, 0.06)
        NSGraphicsContext.restoreGraphicsState()
        stroke(glass, 0xECF5D9, 0.23, 0.7)
    }

    static func button() -> CGImage {
        raster(NSSize(width: 26, height: 26)) {
        gradient(NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: 24, height: 24)), [0x7A6442, 0xE8DDC3])
        gradient(NSBezierPath(ovalIn: NSRect(x: 3, y: 4, width: 20, height: 20)), [0xF6BA62, 0xE79338, 0xCC7029])
        stroke(NSBezierPath(ovalIn: NSRect(x: 4, y: 5, width: 18, height: 18)), 0xFFE2A4, 0.6, 0.6)
        let mark = NSBezierPath(); mark.move(to: CGPoint(x: 13, y: 11)); mark.line(to: CGPoint(x: 13, y: 17)); mark.lineCapStyle = .round; stroke(mark, 0xFFF5DC, 1, 1.8)
        }
    }
}
