import AVFoundation

/// Prepare and play audio away from the main thread so the first sheet never stalls.
final class SoundPlayer {
    enum Effect: CaseIterable { case motor, finish, switchOn, switchOff }
    private let queue = DispatchQueue(label: "com.revo.audio", qos: .userInitiated)
    private var players: [Effect: AVAudioPlayer] = [:]
    private var paperPlayer: AVAudioPlayer?
    private var rustleRevision = 0

    init() {
        queue.async { [self] in
            for effect in Effect.allCases {
                let data: Data
                switch effect {
                case .motor: data = SoundSynth.shredData()
                case .finish: data = SoundSynth.thudData()
                case .switchOn: data = SoundSynth.switchData(powerOn: true)
                case .switchOff: data = SoundSynth.switchData(powerOn: false)
                }
                if let player = try? AVAudioPlayer(data: data) {
                    player.prepareToPlay()
                    players[effect] = player
                }
            }
            if let player = try? AVAudioPlayer(data: SoundSynth.rustleData()) {
                player.enableRate = true
                player.numberOfLoops = -1
                player.volume = 0
                player.prepareToPlay()
                paperPlayer = player
            }
        }
    }

    func play(_ effect: Effect, volume: Float) {
        let requested = ProcessInfo.processInfo.systemUptime
        queue.async { [self] in
            // Audio that missed its visual cue during device startup must not play late.
            guard ProcessInfo.processInfo.systemUptime - requested < 0.2,
                  let player = players[effect] else { return }
            player.currentTime = 0
            player.volume = volume
            player.play()
        }
    }

    /// Movement energy controls loudness, grain density through playback rate, and stereo position.
    func rustle(intensity: Float, pan: Float) {
        let requested = ProcessInfo.processInfo.systemUptime
        queue.async { [self] in
            guard let player = paperPlayer else { return }
            rustleRevision += 1
            let revision = rustleRevision
            let energy = max(0, min(1, intensity))
            guard energy > 0.012 else {
                player.setVolume(0, fadeDuration: 0.10)
                queue.asyncAfter(deadline: .now() + 0.12) { [self] in
                    if rustleRevision == revision { paperPlayer?.stop() }
                }
                return
            }
            guard ProcessInfo.processInfo.systemUptime - requested < 0.2 else { return }
            player.rate = 0.78 + energy * 0.62
            player.pan = pan
            if !player.isPlaying { player.volume = 0; player.play() }
            player.setVolume(0.025 + pow(energy, 0.8) * 0.34, fadeDuration: 0.055)
        }
    }

    func stopAll() {
        queue.async { [self] in
            players.values.forEach { $0.stop() }
            rustleRevision += 1
            paperPlayer?.stop()
        }
    }
}
