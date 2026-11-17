import SwiftUI
import AVFoundation
import UIKit

/// One native audio coordinator for the entire application.
/// Music is decoded directly from the bundled original AAC-LC/M4A files.
/// Short synthesized cues are retained for responsive puzzle sound effects.
@MainActor
final class BerryAudio: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = BerryAudio()

    enum Cue { case place, clear, invalid }
    enum Screen { case menu, gameplay, results }

    static let tracks: [BerrySoundtrackTrack] = {
        guard let url = Bundle.main.url(forResource: "Catalog", withExtension: "json", subdirectory: "Soundtrack"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(BerrySoundtrackCatalog.self, from: data),
              catalog.tracks.count == 15 else { return [] }
        return catalog.tracks.sorted { $0.id < $1.id }
    }()
    static var trackNames: [String] { tracks.map(\.title) }

    @Published private(set) var currentTrackName = "Strawberry Soundtrack"
    @Published private(set) var currentTrackNumber = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var playbackError: String?
    @Published private(set) var isShuffling = true
    @Published private(set) var musicMode: BerryMusicMode = .balanced

    private var musicPlayer: AVAudioPlayer?
    private var effectPlayers: [AVAudioPlayer] = []
    private var currentIndex: Int?
    private var history: [Int] = []
    private var failedIndices = Set<Int>()
    private var screen: Screen = .menu
    private var musicEnabled = false
    private var inactive = false
    private var interrupted = false
    private var pausedForRoute = false
    private var sessionActive = false
    private var musicVolume: Float = 0.22
    private var effectVolume: Float = 0.65
    private var duckFactor: Float = 1
    private var changeGeneration = 0
    private var duckGeneration = 0
    private var endFadeTimer: Timer?
    private var observers: [NSObjectProtocol] = []

    var isMusicEnabled: Bool { musicEnabled }

    private override init() {
        super.init()
        let prefs = UserDefaults.standard
        musicVolume = prefs.object(forKey: "berryblockblast.musicVolume") == nil
            ? 0.22 : Float(prefs.double(forKey: "berryblockblast.musicVolume"))
        effectVolume = prefs.object(forKey: "berryblockblast.effectVolume") == nil
            ? 0.65 : Float(prefs.double(forKey: "berryblockblast.effectVolume"))
        isShuffling = prefs.object(forKey: "berryblockblast.shuffleEnabled.v056") == nil
            ? true : prefs.bool(forKey: "berryblockblast.shuffleEnabled.v056")
        musicMode = BerryMusicMode(rawValue: prefs.string(forKey: "berryblockblast.musicMode.v056") ?? "")
            ?? .balanced
        observeAudioEvents()
    }

    private func observeAudioEvents() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification,
                                            object: AVAudioSession.sharedInstance(), queue: .main) { [weak self] note in
            Task { @MainActor in self?.handleInterruption(note) }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification,
                                            object: AVAudioSession.sharedInstance(), queue: .main) { [weak self] note in
            Task { @MainActor in self?.handleRouteChange(note) }
        })
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification,
                                            object: AVAudioSession.sharedInstance(), queue: .main) { [weak self] _ in
            Task { @MainActor in self?.restoreAfterMediaReset() }
        })
        observers.append(center.addObserver(forName: UIApplication.willResignActiveNotification,
                                            object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.setInactive(true) }
        })
        observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                            object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.setInactive(false) }
        })
    }

    private var canPlayMusic: Bool {
        musicEnabled && !inactive && !interrupted && !pausedForRoute
    }

    private func activateSession() -> Bool {
        do {
            // Ambient honours the Silent switch and mixes with other audio.
            // Music pauses when the app is inactive; no background audio entitlement.
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
            sessionActive = true
            return true
        } catch {
            playbackError = "iPhone audio session unavailable: \(error.localizedDescription)"
            sessionActive = false
            return false
        }
    }

    private func deactivateSession() {
        if sessionActive {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        sessionActive = false
    }

    private func targetVolume() -> Float { min(1, max(0, musicVolume)) * duckFactor }

    func setMusic(_ enabled: Bool) {
        musicEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "berryblockblast.music")
        if !enabled {
            changeGeneration += 1
            endFadeTimer?.invalidate()
            musicPlayer?.pause()
            isPlaying = false
            deactivateSession()
        } else {
            pausedForRoute = false
            ensurePlaying()
        }
    }

    func setMusicVolume(_ value: Float) {
        musicVolume = min(1, max(0, value))
        UserDefaults.standard.set(Double(musicVolume), forKey: "berryblockblast.musicVolume")
        musicPlayer?.setVolume(targetVolume(), fadeDuration: 0.15)
    }

    func setEffectVolume(_ value: Float) {
        effectVolume = min(1, max(0, value))
        UserDefaults.standard.set(Double(effectVolume), forKey: "berryblockblast.effectVolume")
    }

    func setMusicMode(_ mode: BerryMusicMode) {
        musicMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "berryblockblast.musicMode.v056")
        // Do not interrupt the playing song to apply a new playlist preference.
    }

    func setShuffle(_ enabled: Bool) {
        isShuffling = enabled
        UserDefaults.standard.set(enabled, forKey: "berryblockblast.shuffleEnabled.v056")
    }
    func toggleShuffle() { setShuffle(!isShuffling) }

    func setScreen(_ target: Screen) {
        guard screen != target else { ensurePlaying(); return }
        let prior = screen
        screen = target
        if target == .results {
            // Victory is a deliberate transition from active play, not a
            // random gameplay shuffle. The supplied track #05 is full length.
            if currentIndex != 4 && musicEnabled { switchTrack(to: 4) }
        } else if prior == .results && currentIndex == 4 {
            // Returning to play/menu gently exits the results theme.
            if let next = nextGameplayIndex() { switchTrack(to: next) }
        } else {
            // Menu/gameplay transitions do NOT restart the current music.
            ensurePlaying()
        }
    }

    func nextTrack() {
        guard !Self.tracks.isEmpty else { return }
        if let next = nextGameplayIndex() { switchTrack(to: next) }
    }

    func previousTrack() {
        guard history.count >= 2 else { return }
        let previous = history[history.count - 2]
        if Self.tracks.indices.contains(previous) { switchTrack(to: previous) }
    }

    func selectTrack(_ index: Int) {
        guard Self.tracks.indices.contains(index) else { return }
        if !musicEnabled { setMusic(true) }
        switchTrack(to: index)
    }

    private func nextGameplayIndex() -> Int? {
        let catalog = Self.tracks
        let allowed = BerryPlaylistPicker.gameplayIndices(catalog).filter { !failedIndices.contains($0) }
        guard !allowed.isEmpty else { return nil }
        return BerryPlaylistPicker.choose(
            tracks: catalog, lastIndex: currentIndex, history: history,
            mode: musicMode, shuffle: isShuffling
        ).flatMap { !failedIndices.contains($0) ? $0 : allowed.randomElement() }
    }

    private func ensurePlaying() {
        guard canPlayMusic else { return }
        if let p = musicPlayer {
            if p.isPlaying { isPlaying = true; return }
            guard activateSession() else { return }
            p.volume = targetVolume()
            if p.play() {
                isPlaying = true
                scheduleEndFade(for: p)
                return
            }
        }
        let startIndex: Int?
        if screen == .results { startIndex = Self.tracks.indices.contains(4) ? 4 : nil }
        else if screen == .menu && currentIndex == nil { startIndex = Self.tracks.indices.contains(0) ? 0 : nil }
        else { startIndex = nextGameplayIndex() }
        if let startIndex { startTrack(startIndex) }
        else { playbackError = "The original soundtrack is missing from the app bundle." }
    }

    private func switchTrack(to index: Int) {
        guard Self.tracks.indices.contains(index) else { return }
        changeGeneration += 1
        let generation = changeGeneration
        endFadeTimer?.invalidate()
        if !canPlayMusic {
            currentIndex = index
            musicPlayer?.stop()
            musicPlayer = nil
            isPlaying = false
            return
        }
        guard let old = musicPlayer, old.isPlaying else {
            startTrack(index)
            return
        }
        old.setVolume(0, fadeDuration: 0.65)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) { [weak self] in
            Task { @MainActor in
                guard let self, generation == self.changeGeneration else { return }
                old.stop() // One music player at a time: NO overlapping tracks.
                self.startTrack(index)
            }
        }
    }

    private func startTrack(_ index: Int, attempt: Int = 0) {
        guard canPlayMusic, Self.tracks.indices.contains(index) else { return }
        changeGeneration += 1
        endFadeTimer?.invalidate()
        musicPlayer?.stop()
        musicPlayer = nil
        guard activateSession() else { return }
        let track = Self.tracks[index]
        guard let filename = URL(fileURLWithPath: track.file).deletingPathExtension().lastPathComponent as String?,
              let url = Bundle.main.url(forResource: filename, withExtension: "m4a", subdirectory: "Soundtrack")
        else {
            recoverFromTrackError(index, message: "Missing bundle audio: \(track.file)", attempt: attempt)
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.numberOfLoops = 0
            p.volume = 0
            p.prepareToPlay()
            guard p.play() else {
                recoverFromTrackError(index, message: "Cannot start \(track.title)", attempt: attempt)
                return
            }
            musicPlayer = p
            currentIndex = index
            currentTrackName = track.title
            currentTrackNumber = track.id
            playbackError = nil
            isPlaying = true
            failedIndices.remove(index)
            history.append(index)
            if history.count > 40 { history.removeFirst(history.count - 40) }
            p.setVolume(targetVolume(), fadeDuration: 1.05)
            scheduleEndFade(for: p)
        } catch {
            recoverFromTrackError(index, message: "Cannot decode \(track.title): \(error.localizedDescription)", attempt: attempt)
        }
    }

    private func recoverFromTrackError(_ index: Int, message: String, attempt: Int) {
        playbackError = message
        isPlaying = false
        failedIndices.insert(index)
        guard attempt < Self.tracks.count - 1 else { return }
        let alternatives = BerryPlaylistPicker.gameplayIndices(Self.tracks)
            .filter { !failedIndices.contains($0) }
        if let index = alternatives.first { startTrack(index, attempt: attempt + 1) }
    }

    private func scheduleEndFade(for p: AVAudioPlayer) {
        endFadeTimer?.invalidate()
        guard p.duration > 1.8 else { return }
        let remaining = p.duration - p.currentTime
        let t = Timer(timeInterval: max(0.1, remaining - 1.1), repeats: false) { [weak self, weak p] _ in
            Task { @MainActor in
                guard let self, let p, self.musicPlayer === p, p.isPlaying else { return }
                p.setVolume(0, fadeDuration: 0.98)
            }
        }
        endFadeTimer = t
        RunLoop.main.add(t, forMode: .common)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard self.musicPlayer === player else { return }
            self.musicPlayer = nil
            self.endFadeTimer?.invalidate()
            self.isPlaying = false
            if !flag { self.playbackError = "A soundtrack recording stopped unexpectedly." }
            guard self.canPlayMusic else { return }
            if self.screen == .results && self.currentIndex == 4 {
                self.startTrack(0) // Complete the full victory theme, then return to menu music.
            } else if let next = self.nextGameplayIndex() {
                self.startTrack(next)
            }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            guard self.musicPlayer === player else { return }
            let badIndex = self.currentIndex ?? -1
            self.musicPlayer = nil
            self.isPlaying = false
            self.recoverFromTrackError(badIndex,
                message: "Soundtrack decode error: \(error?.localizedDescription ?? "Unknown")", attempt: 0)
        }
    }

    private func setInactive(_ value: Bool) {
        guard inactive != value else { return }
        inactive = value
        if value {
            endFadeTimer?.invalidate()
            musicPlayer?.pause()
            isPlaying = false
            deactivateSession()
        } else {
            ensurePlaying()
        }
    }

    private func handleInterruption(_ notice: Notification) {
        guard let typeValue = notice.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            interrupted = true
            endFadeTimer?.invalidate()
            musicPlayer?.pause()
            isPlaying = false
        } else {
            interrupted = false
            sessionActive = false
            if let raw = notice.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: raw).contains(.shouldResume) {
                ensurePlaying()
            }
        }
    }

    private func handleRouteChange(_ notice: Notification) {
        guard let raw = notice.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else { return }
        if reason == .oldDeviceUnavailable {
            pausedForRoute = true
            musicPlayer?.pause()
            isPlaying = false
        }
    }

    private func restoreAfterMediaReset() {
        sessionActive = false
        let restoreIndex = currentIndex
        musicPlayer?.stop()
        musicPlayer = nil
        isPlaying = false
        if canPlayMusic, let restoreIndex { startTrack(restoreIndex) }
    }

    /// A small duck under clear/high-score and victory sound effects.
    func duckForCelebration(duration: TimeInterval = 1.2) {
        duckGeneration += 1
        let currentGeneration = duckGeneration
        duckFactor = 0.46
        musicPlayer?.setVolume(targetVolume(), fadeDuration: 0.18)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            Task { @MainActor in
                guard let self, self.duckGeneration == currentGeneration else { return }
                self.duckFactor = 1
                self.musicPlayer?.setVolume(self.targetVolume(), fadeDuration: 0.55)
            }
        }
    }

    /// Retain responsive little berry chimes, WITHOUT synthesizing replacement songs.
    private func effectWAV(_ notes: [(Double, Double)]) -> Data {
        let sampleRate = 11025
        let frameCount = notes.reduce(0) { $0 + Int($1.1 * Double(sampleRate)) }
        var pcm = [Int16](repeating: 0, count: frameCount)
        var offset = 0
        for (pitch, duration) in notes {
            let frameLength = Int(duration * Double(sampleRate))
            for frame in 0..<frameLength {
                let t = Double(frame) / Double(sampleRate)
                let env = pow(max(0, 1 - Double(frame) / Double(max(1, frameLength))), 1.3)
                let wave = sin(t * pitch * 2 * .pi) + 0.12 * sin(t * pitch * 4 * .pi)
                pcm[offset + frame] = Int16(max(-32767, min(32767, wave * env * 4300)))
            }
            offset += frameLength
        }
        var data = Data()
        func write16(_ n: UInt16) { var x=n.littleEndian; withUnsafeBytes(of:&x){ data.append(contentsOf:$0) } }
        func write32(_ n: UInt32) { var x=n.littleEndian; withUnsafeBytes(of:&x){ data.append(contentsOf:$0) } }
        data.append(contentsOf: "RIFF".utf8); write32(UInt32(36+frameCount*2))
        data.append(contentsOf: "WAVEfmt ".utf8); write32(16)
        write16(1); write16(1); write32(UInt32(sampleRate)); write32(UInt32(sampleRate*2))
        write16(2); write16(16)
        data.append(contentsOf: "data".utf8); write32(UInt32(frameCount*2))
        pcm.withUnsafeBufferPointer { data.append(contentsOf: UnsafeRawBufferPointer($0)) }
        return data
    }

    func play(_ cue: Cue) {
        let notes: [(Double, Double)]
        switch cue {
        case .place: notes = [(523.25,0.075),(783.99,0.11)]
        case .clear: notes = [(523.25,0.10),(659.25,0.10),(783.99,0.12),(1046.5,0.18)]
        case .invalid: notes = [(246.94,0.12),(196,0.15)]
        }
        if cue == .clear { duckForCelebration(duration: 0.85) }
        guard effectVolume > 0, activateSession() else { return }
        effectPlayers.removeAll { !$0.isPlaying }
        do {
            let p = try AVAudioPlayer(data: effectWAV(notes))
            p.volume = effectVolume
            p.prepareToPlay()
            if p.play() { effectPlayers.append(p) }
        } catch {
            playbackError = "Sound effect failed: \(error.localizedDescription)"
        }
    }
}
