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
    private func activateAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
    }

    private func wav(_ notes: [(Double, Double)], volume: Double, arranged: Bool = false) -> Data {
        let rate = 11025
        let frames = notes.reduce(0) { $0 + Int($1.1 * Double(rate)) }
        // Reserve PCM capacity up front: appending millions of individual Data values
        // made long tracks stall the main thread and caused avoidable reallocations.
        var bytes = Data(capacity: 44 + frames * 2)
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
        var pcm = [Int16](repeating: 0, count: frames)
        var offset = 0
        for (pitch, duration) in notes {
            let count = Int(duration * Double(rate))
            let step = 2 * Double.pi * pitch / Double(rate)
            for index in 0..<count {
                let t = Double(index) / Double(rate)
                let phase = step * Double(index)
                let envelope = pow(max(0, 1 - Double(index) / Double(max(1, count))), 1.4)
                let lead = sin(phase) + 0.18 * sin(2 * phase)
                let bass = sin(0.25 * phase)
                let harmony = sin(1.25 * phase)
                let pluck = sin(2 * phase) * exp(-t * 7)
                let tone = arranged ? lead * 0.6 + bass * 0.2 + harmony * 0.12 + pluck * 0.18 : lead
                pcm[offset + index] = Int16(max(-32767, min(32767, tone * envelope * volume * 23000)))
            }
            offset += count
        }
        pcm.withUnsafeBufferPointer { buffer in
            bytes.append(contentsOf: UnsafeRawBufferPointer(buffer))
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
        activateAudio()
        do {
            effectPlayer = try AVAudioPlayer(data: wav(notes, volume: 0.23 * Double(effectVolume)))
            effectPlayer?.prepareToPlay()
            effectPlayer?.play()
        } catch { }
    }


    private var trackIndex = -1
    private var queue = Array(0..<15).shuffled()
    private var musicVolume: Float = 0.22
    private var effectVolume: Float = 0.65
    private var musicTimer: Timer?
    private var shuffleEnabled = true
    private var history: [Int] = []
    static let trackNames = [
        "Good Morning, Strawberry Village", "A Picnic in the Sunshine", "Berry Blossom Waltz",
        "The Little Pink Bakery", "Blueberry Skies", "Custard's Cozy Afternoon",
        "Strawberry Fields Forevermore", "The Garden Tea Party", "Raspberry Ribbon Dance",
        "Honeycomb Hideaway", "The Sweetest Little Adventure", "Petals in the Breeze",
        "Moonlight Over Berry Lane", "A Basket Full of Wishes", "Goodnight, Strawberry Village"
    ]
    var currentTrackName: String { trackIndex >= 0 ? Self.trackNames[trackIndex] : "Strawberry Jukebox" }
    var currentTrackNumber: Int { max(0, trackIndex) + 1 }
    var isShuffling: Bool { shuffleEnabled }
    func toggleShuffle() { shuffleEnabled.toggle() }
    func previousTrack() {
        guard musicEnabled else { return }
        if history.count >= 2 { history.removeLast(); let previous = history.removeLast(); playTrack(previous) }
        else { playTrack((max(0, trackIndex) + Self.trackNames.count - 1) % Self.trackNames.count) }
    }
    func selectTrack(_ index: Int) {
        guard Self.trackNames.indices.contains(index) else { return }
        playTrack(index)
    }

    func setMusicVolume(_ value: Float) {
        musicVolume = value
        musicPlayer?.volume = value
    }
    func setEffectVolume(_ value: Float) { effectVolume = value }
    func nextTrack() {
        guard musicEnabled else { return }
        if !shuffleEnabled { playTrack((trackIndex + 1) % Self.trackNames.count); return }
        if queue.isEmpty {
            queue = Array(0..<15).filter { $0 != trackIndex }.shuffled()
        }
        let next = queue.removeFirst()
        playTrack(next)
    }
    private func playTrack(_ index: Int) {
        trackIndex = index
        history.append(index)
        if history.count > 30 { history.removeFirst() }
        let scales: [[Double]] = [
            [261.63,293.66,329.63,392,440,523.25,587.33,659.25],
            [293.66,329.63,369.99,440,493.88,587.33,659.25,739.99],
            [246.94,277.18,329.63,369.99,440,493.88,554.37,659.25],
            [261.63,311.13,349.23,392,466.16,523.25,622.25,698.46],
            [220,246.94,277.18,329.63,369.99,440,493.88,554.37]
        ]
        let scale = scales[index % scales.count]
        let motifs: [[Int]] = [
            [0,2,4,5,4,2,1,0], [0,3,4,6,5,3,2,1], [2,4,5,7,6,4,3,1],
            [0,1,3,4,6,5,3,2], [4,3,1,2,5,7,6,4]
        ]
        let motif = motifs[(index / 3) % motifs.count]
        let tempo = 0.23 + Double(index % 4) * 0.035
        var notes: [(Double, Double)] = []
        // Distinct phrases, changing register, rests and cadences over roughly a minute.
        for phrase in 0..<48 {
            for step in 0..<8 {
                let rotation = (phrase / 3 + index) % 8
                let degree = motif[(step + rotation) % 8]
                let pitch = scale[(degree + phrase % 3) % scale.count]
                let octave = (phrase % 6 == 5 && step % 2 == 0) ? 0.5 : 1.0
                notes.append((pitch * octave, tempo * (step == 7 ? 1.7 : 1)))
            }
        }
        musicPlayer?.stop()
        musicTimer?.invalidate()
        do {
            musicPlayer = try AVAudioPlayer(data: wav(notes, volume: 0.12, arranged: true))
            musicPlayer?.volume = musicVolume
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
            musicTimer?.invalidate()
            musicTimer = Timer.scheduledTimer(withTimeInterval: musicPlayer?.duration ?? 60, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.nextTrack() }
            }
        } catch { }
    }
    func setMusic(_ enabled: Bool) {
        guard enabled != musicEnabled else { return }
        musicEnabled = enabled
        if !enabled {
            musicTimer?.invalidate()
            musicTimer = nil
            musicPlayer?.stop()
            musicPlayer = nil
            return
        }
        activateAudio()
        nextTrack()
    }
}
