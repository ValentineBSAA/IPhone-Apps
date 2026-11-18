import Foundation
import SwiftUI
import UserNotifications
import AudioToolbox

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var state: SavedGame
    @Published private(set) var typingThread: String?
    @Published private(set) var visibleThread: String?
    @Published var notificationDraft: String?

    private var deliveryTask: Task<Void, Never>?
    private let ambience = AudioAtmosphere()
    private let persistToDisk: Bool

    init(initial: SavedGame? = nil, persistToDisk: Bool = true) {
        self.persistToDisk = persistToDisk
        if let initial {
            state = initial
        } else if persistToDisk,
                  let data = try? Data(contentsOf: Self.saveURL),
                  let previous = try? JSONDecoder().decode(SavedGame.self, from: data),
                  [1, 2].contains(previous.schemaVersion) {
            state = previous
        } else {
            state = SavedGame()
        }

        // Migration from v1.0: preserve the earlier chapter, choices and collected evidence,
        // but show its scattered contacts within Nora's thread as forwarded information.
        if state.schemaVersion == 1 {
            state.activeThread = state.messages.isEmpty ? nil : Contact.nora.id
            state.messages = state.messages.map { message in
                let source = Contact(rawValue: message.thread)
                let text = (message.thread == Contact.nora.id || message.isOutgoing)
                    ? message.body : "Forwarded from \(source?.name ?? "Unknown"): \(message.body)"
                return GameMessage(id: message.id, thread: Contact.nora.id,
                                   sender: message.isOutgoing ? "player" : Contact.nora.id,
                                   body: text,
                                   kind: message.kind == .call ? .text : message.kind,
                                   createdAt: message.createdAt, isRead: message.isRead,
                                   photoAssetName: message.photoAssetName)
            }
            state.schemaVersion = 2
            state.stories = [:]
        }
        if state.activeThread != nil && SoloStories.scenes[state.sceneID] == nil {
            state = SavedGame()
        }
        if persistToDisk { save() }
    }

    static var saveURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("last-seen-save-v1.json")
    }

    var activeContact: Contact? { state.activeThread.flatMap(Contact.init(rawValue:)) }
    var currentScene: StoryScene? { SoloStories.scenes[state.sceneID] }
    var availableChoices: [StoryChoice] {
        state.choiceReady ? (currentScene?.choices ?? []) : []
    }
    var endingTitle: String? {
        guard state.endingID != nil else { return nil }
        return currentScene?.ending
    }
    var endingDetail: String { currentScene?.endingDetail ?? "" }
    var allMessages: [GameMessage] { state.messages }

    func title(for contact: Contact) -> String { SoloStories.title(for: contact.id) }

    func messages(in thread: String) -> [GameMessage] {
        if state.activeThread == thread { return state.messages }
        return state.stories?[thread]?.messages ?? []
    }

    func unreadCount(in thread: String) -> Int {
        messages(in: thread).filter { !$0.isOutgoing && !$0.isRead }.count
    }

    func ending(for contact: Contact) -> String? {
        if state.activeThread == contact.id { return state.endingID }
        return state.stories?[contact.id]?.endingID
    }

    func hasClues(_ clues: [String]) -> Bool {
        clues.allSatisfy { state.clues.contains($0) }
    }

    func markThreadRead(_ thread: String) {
        guard state.activeThread == thread else { return }
        var dirty = false
        for index in state.messages.indices where
            state.messages[index].thread == thread &&
            !state.messages[index].isOutgoing &&
            !state.messages[index].isRead {
            state.messages[index].isRead = true
            dirty = true
        }
        if dirty {
            state.readThreads.insert(thread)
            save()
        }
    }

    /// A conversation is activated only after the player chooses its contact.
    /// Switching stories snapshots the old progress and never advances inactive threads.
    func selectStory(_ contact: Contact) {
        let thread = contact.id
        if state.activeThread != thread {
            suspend()
            var slots = state.stories ?? [:]
            if let old = state.activeThread {
                slots[old] = StorySlot(capturing: state)
            }
            let next = slots.removeValue(forKey: thread)
                ?? StorySlot(sceneID: SoloStories.start(for: thread))
            next.restore(into: &state)
            state.stories = slots
            state.activeThread = thread
            save()
        }
        visibleThread = thread
        if persistToDisk {
            clearReminder()
            beginOrResume()
        }
    }

    func closeConversation(_ contact: Contact) {
        guard visibleThread == contact.id else { return }
        visibleThread = nil
        suspend()
    }

    func beginOrResume() {
        consumePendingReply()
        guard let thread = state.activeThread, visibleThread == thread,
              state.endingID == nil, !state.choiceReady else { return }
        if state.audioEnabled { ambience.start() }
        deliveryTask?.cancel()
        deliveryTask = Task { [weak self] in
            await self?.runDeliveryLoop()
        }
    }

    func suspend() {
        ambience.stop()
        deliveryTask?.cancel()
        deliveryTask = nil
        typingThread = nil
        save()
    }

    /// Characters have thinking pauses and varied typing duration, not a uniform timer.
    /// No background narration runs while another conversation is selected.
    private func pacing(_ beat: StoryBeat, index: Int) -> (pause: Double, typing: Double) {
        let count = Double(beat.body.count)
        let scramble = Double((index * 17 + beat.body.utf8.reduce(0) { ($0 + Int($1)) % 97 }) % 7)
        let pause = 0.3 + scramble * 0.22 + (index % 7 == 0 ? 1.1 : 0.0)
        let composing = min(4.7, max(0.35, count / 22.0 + Double(index % 4) * 0.18))
        let dramatic = state.slowerText ? 1.6 : 1.0
        return (pause * dramatic, composing * dramatic)
    }

    private func runDeliveryLoop() async {
        while !Task.isCancelled {
            guard state.activeThread == visibleThread,
                  let scene = currentScene else { return }

            if state.nextBeatIndex < scene.beats.count {
                let index = state.nextBeatIndex
                let beat = scene.beats[index]
                let times = pacing(beat, index: index)
                typingThread = nil
                do {
                    try await Task.sleep(nanoseconds: UInt64(times.pause * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                    typingThread = (beat.body.count > 17 && index % 4 != 1) ? beat.thread : nil
                    try await Task.sleep(nanoseconds: UInt64(times.typing * 1_000_000_000))
                } catch {
                    typingThread = nil
                    return
                }
                guard !Task.isCancelled, state.activeThread == visibleThread,
                      state.sceneID == scene.id, state.nextBeatIndex == index else {
                    typingThread = nil
                    return
                }
                typingThread = nil
                deliverBeat(beat, sceneID: scene.id, index: index)
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
        guard let thread = state.activeThread else { return }
        let id = "\(thread)-\(sceneID)-\(index)"
        guard !state.messages.contains(where: { $0.id == id }) else {
            state.nextBeatIndex = index + 1
            save()
            return
        }
        for i in state.messages.indices where state.messages[i].isOutgoing {
            state.messages[i].isRead = true
        }
        let now = Date()
        let resolved = StoryClock.contextualize(beat, sceneID: sceneID, index: index, now: now)
        state.messages.append(
            GameMessage(id: id, thread: thread, sender: thread, body: resolved.body,
                        kind: resolved.kind, createdAt: now, isRead: false,
                        photoAssetName: resolved.asset)
        )
        state.nextBeatIndex = index + 1
        if state.audioEnabled { AudioServicesPlaySystemSound(1104) }
        if state.hapticsEnabled { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        save()
    }

    func revealNextNow() {
        guard state.activeThread == visibleThread, state.endingID == nil, !state.choiceReady,
              let scene = currentScene, state.nextBeatIndex < scene.beats.count else { return }
        deliveryTask?.cancel()
        typingThread = nil
        deliverBeat(scene.beats[state.nextBeatIndex], sceneID: scene.id, index: state.nextBeatIndex)
        beginOrResume()
    }

    @discardableResult
    func choose(_ choiceID: String) -> Bool {
        guard let thread = state.activeThread, state.choiceReady,
              let choice = currentScene?.choices.first(where: { $0.id == choiceID }),
              hasClues(choice.requiredClues),
              SoloStories.scenes[choice.next] != nil else { return false }
        deliveryTask?.cancel()
        let id = "choice-\(thread)-\(state.sceneID)-\(choiceID)"
        if !state.messages.contains(where: { $0.id == id }) {
            state.messages.append(
                GameMessage(id: id, thread: thread, sender: "player",
                            body: choice.title, kind: .text,
                            createdAt: Date(), isRead: false)
            )
        }
        state.visitedChoices.append(choiceID)
        state.sceneID = choice.next
        state.nextBeatIndex = 0
        state.choiceReady = false
        typingThread = nil
        if state.hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        save()
        if visibleThread == thread { beginOrResume() }
        return true
    }

    func inspect(_ message: GameMessage) {
        let clue: String
        switch message.kind {
        case .photograph: clue = "photograph"
        case .voiceNote: clue = "voiceNote"
        case .text, .call: return
        }
        if message.thread == state.activeThread {
            state.clues.insert(clue)
        } else if var slot = state.stories?[message.thread] {
            slot.clues.insert(clue)
            state.stories?[message.thread] = slot
        } else {
            return
        }
        save()
    }

    /// No voice-call UI or fake audio playback without actual recorded files.
    /// A legacy .call message is displayed as an ordinary text-only call record.

    func restart() {
        suspend()
        let current = state.activeThread
        guard let thread = current else { return }
        let initial = StorySlot(sceneID: SoloStories.start(for: thread))
        initial.restore(into: &state)
        save()
        if visibleThread == thread { beginOrResume() }
    }

    func setAudio(_ enabled: Bool) {
        state.audioEnabled = enabled
        if enabled && visibleThread == state.activeThread { ambience.start() }
        else if !enabled { ambience.stop() }
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
        clearReminder()
        save()
    }

    /// This uses the actual pending conversation text, not a generic "fictional game" ad.
    /// iOS renders it under LAST SEEN; it must never pretend to be Apple Messages.
    func scheduleReturnReminder() {
        guard persistToDisk, state.notificationsEnabled, state.endingID == nil,
              let thread = state.activeThread,
              let contact = Contact(rawValue: thread),
              let scene = currentScene else { return }
        let content = UNMutableNotificationContent()
        content.title = contact.name
        content.userInfo = ["thread": thread]
        if state.choiceReady {
            content.body = state.messages.last(where: { !$0.isOutgoing })?.body ?? "Are you there?"
            content.categoryIdentifier = NotificationRouter.replyCategory
        } else if state.nextBeatIndex < scene.beats.count {
            let beat = scene.beats[state.nextBeatIndex]
            switch beat.kind {
            case .photograph: content.body = "Sent a photo"
            case .voiceNote: content.body = "Sent a voice note"
            case .text, .call: content.body = beat.body
            }
        } else {
            return
        }
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: NotificationRouter.storyNotificationID,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 14, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func clearReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [NotificationRouter.storyNotificationID]
        )
    }

    func sendTestNotification() {
        guard state.notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = activeContact?.name ?? "Nora Bennett"
        content.body = "Hey. Are you still there?"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "lastseen-test",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 7, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func handleNotificationReply(_ input: String, thread: String) {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        if state.activeThread != thread {
            // Keep a draft rather than silently applying a response to the wrong storyline.
            notificationDraft = value
            return
        }
        let normalized = Self.normalized(value)
        if state.choiceReady, let matching = availableChoices.first(where: {
            Self.normalized($0.title) == normalized
                && hasClues($0.requiredClues)
        }) {
            _ = choose(matching.id)
            notificationDraft = nil
        } else {
            notificationDraft = value
        }
    }

    static func normalized(_ input: String) -> String {
        input.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    func clearDraft() {
        notificationDraft = nil
        UserDefaults.standard.removeObject(forKey: NotificationRouter.replyStorageKey)
    }

    private func consumePendingReply() {
        guard let raw = UserDefaults.standard.dictionary(forKey: NotificationRouter.replyStorageKey),
              let text = raw["text"] as? String,
              let thread = raw["thread"] as? String else { return }
        UserDefaults.standard.removeObject(forKey: NotificationRouter.replyStorageKey)
        handleNotificationReply(text, thread: thread)
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

    /// Deterministic story advancement for tests, without waiting for UI animation.
    func advanceForTests() {
        guard state.activeThread != nil,
              let scene = currentScene, state.endingID == nil,
              !state.choiceReady else { return }
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
