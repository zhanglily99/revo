import AppKit
import QuartzCore

/// Explicit developer preview; demo jobs never touch files.
enum Preview {
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
