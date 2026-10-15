import AppKit
import QuartzCore

/// A short roller catch followed by a slow, continuous feed through a curved paper surface.
enum PaperFeed {
    struct Timing {
        let approach: Double
        let grip: Double
        let pull: Double
        let stagger: Double
        var lead: Double { approach + grip }
        var duration: Double { lead + pull }

        init(style: ShredStyle, reducedMotion: Bool) {
            approach = reducedMotion ? 0 : 0.30
            grip = reducedMotion ? 0 : 0.17
            pull = reducedMotion ? 0.22 : style == .heavy ? 2.7 : style == .folder ? 2.2 : 1.85
            stagger = reducedMotion ? 0.04 : 0.22
        }
    }

    static func sheet(image: CGImage, sourceX: CGFloat, targetX: CGFloat,
                      index: Int, timing: Timing, reducedMotion: Bool) -> CALayer {
        let width = MachineArtwork.paperWidth, height = MachineArtwork.paperHeight
        let host = CALayer()
        host.bounds = CGRect(x: 0, y: 0, width: 160, height: height + 12)
        host.anchorPoint = CGPoint(x: 0.5, y: 0)
        host.position = CGPoint(x: 80, y: 0)
        host.masksToBounds = false
        let start = CACurrentMediaTime() + Double(index) * timing.stagger
        let samples = reducedMotion ? 2 : 100
        let times = (0..<samples).map { Double($0) / Double(samples - 1) }
        let bandCount = reducedMotion ? 1 : 44

        func smooth(_ t: Double) -> Double { let u = max(0, min(1, t)); return u * u * (3 - 2 * u) }
        func pose(_ time: Double) -> (bottom: CGFloat, x: CGFloat, roll: CGFloat, angle: CGFloat) {
            if reducedMotion { return (-CGFloat(time / timing.pull) * (height + 4), targetX, 0, 0) }
            if time < timing.approach {
                let p = CGFloat(1 - pow(1 - time / timing.approach, 3))
                return (10 - 8 * p, sourceX + (targetX - sourceX) * p, 0,
                        (index == 1 ? 0.065 : -0.055) * (1 - p))
            }
            let caught = time - timing.approach
            if caught < timing.grip {
                let p = CGFloat(smooth(caught / 0.065))
                // The rollers bite a few points, then hold briefly under tension.
                return (2 - 5 * p, targetX, p, 0)
            }
            let pullTime = min(timing.pull, caught - timing.grip)
            let ramp = 0.20
            let distance = pullTime < ramp ? pullTime * pullTime / (2 * ramp) : pullTime - ramp / 2
            let p = CGFloat(distance / (timing.pull - ramp / 2))
            return (-3 - p * (height + 3), targetX, 1, 0)
        }

        func curved(_ y: CGFloat, roll: CGFloat) -> CGFloat {
            guard y > 0 else { return y }
            return y - 4.5 * roll * (y / 13) * exp(-y / 13)
        }

        for band in 0..<bandCount {
            let bottom = CGFloat(band) * height / CGFloat(bandCount)
            let top = CGFloat(band + 1) * height / CGFloat(bandCount)
            let cropTop = CGFloat(image.height) * (1 - CGFloat(band + 1) / CGFloat(bandCount))
            let cropBottom = CGFloat(image.height) * (1 - CGFloat(band) / CGFloat(bandCount))
            // Image crops use top-origin pixels; sheet geometry uses bottom-origin points.
            let crop = CGRect(x: 0, y: cropTop, width: CGFloat(image.width), height: cropBottom - cropTop)
            guard let texture = image.cropping(to: crop) else { continue }
            let strip = CALayer()
            strip.contents = texture
            strip.contentsGravity = .resize
            strip.allowsEdgeAntialiasing = false
            var positions: [NSValue] = [], sizes: [NSValue] = []
            for fraction in times {
                let p = pose(fraction * timing.duration)
                let lower = curved(bottom + p.bottom, roll: p.roll)
                let upper = curved(top + p.bottom, roll: p.roll)
                let middle = (lower + upper) / 2
                positions.append(NSValue(point: CGPoint(x: p.x, y: middle)))
                sizes.append(NSValue(rect: CGRect(x: 0, y: 0, width: width, height: upper - lower + 0.8)))
            }
            strip.position = positions.last!.pointValue
            strip.bounds = sizes.last!.rectValue
            host.addSublayer(strip)
            func track(_ key: String, _ values: [Any]) -> CAKeyframeAnimation {
                let animation = CAKeyframeAnimation(keyPath: key)
                animation.values = values
                animation.keyTimes = times.map { NSNumber(value: $0) }
                animation.calculationMode = .linear
                return animation
            }
            let group = CAAnimationGroup()
            group.animations = [track("position", positions), track("bounds", sizes)]
            group.duration = timing.duration
            group.beginTime = start
            group.fillMode = .backwards
            strip.add(group, forKey: "rollerFeed")
        }
        if !reducedMotion {
            // One continuous reflection avoids visible seams between warped texture bands.
            let contact = CAGradientLayer()
            contact.frame = CGRect(x: 0, y: 0, width: 160, height: 18)
            contact.colors = [NSColor(white: 0, alpha: 0.28).cgColor,
                              NSColor(white: 0, alpha: 0.08).cgColor, NSColor.clear.cgColor]
            contact.locations = [0, 0.4, 1]
            contact.startPoint = CGPoint(x: 0.5, y: 0); contact.endPoint = CGPoint(x: 0.5, y: 1)
            let mask = CAShapeLayer()
            let paths = times.map { fraction -> CGPath in
                let p = pose(fraction * timing.duration)
                let bottom = curved(p.bottom, roll: p.roll)
                let top = curved(p.bottom + height, roll: p.roll)
                return CGPath(roundedRect: CGRect(x: p.x - width / 2, y: bottom, width: width, height: top - bottom),
                              cornerWidth: 5.5, cornerHeight: 5.5, transform: nil)
            }
            mask.path = paths.last
            let clipping = CAKeyframeAnimation(keyPath: "path")
            clipping.values = paths; clipping.keyTimes = times.map { NSNumber(value: $0) }
            clipping.duration = timing.duration; clipping.beginTime = start; clipping.fillMode = .backwards
            mask.add(clipping, forKey: "paperMask")
            contact.mask = mask
            contact.opacity = 0
            let tension = CAKeyframeAnimation(keyPath: "opacity")
            tension.values = times.map { NSNumber(value: Double(pose($0 * timing.duration).roll)) }
            tension.keyTimes = times.map { NSNumber(value: $0) }
            tension.duration = timing.duration; tension.beginTime = start; tension.fillMode = .backwards
            contact.add(tension, forKey: "contactShadow")
            host.addSublayer(contact)
        }
        let alignment = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        alignment.values = times.map { NSNumber(value: Double(pose($0 * timing.duration).angle)) }
        alignment.keyTimes = times.map { NSNumber(value: $0) }
        alignment.duration = timing.duration; alignment.beginTime = start; alignment.fillMode = .backwards
        host.add(alignment, forKey: "alignToRoller")
        return host
    }
}
