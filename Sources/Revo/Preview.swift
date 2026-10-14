import AppKit
import QuartzCore

/// Explicit developer preview; demo jobs never touch files.
enum Preview {
    static func exportIcon(path: String) {
        let ctx = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(MachineArtwork.color(0xE9EDF3).cgColor)
        ctx.addPath(CGPath(roundedRect: CGRect(x: 42, y: 42, width: 940, height: 940), cornerWidth: 208, cornerHeight: 208, transform: nil)); ctx.fillPath()
        ctx.translateBy(x: 68, y: -6); ctx.scaleBy(x: 3.7, y: 3.7)
        ctx.draw(MachineArtwork.image(), in: CGRect(origin: .zero, size: MachineArtwork.size))
        ctx.draw(MachineArtwork.image(glass: true), in: CGRect(origin: .zero, size: MachineArtwork.size))
        ctx.draw(MachineArtwork.shutter(), in: CGRect(x: 47, y: 189, width: 146, height: 7))
        ctx.draw(MachineArtwork.button(), in: MachineArtwork.switchFrame)
        if let image = ctx.makeImage(), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    static func export(panel: RevoPanel, directory: String) {
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        guard let view = panel.contentView as? RevoView else { exit(1) }
        func capture(_ name: String) {
            let width = 720, height = 840
            guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            ctx.setFillColor(MachineArtwork.color(0xE5EAF1).cgColor); ctx.fill(CGRect(x: 0, y: 0, width: width, height: height)); ctx.scaleBy(x: 3, y: 3)
            (view.layer?.presentation() ?? view.layer)?.render(in: ctx)
            if let image = ctx.makeImage(), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) {
                try? data.write(to: URL(fileURLWithPath: directory).appendingPathComponent(name + ".png"))
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { capture("idle"); view.setPower(true) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { capture("on"); view.demo(.photo) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) { capture("feeding") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) { capture("finished"); NSApp.terminate(nil) }
    }
}
