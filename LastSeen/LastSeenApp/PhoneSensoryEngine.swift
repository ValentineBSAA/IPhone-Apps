import Foundation
import AVFoundation
import CoreHaptics
import UIKit

/// A small, original sensory palette. Future story events may select suspense or
/// scare explicitly; ordinary messages never randomly use the horror profiles.
enum PhoneCue: String, CaseIterable {
    case message, outgoing, general, call, lock, unlock
    case corrupted, unknownCaller, suspense, scare, phantom

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
        case .outgoing, .lock, .unlock:
            return [Pulse(time: 0, frequency: 700, duration: 0.08, intensity: 0.23, sharpness: 0.6)]
        case .general:
            return [Pulse(time: 0, frequency: 900, duration: 0.14, intensity: 0.5, sharpness: 0.5)]
        case .call, .unknownCaller:
            return [Pulse(time: 0, frequency: 440, duration: 0.26, intensity: 0.62, sharpness: 0.32),
                    Pulse(time: 0.4, frequency: 330, duration: 0.25, intensity: 0.62, sharpness: 0.32)]
        case .corrupted, .phantom:
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

@MainActor
enum PhoneSensoryEngine {
    private static var audio: AVAudioPlayer?
    private static var engine: CHHapticEngine?
    private static var hapticPlayer: CHHapticPatternPlayer?

    @discardableResult
    static func play(_ cue: PhoneCue, sound: Bool, haptics: Bool, horrorEnabled: Bool) -> Double {
        guard UIApplication.shared.applicationState == .active,
              !cue.isHorror || horrorEnabled else { return 0 }
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
                audio?.volume = 0.8
                if audio?.play() == true { OpeningQA.record("Phone audio requested: " + cue.rawValue) }
            } catch { OpeningQA.record("Phone audio unavailable") }
        }
        if haptics {
            playHaptics(cue)
        }
        return playbackDuration
    }

    private static func playHaptics(_ cue: PhoneCue) {
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            do {
                if engine == nil {
                    let fresh = try CHHapticEngine()
                    fresh.playsHapticsOnly = true
                    engine = fresh
                }
                guard let engine else { return }
                try engine.start()
                try? hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
                let events = cue.pulses.map { pulse in
                    CHHapticEvent(eventType: cue == .message || cue == .outgoing || cue == .lock || cue == .unlock ? .hapticTransient : .hapticContinuous,
                                  parameters: [
                                    CHHapticEventParameter(parameterID: .hapticIntensity, value: pulse.intensity),
                                    CHHapticEventParameter(parameterID: .hapticSharpness, value: pulse.sharpness)
                                  ], relativeTime: pulse.time, duration: cue == .message || cue == .outgoing || cue == .lock || cue == .unlock ? 0 : pulse.duration)
                }
                let pattern = try CHHapticPattern(events: events, parameters: [])
                hapticPlayer = try engine.makePlayer(with: pattern)
                try hapticPlayer?.start(atTime: CHHapticTimeImmediate)
                OpeningQA.record("Core Haptics requested: " + cue.rawValue)
                return
            } catch {
                stopHaptics()
                OpeningQA.record("Core Haptics unavailable; using UIKit fallback")
            }
        }
        let fallback = UINotificationFeedbackGenerator()
        fallback.prepare()
        fallback.notificationOccurred(cue.isHorror ? .warning : .success)
        OpeningQA.record("UIKit haptic requested: " + cue.rawValue)
    }

    static func stopSound() {
        audio?.stop(); audio = nil
    }
    static func stopHaptics() {
        try? hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
        hapticPlayer = nil
        engine?.stop(completionHandler: nil)
        engine = nil
    }
    static func stop() {
        stopSound(); stopHaptics()
    }
}
