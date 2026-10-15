import AVFoundation

/// Prepare and play audio away from the main thread so the first sheet never stalls.
final class SoundPlayer {
    enum Effect: CaseIterable { case motor, finish, switchOn, switchOff }
    private let queue = DispatchQueue(label: "com.revo.audio", qos: .userInitiated)
    private var players: [Effect: AVAudioPlayer] = [:]

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

    func stopAll() {
        queue.async { [self] in players.values.forEach { $0.stop() } }
    }
}
