import Foundation
import AVFoundation
import UIKit

/// Tiny generated ambient soundbed, bundled in code rather than using copyrighted music.
/// Playback is deliberately quiet and respects iPhone's silent mode.
@MainActor final class AudioAtmosphere {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private let buffer: AVAudioPCMBuffer

    init() {
        let frames: AVAudioFrameCount = 44_100 * 4
        let sound = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        sound.frameLength = frames
        let samples = sound.floatChannelData![0]
        var randomSeed: UInt32 = 31_415_927
        for i in 0..<Int(frames) {
            let t = Double(i) / 44_100.0
            let drone = sin(2 * .pi * 73 * t) * 0.17
                      + sin(2 * .pi * 87 * t) * 0.10
                      + sin(2 * .pi * 146 * t) * 0.045
            randomSeed = randomSeed &* 1664525 &+ 1013904223
            let noise = (Double(randomSeed) / Double(UInt32.max) - 0.5) * 0.015
            let envelope = pow(sin(.pi * Double(i) / Double(frames)), 2)
            samples[i] = Float((drone + noise) * (0.65 + 0.35 * envelope))
        }
        buffer = sound
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.volume = 0.24
    }

    func start() {
        guard UIApplication.shared.applicationState == .active else { stop(); return }
        if engine.isRunning && player.isPlaying { return }
        stop()
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            try engine.start()
            player.play()
        } catch {
            stop()
            #if DEBUG
            print("LAST SEEN ambient audio unavailable: \(error)")
            #endif
        }
    }

    func stop() {
        player.stop()
        engine.stop()
    }
}
