import Foundation
import AVFoundation

/// Synthesizes a soft "tri-tone" ascending chime (F4 → A4 → C5) entirely in code —
/// low volume, per-note release, and a whole-chime fade-in to avoid a startle.
/// No audio files are bundled, keeping the app small.
final class ChimePlayer {
    static let shared = ChimePlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private var started = false
    private var fadeTimer: Timer?

    private init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode,
                       format: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1))
    }

    /// F4, A4, C5.
    private let frequencies: [Double] = [349.23, 440.0, 523.25]

    /// Play the chime, repeating gently until `stop()` is called (e.g. the student
    /// acknowledges). Each loop re-runs the soft fade-in, so it reads as a calm
    /// recurring swell rather than a jarring alarm.
    func play() {
        guard let buffer = makeBuffer() else { return }
        do {
            if !started {
                try engine.start()
                started = true
            }
            fadeTimer?.invalidate()
            fadeTimer = nil
            player.stop()
            player.volume = 1
            player.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
            player.play()
        } catch {
            // Audio is a nicety; never let it crash the app.
            NSLog("ZenTime chime error: \(error.localizedDescription)")
        }
    }

    /// Gently fade the looping chime out (over ~0.6s) rather than cutting it dead,
    /// so acknowledging mid-swell feels calm instead of abrupt.
    func stop() {
        fadeTimer?.invalidate()

        let fadeDuration = 0.6
        let step = 0.02
        let decrement = Float(step / fadeDuration)

        let timer = Timer(timeInterval: step, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            let next = self.player.volume - decrement
            if next <= 0 {
                self.player.volume = 0
                self.player.stop()
                self.player.volume = 1   // reset for the next play()
                t.invalidate()
                self.fadeTimer = nil
            } else {
                self.player.volume = next
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        fadeTimer = timer
    }

    private func makeBuffer() -> AVAudioPCMBuffer? {
        let noteDuration = 0.66         // seconds each note sounds
        let noteStride = 0.30           // start-to-start spacing (notes overlap and cross-fade)
        let fadeIn = 0.7                // whole-chime fade-in
        let amplitude: Float = 0.22     // gentle

        let totalDuration = noteStride * Double(frequencies.count - 1) + noteDuration + 0.2
        let frameCount = AVAudioFrameCount(totalDuration * sampleRate)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else {
            return nil
        }
        buffer.frameLength = frameCount

        // Clear.
        for i in 0..<Int(frameCount) { channel[i] = 0 }

        // Sum the three notes with individual attack/release envelopes.
        for (n, freq) in frequencies.enumerated() {
            let startSample = Int(Double(n) * noteStride * sampleRate)
            let noteSamples = Int(noteDuration * sampleRate)
            let attack = Int(0.10 * sampleRate)   // gentle raised-cosine swell in
            let release = Int(0.42 * sampleRate)  // long raised-cosine tail for cross-fade

            for s in 0..<noteSamples {
                let idx = startSample + s
                guard idx < Int(frameCount) else { break }

                // Per-note envelope: raised-cosine attack + release so notes melt
                // into one another instead of stepping. (equal-power-ish blend)
                var env: Float = 1
                if s < attack {
                    let x = Float(s) / Float(attack)
                    env = 0.5 - 0.5 * cos(Float.pi * x)              // 0→1 smooth
                } else if s > noteSamples - release {
                    let x = Float(noteSamples - s) / Float(release)
                    env = 0.5 - 0.5 * cos(Float.pi * max(0, x))     // 1→0 smooth
                }
                env = max(0, env)

                let theta = 2.0 * Double.pi * freq * Double(s) / sampleRate
                channel[idx] += Float(sin(theta)) * env * amplitude
            }
        }

        // Whole-chime fade-in so the very start never startles.
        let fadeSamples = Int(fadeIn * sampleRate)
        for i in 0..<min(fadeSamples, Int(frameCount)) {
            channel[i] *= Float(i) / Float(fadeSamples)
        }

        return buffer
    }
}
