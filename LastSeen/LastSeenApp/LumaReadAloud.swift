import SwiftUI
import AVFoundation

/// Explicit accessibility speech, not a character recording or a microphone.
@MainActor final class LumaReadAloud: ObservableObject {
    @Published private(set) var active = false
    @Published private(set) var notice = ""
    private let synthesizer = AVSpeechSynthesizer()
    private let owner = UUID()
    private var started = Date.distantPast

    static func eligible(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= 4000
    }

    func speak(_ text: String) {
        stop()
        notice = ""
        guard Self.eligible(text), let voice = AVSpeechSynthesisVoice(language: "en-US") else {
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
        started = Date()
        active = true
        synthesizer.speak(utterance)
    }

    func tick(now: Date = Date()) {
        guard active, now.timeIntervalSince(started) >= 1, !synthesizer.isSpeaking else { return }
        stop()
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        if active { PhoneSensoryEngine.endMediaAudio(owner) }
        active = false
    }
}
