import Foundation
import SwiftUI
import AVFoundation
import AudioToolbox
import UserNotifications

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var state: SavedGame
    @Published private(set) var typingThread: String? = nil
    @Published private(set) var playingVoiceID: String? = nil
    @Published var presentedCall: GameMessage? = nil

    private var deliveryTask: Task<Void, Never>?
    private let synth = AVSpeechSynthesizer()
    private let persistToDisk: Bool

    init(initial: SavedGame? = nil, persistToDisk: Bool = true) {
        self.persistToDisk = persistToDisk
        if let initial {
            state = initial
        } else if persistToDisk,
                  let data = try? Data(contentsOf: Self.saveURL),
                  let loaded = try? JSONDecoder().decode(SavedGame.self, from: data),
                  loaded.schemaVersion == 1,
                  StoryScript.scenes[loaded.sceneID] != nil {
            state = loaded
        } else {
            state = SavedGame()
        }
    }

    static var saveURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("last-seen-save-v1.json")
    }

    var currentScene: StoryScene? { StoryScript.scenes[state.sceneID] }
    var availableChoices: [StoryChoice] {
        state.choiceReady ? (currentScene?.choices ?? []) : []
    }
    var endingTitle: String? {
        guard state.endingID != nil else { return nil }
        return currentScene?.ending
    }
    var endingDetail: String { currentScene?.endingDetail ?? "" }
    var allMessages: [GameMessage] { state.messages }

    func messages(in thread: String) -> [GameMessage] {
        state.messages.filter { $0.thread == thread }
    }

    func unreadCount(in thread: String) -> Int {
        state.messages.filter { $0.thread == thread && !$0.isOutgoing && !$0.isRead }.count
    }

    func hasClues(_ clues: [String]) -> Bool {
        clues.allSatisfy { state.clues.contains($0) }
    }

    func markThreadRead(_ thread: String) {
        var changed = false
        for index in state.messages.indices where state.messages[index].thread == thread && !state.messages[index].isOutgoing && !state.messages[index].isRead {
            state.messages[index].isRead = true
            changed = true
        }
        if changed {
            state.readThreads.insert(thread)
            save()
        }
    }

    func beginOrResume() {
        guard state.endingID == nil, !state.choiceReady else { return }
        deliveryTask?.cancel()
        deliveryTask = Task { [weak self] in
            await self?.runDeliveryLoop()
        }
    }

    func suspend() {
        deliveryTask?.cancel()
        deliveryTask = nil
        typingThread = nil
        save()
    }

    private func runDeliveryLoop() async {
        while !Task.isCancelled {
            guard let scene = currentScene else { return }

            if state.nextBeatIndex < scene.beats.count {
                let beat = scene.beats[state.nextBeatIndex]
                typingThread = beat.thread
                let duration = state.slowerText ? max(3.0, beat.delay * 1.65) : beat.delay
                do {
                    try await Task.sleep(nanoseconds: UInt64(max(0.1, duration) * 1_000_000_000))
                } catch {
                    typingThread = nil
                    return
                }
                guard !Task.isCancelled else {
                    typingThread = nil
                    return
                }
                typingThread = nil
                deliverBeat(beat, sceneID: scene.id, index: state.nextBeatIndex)
            } else if !scene.choices.isEmpty {
                state.choiceReady = true
                save()
                return
            } else if let next = scene.next {
                state.sceneID = next
                state.nextBeatIndex = 0
                state.choiceReady = false
                save()
            } else if scene.ending != nil {
                state.endingID = scene.id
                state.choiceReady = false
                save()
                return
            } else {
                return
            }
        }
    }

    private func deliverBeat(_ beat: StoryBeat, sceneID: String, index: Int) {
        let id = "\(sceneID)-\(index)"
        guard !state.messages.contains(where: { $0.id == id }) else {
            state.nextBeatIndex = index + 1
            save()
            return
        }
        for i in state.messages.indices where state.messages[i].thread == beat.thread && state.messages[i].isOutgoing {
            state.messages[i].isRead = true
        }
        state.messages.append(
            GameMessage(
                id: id, thread: beat.thread, sender: beat.sender, body: beat.body,
                kind: beat.kind, createdAt: Date(), isRead: false
            )
        )
        state.nextBeatIndex = index + 1
        if state.audioEnabled { AudioServicesPlaySystemSound(1104) }
        if state.hapticsEnabled { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        save()
    }

    func revealNextNow() {
        guard state.endingID == nil, !state.choiceReady,
              let scene = currentScene,
              state.nextBeatIndex < scene.beats.count else { return }
        deliveryTask?.cancel()
        typingThread = nil
        deliverBeat(scene.beats[state.nextBeatIndex], sceneID: scene.id, index: state.nextBeatIndex)
        beginOrResume()
    }

    @discardableResult
    func choose(_ choiceID: String) -> Bool {
        guard state.choiceReady,
              let choice = currentScene?.choices.first(where: { $0.id == choiceID }),
              hasClues(choice.requiredClues),
              StoryScript.scenes[choice.next] != nil else { return false }

        deliveryTask?.cancel()
        let contact = choiceID == "caretaker_path" || choiceID == "taken" || choiceID == "eli_trust_early" ? "eli"
            : choiceID == "unknown_path" ? "unit7" : "nora"
        let choiceMessage = GameMessage(
            id: "choice-\(state.sceneID)-\(choiceID)",
            thread: contact, sender: "player", body: choice.title,
            kind: .text, createdAt: Date(), isRead: false
        )
        if !state.messages.contains(where: { $0.id == choiceMessage.id }) {
            state.messages.append(choiceMessage)
        }
        state.visitedChoices.append(choiceID)
        state.sceneID = choice.next
        state.nextBeatIndex = 0
        state.choiceReady = false
        typingThread = nil
        if state.hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        save()
        beginOrResume()
        return true
    }

    func inspect(_ message: GameMessage) {
        switch message.kind {
        case .photograph: state.clues.insert("photograph")
        case .voiceNote: state.clues.insert("voiceNote")
        case .call: state.clues.insert("call")
        case .text: break
        }
        save()
    }

    func toggleVoice(_ message: GameMessage) {
        inspect(message)
        guard state.audioEnabled else { return }
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
            if playingVoiceID == message.id {
                playingVoiceID = nil
                return
            }
        }
        let utterance = AVSpeechUtterance(string: message.body.replacingOccurrences(of: "Voice message: ", with: ""))
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.44
        utterance.pitchMultiplier = 0.82
        synth.speak(utterance)
        playingVoiceID = message.id
    }

    func stopVoice() {
        synth.stopSpeaking(at: .immediate)
        playingVoiceID = nil
    }

    func answerCall() {
        if let call = presentedCall {
            inspect(call)
            let scripted = GameMessage(
                id: "call-transcript-\(call.id)", thread: call.thread,
                sender: "unit7", body: "Call connected: \"There is no seventh floor. Stop counting the doors.\"",
                kind: .text, createdAt: Date(), isRead: false
            )
            if !state.messages.contains(where: { $0.id == scripted.id }) {
                state.messages.append(scripted)
            }
            if state.audioEnabled {
                let statement = AVSpeechUtterance(string: "There is no seventh floor. Stop counting the doors.")
                statement.voice = AVSpeechSynthesisVoice(language: "en-US")
                statement.rate = 0.38
                statement.pitchMultiplier = 0.65
                synth.speak(statement)
            }
            save()
        }
        presentedCall = nil
    }

    func declineCall() {
        if let call = presentedCall {
            let missed = GameMessage(
                id: "call-declined-\(call.id)", thread: call.thread, sender: "unit7",
                body: "Missed call", kind: .text, createdAt: Date(), isRead: false
            )
            if !state.messages.contains(where: { $0.id == missed.id }) {
                state.messages.append(missed)
            }
            save()
        }
        presentedCall = nil
    }

    func restart() {
        suspend()
        stopVoice()
        presentedCall = nil
        let keepAudio = state.audioEnabled
        let keepHaptics = state.hapticsEnabled
        let keepNotifications = state.notificationsEnabled
        let keepSlow = state.slowerText
        state = SavedGame()
        state.audioEnabled = keepAudio
        state.hapticsEnabled = keepHaptics
        state.notificationsEnabled = keepNotifications
        state.slowerText = keepSlow
        save()
        beginOrResume()
    }

    func setAudio(_ enabled: Bool) {
        state.audioEnabled = enabled
        if !enabled { stopVoice() }
        save()
    }

    func setHaptics(_ enabled: Bool) {
        state.hapticsEnabled = enabled
        save()
    }

    func setSlowText(_ enabled: Bool) {
        state.slowerText = enabled
        save()
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            Task { @MainActor in
                self?.state.notificationsEnabled = granted
                self?.save()
            }
        }
    }

    func disableNotifications() {
        state.notificationsEnabled = false
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["last-seen-reminder"])
        save()
    }

    func scheduleReturnReminder() {
        guard state.notificationsEnabled, state.endingID == nil else { return }
        let content = UNMutableNotificationContent()
        content.title = "LAST SEEN"
        content.body = "Your fictional messages are still waiting. Continue The Missing Floor."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "last-seen-reminder",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 900, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func clearReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["last-seen-reminder"])
    }

    private func save() {
        guard persistToDisk else { return }
        state.lastSaved = Date()
        do {
            let directory = Self.saveURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(state)
            try data.write(to: Self.saveURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            #if DEBUG
            print("LAST SEEN save failed: \(error)")
            #endif
        }
    }

    // Pure synchronous progression for unit tests. Never used in the actual player's session.
    func advanceForTests() {
        guard let scene = currentScene, state.endingID == nil, !state.choiceReady else { return }
        if state.nextBeatIndex < scene.beats.count {
            deliverBeat(scene.beats[state.nextBeatIndex], sceneID: scene.id, index: state.nextBeatIndex)
        } else if !scene.choices.isEmpty {
            state.choiceReady = true
        } else if let next = scene.next {
            state.sceneID = next
            state.nextBeatIndex = 0
        } else if scene.ending != nil {
            state.endingID = scene.id
        }
    }
}
