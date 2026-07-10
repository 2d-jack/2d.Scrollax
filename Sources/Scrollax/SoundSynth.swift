import AVFoundation

/// Chamberlin-topology state variable filter: cheap, stable, gives low/band/high outputs
/// from a single pass, which is all the DSP we need for percussive click/snap textures.
struct StateVariableFilter {
    var cutoff: Float
    var resonance: Float
    let sampleRate: Float

    private var low: Float = 0
    private var band: Float = 0

    init(cutoff: Float, resonance: Float, sampleRate: Float) {
        self.cutoff = cutoff
        self.resonance = resonance
        self.sampleRate = sampleRate
    }

    mutating func process(_ input: Float) -> (low: Float, band: Float, high: Float) {
        let f = 2 * sin(Float.pi * min(cutoff, sampleRate * 0.49) / sampleRate)
        let q = 1 / max(resonance, 0.5)
        low += f * band
        let high = input - low - q * band
        band += f * high
        return (low, band, high)
    }
}

enum Synth {
    static let sampleRate: Float = 44_100

    static func whiteNoise(_ count: Int, seed: inout UInt64) -> [Float] {
        (0..<count).map { _ in
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let v = Float((seed >> 33) & 0xFFFF_FFFF) / Float(0xFFFF_FFFF)
            return v * 2 - 1
        }
    }

    static func randomFloat(_ range: ClosedRange<Float>, seed: inout UInt64) -> Float {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        let v = Float((seed >> 33) & 0xFFFF_FFFF) / Float(0xFFFF_FFFF)
        return range.lowerBound + v * (range.upperBound - range.lowerBound)
    }

    static func envelope(_ n: Int, attack: Int, decayTau: Float) -> [Float] {
        (0..<n).map { i -> Float in
            if i < attack {
                return Float(i) / Float(max(attack, 1))
            }
            let t = Float(i - attack)
            return exp(-t / decayTau)
        }
    }

    /// Feeds a brief noise burst into a resonant filter and then lets the filter ring
    /// out on silence. This is what gives a *pitched, musical* decay (a twang or squeak)
    /// instead of the "static" quality you get from feeding noise continuously — the
    /// tail is the filter's own resonance, not noise.
    private static func exciteAndRing(
        duration: Float,
        burstDuration: Float,
        cutoffStart: Float,
        cutoffEnd: Float,
        resonance: Float,
        bandMix: Float,
        decayTau: Float,
        seed: inout UInt64
    ) -> [Float] {
        let n = Int(duration * sampleRate)
        let burstN = max(1, Int(burstDuration * sampleRate))
        let noise = whiteNoise(burstN, seed: &seed)
        var svf = StateVariableFilter(cutoff: cutoffStart, resonance: resonance, sampleRate: sampleRate)
        var out = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let input = i < burstN ? noise[i] : 0
            let t = Float(i) / Float(n)
            svf.cutoff = cutoffStart + (cutoffEnd - cutoffStart) * t
            let o = svf.process(input)
            let decay = exp(-Float(i) / decayTau)
            out[i] = (o.band * bandMix + o.low * (1 - bandMix)) * decay
        }
        return out
    }

    /// A longer resonant ring with a descending pitch and a slow wobble — reads as a
    /// rubbery, gluey drag rather than continuous filtered static.
    static func glueyGrip(seed: inout UInt64) -> [Float] {
        let duration: Float = 0.22
        let n = Int(duration * sampleRate)
        let cutoffStart = randomFloat(950...1250, seed: &seed)
        let cutoffEnd = randomFloat(260...380, seed: &seed)
        let wobbleHz = randomFloat(22...32, seed: &seed)
        var raw = exciteAndRing(
            duration: duration,
            burstDuration: 0.014,
            cutoffStart: cutoffStart,
            cutoffEnd: cutoffEnd,
            resonance: 7.5,
            bandMix: 0.6,
            decayTau: duration * sampleRate / 3.2,
            seed: &seed
        )
        for i in 0..<n {
            let wobble = 1.0 - 0.08 * sin(2 * Float.pi * wobbleHz * Float(i) / sampleRate)
            raw[i] *= wobble
        }
        return normalize(onePoleLowpass(raw, cutoff: 1900))
    }

    /// A short, damped, low-passed tap — deliberately non-resonant so it reads as a
    /// muted knock rather than a sharp click.
    static func mechanicalClick(seed: inout UInt64) -> [Float] {
        let duration: Float = 0.04
        let n = Int(duration * sampleRate)
        let burstN = Int(0.01 * sampleRate)
        let noise = whiteNoise(burstN, seed: &seed)
        let cutoff = randomFloat(1100...1700, seed: &seed)
        var svf = StateVariableFilter(cutoff: cutoff, resonance: 1.0, sampleRate: sampleRate)
        let env = envelope(n, attack: 18, decayTau: Float(n) * 0.22)
        var out = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let input = i < burstN ? noise[i] : 0
            out[i] = svf.process(input).low * env[i]
        }
        return normalize(onePoleLowpass(out, cutoff: 2200))
    }

    /// A short sine "thock" with a touch of noise texture — a soft, muted pop.
    static func softPop(seed: inout UInt64) -> [Float] {
        let duration: Float = 0.06
        let n = Int(duration * sampleRate)
        let freq = randomFloat(150...260, seed: &seed)
        let noise = whiteNoise(n, seed: &seed)
        var svf = StateVariableFilter(cutoff: 900, resonance: 1.2, sampleRate: sampleRate)
        let env = envelope(n, attack: 30, decayTau: Float(n) * 0.16)
        var out = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let sine = sin(2 * Float.pi * freq * Float(i) / sampleRate)
            let noiseOut = svf.process(noise[i]).low
            out[i] = (sine * 0.85 + noiseOut * 0.15) * env[i]
        }
        return normalize(out)
    }

    /// A lighter, quicker sibling of softPop — higher pitch with a slight downward
    /// chirp, so it reads as a small airy bubble rather than a thock.
    static func bubblePop(seed: inout UInt64) -> [Float] {
        let duration: Float = 0.045
        let n = Int(duration * sampleRate)
        let freqStart = randomFloat(340...480, seed: &seed)
        let noise = whiteNoise(n, seed: &seed)
        var svf = StateVariableFilter(cutoff: 1400, resonance: 1.1, sampleRate: sampleRate)
        let env = envelope(n, attack: 14, decayTau: Float(n) * 0.14)
        var phase: Float = 0
        var out = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let t = Float(i) / Float(n)
            let freq = freqStart * (1 - 0.35 * t)
            phase += 2 * Float.pi * freq / sampleRate
            let noiseOut = svf.process(noise[i]).low
            out[i] = (sin(phase) * 0.8 + noiseOut * 0.2) * env[i]
        }
        return normalize(out)
    }

    /// A deeper, softer cousin of softPop — lower fundamental, slower attack, and a
    /// heavier lowpass so it feels cushioned, like a fingertip on felt.
    static func velvetTap(seed: inout UInt64) -> [Float] {
        let duration: Float = 0.08
        let n = Int(duration * sampleRate)
        let freq = randomFloat(95...150, seed: &seed)
        let noise = whiteNoise(n, seed: &seed)
        var svf = StateVariableFilter(cutoff: 500, resonance: 1.0, sampleRate: sampleRate)
        let env = envelope(n, attack: 55, decayTau: Float(n) * 0.2)
        var out = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let sine = sin(2 * Float.pi * freq * Float(i) / sampleRate)
            let noiseOut = svf.process(noise[i]).low
            out[i] = (sine * 0.9 + noiseOut * 0.1) * env[i]
        }
        return normalize(onePoleLowpass(out, cutoff: 1200))
    }

    /// A rounded "plip" — a sine that rises in pitch through the tail, which is what
    /// the ear recognizes as a liquid drop. Kept mostly pure tone so it stays soft.
    static func waterDrop(seed: inout UInt64) -> [Float] {
        let duration: Float = 0.07
        let n = Int(duration * sampleRate)
        let freqStart = randomFloat(280...360, seed: &seed)
        let freqEnd = freqStart * randomFloat(1.8...2.3, seed: &seed)
        let noise = whiteNoise(n, seed: &seed)
        var svf = StateVariableFilter(cutoff: 800, resonance: 1.2, sampleRate: sampleRate)
        let env = envelope(n, attack: 25, decayTau: Float(n) * 0.18)
        var phase: Float = 0
        var out = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let t = Float(i) / Float(n)
            let freq = freqStart + (freqEnd - freqStart) * t * t
            phase += 2 * Float.pi * freq / sampleRate
            let noiseOut = svf.process(noise[i]).low
            out[i] = (sin(phase) * 0.92 + noiseOut * 0.08) * env[i]
        }
        return normalize(out)
    }

    private static func onePoleLowpass(_ samples: [Float], cutoff: Float) -> [Float] {
        let a = 1 - exp(-2 * Float.pi * cutoff / sampleRate)
        var y: Float = 0
        return samples.map { x in
            y += a * (x - y)
            return y
        }
    }

    private static func normalize(_ samples: [Float]) -> [Float] {
        let peak = samples.map { abs($0) }.max() ?? 1
        guard peak > 0.0001 else { return samples }
        let scale = 0.85 / peak
        return samples.map { $0 * scale }
    }

    static func makeBuffer(from samples: [Float]) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = buffer.frameCapacity
        let channel = buffer.floatChannelData![0]
        for i in 0..<samples.count { channel[i] = samples[i] }
        return buffer
    }
}
