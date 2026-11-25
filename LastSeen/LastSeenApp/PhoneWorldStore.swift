import Foundation
import SwiftUI

/// Fictional everyday life surrounding the horror. It does not access real
/// Contacts, Messages, Calendar, Mail, Photos, or device communication data.
enum Neighbor: String, CaseIterable, Identifiable, Codable {
    case maya, denise, helen, lily, daniel, adrian, tessa, unknown
    static let original: [Neighbor] = [.maya, .denise]
    static func visible(in world: PhoneWorld) -> [Neighbor] { allCases.filter { original.contains($0) || world.threads[$0.id] != nil } }

    var id: String { rawValue }
    var name: String {
        switch self {
        case .maya: return "Maya Brooks"
        case .denise: return "Denise Hall"
        case .helen: return "Helen Bennett"
        case .lily: return "Lily Bennett"
        case .daniel: return "Daniel Bennett"
        case .adrian: return "Adrian Cole"
        case .tessa: return "Tessa Reed"
        case .unknown: return "Unknown number"
        }
    }
    var subtitle: String {
        switch self {
        case .maya: return "Friend"
        case .denise: return "Building office"
        case .helen: return "Mum"
        case .lily: return "Sister"
        case .daniel: return "Brother"
        case .adrian: return "Technical lead · Blue Hour Interactive"
        case .tessa: return "Artist / producer · Blue Hour Interactive"
        case .unknown: return "Unverified sender"
        }
    }
    var initials: String { name.split(separator: " ").prefix(2).compactMap(\.first).map { String($0) }.joined() }

    // Both portraits are existing, approved images. They are assigned as
    // unique character headshots rather than leaving new contacts as initials.
    // Keep these assignments stable across relaunch and story progression.
    var portraitAssetName: String {
        switch self {
        case .maya: return "Contact_Maya"
        case .denise: return "Contact_Denise"
        case .helen: return "Contact_B27_01"
        case .lily: return "Contact_B27_03"
        case .daniel: return "Contact_B27_04"
        case .adrian: return "Contact_B27_06"
        case .tessa: return "Contact_B27_07"
        case .unknown: return ""
        }
    }

    var hue: Color { self == .maya ? Color(red: 0.49, green: 0.52, blue: 0.78) : Color(red: 0.40, green: 0.60, blue: 0.56) }
}

struct NeighborMessage: Codable, Identifiable, Equatable {
    var id: String
    var thread: String
    var text: String
    var fromPlayer: Bool
    var at: Date
    var read: Bool = false
    var recipientReadAt: Date? = nil
    var receiptTracked: Bool? = nil
}

struct PhoneNote: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var body: String
    var modifiedAt: Date
    var pinned: Bool
}

struct PhoneEvent: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
    var startsAt: Date
    var endsAt: Date
}

struct LumaCallRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let contact: Neighbor
    let date: Date
}

struct PhoneWorld: Codable {
    var version: Int = 1
    var createdAt: Date
    var threads: [String: [NeighborMessage]]
    var progress: [String: Int] = [:]
    var flags: Set<String> = []
    var notes: [PhoneNote]
    var events: [PhoneEvent]
    var soundEnabled: Bool = true
    var pendingReplies: [PhonePendingReply]? = nil
    var callHistory: [LumaCallRecord]? = nil
    var favoriteContacts: [String]? = nil
    var everydayArchiveRevision: Int? = nil
    var utilitySnippets: [LumaSnippet]? = nil
    var pinnedSnippet: String? = nil
}

/// This is a separate *fictional world save* while compatibility with existing
/// v1.0.x story data is maintained. It survives app restarts and story replays.
@MainActor
final class PhoneWorldStore: ObservableObject {
    @Published private(set) var state: PhoneWorld
    @Published var visibleThread: Neighbor? = nil
    private let persistToDisk: Bool
    private let storageURL: URL

    static var saveURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("lastseen-world-v1.json")
    }

    init(initial: PhoneWorld? = nil, persistToDisk: Bool = true, now: Date = Date(), storageURL: URL? = nil) {
        self.persistToDisk = persistToDisk
        let resolvedURL = storageURL ?? Self.saveURL
        self.storageURL = resolvedURL
        if let initial {
            state = initial
        } else if persistToDisk,
            let data = try? Data(contentsOf: resolvedURL),
            let previous = try? JSONDecoder().decode(PhoneWorld.self, from: data),
            previous.version == 1 {
            state = previous
        } else {
            let calendar = Calendar.current
            let morning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
            let service = calendar.date(byAdding: .day, value: 1, to: morning) ?? now
            let coffee = calendar.date(byAdding: .day, value: 2, to: morning) ?? now
            state = PhoneWorld(
                createdAt: now,
                threads: [
                    "maya": [
                        NeighborMessage(id: "maya-hello", thread: "maya",
                            text: "Hey! Are we still doing coffee this week?", fromPlayer: false,
                            at: now.addingTimeInterval(-420)),
                        NeighborMessage(id: "maya-followup", thread: "maya",
                            text: "No rush. Just trying to plan around work lol", fromPlayer: false,
                            at: now.addingTimeInterval(-350))
                    ],
                    "denise": [
                        NeighborMessage(id: "denise-hello", thread: "denise",
                            text: "Hi! Denise from the building office. Elevator maintenance is scheduled this week. The front entrance will stay open.",
                            fromPlayer: false, at: now.addingTimeInterval(-780))
                    ]
                ],
                notes: [
                    PhoneNote(id: "shopping", title: "Pick up", body: "Coffee beans\nPaper towels\nBatteries", modifiedAt: now.addingTimeInterval(-86400), pinned: false),
                    PhoneNote(id: "building", title: "Building information",
                        body: "Maintenance desk: lobby\nNora: 402\nBuilding office: ground floor\nRemember to ask about elevator inspection.",
                        modifiedAt: now.addingTimeInterval(-600), pinned: true)
                ],
                events: [
                    PhoneEvent(id: "inspection", title: "Building elevator inspection",
                        detail: "Building office notice. Exact schedule subject to confirmation.",
                        startsAt: service, endsAt: service.addingTimeInterval(3600)),
                    PhoneEvent(id: "coffee", title: "Coffee with Maya?",
                        detail: "Tentative. Confirm by text.",
                        startsAt: coffee.addingTimeInterval(3600 * 2),
                        endsAt: coffee.addingTimeInterval(3600 * 3))
                ]
            )
        }
        if resolvedURL == RestoredPhoneBackup.url || state.everydayArchiveRevision != nil { NoraEverydayArchive.expand(&state) }
        save()
    }

    func messages(_ neighbor: Neighbor) -> [NeighborMessage] {
        state.threads[neighbor.id] ?? []
    }

    func countUnread(_ neighbor: Neighbor) -> Int {
        messages(neighbor).filter { !$0.fromPlayer && !$0.read }.count
    }

    func markRead(_ neighbor: Neighbor) {
        guard var messages = state.threads[neighbor.id] else { return }
        guard messages.contains(where: { !$0.fromPlayer && !$0.read }) else { return }
        for i in messages.indices where !messages[i].fromPlayer { messages[i].read = true }
        state.threads[neighbor.id] = messages
        save()
    }

    /// Only Phone Lab starts this tutorial; the legacy campaign is unchanged.
    static let tutorialNoteID = "nora-before-i-forget"
    static let tutorialNoteTitle = "Before I forget"
    static let tutorialNoteBody = "The book reservation receipt is in Files. I left myself a desk reminder about the private folders. Pick up the book before the weekend.\n\nIf Maya asks, tell her I haven't forgotten our coffee plans.\n— Nora"
    var tutorialStarted: Bool { state.flags.contains("phone-tutorial-started") }
    var tutorialFinished: Bool { state.flags.contains("phone-tutorial-finished") }

    func startPhoneTutorial(now: Date = Date()) {
        guard !tutorialStarted else { return }
        state.flags.insert("phone-tutorial-started")
        if !state.notes.contains(where: { $0.id == Self.tutorialNoteID }) {
            state.notes.insert(PhoneNote(id: Self.tutorialNoteID, title: Self.tutorialNoteTitle,
                                         body: Self.tutorialNoteBody, modifiedAt: now.addingTimeInterval(-86400), pinned: true), at: 0)
        }
        tutorialMessage("contact", "Nora? Your phone's showing as available again. If someone else has it, could you let me know? I haven't heard from her since we made plans for coffee.", now: now)
        save()
    }

    /// Replay only the introductory authored messages and flags. Do not touch
    /// restored documents, other messages, notes, app settings or owner security.
    func recoverPhotoDiscovery() {
        let recovered = NoraPhotoCatalog.discoveryFlags(from: state.flags)
        if recovered != state.flags { state.flags = recovered; save() }
    }

    func resetPhoneTutorial() {
        state.flags = NoraPhotoCatalog.discoveryFlags(from: state.flags)
        state.flags = Set(state.flags.filter { !$0.hasPrefix("phone-tutorial-") })
        state.pendingReplies = state.pendingReplies?.filter { !$0.outgoingID.hasPrefix("phone-tutorial-") }
        for key in Array(state.threads.keys) {
            state.threads[key]?.removeAll { $0.id.hasPrefix("phone-tutorial-") }
        }
        save()
    }

    func recordTutorialVisit(_ id: String, now: Date = Date()) {
        guard tutorialStarted, !tutorialFinished,
              ["note", "desk", "reservation", "journal"].contains(id) else { return }
        if state.flags.insert("phone-tutorial-visited-" + id).inserted {
            advanceTutorial(now: now)
            state.flags = NoraPhotoCatalog.discoveryFlags(from: state.flags)
            save()
        }
    }

    /// Free text is saved verbatim. Only the local authored reply plan can
    /// advance the introductory conversation; evidence gates remain independent.
    @discardableResult
    func sendReactive(to neighbor: Neighbor, text: String, now: Date = Date()) -> Bool {
        guard Neighbor.visible(in: state).contains(neighbor), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.count <= 2000 else { return false }
        let pending = state.pendingReplies ?? []
        guard pending.filter({ $0.neighbor == neighbor }).count < 8 else { return false }
        let introductory = neighbor == .maya && tutorialStarted && !tutorialFinished
        let key = (introductory ? "phone-tutorial-custom-" : "custom-") + UUID().uuidString
        let plan = PhoneReplyPolicy.plan(for: neighbor, text: text, flags: state.flags,
                                         tutorialStarted: tutorialStarted, tutorialFinished: tutorialFinished)
        let previous = pending.filter { $0.neighbor == neighbor }.map(\.dueAt).max() ?? now
        let base = max(now, previous)
        let readAt = base.addingTimeInterval(0.8)
        let due = base.addingTimeInterval(3.2 + min(2, Double(plan.text.count) / 130))
        append(NeighborMessage(id: key, thread: neighbor.id, text: text, fromPlayer: true,
                               at: now, read: true, receiptTracked: true))
        state.pendingReplies = pending + [PhonePendingReply(id: key + "-response", outgoingID: key,
            neighbor: neighbor, text: plan.text, readAt: readAt, dueAt: due, startsTutorial: plan.startsTutorial)]
        save()
        return true
    }

    func hasPendingReply(_ neighbor: Neighbor) -> Bool {
        (state.pendingReplies ?? []).contains { $0.neighbor == neighbor }
    }

    func isTyping(_ neighbor: Neighbor, now: Date = Date()) -> Bool {
        (state.pendingReplies ?? []).contains { $0.neighbor == neighbor && $0.readAt <= now && now < $0.dueAt }
    }

    func advancePendingReplies(now: Date = Date()) {
        advanceInvestigation(now: now)
        let pending = state.pendingReplies ?? []
        guard !pending.isEmpty else { return }
        var changed = false
        for item in pending where item.readAt <= now {
            if let index = state.threads[item.neighbor.id]?.firstIndex(where: { $0.id == item.outgoingID }),
               state.threads[item.neighbor.id]?[index].recipientReadAt == nil {
                state.threads[item.neighbor.id]?[index].recipientReadAt = item.readAt
                changed = true
            }
        }
        let due = pending.filter { $0.dueAt <= now }.sorted { $0.dueAt < $1.dueAt }
        for item in due {
            if item.startsTutorial && tutorialStarted && !state.flags.contains("phone-tutorial-replied") {
                state.flags.insert("phone-tutorial-replied")
                tutorialMessage("notes", item.text, now: now)
                advanceTutorial(now: now.addingTimeInterval(0.1))
                state.flags = NoraPhotoCatalog.discoveryFlags(from: state.flags)
            } else {
                append(NeighborMessage(id: item.id, thread: item.neighbor.id, text: item.text,
                                       fromPlayer: false, at: now, read: false))
            }
            changed = true
        }
        if !due.isEmpty {
            let ids = Set(due.map(\.id))
            state.pendingReplies = pending.filter { !ids.contains($0.id) }
        }
        if changed { save() }
    }

    private func tutorialMessage(_ id: String, _ text: String, now: Date) {
        append(NeighborMessage(id: "phone-tutorial-" + id, thread: "maya", text: text,
                               fromPlayer: false, at: now, read: false))
    }

    private func advanceTutorial(now: Date) {
        guard state.flags.contains("phone-tutorial-replied") else { return }
        if state.flags.contains("phone-tutorial-visited-note"),
           state.flags.insert("phone-tutorial-note-guidance").inserted {
            tutorialMessage("files", "She kept reminders everywhere. Try Files. There should be a desk reminder and a reservation receipt. Maybe those will help you work out what she was planning.", now: now)
        }
        if state.flags.contains("phone-tutorial-note-guidance"),
           state.flags.contains("phone-tutorial-visited-desk"),
           state.flags.contains("phone-tutorial-visited-reservation"),
           state.flags.insert("phone-tutorial-file-guidance").inserted {
            tutorialMessage("journal", "That sounds like Nora. She sometimes kept her personal notes locked. If you can work out how to open them, check whether she wrote anything about her plans. Don't worry about rushing.", now: now.addingTimeInterval(0.1))
        }
        if state.flags.contains("phone-tutorial-file-guidance"),
           state.flags.contains("phone-tutorial-visited-journal"),
           state.flags.insert("phone-tutorial-finished").inserted {
            tutorialMessage("finish", "Thanks for looking. I wish I knew why she stopped answering. Keep the phone for now, and let me know if anything else turns up.", now: now.addingTimeInterval(0.2))
        }
    }

    var tutorialChoices: [String] {
        guard tutorialStarted, !state.flags.contains("phone-tutorial-replied") else { return [] }
        return ["I got the phone working. Is everything okay?", "I'm not Nora. I was asked to repair this phone."]
    }

    func choices(_ neighbor: Neighbor) -> [String] {
        if neighbor == .maya && tutorialStarted { return tutorialChoices }
        guard Neighbor.original.contains(neighbor) else { return [] }
        let stage = state.progress[neighbor.id] ?? 0
        if stage == 0 {
            switch neighbor {
            case .maya: return ["Coffee sounds good!", "I might be busy this week.", "How's work going?"]
            case .denise: return ["Thanks for letting me know.", "Do you know what time the elevator will be checked?"]
            default: return []
            }
        }
        if stage == 1 {
            switch neighbor {
            case .maya: return ["I'll text you when I know.", "See you soon!"]
            case .denise: return ["Perfect, thank you.", "Could you send an update if that changes?"]
            default: return []
            }
        }
        return []
    }

    @discardableResult
    func reply(to neighbor: Neighbor, text: String, now: Date = Date()) -> Bool {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let chosen = choices(neighbor).first(where: { normalize($0) == normalize(clean) }) else {
            return false
        }
        if neighbor == .maya && tutorialStarted {
            guard !state.flags.contains("phone-tutorial-replied") else { return false }
            append(NeighborMessage(id: "phone-tutorial-player-reply", thread: "maya", text: chosen,
                                   fromPlayer: true, at: now, read: true))
            state.flags.insert("phone-tutorial-replied")
            tutorialMessage("notes", "Oh, thank you for telling me. I'm Maya, a friend of Nora's. I was expecting to hear from her. Could you look in Notes for something called Before I forget? She mentioned writing down her plans.", now: now.addingTimeInterval(0.1))
            advanceTutorial(now: now.addingTimeInterval(0.2))
            state.flags = NoraPhotoCatalog.discoveryFlags(from: state.flags)
            save()
            return true
        }
        let stage = state.progress[neighbor.id] ?? 0
        let id = "\(neighbor.id)-choice-\(stage)"
        if state.threads[neighbor.id]?.contains(where: { $0.id == id }) == true { return false }

        append(NeighborMessage(id: id, thread: neighbor.id, text: chosen,
                               fromPlayer: true, at: now, read: true))
        let response: String
        switch (neighbor, stage) {
        case (.maya, 0):
            if chosen.contains("busy") {
                response = "Totally fair. We'll figure something out when things settle down."
            } else if chosen.contains("work") {
                response = "Same old chaos, honestly 😅. I'll tell you about it over coffee."
            } else {
                response = "Nice! There's that little place across from the bookstore. We can pick a day."
            }
        case (.maya, _):
            response = "Sounds good ❤️. And hey, don't forget to eat something today."
        case (.denise, 0):
            if chosen.contains("time") {
                response = "I have a tentative window for tomorrow morning. The contractor hasn't confirmed yet."
            } else {
                response = "You're welcome. I'll put a notice on the lobby board once it's confirmed."
            }
        case (.denise, _):
            response = "Of course! I'll message the building when we have the final schedule."
        default: return false
        }
        append(NeighborMessage(id: "\(neighbor.id)-response-\(stage)", thread: neighbor.id,
                               text: response, fromPlayer: false,
                               at: now.addingTimeInterval(2), read: false))
        state.progress[neighbor.id] = stage + 1
        save()
        return true
    }

    func addNote(title: String = "New note", body: String = "", now: Date = Date()) -> String {
        let id = UUID().uuidString
        state.notes.insert(PhoneNote(id: id, title: title, body: body,
                                     modifiedAt: now, pinned: false), at: 0)
        save()
        return id
    }

    func updateNote(_ id: String, title: String, body: String) {
        guard id != Self.tutorialNoteID, let index = state.notes.firstIndex(where: { $0.id == id }) else { return }
        state.notes[index].title = title
        state.notes[index].body = body
        state.notes[index].modifiedAt = Date()
        save()
    }

    func togglePin(_ id: String) {
        guard let index = state.notes.firstIndex(where: { $0.id == id }) else { return }
        state.notes[index].pinned.toggle()
        save()
    }

    func removeNote(_ id: String) {
        guard id != Self.tutorialNoteID else { return }
        state.notes.removeAll { $0.id == id }
        save()
    }

    /// Adds mundane continuity to the fictional world after significant clues.
    /// Only fires once. This never starts a second horror campaign.
    func reconcile(with game: GameStore) {
        guard game.state.clues.contains("photograph"),
              !state.flags.contains("noticed-elevator") else { return }
        state.flags.insert("noticed-elevator")
        append(NeighborMessage(id: "denise-update", thread: "denise",
            text: "Small update: the contractor hasn't signed off on the elevator work yet. If anything seems unusual, please let the office know.",
            fromPlayer: false, at: Date(), read: false))
        save()
    }

    private func append(_ value: NeighborMessage) {
        var list = state.threads[value.thread] ?? []
        if !list.contains(where: { $0.id == value.id }) {
            list.append(value)
            state.threads[value.thread] = list
        }
    }

    private func normalize(_ input: String) -> String {
        input.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    @discardableResult func completeRecoveryCircuit(verified: [[String]]) -> Bool {
        guard verified == RecoveryCircuit.stages, !state.flags.contains(RecoveryCircuit.completion) else { return false }
        state.flags.insert(RecoveryCircuit.completion)
        save()
        return true
    }

    @discardableResult func earnUtility(_ tool: LumaUtility, answer: String) -> Bool {
        guard LumaUtility.next(in: state.flags) == tool, tool.correct == answer else { return false }
        state.flags.insert(tool.flag); save(); return true
    }
    func visitWebRecord(_ id: String, now: Date = Date()) {
        guard let page = LumaWebCatalog.page(id), page.available(state.flags) else { return }
        guard state.flags.insert("web.visited." + page.id).inserted else { return }
        advanceInvestigation(now: now)
        save()
    }
    func inspectWebAttachment(_ id: String, now: Date = Date()) {
        guard LumaWebCatalog.attachments(in: state.flags).contains(id) else { return }
        if state.flags.insert("web.inspected." + id).inserted {
            advanceInvestigation(now: now); save()
        }
    }
    @discardableResult
    func submitWebReview(_ answer: String, now: Date = Date()) -> Bool {
        guard LumaWebCatalog.isReviewReady(state.flags),
              answer == "A copy may have a different import date from its original capture." else { return false }
        if state.flags.insert("investigation.chapter2.reviewed").inserted {
            advanceInvestigation(now:now); save()
        }
        return true
    }
    func advanceInvestigation(now: Date = Date()) {
        guard state.everydayArchiveRevision != nil,
              state.flags.contains("phone-tutorial-finished"),
              state.flags.contains("web.visited.studio") else { return }
        if state.flags.insert("investigation.contact.received").inserted {
            append(NeighborMessage(id: "unknown-intro-v1", thread: Neighbor.unknown.id,
                text: "Is this number working again? Before you trust anything on that phone, look at the studio's saved pages. Some of the records are not what they seem.",
                fromPlayer: false, at: now, read: false))
            save()
        }
        if state.flags.contains("investigation.chapter2.reviewed"),
           state.flags.contains("web.visited.archive-ledger"),
           state.flags.insert("investigation.chapter2.ledgerAcknowledged").inserted {
            append(NeighborMessage(id:"unknown-review-v2",thread:Neighbor.unknown.id,
                text:"You separated the copy from the original. Good. Keep that distinction in your notes. I still cannot tell you who made the first record.",
                fromPlayer:false,at:now,read:false))
            save()
        }
    }
    func storeSnippet(_ snippet: LumaSnippet) {
        guard LumaRecords.publicRecords(state).contains(snippet) else { return }
        var values = state.utilitySnippets ?? []
        values.removeAll { $0.id == snippet.id }
        values.insert(snippet, at: 0)
        state.utilitySnippets = Array(values.prefix(50)); save()
    }
    func removeSnippet(_ id: String) {
        state.utilitySnippets?.removeAll { $0.id == id }
        if state.pinnedSnippet == id { state.pinnedSnippet = nil }; save()
    }
    func pinSnippet(_ id: String?) {
        guard id == nil || (state.utilitySnippets ?? []).contains(where: { $0.id == id }) else { return }
        state.pinnedSnippet = id; save()
    }

    func recordCallAttempt(_ contact: Neighbor, now: Date = Date()) {
        var calls = state.callHistory ?? []
        calls.insert(LumaCallRecord(id: UUID(), contact: contact, date: now), at: 0)
        state.callHistory = Array(calls.prefix(100))
        save()
    }

    func toggleFavoriteContact(_ contact: Neighbor) {
        var ids = state.favoriteContacts ?? []
        if ids.contains(contact.id) { ids.removeAll { $0 == contact.id } }
        else { ids.append(contact.id) }
        state.favoriteContacts = ids
        save()
    }

    func restoreCheckpoint(_ replacement: PhoneWorld) throws {
        guard replacement.version == 1 else { throw CocoaError(.fileReadCorruptFile) }
        var replacement = replacement
        if storageURL == RestoredPhoneBackup.url || state.everydayArchiveRevision != nil { NoraEverydayArchive.expand(&replacement) }
        if persistToDisk {
            try FileManager.default.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(replacement).write(to: storageURL, options: .atomic)
        }
        visibleThread = nil
        state = replacement
    }

    private func save() {
        guard persistToDisk else { return }
        do {
            let dir = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: storageURL, options: .atomic)
        } catch {
            #if DEBUG
            print("LAST SEEN fictional world save error: \(error)")
            #endif
        }
    }
}
