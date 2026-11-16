import Foundation
import AVFoundation

/// Original synthesized berry sound effects and music-box melody.
@MainActor
final class BerryAudio {
    static let shared = BerryAudio()
    enum Cue { case place, clear, invalid }
    private var effectPlayer: AVAudioPlayer?
    private var musicPlayer: AVAudioPlayer?
    private var musicEnabled = false
    private init() {}

    private func wav(_ notes: [(Double, Double)], volume: Double) -> Data {
        let rate = 22050
        let frames = notes.reduce(0) { $0 + Int($1.1 * Double(rate)) }
        var bytes = Data()
        func write32(_ n: UInt32) {
            var value = n.littleEndian
            withUnsafeBytes(of: &value) { bytes.append(contentsOf: $0) }
        }
        func write16(_ n: UInt16) {
            var value = n.littleEndian
            withUnsafeBytes(of: &value) { bytes.append(contentsOf: $0) }
        }
        bytes.append(contentsOf: Array("RIFF".utf8)); write32(UInt32(36 + frames * 2))
        bytes.append(contentsOf: Array("WAVEfmt ".utf8)); write32(16)
        write16(1); write16(1); write32(UInt32(rate)); write32(UInt32(rate * 2))
        write16(2); write16(16)
        bytes.append(contentsOf: Array("data".utf8)); write32(UInt32(frames * 2))
        for (pitch, duration) in notes {
            let count = Int(duration * Double(rate))
            for index in 0..<count {
                let t = Double(index) / Double(rate)
                let envelope = pow(max(0, 1 - Double(index) / Double(max(1, count))), 1.4)
                let tone = sin(2 * Double.pi * pitch * t) + 0.18 * sin(4 * Double.pi * pitch * t)
                let sample = Int16(max(-32767, min(32767, tone * envelope * volume * 23000)))
                write16(UInt16(bitPattern: sample))
            }
        }
        return bytes
    }

    func play(_ cue: Cue) {
        let notes: [(Double, Double)]
        switch cue {
        case .place: notes = [(523.25, 0.075), (783.99, 0.11)]
        case .clear: notes = [(523.25, 0.10), (659.25, 0.10), (783.99, 0.12), (1046.50, 0.18)]
        case .invalid: notes = [(246.94, 0.12), (196.0, 0.15)]
        }
        do {
            effectPlayer = try AVAudioPlayer(data: wav(notes, volume: 0.23))
            effectPlayer?.prepareToPlay()
            effectPlayer?.play()
        } catch { }
    }

    func setMusic(_ enabled: Bool) {
        guard enabled != musicEnabled else { return }
        musicEnabled = enabled
        if !enabled { musicPlayer?.stop(); musicPlayer = nil; return }
        let melody: [(Double, Double)] = [
            (523.25, 0.22), (659.25, 0.22), (783.99, 0.22), (659.25, 0.22),
            (587.33, 0.22), (698.46, 0.22), (880.0, 0.22), (698.46, 0.22),
            (659.25, 0.22), (783.99, 0.22), (1046.5, 0.28), (783.99, 0.16),
            (698.46, 0.22), (659.25, 0.22), (587.33, 0.22), (523.25, 0.34)
        ]
        do {
            musicPlayer = try AVAudioPlayer(data: wav(melody, volume: 0.09))
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
        } catch { }
    }
}
