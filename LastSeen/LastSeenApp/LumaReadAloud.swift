import SwiftUI
import AVFoundation
import Combine
import UIKit

/// Explicit accessibility speech, not a character recording or a microphone.
@MainActor final class LumaReadAloud: ObservableObject {
    @Published private(set) var active = false
    @Published private(set) var notice = ""
    private let synthesizer = AVSpeechSynthesizer()
    private let owner = UUID()
    private var started: TimeInterval = 0
    private var observedSpeaking = false

    static func eligible(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= 4000
    }

    func speak(_ text: String) {
        stop()
        notice = ""
        guard UIApplication.shared.applicationState == .active,
              Self.eligible(text), let voice = AVSpeechSynthesisVoice(language: "en-US") else {
            notice = "System read-aloud is unavailable."
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
        } catch {
            notice = "Audio is unavailable."
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        PhoneSensoryEngine.beginMediaAudio(owner)
        started = ProcessInfo.processInfo.systemUptime
        observedSpeaking = false
        active = true
        synthesizer.speak(utterance)
    }

    /// Monotonic startup grace avoids wall-clock changes and a premature stop
    /// while the system is preparing its voice. No automatic replay.
    static func shouldStop(speaking: Bool, observedSpeaking: Bool, elapsed: TimeInterval) -> Bool {
        guard !speaking else { return false }
        return observedSpeaking || (elapsed.isFinite && elapsed >= 3)
    }

    func tick() {
        guard active else { return }
        guard UIApplication.shared.applicationState == .active else { stop(); return }
        let speaking = synthesizer.isSpeaking
        if speaking { observedSpeaking = true }
        if Self.shouldStop(speaking: speaking, observedSpeaking: observedSpeaking,
                           elapsed: ProcessInfo.processInfo.systemUptime - started) { stop() }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        if active { PhoneSensoryEngine.endMediaAudio(owner) }
        active = false
        observedSpeaking = false
    }
}
