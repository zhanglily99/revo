import Foundation

/// Synthesize PCM WAV effects without external audio assets.
enum SoundSynth {
    private static let sampleRate = 22050

    /// A short two-part detent, with a lower pitch when switching off.
    static func switchData(powerOn: Bool) -> Data {
        let duration = 0.075
        let n = Int(Double(sampleRate) * duration)
        let pitch = powerOn ? 1750.0 : 1420.0
        var samples = [Int16](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / Double(sampleRate)
            let attack = min(1, t / 0.0006)
            let click = (sin(2 * .pi * pitch * t) * 0.38 + sin(2 * .pi * pitch * 2.31 * t) * 0.13) * exp(-t * 190) * attack
            let detentTime = max(0, t - 0.011)
            let detent = t > 0.011 ? sin(2 * .pi * 480 * detentTime) * exp(-detentTime * 130) * 0.22 : 0
            let body = sin(2 * .pi * 210 * t) * exp(-t * 105) * 0.10 * attack
            samples[i] = Int16(max(-1, min(1, click + detent + body)) * 32767)
        }
        return wav(samples)
    }

    /// A short motor startup with a rising pitch.
    static func wakeData() -> Data {
        let duration = 0.35
        let n = Int(Double(sampleRate) * duration)
        var samples = [Int16](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / Double(sampleRate)
            let freq = 70 + 90 * t / duration
            let env = min(1.0, t / 0.08) * (1 - t / duration)
            let v = sin(2 * .pi * freq * t) * 0.5 * env
            samples[i] = Int16(v * 32767 * 0.4)
        }
        return wav(samples)
    }

    /// Low motor rumble with filtered noise pulsing at 13 Hz.
    static func shredData() -> Data {
        let duration = 1.5
        let n = Int(Double(sampleRate) * duration)
        var samples = [Int16](repeating: 0, count: n)
        var lastNoise = 0.0
        for i in 0..<n {
            let t = Double(i) / Double(sampleRate)
            let rumble = sin(2 * .pi * 65 * t) * 0.25
            let white = Double.random(in: -1...1)
            lastNoise = lastNoise * 0.55 + white * 0.45 // Simple low-pass filter.
            let chop = 0.55 + 0.45 * sin(2 * .pi * 13 * t) // Cutter pulse.
            let noise = lastNoise * chop * 0.8
            let env = min(1.0, t / 0.1) * min(1.0, (duration - t) / 0.25)
            let v = (rumble + noise) * env
            samples[i] = Int16(max(-1, min(1, v)) * 32767 * 0.6)
        }
        return wav(samples)
    }

    /// A soft finishing thump with a short click.
    static func thudData() -> Data {
        let duration = 0.22
        let n = Int(Double(sampleRate) * duration)
        var samples = [Int16](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / Double(sampleRate)
            let decay = exp(-t * 18)
            let thump = sin(2 * .pi * 58 * t) * decay * 0.9
            let click = i < 200 ? Double.random(in: -1...1) * exp(-t * 200) * 0.35 : 0
            let v = (thump + click) * 0.7
            samples[i] = Int16(max(-1, min(1, v)) * 32767 * 0.7)
        }
        return wav(samples)
    }

    /// Falling paper noise, gradually damped.
    static func swishData() -> Data {
        let duration = 0.5
        let n = Int(Double(sampleRate) * duration)
        var samples = [Int16](repeating: 0, count: n)
        var lastNoise = 0.0
        for i in 0..<n {
            let t = Double(i) / Double(sampleRate)
            let white = Double.random(in: -1...1)
            let lp = 0.35 + 0.5 * (t / duration)
            lastNoise = lastNoise * lp + white * (1 - lp)
            let env = pow(sin(.pi * t / duration), 1.5)
            let v = lastNoise * env * 0.55
            samples[i] = Int16(max(-1, min(1, v)) * 32767 * 0.7)
        }
        return wav(samples)
    }

    /// Sparse, overlapping friction grains resemble loose paper rather than a motor.
    static func rustleData() -> Data {
        let duration = 2.1
        let n = Int(Double(sampleRate) * duration)
        let grains = (0..<64).map { _ in
            (start: Double.random(in: 0..<duration), length: Double.random(in: 0.012...0.10),
             amplitude: Double.random(in: 0.12...0.9))
        }
        var low = 0.0, high = 0.0
        var samples = [Int16](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / Double(sampleRate)
            let white = Double.random(in: -1...1)
            low = low * 0.86 + white * 0.14
            high = high * 0.32 + white * 0.68
            var envelope = 0.035
            for grain in grains {
                let phase = (t - grain.start + duration).truncatingRemainder(dividingBy: duration) / grain.length
                if phase < 1 { envelope += pow(sin(.pi * phase), 2) * grain.amplitude }
            }
            let sample = (high - low) * min(1.3, envelope) * 0.55
            samples[i] = Int16(max(-1, min(1, sample)) * 32767)
        }
        return wav(samples)
    }

    private static func wav(_ samples: [Int16]) -> Data {
        let dataSize = samples.count * 2
        var d = Data()
        func str(_ s: String) { d.append(contentsOf: s.utf8) }
        func u32(_ v: UInt32) { var v = v.littleEndian; d.append(Data(bytes: &v, count: 4)) }
        func u16(_ v: UInt16) { var v = v.littleEndian; d.append(Data(bytes: &v, count: 2)) }
        str("RIFF"); u32(UInt32(36 + dataSize)); str("WAVE")
        str("fmt "); u32(16); u16(1); u16(1)
        u32(UInt32(sampleRate)); u32(UInt32(sampleRate * 2)); u16(2); u16(16)
        str("data"); u32(UInt32(dataSize))
        for s in samples { var v = s.littleEndian; d.append(Data(bytes: &v, count: 2)) }
        return d
    }
}
