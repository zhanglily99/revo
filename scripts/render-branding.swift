import AppKit
import ImageIO
import UniformTypeIdentifiers

// Compile alongside BrandMark.swift. Every raster and SVG shares the same outlined lettering.
private func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha).cgColor
}

private func background(_ context: CGContext, size: CGSize) {
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [color(0xE9ECEF), color(0x98AFC7), color(0x305282)] as CFArray, locations: [0, 0.49, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: size.width * 0.02, y: 0),
        end: CGPoint(x: size.width * 0.96, y: size.height), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

private func png(_ url: URL, size: CGSize, draw: (CGContext) -> Void) {
    let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8,
        bytesPerRow: Int(size.width) * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    draw(context)
    NSGraphicsContext.restoreGraphicsState()
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    precondition(CGImageDestinationFinalize(destination))
}

private let markRect = CGRect(x: 171, y: 620, width: 738, height: 214.86)
private let xs: [CGFloat] = [4, 18, 32, 92, 109, 123, 197, 271, 285, 302, 371, 440, 451, 465, 539, 613, 627]
private let ys: [CGFloat] = [4, 18, 32, 78, 92, 106, 152, 166, 180]

private func guides(_ context: CGContext) {
    let scale = markRect.width / BrandMark.size.width
    context.saveGState()
    context.setStrokeColor(color(0xF3F7FA, 0.29)); context.setLineWidth(0.65)
    for x in xs {
        let px = markRect.minX + x * scale
        context.move(to: CGPoint(x: px, y: 0)); context.addLine(to: CGPoint(x: px, y: 1440))
    }
    for y in ys {
        let py = markRect.minY + y * scale
        context.move(to: CGPoint(x: 0, y: py)); context.addLine(to: CGPoint(x: 1080, y: py))
    }
    context.strokePath()
    context.setStrokeColor(color(0xF3F7FA, 0.38)); context.setLineWidth(0.75)
    for cx: CGFloat in [92, 197, 539] {
        for radius: CGFloat in [60, 74, 88] {
            context.strokeEllipse(in: CGRect(x: markRect.minX + (cx - radius) * scale,
                y: markRect.minY + (92 - radius) * scale, width: 2 * radius * scale, height: 2 * radius * scale))
        }
    }
    context.setStrokeColor(color(0xF3F7FA, 0.24)); context.setLineWidth(0.65)
    let apex = CGPoint(x: markRect.minX + 371 * scale, y: markRect.minY + 18 * scale)
    for sign: CGFloat in [-1, 1] {
        let dx: CGFloat = sign * 69 / 148
        let bottomX = apex.x + dx * (0 - apex.y)
        let topX = apex.x + dx * (1440 - apex.y)
        context.move(to: CGPoint(x: bottomX, y: 0)); context.addLine(to: CGPoint(x: topX, y: 1440))
    }
    context.strokePath()
    context.restoreGState()
}

private func svgPath(_ path: CGPath) -> String {
    var commands: [String] = []
    func point(_ p: CGPoint) -> String { String(format: "%.3f %.3f", p.x, p.y) }
    path.applyWithBlock { pointer in
        let e = pointer.pointee
        switch e.type {
        case .moveToPoint: commands.append("M" + point(e.points[0]))
        case .addLineToPoint: commands.append("L" + point(e.points[0]))
        case .addQuadCurveToPoint: commands.append("Q" + point(e.points[0]) + " " + point(e.points[1]))
        case .addCurveToPoint: commands.append("C" + point(e.points[0]) + " " + point(e.points[1]) + " " + point(e.points[2]))
        case .closeSubpath: commands.append("Z")
        @unknown default: break
        }
    }
    return commands.joined(separator: " ")
}

@main
struct RenderBranding {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else { fatalError("Usage: render-branding OUTPUT_DIRECTORY") }
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let portrait = CGSize(width: 1080, height: 1440)
        for construction in [false, true] {
            png(output.appendingPathComponent(construction ? "Revo-Construction.png" : "Revo-Wordmark-Gradient.png"), size: portrait) { context in
                background(context, size: portrait)
                if construction { guides(context) }
                BrandMark.draw(in: markRect, color: NSColor(cgColor: color(0xF8F9F7))!)
            }
        }
        for (name, ink) in [("White", UInt32(0xF8F9F7)), ("Navy", UInt32(0x305282))] {
            png(output.appendingPathComponent("Revo-Wordmark-\(name).png"), size: CGSize(width: 2528, height: 736)) { context in
                BrandMark.draw(in: CGRect(x: 0, y: 0, width: 2528, height: 736), color: NSColor(cgColor: color(ink))!)
            }
        }
        png(output.appendingPathComponent("Revo-AppIcon.png"), size: CGSize(width: 1024, height: 1024)) { context in
            let tile = CGPath(roundedRect: CGRect(x: 32, y: 32, width: 960, height: 960), cornerWidth: 216, cornerHeight: 216, transform: nil)
            context.saveGState(); context.addPath(tile); context.clip()
            background(context, size: CGSize(width: 1024, height: 1024))
            let light = CGGradient(colorsSpace: nil, colors: [color(0xFFFFFF, 0.14), color(0xFFFFFF, 0)] as CFArray, locations: [0, 1])!
            context.drawLinearGradient(light, start: CGPoint(x: 512, y: 992), end: CGPoint(x: 512, y: 500), options: [])
            context.restoreGState()
            context.addPath(tile); context.setStrokeColor(color(0xFFFFFF, 0.35)); context.setLineWidth(1.5); context.strokePath()
            BrandMark.draw(in: CGRect(x: 117, y: 397, width: 790, height: 230), color: NSColor(cgColor: color(0xF8F9F7))!)
        }
        let path = svgPath(BrandMark.outline)
        for (name, ink) in [("White", "#F8F9F7"), ("Navy", "#305282")] {
            let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"632\" height=\"184\" viewBox=\"0 0 632 184\"><title>Revo geometric wordmark</title><g transform=\"translate(0 184) scale(1 -1)\"><path fill=\"\(ink)\" d=\"\(path)\"/></g></svg>\n"
            try svg.write(to: output.appendingPathComponent("Revo-Wordmark-\(name).svg"), atomically: true, encoding: .utf8)
        }
        let scale = markRect.width / BrandMark.size.width
        let rectTop = 1440 - markRect.minY
        let defs = "<defs><linearGradient id=\"sky\" x1=\"2%\" y1=\"100%\" x2=\"96%\" y2=\"0%\"><stop stop-color=\"#E9ECEF\"/><stop offset=\".49\" stop-color=\"#98AFC7\"/><stop offset=\"1\" stop-color=\"#305282\"/></linearGradient></defs>"
        let appIcon = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"0 0 1024 1024\"><title>Revo app icon</title>\(defs)<rect x=\"32\" y=\"32\" width=\"960\" height=\"960\" rx=\"216\" fill=\"url(#sky)\" stroke=\"#FFFFFF\" stroke-opacity=\".35\" stroke-width=\"1.5\"/><g transform=\"translate(117 627) scale(1.25 -1.25)\"><path fill=\"#F8F9F7\" d=\"\(path)\"/></g></svg>\n"
        try appIcon.write(to: output.appendingPathComponent("Revo-AppIcon.svg"), atomically: true, encoding: .utf8)
        var construction = "<g fill=\"none\" stroke=\"#F3F7FA\" stroke-width=\".65\" stroke-opacity=\".29\">"
        for x in xs {
            let px = markRect.minX + x * scale
            construction += "<path d=\"M\(px) 0V1440\"/>"
        }
        for y in ys {
            let py = 1440 - markRect.minY - y * scale
            construction += "<path d=\"M0 \(py)H1080\"/>"
        }
        for cx: CGFloat in [92, 197, 539] {
            for r: CGFloat in [60, 74, 88] {
                construction += "<circle cx=\"\(markRect.minX + cx * scale)\" cy=\"\(1440 - markRect.minY - 92 * scale)\" r=\"\(r * scale)\" stroke-opacity=\".38\"/>"
            }
        }
        let ax = markRect.minX + 371 * scale, ay = markRect.minY + 18 * scale
        for sign: CGFloat in [-1, 1] {
            let dx: CGFloat = sign * 69 / 148
            construction += "<path d=\"M\(ax + dx * (1440 - ay)) 0L\(ax - dx * ay) 1440\" stroke-opacity=\".24\"/>"
        }
        construction += "</g>"
        for showConstruction in [false, true] {
            let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1080\" height=\"1440\" viewBox=\"0 0 1080 1440\"><title>Revo \(showConstruction ? "construction study" : "wordmark")</title>\(defs)<path fill=\"url(#sky)\" d=\"M0 0H1080V1440H0Z\"/>\(showConstruction ? construction : "")<g transform=\"translate(\(markRect.minX) \(rectTop)) scale(\(scale) -\(scale))\"><path fill=\"#F8F9F7\" d=\"\(path)\"/></g></svg>\n"
            try svg.write(to: output.appendingPathComponent(showConstruction ? "Revo-Construction.svg" : "Revo-Wordmark-Gradient.svg"), atomically: true, encoding: .utf8)
        }
        print("Generated Revo wordmarks, construction sheets, and app icon at \(output.path)")
    }
}
