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
        return Neighbor.allCases.compactMap { neighbor -> PhoneAlert? in
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

@MainActor
enum PhoneSensoryEngine {
    private static var audio: AVAudioPlayer?
    private static var engine: CHHapticEngine?
    private static var hapticPlayer: CHHapticPatternPlayer?
    private static var currentCue: PhoneCue?
    private static var deferredAuthentication: Task<Void, Never>?
    private static var queued: [(PhoneCue, Bool, Bool, Bool)] = []
    private static var drainTask: Task<Void, Never>?
    private static var hapticQueue: [PhoneHapticProfile] = []
    private static var hapticDrain: Task<Void, Never>?
    private static var hapticUntil: TimeInterval = 0

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
                if state == .background { return }
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
            OpeningQA.record("Authentication audio expired while inactive")
        }
    }
    static func cancelAuthentication() {
        deferredAuthentication?.cancel(); deferredAuthentication = nil
    }
    private static func scheduleDrain() {
        guard drainTask == nil else { return }
        drainTask = Task { @MainActor in
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: 50_000_000) } catch { return }
                guard UIApplication.shared.applicationState == .active else { queued.removeAll(); break }
                if audio?.isPlaying == true { continue }
                guard !queued.isEmpty else { break }
                let next = queued.removeFirst()
                play(next.0, sound: next.1, haptics: next.2, horrorEnabled: next.3)
            }
            drainTask = nil
        }
    }

    @discardableResult
    static func play(_ cue: PhoneCue, sound: Bool, haptics: Bool, horrorEnabled: Bool, hapticProfile: PhoneHapticProfile? = nil) -> Double {
        guard UIApplication.shared.applicationState == .active,
              !cue.isHorror || horrorEnabled else { return 0 }
        // Dispatch tactile feedback on arrival, not after the audio queue.
        if haptics && preference("lastseen.lab.messageHaptics") {
            requestHaptics(hapticProfile ?? .cue(cue))
        }
        guard sound && preference("lastseen.lab.messageSound") else { return 0 }
        if audio?.isPlaying == true, let currentCue {
            if cue.isKeypress && !currentCue.isKeypress { return 0 }
            if !cue.isKeypress && !currentCue.isKeypress && !cue.isAuthentication {
                if queued.count < 12 { queued.append((cue, sound, false, horrorEnabled)); scheduleDrain() }
                OpeningQA.record("Phone audio queued: " + cue.rawValue)
                return 0
            }
        }
        var playbackDuration = 0.0
        if sound {
            do {
                audio?.stop()
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                if let url = cue.audioURL() {
                    audio = try AVAudioPlayer(contentsOf: url)
                } else {
                    OpeningQA.record("Missing bundled phone sound: " + cue.assetName)
                    audio = try AVAudioPlayer(data: cue.waveData())
                }
                audio?.numberOfLoops = 0
                playbackDuration = audio?.duration ?? 0
                audio?.volume = cue == .passcodeKeypress || cue == .authenticationFailed || cue == .timerCompleted ? 1.0 : 0.8
                audio?.prepareToPlay()
                currentCue = cue
                if audio?.play() == true { OpeningQA.record("Phone audio started: " + cue.rawValue) }
                else { OpeningQA.record("Phone audio start failed: " + cue.rawValue) }
            } catch { OpeningQA.record("Phone audio unavailable") }
        }
        return playbackDuration
    }

    private static func requestHaptics(_ profile: PhoneHapticProfile) {
        let now = ProcessInfo.processInfo.systemUptime
        if now < hapticUntil || !hapticQueue.isEmpty {
            // Keypresses never interrupt an incoming alert. Alert bursts retain
            // a short FIFO, independent of the length of any sound recording.
            if profile.isInteraction { return }
            if hapticQueue.count < 12 { hapticQueue.append(profile) }
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

    static func stopSound() {
        audio?.stop(); audio = nil; currentCue = nil
        drainTask?.cancel(); drainTask = nil; queued.removeAll()
    }
    static func stopHaptics() {
        hapticDrain?.cancel(); hapticDrain = nil; hapticQueue.removeAll(); hapticUntil = 0
        try? hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
        hapticPlayer = nil
        engine?.stop(completionHandler: nil)
        engine = nil
    }
    static func stop() {
        cancelAuthentication(); stopSound(); stopHaptics()
    }
}
