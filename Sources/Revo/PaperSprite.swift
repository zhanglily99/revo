import AppKit
import ImageIO

/// Render each file as a paper preview with type-specific content.
/// A 4x bitmap keeps the small sheet crisp on Retina displays.
enum PaperSprite {
    static let size = NSSize(width: 40, height: 44)
    private static let scale: CGFloat = 4

    static func make(for url: URL, style: ShredStyle) -> CGImage? {
        let pixels = NSSize(width: size.width * scale, height: size.height * scale)
        guard let context = CGContext(data: nil, width: Int(pixels.width), height: Int(pixels.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        defer { NSGraphicsContext.restoreGraphicsState() }
        func S(_ v: CGFloat) -> CGFloat { v * scale }

        // Paper stock.
        let paperRect = NSRect(x: S(0.5), y: S(0.5), width: S(39), height: S(43))
        let paperPath = NSBezierPath(roundedRect: paperRect, xRadius: S(2.5), yRadius: S(2.5))
        NSColor(white: 0.97, alpha: 1).setFill()
        paperPath.fill()
        NSColor(white: 0.72, alpha: 1).setStroke()
        paperPath.lineWidth = S(0.6)
        paperPath.stroke()

        func drawIcon(_ rect: NSRect, edge: CGFloat) {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: S(edge), height: S(edge))
            icon.draw(in: rect)
        }
        func drawLine(_ rect: NSRect) {
            NSColor(white: 0.78, alpha: 1).setFill()
            NSBezierPath(roundedRect: rect, xRadius: S(0.9), yRadius: S(0.9)).fill()
        }

        switch style {
        case .photo:
            // Instant photo with a white bottom margin.
            let rect = NSRect(x: S(4), y: S(9), width: S(32), height: S(31))
            if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
               let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 160,
                kCGImageSourceCreateThumbnailWithTransform: true
               ] as CFDictionary) {
                NSImage(cgImage: thumbnail, size: rect.size).draw(in: rect)
            } else {
                NSColor(calibratedRed: 0.68, green: 0.76, blue: 0.61, alpha: 1).setFill()
                rect.fill()
                NSColor(calibratedRed: 0.96, green: 0.86, blue: 0.60, alpha: 1).setFill()
                NSBezierPath(ovalIn: NSRect(x: S(24), y: S(29), width: S(7), height: S(7))).fill()
                let hill = NSBezierPath(); hill.move(to: NSPoint(x: S(4), y: S(9)))
                hill.line(to: NSPoint(x: S(13), y: S(29))); hill.line(to: NSPoint(x: S(25), y: S(9))); hill.close()
                NSColor(calibratedRed: 0.36, green: 0.48, blue: 0.38, alpha: 1).setFill(); hill.fill()
            }
        case .audio:
            // Centered waveform and a title line.
            NSColor(calibratedRed: 0.45, green: 0.62, blue: 0.40, alpha: 0.85).setFill()
            let heights: [CGFloat] = [5, 9, 14, 10, 16, 12, 7, 12, 15, 9, 6, 10]
            for (i, h) in heights.enumerated() {
                let x = S(6) + CGFloat(i) * S(2.4)
                NSBezierPath(
                    roundedRect: NSRect(x: x, y: S(22) - S(h) / 2, width: S(1.4), height: S(h)),
                    xRadius: S(0.7), yRadius: S(0.7)
                ).fill()
            }
            drawLine(NSRect(x: S(9), y: S(6), width: S(22), height: S(1.8)))
        case .video:
            // Film perforations around a central frame.
            NSColor(white: 0.25, alpha: 0.8).setFill()
            for row in 0..<6 {
                let y = S(6) + CGFloat(row) * S(5.6)
                NSBezierPath(roundedRect: NSRect(x: S(3), y: y, width: S(2.2), height: S(2.8)), xRadius: S(0.5), yRadius: S(0.5)).fill()
                NSBezierPath(roundedRect: NSRect(x: S(34.8), y: y, width: S(2.2), height: S(2.8)), xRadius: S(0.5), yRadius: S(0.5)).fill()
            }
            drawIcon(NSRect(x: S(9), y: S(11), width: S(22), height: S(22)), edge: 22)
        case .document, .folder, .heavy:
            // Document icon and printed lines.
            drawIcon(NSRect(x: S(13), y: S(25), width: S(14), height: S(14)), edge: 14)
            let lineWidths: [CGFloat] = [22, 17, 20, 13]
            for (i, width) in lineWidths.enumerated() {
                let y = S(18.5) - CGFloat(i) * S(4.6)
                drawLine(NSRect(x: S(9), y: y, width: S(width), height: S(1.8)))
            }
        }

        return context.makeImage()
    }
}
