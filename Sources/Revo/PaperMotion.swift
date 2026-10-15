import Foundation

/// Bounded inertial motion for a loose fragment, measured in the machine's coordinates.
struct PaperMotion {
    var offset = CGPoint.zero
    var velocity = CGPoint.zero
    var angle: CGFloat = 0
    var spin: CGFloat = 0
    let variation: CGFloat

    mutating func impulse(_ delta: CGPoint) {
        velocity.x += delta.x * variation
        velocity.y += min(105, hypot(delta.x, delta.y) * 0.27) * variation
        spin += delta.x * 0.025 * variation + delta.y * 0.012
        velocity.x = max(-280, min(280, velocity.x))
        velocity.y = min(180, velocity.y)
        spin = max(-12, min(12, spin))
    }

    mutating func step(_ dt: CGFloat, horizontalRange: ClosedRange<CGFloat>) {
        velocity.x += (-42 * offset.x - 6.5 * velocity.x) * dt
        velocity.y -= 270 * dt
        offset.x += velocity.x * dt
        offset.y += velocity.y * dt
        if offset.x < horizontalRange.lowerBound || offset.x > horizontalRange.upperBound {
            offset.x = max(horizontalRange.lowerBound, min(horizontalRange.upperBound, offset.x))
            velocity.x *= -0.3
        }
        if offset.y < 0 {
            offset.y = 0
            velocity.y = abs(velocity.y) > 15 ? abs(velocity.y) * 0.24 : 0
            velocity.x *= exp(-5 * dt)
        }
        if offset.y > 62 { offset.y = 62; velocity.y = min(0, velocity.y) }
        spin += (-34 * angle - 6.5 * spin) * dt
        angle += spin * dt
        angle = max(-1.5, min(1.5, angle))
        if isSettled { offset = .zero; velocity = .zero; angle = 0; spin = 0 }
    }

    var intensity: CGFloat {
        let speed = (velocity.x * velocity.x + velocity.y * velocity.y).squareRoot()
        return min(1, (speed + abs(spin) * 8) / 210)
    }
    var isSettled: Bool {
        abs(offset.x) < 0.08 && offset.y < 0.05 && abs(velocity.x) < 0.65 &&
        abs(velocity.y) < 0.7 && abs(angle) < 0.004 && abs(spin) < 0.04
    }
}
