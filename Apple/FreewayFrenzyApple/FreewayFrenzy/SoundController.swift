import AVFoundation
import Foundation

private enum VoiceKind {
    case sine, noise, sweep
}

private struct Voice: Sendable {
    var active = false
    var kind: VoiceKind = .sine
    var phase = 0.0
    var frequency = 440.0
    var endFrequency = 440.0
    var level = 0.0
    var duration = 0.0
    var elapsed = 0.0
}

private final class AudioSynthState: @unchecked Sendable {
    var sampleRate = 44_100.0
    var enginePhase = 0.0
    var engineLevel = 0.0
    var targetEngineLevel = 0.0
    var voices: [Voice] = Array(repeating: Voice(), count: 10)
    var noiseSeed: UInt32 = 12_345
}

final class SoundController: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let synth = AudioSynthState()
    private var didConfigureEngine = false
    private var audioUnavailable = false

    init() {}

    func setEngineSpeed(_ speed: CGFloat) {
        guard ensureEngine() else { return }
        let normalized = min(max(Double(speed) / 280.0, 0), 1)
        synth.targetEngineLevel = 0.04 + normalized * 0.09
    }

    func stopEngine() {
        synth.targetEngineLevel = 0
    }

    func playCoin() {
        trigger(kind: .sweep, frequency: 880, endFrequency: 1760, level: 0.22, duration: 0.14)
        trigger(kind: .sine, frequency: 1320, endFrequency: 1320, level: 0.08, duration: 0.09, delay: 0.05)
    }

    func playCrash() {
        // Soft "slime blob plop" — two detuned downward bloops + a round low tail,
        // instead of a harsh noise burst. Gentle on the ears.
        trigger(kind: .sweep, frequency: 340, endFrequency: 78, level: 0.18, duration: 0.20)
        trigger(kind: .sweep, frequency: 250, endFrequency: 66, level: 0.12, duration: 0.26, delay: 0.04)
        trigger(kind: .sine, frequency: 130, endFrequency: 58, level: 0.10, duration: 0.16, delay: 0.07)
    }

    func playLane() {
        trigger(kind: .sweep, frequency: 320, endFrequency: 180, level: 0.07, duration: 0.07)
    }

    func playBoost() {
        trigger(kind: .sweep, frequency: 220, endFrequency: 520, level: 0.1, duration: 0.18)
    }

    func playTap() {
        trigger(kind: .sine, frequency: 620, endFrequency: 620, level: 0.12, duration: 0.05)
    }

    func playStart() {
        trigger(kind: .sweep, frequency: 330, endFrequency: 660, level: 0.14, duration: 0.2)
        trigger(kind: .sine, frequency: 880, endFrequency: 880, level: 0.1, duration: 0.15, delay: 0.08)
    }

    private func trigger(
        kind: VoiceKind,
        frequency: Double,
        endFrequency: Double,
        level: Double,
        duration: Double,
        delay: Double = 0
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            guard ensureEngine() else { return }
            guard let index = synth.voices.firstIndex(where: { !$0.active }) else { return }
            synth.voices[index] = Voice(
                active: true,
                kind: kind,
                frequency: frequency,
                endFrequency: endFrequency,
                level: level,
                duration: duration,
                elapsed: 0
            )
            if !engine.isRunning {
                do {
                    try engine.start()
                } catch {
                    audioUnavailable = true
                    synth.targetEngineLevel = 0
                }
            }
        }
    }

    @discardableResult
    private func ensureEngine() -> Bool {
        if audioUnavailable { return false }
        if didConfigureEngine {
            if !engine.isRunning {
                do {
                    try engine.start()
                } catch {
                    audioUnavailable = true
                    return false
                }
            }
            return true
        }
        didConfigureEngine = true
        return configureEngine()
    }

    @discardableResult
    private func configureEngine() -> Bool {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: synth.sampleRate, channels: 1) else {
            audioUnavailable = true
            return false
        }
        let state = synth
        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let sampleRate = state.sampleRate
            let dt = 1.0 / sampleRate

            state.engineLevel += (state.targetEngineLevel - state.engineLevel) * 0.02

            for frame in 0..<Int(frameCount) {
                var sample = 0.0

                if state.engineLevel > 0.001 {
                    let engineFreq = 52.0 + state.engineLevel * 420.0
                    state.enginePhase += 2.0 * Double.pi * engineFreq / sampleRate
                    if state.enginePhase >= 2.0 * Double.pi { state.enginePhase -= 2.0 * Double.pi }
                    sample += sin(state.enginePhase) * state.engineLevel
                    sample += sin(state.enginePhase * 2.0) * state.engineLevel * 0.25
                }

                for index in state.voices.indices where state.voices[index].active {
                    var voice = state.voices[index]
                    voice.elapsed += dt
                    let t = min(voice.elapsed / voice.duration, 1)
                    let envelope = (1 - t) * (1 - t)

                    let freq = voice.frequency + (voice.endFrequency - voice.frequency) * t
                    voice.phase += 2.0 * Double.pi * freq / sampleRate
                    if voice.phase >= 2.0 * Double.pi { voice.phase -= 2.0 * Double.pi }

                    switch voice.kind {
                    case .sine:
                        sample += sin(voice.phase) * voice.level * envelope
                    case .sweep:
                        sample += sin(voice.phase) * voice.level * envelope
                    case .noise:
                        state.noiseSeed ^= state.noiseSeed << 13
                        state.noiseSeed ^= state.noiseSeed >> 17
                        state.noiseSeed ^= state.noiseSeed << 5
                        let noise = Double(state.noiseSeed % 10_000) / 10_000.0 - 0.5
                        sample += noise * voice.level * envelope * 2.2
                    }

                    if voice.elapsed >= voice.duration {
                        voice.active = false
                    }
                    state.voices[index] = voice
                }

                let clamped = Float(max(-1, min(1, sample)))
                for buffer in ablPointer {
                    guard let mData = buffer.mData else { continue }
                    let data = mData.assumingMemoryBound(to: Float.self)
                    data[frame] = clamped
                }
            }
            return noErr
        }

        if let sourceNode {
            engine.attach(sourceNode)
            engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
            synth.sampleRate = format.sampleRate
            do {
                try engine.start()
            } catch {
                audioUnavailable = true
                synth.targetEngineLevel = 0
                return false
            }
            return true
        }
        audioUnavailable = true
        return false
    }
}
