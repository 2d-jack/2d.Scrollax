import AVFoundation
import AudioToolbox

/// Owns the audio graph and a small pool of player voices so overlapping scroll ticks
/// can layer on top of each other instead of cutting each other off — that layering is
/// what makes fast scrolling sound "smooth" rather than like a machine gun of clicks.
/// A peak limiter sits after the mixer so that layering doesn't clip/distort when many
/// voices land at once during fast scrolling.
final class AudioEngine {
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: Double(Synth.sampleRate), channels: 1)!

    private struct Voice {
        let player: AVAudioPlayerNode
        let pitch: AVAudioUnitVarispeed
    }

    private var voices: [Voice] = []
    private var nextVoice = 0
    private var bufferPool: [AVAudioPCMBuffer] = []
    private var seed: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000) &+ 0x9E3779B97F4A7C15

    var pack: SoundPack = .softPop {
        didSet { rerenderPool() }
    }

    var volume: Float = 0.8 {
        didSet { engine.mainMixerNode.outputVolume = max(0, min(1, volume)) }
    }

    init(voiceCount: Int = 14) {
        let limiterDescription = AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: kAudioUnitSubType_PeakLimiter,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        let limiter = AVAudioUnitEffect(audioComponentDescription: limiterDescription)
        engine.attach(limiter)
        engine.disconnectNodeOutput(engine.mainMixerNode)

        for _ in 0..<voiceCount {
            let player = AVAudioPlayerNode()
            let pitch = AVAudioUnitVarispeed()
            engine.attach(player)
            engine.attach(pitch)
            engine.connect(player, to: pitch, format: format)
            engine.connect(pitch, to: engine.mainMixerNode, format: format)
            voices.append(Voice(player: player, pitch: pitch))
        }

        engine.connect(engine.mainMixerNode, to: limiter, format: nil)
        engine.connect(limiter, to: engine.outputNode, format: nil)

        engine.mainMixerNode.outputVolume = volume
        engine.prepare()
        do {
            try engine.start()
        } catch {
            FileHandle.standardError.write("Scrollax: failed to start audio engine: \(error)\n".data(using: .utf8)!)
        }
        rerenderPool()
    }

    private func rerenderPool(count: Int = 18) {
        let activePack = pack
        bufferPool = (0..<count).map { _ in Synth.makeBuffer(from: activePack.render(seed: &seed)) }
    }

    /// - Parameter intensity: 0...1, derived from scroll speed. Louder and slightly
    ///   higher-pitched at higher intensity, like a real material responding to force.
    func playTick(intensity: Float) {
        guard let buffer = bufferPool.randomElement() else { return }
        let clamped = max(0, min(1, intensity))
        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count

        voice.pitch.rate = 0.96 + 0.14 * clamped
        voice.player.volume = 0.28 + 0.6 * clamped
        voice.player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !voice.player.isPlaying {
            voice.player.play()
        }
    }

    func playPreview() {
        playTick(intensity: 0.7)
    }
}
