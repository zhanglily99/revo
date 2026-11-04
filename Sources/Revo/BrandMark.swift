import AppKit

/// A geometric wordmark built from one stroke weight, shared circles, and tangent curves.
enum BrandMark {
    static let size = CGSize(width: 632, height: 184)
    static let strokeWidth: CGFloat = 28

    static var centerlines: [CGPath] {
        let r = CGMutablePath()
        r.move(to: CGPoint(x: 18, y: 18)); r.addLine(to: CGPoint(x: 18, y: 166))
        r.move(to: CGPoint(x: 18, y: 92))
        r.addCurve(to: CGPoint(x: 92, y: 166), control1: CGPoint(x: 18, y: 132.869),
                   control2: CGPoint(x: 51.131, y: 166))

        let e = CGMutablePath()
        // A small lower-right aperture keeps the rounded letter recognizable as e.
        e.addArc(center: CGPoint(x: 197, y: 92), radius: 74,
                 startAngle: 0, endAngle: 325 * .pi / 180, clockwise: false)
        e.move(to: CGPoint(x: 123, y: 92)); e.addLine(to: CGPoint(x: 271, y: 92))

        let v = CGMutablePath()
        v.move(to: CGPoint(x: 302, y: 166)); v.addLine(to: CGPoint(x: 371, y: 18))
        v.addLine(to: CGPoint(x: 440, y: 166))

        let o = CGPath(ellipseIn: CGRect(x: 465, y: 18, width: 148, height: 148), transform: nil)
        return [r, e, v, o]
    }

    static var outline: CGPath {
        let result = CGMutablePath()
        for path in centerlines {
            result.addPath(path.copy(strokingWithWidth: strokeWidth, lineCap: .round, lineJoin: .round, miterLimit: 4))
        }
        return result
    }

    static func draw(in rect: CGRect, color: NSColor) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let scale = min(rect.width / size.width, rect.height / size.height)
        context.saveGState()
        context.translateBy(x: rect.midX - size.width * scale / 2,
                            y: rect.midY - size.height * scale / 2)
        context.scaleBy(x: scale, y: scale)
        context.addPath(outline); context.setFillColor(color.cgColor); context.fillPath()
        context.restoreGState()
    }
}
