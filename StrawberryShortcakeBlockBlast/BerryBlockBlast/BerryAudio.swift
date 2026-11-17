import SwiftUI
import AVFoundation
import UIKit

/// One native audio coordinator for the entire application.
/// Music is decoded directly from the bundled original AAC-LC/M4A files.
/// All music and game effects are the actual supplied, byte-verified recordings.
@MainActor
final class BerryAudio: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = BerryAudio()

    enum Cue: String {
        case menuSelect = "menu_select", menuBack = "menu_back", gameStart = "game_start"
        case pickup = "block_pickup", place = "block_place", invalid = "invalid_placement"
        case clear = "row_clear", combo = "berry_combo", highScore = "new_high_score"
        case victory = "victory", gameOver = "no_more_moves", reward = "reward_unlocked"
        case blitzStart = "blitz_start", tenSeconds = "ten_seconds_left"
        case countdown = "final_countdown_tick", timeUp = "time_up"
    }
    enum Screen { case menu, gameplay, blitz, results }

    static let tracks: [BerrySoundtrackTrack] = {
        guard let url = Bundle.main.url(forResource: "Catalog", withExtension: "json", subdirectory: "Music"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(BerrySoundtrackCatalog.self, from: data),
              catalog.tracks.count == 51 else { return [] }
        return catalog.tracks.sorted { $0.id < $1.id }
    }()
    static var trackNames: [String] { tracks.map(\.title) }
    static let effects: [BerryEffectTrack] = {
        guard let url = Bundle.main.url(forResource: "Catalog", withExtension: "json", subdirectory: "Effects"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(BerryEffectsCatalog.self, from: data),
              catalog.effects.count == 16 else { return [] }
        return catalog.effects.sorted { $0.id < $1.id }
    }()

    @Published private(set) var currentTrackName = "Strawberry Soundtrack"
    @Published private(set) var currentTrackNumber = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var playbackError: String?
    @Published private(set) var isShuffling = true
    @Published private(set) var musicMode: BerryMusicMode = .balanced

    private var musicPlayer: AVAudioPlayer?
    private var effectPlayers: [AVAudioPlayer] = []
    private var lastEffectTime: [String: TimeInterval] = [:]
    private var currentIndex: Int?
    private var pendingTrackIndex: Int?
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
        // A screenshot can temporarily make an app inactive. Only actual
        // backgrounding should suspend the soundtrack.
        // iOS sends willResignActive BEFORE didEnterBackground, including
        // on lock/low-power transitions. Stop audio immediately, not seconds later.
        observers.append(center.addObserver(forName: UIApplication.willResignActiveNotification,
                                            object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.setInactive(true) }
        })
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification,
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
            pendingTrackIndex = nil
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

    private func playlistForScreen() -> BerryPlaylistKind {
        switch screen {
        case .menu: return .menu
        case .gameplay: return .gameplay
        case .blitz: return .blitz
        case .results: return .results
        }
    }

    private func nextPlaylistIndex() -> Int? {
        let kind = playlistForScreen()
        let allowed = BerryPlaylistPicker.indices(Self.tracks, for: kind)
            .filter { !failedIndices.contains($0) }
        guard !allowed.isEmpty else { return nil }
        let chosen = BerryPlaylistPicker.choose(
            tracks: Self.tracks, lastIndex: currentIndex, history: history,
            mode: musicMode, shuffle: isShuffling, playlist: kind
        )
        return chosen.flatMap { allowed.contains($0) ? $0 : allowed.first }
    }

    func setScreen(_ target: Screen) {
        guard screen != target else { ensurePlaying(); return }
        screen = target
        guard musicEnabled else { return }
        // Keep the current track when it belongs to the new screen's playlist.
        // Otherwise fade to the relevant menu, gameplay, victory or Blitz mix.
        if let index = currentIndex,
           Self.tracks.indices.contains(index),
           BerryPlaylistPicker.indices(Self.tracks, for: playlistForScreen()).contains(index),
           pendingTrackIndex == nil {
            ensurePlaying()
        } else if let chosen = nextPlaylistIndex() {
            switchTrack(to: chosen)
        } else {
            ensurePlaying()
        }
    }

    func nextTrack() {
        guard !Self.tracks.isEmpty else { return }
        if let next = nextPlaylistIndex() { switchTrack(to: next) }
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

    private func ensurePlaying() {
        guard canPlayMusic && UIApplication.shared.applicationState == .active else { return }
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
        let startIndex = (currentIndex == nil && screen == .menu) ? 
            BerryPlaylistPicker.indices(Self.tracks, for: .menu).first : nextPlaylistIndex()
        if let startIndex { startTrack(startIndex) }
        else { playbackError = "The original soundtrack is missing from the app bundle." }
    }

    private func switchTrack(to index: Int) {
        guard Self.tracks.indices.contains(index) else { return }
        if currentIndex == index && musicPlayer?.isPlaying == true && pendingTrackIndex == nil { return }
        pendingTrackIndex = index
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
        pendingTrackIndex = nil
        guard activateSession() else { return }
        let track = Self.tracks[index]
        let filename = URL(fileURLWithPath: track.file).deletingPathExtension().lastPathComponent
        guard let url = Bundle.main.url(forResource: filename, withExtension: "m4a", subdirectory: "Music")
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
        let alternatives = BerryPlaylistPicker.indices(Self.tracks, for: playlistForScreen())
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
            // An intentional fade already owns the next song. Don't start
            // a competing auto-advance in the final fraction of a second.
            if self.pendingTrackIndex != nil { return }
            if !flag { self.playbackError = "A soundtrack recording stopped unexpectedly." }
            guard self.canPlayMusic else { return }
            if let next = self.nextPlaylistIndex() { self.startTrack(next) }
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
            changeGeneration += 1
            duckGeneration += 1
            duckFactor = 1
            pendingTrackIndex = nil
            endFadeTimer?.invalidate()
            musicPlayer?.pause()
            // SFX must not continue playing under the lock screen or in background.
            effectPlayers.forEach { $0.stop() }
            effectPlayers.removeAll()
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

    /// Real 48-kHz PCM WAV effects from the uploaded, source-verified 16-file pack.
    /// Slight per-event cooldown prevents a finger and a gesture from double-firing.
    func play(_ cue: Cue) {
        guard !inactive && UIApplication.shared.applicationState == .active else { return }
        guard UserDefaults.standard.object(forKey: "berryblockblast.sound") == nil ||
              UserDefaults.standard.bool(forKey: "berryblockblast.sound") else { return }
        guard effectVolume > 0 else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let minimumGap: TimeInterval = cue == .place ? 0.055 : 0.12
        if now - (lastEffectTime[cue.rawValue] ?? -100) < minimumGap { return }
        lastEffectTime[cue.rawValue] = now
        if [.clear, .combo, .highScore, .victory, .timeUp].contains(cue) {
            duckForCelebration(duration: cue == .victory ? 2 : 1.0)
        }
        guard let effect = Self.effects.first(where: { $0.eventKey == cue.rawValue }),
              let url = Bundle.main.url(forResource: URL(fileURLWithPath: effect.file)
                    .deletingPathExtension().lastPathComponent,
                    withExtension: "wav", subdirectory: "Effects"),
              activateSession() else { return }
        // Each effect is allowed one instance; limit global overlap as well.
        effectPlayers.removeAll { !$0.isPlaying }
        if effectPlayers.count >= 4 { effectPlayers[0].stop(); effectPlayers.removeFirst() }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = min(1, effectVolume * 0.76)
            player.prepareToPlay()
            if player.play() { effectPlayers.append(player) }
        } catch {
            playbackError = "Audio effect \(effect.title) could not play: \(error.localizedDescription)"
        }
    }
}
