import Foundation
import AVFoundation
import Speech

/// Future voice architecture. The shipping game never creates or starts this service.
/// The feature gate is intentionally a compile-time false constant.
enum FutureVoiceFeatures {
    static let enabled = false
    static let showTranscriptDuringCall = false
    static let permitCloudRecognition = false
    static let requireRecordedCharacterDialogue = true
    static let requireUserInitiatedCall = true
}

/// Design contract for a future fictional, in-app, push-to-talk call:
/// 1. Player explicitly starts a *fictional* character call, after microphone and
///    speech permissions are described and granted.
/// 2. The visible call screen says "Microphone on", but the interim transcript
///    can remain hidden to maintain immersion. iOS's orange mic indicator stays.
/// 3. Live microphone PCM enters AVAudioEngine, then SFSpeechRecognizer.
/// 4. On-device recognition is mandatory; unsupported locales remain disabled.
/// 5. Only the final transcription string enters a bounded narrative intent
///    parser; recorded character voice lines play through the app's own audio.
/// 6. The audio isn't uploaded or saved by default, and the session is stopped
///    when the player hangs up, leaves the app, or revokes permission.
///
/// None of this flow is reachable from any UI or game action in v1.0.3.
enum FutureVoiceError: LocalizedError {
    case disabled
    case permissionRequired
    case onDeviceNotAvailable
    case recordingFailed

    var errorDescription: String? {
        switch self {
        case .disabled: return "The LAST SEEN voice prototype is intentionally disabled."
        case .permissionRequired: return "Microphone and speech permissions are required."
        case .onDeviceNotAvailable: return "On-device speech recognition is unavailable for this locale."
        case .recordingFailed: return "The in-game microphone session could not start."
        }
    }
}

/// Isolated, opt-in implementation scaffold for iOS 16.
/// Never instantiate or call start() from production gameplay.
final class FutureOnDeviceSpeechSession {
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isCapturing = false

    var isAvailableWithoutNetwork: Bool {
        SFSpeechRecognizer(locale: Locale.current)?.supportsOnDeviceRecognition ?? false
    }

    func start(onFinalTranscript: @escaping (String) -> Void) throws {
        guard FutureVoiceFeatures.enabled else { throw FutureVoiceError.disabled }
        guard SFSpeechRecognizer.authorizationStatus() == .authorized,
              AVAudioSession.sharedInstance().recordPermission == .granted else {
            throw FutureVoiceError.permissionRequired
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale.current),
              recognizer.supportsOnDeviceRecognition else {
            throw FutureVoiceError.onDeviceNotAvailable
        }
        guard !isCapturing else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        recognitionRequest = request

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat,
                                    options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: [])
            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let result, result.isFinal {
                    onFinalTranscript(result.bestTranscription.formattedString)
                }
                if error != nil {
                    // The call UI will present the error when the feature is enabled.
                    // No raw audio or transcript is persisted here.
                }
            }
            audioEngine.prepare()
            try audioEngine.start()
            isCapturing = true
        } catch {
            stop()
            throw FutureVoiceError.recordingFailed
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if isCapturing {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isCapturing = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    deinit {
        stop()
    }
}
