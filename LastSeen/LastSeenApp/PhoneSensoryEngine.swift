import Foundation
import AVFoundation
import CoreHaptics
import UIKit

/// A small, original sensory palette. Future story events may select suspense or
/// scare explicitly; ordinary messages never randomly use the horror profiles.
enum PhoneCue: String, CaseIterable {
    case message, outgoing, general, call, lock, unlock
    case corrupted, unknownCaller, suspense, scare, phantom
    case authenticationFailed, passcodeKeypress, timerCompleted, dialerKeypress

    var isHorror: Bool {
        switch self {
        case .corrupted, .unknownCaller, .suspense, .scare, .phantom: return true
        default: return false
        }
    }

    var assetName: String {
        switch self {
        case .message: return "PhoneIncomingText"
        case .outgoing: return "PhoneOutgoingText"
        case .general: return "PhoneGeneralNotification"
        case .call: return "PhoneIncomingCall"
        case .lock: return "PhoneLock"
        case .unlock: return "PhoneUnlock"
        case .corrupted: return "PhoneCorruptedNotification"
        case .unknownCaller: return "PhoneUnknownCaller"
        case .suspense: return "PhoneHeartbeat"
        case .scare: return "PhoneAnomaly"
        case .phantom: return "PhonePhantomVibration"
        case .authenticationFailed: return "PhoneAuthenticationFailed"
        case .passcodeKeypress: return "PhonePasscodeKeypress"
        case .timerCompleted: return "PhoneTimerCompleted"
        case .dialerKeypress: return "PhoneDialerKeypress"
        }
    }

    var title: String {
        switch self {
        case .message: return "Incoming text message"
        case .outgoing: return "Outgoing text message"
        case .general: return "General notification"
        case .call: return "Incoming phone call"
        case .lock: return "Phone lock"
        case .unlock: return "Phone unlock"
        case .corrupted: return "Corrupted notification"
        case .unknownCaller: return "Unknown caller"
        case .suspense: return "Electronic heartbeat"
        case .scare: return "Sudden system anomaly"
        case .phantom: return "Phantom vibration"
        case .authenticationFailed: return "Authentication failed"
        case .passcodeKeypress: return "Passcode keypress"
        case .timerCompleted: return "Timer completed"
        case .dialerKeypress: return "Phone dialer keypress"
        }
    }

    func audioURL(in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: assetName, withExtension: "mp3")
    }

    struct Pulse {
        let time: Double
        let frequency: Double
        let duration: Double
        let intensity: Float
        let sharpness: Float
    }

    var pulses: [Pulse] {
        switch self {
        case .message:
            return [Pulse(time: 0, frequency: 880, duration: 0.12, intensity: 0.55, sharpness: 0.65),
                    Pulse(time: 0.16, frequency: 1175, duration: 0.16, intensity: 0.45, sharpness: 0.55)]
        case .outgoing, .lock, .unlock, .passcodeKeypress, .dialerKeypress:
            return [Pulse(time: 0, frequency: 700, duration: 0.08, intensity: 0.23, sharpness: 0.6)]
        case .general, .timerCompleted:
            return [Pulse(time: 0, frequency: 900, duration: 0.14, intensity: 0.5, sharpness: 0.5)]
        case .call, .unknownCaller:
            return [Pulse(time: 0, frequency: 440, duration: 0.26, intensity: 0.62, sharpness: 0.32),
                    Pulse(time: 0.4, frequency: 330, duration: 0.25, intensity: 0.62, sharpness: 0.32)]
        case .corrupted, .phantom, .authenticationFailed:
            return [Pulse(time: 0, frequency: 230, duration: 0.14, intensity: 0.6, sharpness: 0.65),
                    Pulse(time: 0.23, frequency: 150, duration: 0.27, intensity: 0.74, sharpness: 0.32)]
        case .suspense:
            return [Pulse(time: 0, frequency: 170, duration: 0.23, intensity: 0.35, sharpness: 0.2),
                    Pulse(time: 0.32, frequency: 145, duration: 0.26, intensity: 0.5, sharpness: 0.25)]
        case .scare:
            return [Pulse(time: 0, frequency: 230, duration: 0.15, intensity: 0.8, sharpness: 0.85),
                    Pulse(time: 0.18, frequency: 130, duration: 0.32, intensity: 0.65, sharpness: 0.4)]
        }
    }

    var isKeypress: Bool { self == .passcodeKeypress || self == .dialerKeypress }
    var isAuthentication: Bool { self == .unlock || self == .authenticationFailed }
    var duration: Double { (pulses.map { $0.time + $0.duration }.max() ?? 0) + 0.04 }

    /// Generate a bounded, click-free mono PCM WAV; no external resources or
    /// copyrighted system sound samples. Volume is not changed at OS level.
    func waveData() -> Data {
        let rate = 44_100
        let frameCount = Int(ceil(duration * Double(rate)))
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        data.append(contentsOf: "RIFF".utf8)
        append(UInt32(36 + frameCount * 2))
        data.append(contentsOf: "WAVEfmt ".utf8)
        append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
        append(UInt32(rate)); append(UInt32(rate * 2))
        append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: "data".utf8)
        append(UInt32(frameCount * 2))
        for index in 0..<frameCount {
            let t = Double(index) / Double(rate)
            var sample = 0.0
            for p in pulses {
                let local = t - p.time
                guard local >= 0, local < p.duration else { continue }
                let envelope = min(1, local / 0.012) * pow(max(0, 1 - local / p.duration), 1.6)
                let fundamental = sin(2 * Double.pi * p.frequency * local)
                let harmonic = sin(2 * Double.pi * p.frequency * 2 * local) * 0.12
                sample += (fundamental + harmonic) * envelope * 0.28
            }
            append(Int16(max(-1, min(1, sample)) * Double(Int16.max)))
        }
        return data
    }
}

/// Incoming IDs, not unread counts: a read receipt, reopening an app, or an
/// outgoing message cannot retrigger the phone. A burst is one sensory alert.
enum PhoneMessageArrival {
    static func incomingIDs(in world: PhoneWorld) -> Set<String> {
        Set(world.threads.values.flatMap { $0 }.filter { !$0.fromPlayer }.map(\.id))
    }
    static func outgoingIDs(in world: PhoneWorld) -> Set<String> {
        Set(world.threads.values.flatMap { $0 }.filter { $0.fromPlayer }.map(\.id))
    }
    static func newest(in world: PhoneWorld, previous: Set<String>) -> PhoneAlert? {
        let added = incomingIDs(in: world).subtracting(previous)
        return Neighbor.visible(in:world).compactMap { neighbor -> PhoneAlert? in
            let messages = world.threads[neighbor.id] ?? []
            guard let newest = messages.filter({ !$0.fromPlayer && added.contains($0.id) })
                .max(by: { $0.at < $1.at }) else { return nil }
            return PhoneAlert(neighbor: neighbor, message: newest, count: messages.filter { !$0.fromPlayer && !$0.read }.count)
        }.max(by: { $0.message.at < $1.message.at })
    }
}

/// A tactile profile is independent of its audio file. Mail uses the existing
/// general notification recording but has a different physical pulse pattern.
enum PhoneHapticProfile: Equatable {
    case cue(PhoneCue), mail, social, security
    struct Pulse: Equatable {
        let time: Double
        let duration: Double
        let intensity: Float
        let sharpness: Float
    }
    var pulses: [Pulse] {
        switch self {
        case .mail:
            return [.init(time: 0, duration: 0.18, intensity: 0.75, sharpness: 0.40)]
        case .social:
            return [.init(time: 0, duration: 0.09, intensity: 0.54, sharpness: 0.65)]
        case .security:
            return [.init(time: 0, duration: 0.15, intensity: 0.78, sharpness: 0.45),
                    .init(time: 0.25, duration: 0.18, intensity: 0.72, sharpness: 0.40)]
        case .cue(.message):
            return [.init(time: 0, duration: 0.10, intensity: 0.78, sharpness: 0.65),
                    .init(time: 0.17, duration: 0.13, intensity: 0.68, sharpness: 0.55)]
        case .cue(.unlock):
            return [.init(time: 0, duration: 0.09, intensity: 0.55, sharpness: 0.48)]
        case .cue(let cue):
            return cue.pulses.map { .init(time: $0.time, duration: $0.duration, intensity: $0.intensity, sharpness: $0.sharpness) }
        }
    }
    var duration: Double { pulses.map { $0.time + $0.duration }.max() ?? 0 }
    var isInteraction: Bool {
        switch self {
        case .cue(.outgoing), .cue(.passcodeKeypress), .cue(.dialerKeypress), .cue(.lock): return true
        default: return false
        }
    }
    var isHorror: Bool {
        if case .cue(let cue) = self { return cue.isHorror }
        return false
    }
    var name: String {
        switch self {
        case .cue(let cue): return cue.rawValue
        case .mail: return "mail"
        case .social: return "social"
        case .security: return "security"
        }
    }
}

/// Only newly committed local inbox records count; static history, sent mail,
/// drafts, read changes and folder changes do not create arrival feedback.
enum PhoneMailArrival {
    static func inboxIDs(in world: PhoneWorld) -> Set<String> {
        Set((world.connectedWorld?.mail ?? []).filter { $0.kind == "inbox" }.map(\.id))
    }
    static func added(in world: PhoneWorld, previous: Set<String>) -> Set<String> {
        inboxIDs(in: world).subtracting(previous)
    }
}

/// A bounded sound queue. Authentication outcomes take precedence over waiting
/// alerts, but never restart an alert already in progress. Keypad/outgoing
/// sounds are expendable when a real notification needs the player.
enum PhoneAudioPriority {
    enum Decision: Equatable { case start, enqueue, drop }
    static func allowsCue(_ cue: PhoneCue, horrorEnabled: Bool, horrorPreference: Bool) -> Bool {
        !cue.isHorror || (horrorEnabled && horrorPreference)
    }
    static func cancelsForAuthentication(_ cue: PhoneCue?) -> Bool { cue?.isAuthentication == true }
    static func interaction(_ cue: PhoneCue) -> Bool {
        cue.isKeypress || cue == .outgoing
    }
    /// Optional atmosphere is never queued behind meaningful phone feedback.
    static func allowsAtmosphere(playing: Bool, waiting: Bool, mediaReserved: Bool) -> Bool {
        !playing && !waiting && !mediaReserved
    }
    static func decision(for cue: PhoneCue, playing: PhoneCue?, waiting: Bool) -> Decision {
        if interaction(cue) {
            if waiting { return .drop }
            if let playing, !interaction(playing) { return .drop }
            return .start
        }
        if let playing {
            if interaction(playing) && (!waiting || cue.isAuthentication) { return .start }
            if cue.isAuthentication && playing.isAuthentication { return .start }
            return .enqueue
        }
        return waiting && !cue.isAuthentication ? .enqueue : .start
    }
}

struct PhoneAudioQueue {
    struct Entry: Equatable {
        let cue: PhoneCue
        let horrorEnabled: Bool
    }
    private(set) var entries: [Entry] = []
    var isEmpty: Bool { entries.isEmpty }
    mutating func append(_ entry: Entry) {
        if entry.cue.isAuthentication {
            cancelAuthentication()
            if entries.count >= 12 { entries.removeLast() }
            entries.insert(entry, at: 0)
        } else if entries.count < 12 {
            entries.append(entry)
        }
    }
    mutating func next() -> Entry? {
        entries.isEmpty ? nil : entries.removeFirst()
    }
    mutating func cancelAuthentication() { entries.removeAll { $0.cue.isAuthentication } }
    mutating func cancelHorror() { entries.removeAll { $0.cue.isHorror } }
    mutating func removeAll() { entries.removeAll() }
}

/// A tokenized reservation for audible foreground media. A stale view may
/// release its own token without accidentally unmuting a newer recording.
struct PhoneMediaAudioReservations {
    private(set) var owners: Set<UUID> = []
    var isReserved: Bool { !owners.isEmpty }
    mutating func begin(_ owner: UUID) { owners.insert(owner) }
    mutating func end(_ owner: UUID) { owners.remove(owner) }
}

/// Single-owner lease for disposable playback, independent of normal alerts.
struct PhoneAudioLease {
    private(set) var owner: UUID?
    mutating func begin(_ token: UUID) { owner = token }
    @discardableResult mutating func end(_ token: UUID? = nil) -> Bool {
        guard let owner, token == nil || token == owner else { return false }
        self.owner = nil
        return true
    }
}

@MainActor
enum PhoneSensoryEngine {
    private static var audio: AVAudioPlayer?
    private static var engine: CHHapticEngine?
    private static var hapticPlayer: CHHapticPatternPlayer?
    private static var currentCue: PhoneCue?
    private static var optionalAtmosphereLease = PhoneAudioLease()
    private static var deferredAuthentication: Task<Void, Never>?
    private static var queued = PhoneAudioQueue()
    private static var drainTask: Task<Void, Never>?
    private static var hapticQueue: [PhoneHapticProfile] = []
    private static var hapticDrain: Task<Void, Never>?
    private static var hapticUntil: TimeInterval = 0
    private static var currentHapticProfile: PhoneHapticProfile?
    private static var mediaReservations = PhoneMediaAudioReservations()
    private static var previewLease = PhoneAudioLease()
    private static var previewAudio: AVAudioPlayer?
    private static var previewHapticUntil: TimeInterval = 0
    private static var previewOwnsHaptic = false
    private static var previewHorror = false

    /// Play the exact original recording, or its optional tactile profile.
    /// Previews are admitted only when their selected channels are idle.
    /// They never enqueue, synthesize substitute audio, or reserve media.
    static func preview(owner: UUID, url: URL?, profile: PhoneHapticProfile?,
                        sound: Bool, haptics: Bool, horror: Bool) -> Bool {
        guard UIApplication.shared.applicationState == .active,
              !horror || preference("lastseen.lab.horrorEffects") else { return false }
        stopPreview()
        let tactile = haptics && preference("lastseen.lab.messageHaptics") ? profile : nil
        guard sound || tactile != nil else { return false }
        if sound {
            guard PhoneAudioPriority.allowsAtmosphere(playing: audio?.isPlaying == true,
                waiting: !queued.isEmpty, mediaReserved: mediaReservations.isReserved),
                let url else { return false }
        }
        if tactile != nil {
            guard ProcessInfo.processInfo.systemUptime >= hapticUntil, hapticQueue.isEmpty else { return false }
        }
        if sound, let url {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.ambient, mode: .default)
                try session.setActive(true)
                let candidate = try AVAudioPlayer(contentsOf: url)
                candidate.numberOfLoops = 0
                candidate.prepareToPlay()
                guard candidate.play() else { return false }
                previewAudio = candidate
            } catch { return false }
        }
        previewLease.begin(owner)
        previewHorror = horror
        if let tactile {
            playHaptics(tactile)
            previewOwnsHaptic = true
            previewHapticUntil = hapticUntil
        }
        return true
    }

    static func previewIsActive(_ owner: UUID) -> Bool {
        guard previewLease.owner == owner else { return false }
        if previewAudio?.isPlaying == true ||
            (previewOwnsHaptic && ProcessInfo.processInfo.systemUptime < previewHapticUntil) { return true }
        stopPreview(owner: owner)
        return false
    }

    static func stopPreview(owner: UUID? = nil) {
        guard previewLease.end(owner) else { return }
        previewAudio?.stop(); previewAudio = nil
        if previewOwnsHaptic {
            try? hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
            hapticPlayer = nil
            currentHapticProfile = nil
            hapticUntil = 0
        }
        previewOwnsHaptic = false
        previewHapticUntil = 0
        previewHorror = false
    }

    static func beginMediaAudio(_ owner: UUID) {
        mediaReservations.begin(owner)
        stopSound()
    }
    static func endMediaAudio(_ owner: UUID) {
        mediaReservations.end(owner)
    }

    private static func preference(_ key: String) -> Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil || defaults.bool(forKey: key)
    }

    // Face ID may return while UIKit is inactive. Retain a single explicit outcome
    // until foreground activation, never replay after background or a new request.
    static func authentication(_ cue: PhoneCue, sound: Bool, haptics: Bool) {
        guard cue.isAuthentication else { return }
        cancelAuthentication()
        deferredAuthentication = Task { @MainActor in
            for _ in 0..<50 {
                guard !Task.isCancelled else { return }
                let state = UIApplication.shared.applicationState
                if state == .background {
                    deferredAuthentication = nil
                    return
                }
                if state == .active {
                    deferredAuthentication = nil
                    let defaults = UserDefaults.standard
                    let soundEnabled = defaults.object(forKey: "lastseen.lab.messageSound") == nil || defaults.bool(forKey: "lastseen.lab.messageSound")
                    let hapticsEnabled = defaults.object(forKey: "lastseen.lab.messageHaptics") == nil || defaults.bool(forKey: "lastseen.lab.messageHaptics")
                    play(cue, sound: sound && soundEnabled, haptics: haptics && hapticsEnabled, horrorEnabled: false)
                    return
                }
                do { try await Task.sleep(nanoseconds: 100_000_000) } catch { return }
            }
            deferredAuthentication = nil
            OpeningQA.record("Authentication audio expired while inactive")
        }
    }
    static func cancelAuthentication() {
        deferredAuthentication?.cancel(); deferredAuthentication = nil
        queued.cancelAuthentication()
        if PhoneAudioPriority.cancelsForAuthentication(currentCue) {
            audio?.stop(); audio = nil; currentCue = nil
            if !queued.isEmpty { scheduleDrain() }
        }
        if case .cue(let cue)? = currentHapticProfile, cue.isAuthentication {
            try? hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
            hapticPlayer = nil; currentHapticProfile = nil; hapticUntil = 0
        }
        hapticQueue.removeAll {
            if case .cue(let cue) = $0 { return cue.isAuthentication }
            return false
        }
    }
    private static func scheduleDrain() {
        guard drainTask == nil else { return }
        drainTask = Task { @MainActor in
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: 50_000_000) } catch { return }
                guard UIApplication.shared.applicationState == .active else { queued.removeAll(); break }
                if audio?.isPlaying == true { continue }
                guard let next = queued.next() else { break }
                guard !mediaReservations.isReserved, preference("lastseen.lab.messageSound"),
                      !next.cue.isHorror || (next.horrorEnabled && preference("lastseen.lab.horrorEffects")) else { continue }
                // Draining bypasses admission; otherwise the first item could
                // be requeued behind its own successors.
                startAudio(next.cue)
            }
            drainTask = nil
        }
    }

    /// A quiet, disposable first-entry effect. Never enqueue it or emit haptics.
    static func playOptionalAtmosphere(_ cue: PhoneCue, owner: UUID, sound: Bool, horrorEnabled: Bool) {
        guard cue == .suspense, UIApplication.shared.applicationState == .active,
              sound, horrorEnabled, preference("lastseen.lab.messageSound"),
              preference("lastseen.lab.horrorEffects"),
              PhoneAudioPriority.allowsAtmosphere(playing: audio?.isPlaying == true,
                  waiting: !queued.isEmpty, mediaReserved: mediaReservations.isReserved) else { return }
        guard previewLease.owner == nil else { return }
        if startAudio(cue, atmosphere: true) > 0 { optionalAtmosphereLease.begin(owner) }
    }

    /// Stop only the disposable cue; never clear a genuine alert or its queue.
    static func stopOptionalAtmosphere(owner: UUID? = nil) {
        guard optionalAtmosphereLease.end(owner) else { return }
        audio?.stop(); audio = nil; currentCue = nil
    }

    @discardableResult
    static func play(_ cue: PhoneCue, sound: Bool, haptics: Bool, horrorEnabled: Bool, hapticProfile: PhoneHapticProfile? = nil) -> Double {
        guard UIApplication.shared.applicationState == .active,
              PhoneAudioPriority.allowsCue(cue, horrorEnabled: horrorEnabled,
                  horrorPreference: preference("lastseen.lab.horrorEffects")) else { return 0 }
        // Dispatch tactile feedback on arrival, not after the audio queue.
        if haptics && preference("lastseen.lab.messageHaptics") {
            requestHaptics(hapticProfile ?? .cue(cue))
        }
        // Media owns the audible channel; arrivals still reach the journal,
        // banner and independent haptic path. Never replay missed sound bursts.
        guard sound && preference("lastseen.lab.messageSound"), !mediaReservations.isReserved else { return 0 }
        stopOptionalAtmosphere()
        let playing = audio?.isPlaying == true ? currentCue : nil
        switch PhoneAudioPriority.decision(for: cue, playing: playing, waiting: !queued.isEmpty) {
        case .drop: return 0
        case .enqueue:
            queued.append(.init(cue: cue, horrorEnabled: horrorEnabled))
            scheduleDrain()
            OpeningQA.record("Phone audio queued: " + cue.rawValue)
            return 0
        case .start:
            let duration = startAudio(cue)
            if !queued.isEmpty { scheduleDrain() }
            return duration
        }
    }

    @discardableResult
    private static func startAudio(_ cue: PhoneCue, atmosphere: Bool = false) -> Double {
        stopPreview()
        optionalAtmosphereLease.end()
        audio?.stop(); audio = nil; currentCue = nil
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
            func start(_ candidate: AVAudioPlayer) -> Double? {
                candidate.numberOfLoops = 0
                candidate.volume = atmosphere ? 0.35 : (cue == .passcodeKeypress || cue == .authenticationFailed || cue == .timerCompleted ? 1.0 : 0.8)
                candidate.prepareToPlay()
                guard candidate.play() else { return nil }
                audio = candidate; currentCue = cue
                return candidate.duration
            }
            if let url = cue.audioURL() {
                if let candidate = try? AVAudioPlayer(contentsOf: url), let duration = start(candidate) {
                    OpeningQA.record("Phone audio started: " + cue.rawValue)
                    return duration
                }
                OpeningQA.record("Bundled phone sound failed to start: " + cue.assetName)
            } else {
                OpeningQA.record("Missing bundled phone sound: " + cue.assetName)
            }
            // Runtime resilience only. Release asset checks still require the original files.
            if let duration = start(try AVAudioPlayer(data: cue.waveData())) {
                OpeningQA.record("Phone fallback audio started: " + cue.rawValue)
                return duration
            }
        } catch {
            OpeningQA.record("Phone audio session or player unavailable: " + cue.rawValue)
        }
        OpeningQA.record("Phone audio start failed: " + cue.rawValue)
        return 0
    }

    private static func requestHaptics(_ profile: PhoneHapticProfile) {
        stopPreview()
        let now = ProcessInfo.processInfo.systemUptime
        if now < hapticUntil || !hapticQueue.isEmpty {
            // Keypresses never interrupt an incoming alert. Alert bursts retain
            // a short FIFO, independent of the length of any sound recording.
            if profile.isInteraction { return }
            if case .cue(let cue) = profile, cue.isAuthentication {
                hapticQueue.removeAll {
                    if case .cue(let pending) = $0 { return pending.isAuthentication }
                    return false
                }
                if hapticQueue.count >= 12 { hapticQueue.removeLast() }
                hapticQueue.insert(profile, at: 0)
            } else if hapticQueue.count < 12 { hapticQueue.append(profile) }
            if hapticDrain == nil {
                hapticDrain = Task { @MainActor in
                    while !Task.isCancelled {
                        do { try await Task.sleep(nanoseconds: 30_000_000) } catch { return }
                        guard UIApplication.shared.applicationState == .active,
                              preference("lastseen.lab.messageHaptics") else { hapticQueue.removeAll(); break }
                        guard ProcessInfo.processInfo.systemUptime >= hapticUntil else { continue }
                        guard !hapticQueue.isEmpty else { break }
                        let next = hapticQueue.removeFirst()
                        if case .cue(let cue) = next, cue.isHorror && !preference("lastseen.lab.horrorEffects") { continue }
                        playHaptics(next)
                    }
                    hapticDrain = nil
                }
            }
            return
        }
        playHaptics(profile)
    }

    private static func playHaptics(_ profile: PhoneHapticProfile) {
        currentHapticProfile = profile
        hapticUntil = ProcessInfo.processInfo.systemUptime + profile.duration + 0.035
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            do {
                if engine == nil {
                    let fresh = try CHHapticEngine()
                    fresh.playsHapticsOnly = true
                    fresh.isAutoShutdownEnabled = true
                    fresh.resetHandler = { [weak fresh] in
                        Task { @MainActor in
                            guard let fresh, engine === fresh else { return }
                            hapticPlayer = nil
                            // A subsequent event recreates the engine after reset.
                            engine = nil
                        }
                    }
                    engine = fresh
                }
                guard let engine else { throw CocoaError(.featureUnsupported) }
                try engine.start()
                try? hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
                let events = profile.pulses.map { pulse in
                    CHHapticEvent(eventType: profile.isInteraction ? .hapticTransient : .hapticContinuous,
                                  parameters: [
                                    CHHapticEventParameter(parameterID: .hapticIntensity, value: pulse.intensity),
                                    CHHapticEventParameter(parameterID: .hapticSharpness, value: pulse.sharpness)
                                  ], relativeTime: pulse.time, duration: profile.isInteraction ? 0 : pulse.duration)
                }
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
                hapticPlayer = player
                OpeningQA.record("Core Haptics requested: " + profile.name)
                return
            } catch {
                try? hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
                hapticPlayer = nil
                engine?.stop(completionHandler: nil); engine = nil
                OpeningQA.record("Core Haptics unavailable; using UIKit fallback")
            }
        }
        if profile.isInteraction {
            let fallback = UIImpactFeedbackGenerator(style: .light)
            fallback.prepare(); fallback.impactOccurred()
        } else {
            let fallback = UINotificationFeedbackGenerator()
            fallback.prepare()
            switch profile {
            case .cue(.authenticationFailed): fallback.notificationOccurred(.error)
            case .security: fallback.notificationOccurred(.warning)
            case .cue(let cue) where cue.isHorror: fallback.notificationOccurred(.warning)
            default: fallback.notificationOccurred(.success)
            }
        }
        OpeningQA.record("UIKit haptic requested: " + profile.name)
    }

    /// Turning off horror is not a global mute or an authentication cancellation.
    static func stopHorrorEffects() {
        if previewHorror { stopPreview() }
        queued.cancelHorror()
        if currentCue?.isHorror == true {
            audio?.stop(); audio = nil; currentCue = nil
            optionalAtmosphereLease.end()
        }
        if !queued.isEmpty { scheduleDrain() }
        hapticQueue.removeAll { $0.isHorror }
        if currentHapticProfile?.isHorror == true {
            try? hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
            hapticPlayer = nil
            currentHapticProfile = nil
            hapticUntil = 0
        }
    }

    static func stopSound() {
        stopPreview()
        optionalAtmosphereLease.end()
        audio?.stop(); audio = nil; currentCue = nil
        drainTask?.cancel(); drainTask = nil; queued.removeAll()
    }
    static func stopHaptics() {
        stopPreview()
        hapticDrain?.cancel(); hapticDrain = nil; hapticQueue.removeAll(); hapticUntil = 0
        currentHapticProfile = nil
        try? hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
        hapticPlayer = nil
        engine?.stop(completionHandler: nil)
        engine = nil
    }
    static func stop() {
        cancelAuthentication(); stopSound(); stopHaptics()
    }
}
