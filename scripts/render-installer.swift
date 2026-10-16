import AppKit

// A two-resolution Finder background keeps installation text sharp on Retina displays.
let destination = CommandLine.arguments[1]
let size = CGSize(width: 640, height: 420)
for scale in [1, 2] {
    let ctx = CGContext(data: nil, width: Int(size.width) * scale, height: Int(size.height) * scale,
                        bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
    CGRect(origin: .zero, size: size).fill()
    let wash = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: [NSColor(calibratedRed: 0.79, green: 0.88, blue: 0.84, alpha: 0.35).cgColor,
                                   NSColor.white.withAlphaComponent(0).cgColor] as CFArray,
                          locations: [0, 1])!
    ctx.drawRadialGradient(wash, startCenter: CGPoint(x: 520, y: 30), startRadius: 0,
                           endCenter: CGPoint(x: 520, y: 30), endRadius: 330, options: [])
    func centered(_ text: String, y: CGFloat, font: NSFont, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let width = (text as NSString).size(withAttributes: attributes).width
        (text as NSString).draw(at: CGPoint(x: (size.width - width) / 2, y: y), withAttributes: attributes)
    }
    centered("Revo", y: 332, font: NSFont(name: "Georgia-Italic", size: 34)!,
             color: NSColor(calibratedRed: 0.24, green: 0.29, blue: 0.32, alpha: 1))
    let arrow = NSBezierPath()
    arrow.move(to: CGPoint(x: 293, y: 210)); arrow.line(to: CGPoint(x: 347, y: 210))
    arrow.move(to: CGPoint(x: 335, y: 221)); arrow.line(to: CGPoint(x: 347, y: 210))
    arrow.line(to: CGPoint(x: 335, y: 199))
    arrow.lineWidth = 1.6; arrow.lineCapStyle = .round; arrow.lineJoinStyle = .round
    NSColor(calibratedRed: 0.51, green: 0.59, blue: 0.56, alpha: 1).setStroke(); arrow.stroke()
    centered("Drag Revo to Applications.", y: 91, font: .systemFont(ofSize: 17, weight: .medium),
             color: NSColor(calibratedWhite: 0.30, alpha: 1))
    centered("macOS 14 or later  ·  Apple silicon & Intel", y: 61,
             font: .systemFont(ofSize: 11), color: NSColor(calibratedWhite: 0.53, alpha: 1))
    let pixels = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    let name = scale == 1 ? "installer-background.png" : "installer-background@2x.png"
    try pixels.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination).appendingPathComponent(name))
}
