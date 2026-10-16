import AppKit
import QuartzCore

/// Explicit developer preview; demo jobs never touch files.
enum Preview {
    /// Record the real view and physics using demo sheets; no filesystem operations are performed.
    static func record(panel: RevoPanel, directory: String) {
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        guard let view = panel.contentView as? RevoView else { exit(1) }
        view.setPower(false)
        let width = 560, height = 500, fps = 20
        let duration = 12.0
        let start = CACurrentMediaTime()
        var powered = false, fed = false, switchedOff = false, frame = 0
        func smooth(_ value: Double) -> Double {
            let t = max(0, min(1, value))
            return t * t * (3 - 2 * t)
        }
        func movement(_ t: Double) -> CGPoint {
            if t < 4.7 { return .zero }
            if t < 6.4 {
                let p = (t - 4.7) / 1.7
                return CGPoint(x: 32 * sin(p * .pi * 2), y: 10 * sin(p * .pi))
            }
            if t < 8.1 {
                let p = (t - 6.4) / 1.7
                let envelope = sin(.pi * p)
                return CGPoint(x: 43 * envelope * sin(p * .pi * 9),
                               y: 12 * envelope * sin(p * .pi * 7))
            }
            return .zero
        }
        let timer = Timer(timeInterval: 1.0 / Double(fps), repeats: true) { timer in
            let time = CACurrentMediaTime() - start
            if time >= 0.8 && !powered { view.setPower(true); powered = true }
            if time >= 1.65 && !fed { view.demo(.photo); fed = true }
            if time >= 10.5 && !switchedOff { view.setPower(false); switchedOff = true }
            let offset = movement(time)
            view.previewMovement(to: offset)
            guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                       bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
            NSGradient(starting: MachineArtwork.color(0xEEF1F4), ending: MachineArtwork.color(0xDFE8E8))!
                .draw(in: CGRect(x: 0, y: 0, width: width, height: height), angle: 18)
            ctx.saveGState()
            ctx.translateBy(x: 130, y: 40)
            ctx.scaleBy(x: 1.25, y: 1.25)
            ctx.translateBy(x: offset.x, y: offset.y)
            (view.layer?.presentation() ?? view.layer)?.render(in: ctx)
            ctx.restoreGState()

            // A recording cursor makes the power clicks and body drag understandable without captions.
            var cursor: CGPoint?
            var pressed = false
            if time < 1.25 {
                let p = smooth((time - 0.15) / 0.6)
                cursor = CGPoint(x: 450 - 82 * p, y: 190 + 90 * p)
                pressed = time >= 0.78 && time < 0.93
            } else if time >= 4.4 && time < 8.35 {
                cursor = CGPoint(x: 130 + (120 + offset.x) * 1.25, y: 40 + (190 + offset.y) * 1.25)
                pressed = time >= 4.7 && time < 8.1
            } else if time >= 10.15 && time < 11.15 {
                cursor = CGPoint(x: 368, y: 280)
                pressed = time >= 10.48 && time < 10.63
            }
            if let cursor {
                if pressed {
                    MachineArtwork.color(0x78A594, 0.20).setFill()
                    NSBezierPath(ovalIn: CGRect(x: cursor.x - 10, y: cursor.y - 10, width: 20, height: 20)).fill()
                }
                let arrow = NSBezierPath()
                arrow.move(to: cursor)
                for delta in [CGPoint(x: 1, y: -20), CGPoint(x: 6, y: -15), CGPoint(x: 11, y: -23),
                              CGPoint(x: 15, y: -21), CGPoint(x: 10, y: -13), CGPoint(x: 17, y: -12)] {
                    arrow.line(to: CGPoint(x: cursor.x + delta.x, y: cursor.y + delta.y))
                }
                arrow.close()
                NSColor.white.setStroke(); arrow.lineWidth = 2; arrow.lineJoinStyle = .round; arrow.stroke()
                MachineArtwork.color(0x354047).setFill(); arrow.fill()
            }
            NSGraphicsContext.restoreGraphicsState()
            if let image = ctx.makeImage(), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) {
                let path = URL(fileURLWithPath: directory).appendingPathComponent(String(format: "frame-%04d.png", frame))
                do { try data.write(to: path) } catch { fputs("Unable to write demo frame: \(error)\n", stderr); exit(1) }
            }
            frame += 1
            if time >= duration { timer.invalidate(); NSApp.terminate(nil) }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    static func export(panel: RevoPanel, directory: String) {
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        guard let view = panel.contentView as? RevoView else { exit(1) }
        func capture(_ name: String) {
            let width = Int(MachineArtwork.size.width * 3), height = Int(MachineArtwork.size.height * 3)
            guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            ctx.setFillColor(MachineArtwork.color(0xE5EAF1).cgColor); ctx.fill(CGRect(x: 0, y: 0, width: width, height: height)); ctx.scaleBy(x: 3, y: 3)
            (view.layer?.presentation() ?? view.layer)?.render(in: ctx)
            if let image = ctx.makeImage(), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) {
                try? data.write(to: URL(fileURLWithPath: directory).appendingPathComponent(name + ".png"))
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { capture("idle"); view.setPower(true) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { capture("on"); view.demo(.photo) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) { capture("gripping") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) { capture("feeding") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.9) { capture("finished"); NSApp.terminate(nil) }
    }
}
