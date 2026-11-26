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
    var attachments: [LumaMessageAttachment]? = nil
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
    enum Outcome:String,Codable {
        case noAnswer, ended
        var title:String {self == .noAnswer ? "No answer":"Call ended"}
    }
    let id: UUID
    let contact: Neighbor
    let date: Date
    // Optional for compatibility with existing historical attempts.
    var outcome:Outcome? = nil
    var outcomeTitle:String {outcome?.title ?? "Outgoing attempt"}
}
enum LumaPhoneDirectoryPolicy {
    static func canCall(_ contact:Neighbor,in world:PhoneWorld)->Bool {
        contact != .unknown && Neighbor.visible(in:world).contains(contact)
    }
    static func contacts(_ world:PhoneWorld,query:String="",favoritesOnly:Bool=false)->[Neighbor] {
        let q=query.trimmingCharacters(in:.whitespacesAndNewlines)
        return Neighbor.visible(in:world).filter {
            canCall($0,in:world) &&
            (!favoritesOnly || (world.favoriteContacts ?? []).contains($0.id)) &&
            (q.isEmpty || $0.name.localizedCaseInsensitiveContains(q) || $0.subtitle.localizedCaseInsensitiveContains(q))
        }.sorted{$0.name < $1.name}
    }
    static func recents(_ world:PhoneWorld,query:String="")->[LumaCallRecord] {
        let allowed=Set(contacts(world,query:query))
        return (world.callHistory ?? []).filter{allowed.contains($0.contact)}
            .sorted{$0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date > $1.date}
    }
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
    var connectedWorld: LumaConnectedState? = nil
    var relaySupport: RelaySupportHistory? = nil
}

/// This is a separate *fictional world save* while compatibility with existing
/// v1.0.x story data is maintained. It survives app restarts and story replays.
@MainActor
final class PhoneWorldStore: ObservableObject {
    @Published private(set) var state: PhoneWorld
    @Published var visibleThread: Neighbor? = nil
    private var supportGenerationEpoch = UUID()
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
    @discardableResult
    func recoverPrivatePhoto(_ id:String,authenticated:Bool)->Bool {
        guard authenticated,state.everydayArchiveRevision != nil,
              NoraPhotoCatalog.privateRecoveryEligible(id,flags:state.flags) else{return false}
        if state.flags.insert("nora-photo-unlocked-"+id).inserted {save()}
        return true
    }
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
    func sendReactive(to neighbor: Neighbor, text: String, now: Date = Date(), attachments: [LumaMessageAttachment] = []) -> Bool {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Neighbor.visible(in: state).contains(neighbor), (!clean.isEmpty || !attachments.isEmpty),
              text.count <= 2000, LumaMessageAttachmentCatalog.canSend(attachments, to: neighbor, world: state) else { return false }
        let pending = state.pendingReplies ?? []
        guard pending.filter({ $0.neighbor == neighbor }).count < 8 else { return false }
        let introductory = neighbor == .maya && tutorialStarted && !tutorialFinished
        let key = (introductory ? "phone-tutorial-custom-" : "custom-") + UUID().uuidString
        let thread = state.threads[neighbor.id] ?? []
        let reactiveReplies = thread.filter { !$0.fromPlayer && ($0.id.hasPrefix("custom-") || $0.id.hasPrefix("phone-tutorial-custom-")) }
        let waiting = pending.filter { $0.neighbor == neighbor }
        let lastReply = waiting.last?.text ?? reactiveReplies.last?.text
        let previousMessage = thread.last(where: { $0.fromPlayer && $0.receiptTracked == true })?.text
        let recent = Array((reactiveReplies.map(\.text) + waiting.map(\.text)).suffix(6))
        let plan = clean.isEmpty
            ? PhoneReplyPlan(text: "I've received the attachment. What would you like me to know about it?")
            : PhoneReplyPolicy.plan(for: neighbor, text: text, flags: state.flags,
                                         tutorialStarted: tutorialStarted, tutorialFinished: tutorialFinished, previousReply: lastReply,
                                         previousMessage: previousMessage, recentReplies: recent)
        let previous = pending.filter { $0.neighbor == neighbor }.map(\.dueAt).max() ?? now
        let base = max(now, previous)
        let recentExchange = reactiveReplies.last.map {
            let elapsed = now.timeIntervalSince($0.at)
            return elapsed >= 0 && elapsed <= 90
        } ?? false
        let timing = PhoneReplyTiming.window(neighbor: neighbor, text: plan.text, introductory: introductory,
                                             everyday: plan.everyday, now: now, recentExchange: recentExchange,
                                             alreadyWaiting: !waiting.isEmpty)
        let readAt = base.addingTimeInterval(timing.read)
        let typingAt = base.addingTimeInterval(timing.typing)
        let due = base.addingTimeInterval(timing.due)
        let displayText = clean.isEmpty ? (attachments.count == 1 ? "Attachment" : "\(attachments.count) attachments") : text
        append(NeighborMessage(id: key, thread: neighbor.id, text: displayText, fromPlayer: true,
                               at: now, read: true, receiptTracked: true, attachments: attachments.isEmpty ? nil : attachments))
        state.pendingReplies = pending + [PhonePendingReply(id: key + "-response", outgoingID: key,
            neighbor: neighbor, text: plan.text, readAt: readAt, dueAt: due, startsTutorial: plan.startsTutorial, typingAt: typingAt)]
        save()
        return true
    }

    func hasPendingReply(_ neighbor: Neighbor) -> Bool {
        (state.pendingReplies ?? []).contains { $0.neighbor == neighbor }
    }

    func isTyping(_ neighbor: Neighbor, now: Date = Date()) -> Bool {
        (state.pendingReplies ?? []).contains { $0.neighbor == neighbor && ($0.typingAt ?? $0.readAt) <= now && now < $0.dueAt }
    }

    func advancePendingReplies(now: Date = Date()) {
        advanceInvestigation(now: now)
        advanceConnectedMail(now: now)
        advanceSocialReplies(now: now)
        advanceCommunityActivity(now: now)
        advanceDayblink(now: now)
        let priorHavenDelivered=connected.havenEvent?.delivered == true
        advanceHavenWatch(now: now)
        advanceHavenFollowup(now: now,priorJustDelivered:!priorHavenDelivered && connected.havenEvent?.delivered == true)
        advanceMotionwell(now: now)
        advanceCharacterCheckIns(now:now)
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
        let due = pending.filter { $0.dueAt <= now }.sorted { ($0.dueAt, $0.id) < ($1.dueAt, $1.id) }
        for item in due {
            if item.startsTutorial && tutorialStarted && !state.flags.contains("phone-tutorial-replied") {
                state.flags.insert("phone-tutorial-replied")
                tutorialMessage("notes", item.text, now: now)
                advanceTutorial(now: now.addingTimeInterval(0.1))
                state.flags = NoraPhotoCatalog.discoveryFlags(from: state.flags)
            } else {
                let text = currentPendingReplyText(item)
                append(NeighborMessage(id: item.id, thread: item.neighbor.id, text: text,
                                       fromPlayer: false, at: item.dueAt, read: false))
            }
            changed = true
        }
        if !due.isEmpty {
            let ids = Set(due.map(\.id))
            state.pendingReplies = pending.filter { !ids.contains($0.id) }
        }
        if changed { save() }
    }

    /// Schedule only finite eligible events, and deliver at most one per tick.
    /// Never interrupt a reply or an unread tutorial instruction.
    func advanceCharacterCheckIns(now:Date=Date()) {
        guard state.everydayArchiveRevision != nil else{return}
        var c=connected
        var pending=CharacterCheckIns.scheduled(in:state,now:now)
        let due=pending.filter{$0.dueAt<=now}.sorted{($0.dueAt,$0.id)<($1.dueAt,$1.id)}
        if !due.isEmpty, CharacterCheckIns.foregroundPriority(in:state,now:now) {
            // Keep every overdue optional event out of the regular-reply tick.
            // Preserve future deadlines, and do not save again until a retry is due.
            pending=pending.map{$0.dueAt<=now ? .init(id:$0.id,dueAt:now.addingTimeInterval(15)):$0}
        } else if let entry=due.first,
           let event=CharacterCheckIns.events.first(where:{$0.id==entry.id}),
           CharacterCheckIns.eligible(event,in:state),
           !CharacterCheckIns.blocked(event,in:state) {
            append(NeighborMessage(id:event.id,thread:event.contact.id,text:event.text,fromPlayer:false,at:now,read:false))
            pending.removeAll{$0.id==entry.id}
            // Avoid catch-up bursts if several messages matured off-screen.
            pending=pending.map{.init(id:$0.id,dueAt:max($0.dueAt,now.addingTimeInterval(35)))}
        } else if let entry=due.first {
            // A normal conversation takes precedence. Reconsider later without
            // continually saving the same blocked event each timer tick.
            pending=pending.map{$0.id==entry.id ? .init(id:$0.id,dueAt:now.addingTimeInterval(15)):$0}
        }
        guard (c.characterCheckIns ?? []) != pending else{return}
        c.characterCheckIns=pending
        commitConnected(c)
    }

    private func currentPendingReplyText(_ item: PhonePendingReply) -> String {
        // Keep ordinary authored replies stable; only reevaluate those whose
        // speaker's knowledge or service state has changed since composition.
        guard let outgoing = state.threads[item.neighbor.id]?.first(where: { $0.id == item.outgoingID && $0.fromPlayer }) else { return item.text }
        if item.neighbor == .unknown && state.flags.contains("web.visited." + InvestigationResolution.indexID) {
            return PhoneReplyPolicy.plan(for: item.neighbor, text: outgoing.text, flags: state.flags,
                                         tutorialStarted: tutorialStarted, tutorialFinished: tutorialFinished).text
        }
        if item.neighbor == .maya && state.flags.contains(InvestigationResolution.read) {
            let words = PhoneEverydayConversation.words(outgoing.text)
            if !words.isDisjoint(with: ["nora","missing","where","safe","disappeared","location","address"]) {
                return PhoneReplyPolicy.plan(for: item.neighbor, text: outgoing.text, flags: state.flags,
                                             tutorialStarted: tutorialStarted, tutorialFinished: tutorialFinished).text
            }
        }
        return item.text
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
        guard LumaWebCatalog.visitedAttachments(in:state.flags).contains(id) else { return }
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
    func recordInvestigationMailRead(_ id: String) {
        guard LumaMailCatalog.visible(state).contains(where: { $0.id == id && $0.kind == "inbox" }) else { return }
        if id == InvestigationReview.mailID, InvestigationReview.availableMail(state) {
            if state.flags.insert(InvestigationReview.read).inserted { save() }
        } else if id == InvestigationResolution.mailID, InvestigationResolution.availableMail(state) {
            if state.flags.insert(InvestigationResolution.read).inserted { save() }
        }
    }
    func setInvestigationReviewChoice(_ id: String, value: Int) {
        guard InvestigationReview.ready(state), !state.flags.contains(InvestigationReview.finished),
              InvestigationReview.items.contains(where: { $0.id == id }),
              value == -1 || InvestigationReview.classifications.indices.contains(value) else { return }
        var c = connected
        var choices = InvestigationReview.visibleSelection(state)
        if value == -1 { choices.removeValue(forKey: id) } else { choices[id] = value }
        c.investigationReviewSelection = choices
        commitConnected(c)
    }
    @discardableResult
    func completeInvestigationReview(now: Date = Date()) -> Bool {
        guard InvestigationReview.ready(state), InvestigationReview.valid(InvestigationReview.visibleSelection(state)) else { return false }
        if state.flags.insert(InvestigationReview.finished).inserted {
            append(NeighborMessage(id: "local-review-followup-03", thread: Neighbor.unknown.id,
                text: "You are being careful with what the records actually say. Keep doing that. A supported observation is not the same as an explanation.",
                fromPlayer: false, at: now, read: false))
            save()
        }
        return true
    }
    @discardableResult
    func finishInvestigation(_ choice: InvestigationResolution.Choice, now: Date = Date()) -> Bool {
        guard InvestigationResolution.ready(state) else { return false }
        if state.flags.contains(InvestigationResolution.completed) {
            return InvestigationResolution.ending(state) == choice
        }
        var c = connected
        c.investigationDisposition = choice
        let outgoing = choice == .minimal
            ? "The repeated activity belongs to the local rehearsal. The original image capture and present location are not established. No private records are included."
            : "The repair review is complete. I'm keeping the private records local."
        append(NeighborMessage(id: "local-resolution-out", thread: Neighbor.maya.id, text: outgoing, fromPlayer: true, at: now, read: true))
        append(NeighborMessage(id: "local-resolution-in", thread: Neighbor.maya.id, text: InvestigationResolution.message(choice), fromPlayer: false, at: now.addingTimeInterval(1), read: false))
        state.flags.insert(InvestigationResolution.completed)
        commitConnected(c)
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
        if InvestigationReview.eligible(state) {
            reconcileInvestigationMail(id: InvestigationReview.mailID, requested: InvestigationReview.requested,
                                       delay: 25, now: now, make: InvestigationReview.mail(at:))
        }
        if InvestigationResolution.eligible(state),
           state.flags.contains("web.visited." + InvestigationResolution.indexID),
           state.flags.contains("web.visited." + InvestigationResolution.noteID) {
            reconcileInvestigationMail(id: InvestigationResolution.mailID, requested: InvestigationResolution.requested,
                                       delay: 12, now: now, make: InvestigationResolution.mail(at:))
        }
    }

    /// Reconcile only an already eligible authored event. An older or interrupted
    /// checkpoint can have a request flag but no queued record. Never grant a
    /// read/completion flag here, reset an existing deadline, or replay delivered mail.
    private func reconcileInvestigationMail(id: String, requested: String, delay: TimeInterval,
                                            now: Date, make: (Date) -> LumaMailRecord) {
        var c = connected
        let delivered = c.mail.contains { $0.id == id && $0.kind == "inbox" }
        let queued = c.pendingMail.contains { $0.record.id == id }
        let inserted = state.flags.insert(requested).inserted
        if !delivered && !queued {
            let due = now.addingTimeInterval(delay)
            c.pendingMail.append(.init(record: make(due), dueAt: due))
            commitConnected(c)
        } else if inserted {
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

    @discardableResult
    func recordCallAttempt(_ contact: Neighbor, now: Date = Date()) -> UUID? {
        guard LumaPhoneDirectoryPolicy.canCall(contact,in:state) else{return nil}
        let id=UUID()
        var calls = state.callHistory ?? []
        calls.insert(LumaCallRecord(id:id,contact:contact,date:now), at:0)
        state.callHistory = Array(calls.prefix(100))
        save()
        return id
    }

    func finishCallAttempt(_ id:UUID,outcome:LumaCallRecord.Outcome) {
        guard var calls=state.callHistory,
              let index=calls.firstIndex(where:{$0.id==id}),
              calls[index].outcome==nil,
              LumaPhoneDirectoryPolicy.canCall(calls[index].contact,in:state) else{return}
        calls[index].outcome=outcome
        state.callHistory=calls
        save()
    }

    func toggleFavoriteContact(_ contact: Neighbor) {
        guard LumaPhoneDirectoryPolicy.canCall(contact,in:state) else{return}
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
        supportGenerationEpoch = UUID()
        state = replacement
    }

    // All connected-app changes use the same world persistence and checkpoint path.
    var connected: LumaConnectedState { state.connectedWorld ?? LumaConnectedState() }
    func beginRelaySupport(installed: String, now: Date = Date()) {
        guard RelaySupportAccess.available(installed: installed, flags: state.flags),
              state.relaySupport == nil else { return }
        state.relaySupport = RelaySupportHistory(messages: [
            .init(id: "support-welcome", text: "Hey, I'm Alex. This is your own support space, separate from the restored owner's conversations. Ask me about Relay, Patchline or the recovery tools.", at: now, outgoing: false)
        ], seenIDs: [], notifiedIDs: [], activeInstallation: true)
        save()
    }

    func setRelaySupportPreferences(notifications: Bool? = nil, previews: Bool? = nil, installed: String) {
        guard RelaySupportAccess.available(installed: installed, flags: state.flags),
              var history = state.relaySupport else { return }
        if let notifications { history.notificationsEnabled = notifications }
        if let previews { history.previewsEnabled = previews }
        guard history != state.relaySupport else { return }
        state.relaySupport = history
        save()
    }

    func markRelaySupportRead(installed: String) {
        guard RelaySupportAccess.available(installed: installed, flags: state.flags),
              var history = state.relaySupport else { return }
        let ids = Set(history.messages.filter { !$0.outgoing }.map(\.id))
        guard history.seenIDs != ids else { return }
        history.seenIDs = ids
        history.notifiedIDs = (history.notifiedIDs ?? []).union(ids)
        state.relaySupport = history
        save()
    }

    /// Only actual incoming support messages are eligible. Existing saves are
    /// baselined on migration, so importing old chat does not replay alerts.
    func advanceRelaySupportActivity(installed: String, now: Date = Date()) {
        let active = RelaySupportAccess.available(installed: installed, flags: state.flags)
        if active { beginRelaySupport(installed: installed, now: now) }
        guard var history = state.relaySupport else { return }
        let original = history
        let incoming = history.messages.filter { !$0.outgoing }
        let all = Set(incoming.map(\.id))
        history.activeInstallation = active
        if history.seenIDs == nil { history.seenIDs = all }
        if history.notifiedIDs == nil { history.notifiedIDs = all }
        var value = connected
        var changedJournal = false
        if !active {
            // Preserve the chat but retire old notification delivery on uninstall.
            // Reinstall must not replay the previous installation's alerts.
            history.notifiedIDs = (history.notifiedIDs ?? []).union(all)
            if var notices = value.activityJournal {
                for index in notices.indices where notices[index].kind == .support && !notices[index].dismissed {
                    notices[index].dismissed = true
                    changedJournal = true
                }
                if changedJournal { value.activityJournal = notices }
            }
        }
        if active {
            for message in incoming where !(history.seenIDs ?? []).contains(message.id) &&
                !(history.notifiedIDs ?? []).contains(message.id) &&
                now.timeIntervalSince(message.at) >= 2 {
                history.notifiedIDs?.insert(message.id)
                guard history.notificationsEnabled ?? true else { continue }
                addActivity(.init(id: "relay-support-" + message.id, kind: .support, date: now,
                    title: "Alex Morgan", detail: String(message.text.prefix(160)), targetID: message.id,
                    channel: nil, author: nil), to: &value)
                changedJournal = true
            }
        }
        guard history != original || changedJournal else { return }
        state.relaySupport = history
        if changedJournal { state.connectedWorld = value }
        save()
    }

    @discardableResult
    func sendRelaySupport(_ raw: String, installed: String, sources: String, now: Date = Date(), attachments: [LumaMessageAttachment] = []) -> Bool {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard RelaySupportAccess.available(installed: installed, flags: state.flags),
              (!text.isEmpty || !attachments.isEmpty), raw.count <= 2000,
              RelaySupportAttachmentPolicy.canSend(attachments, world: state) else { return false }
        beginRelaySupport(installed: installed, now: now)
        guard var history = state.relaySupport else { return false }
        let provider = RelaySupportLocalProvider()
        let answer: RelaySupportAnswer
        if !attachments.isEmpty {
            answer = RelaySupportDocumentContext.localAnswer(items: attachments, question: text, world: state)
        } else {
            answer = provider.reply(question: text, recent: Array(history.messages.suffix(12)), flags: state.flags, sources: sources, installed: installed)
        }
        let displayText = text.isEmpty ? "Shared attachment" : text
        history.messages.append(.init(id: UUID().uuidString, text: displayText, at: now, outgoing: true,
                                      attachments: attachments.isEmpty ? nil : attachments))
        history.messages.append(.init(id: UUID().uuidString, text: answer.text, at: now, outgoing: false,
                                      guideID: answer.guideID.flatMap { RelaySupportKnowledge.generalGuide($0)?.id },
                                      packageID: answer.packageID))
        state.relaySupport = history
        save()
        return true
    }

    func relaySupportPhotoRequest(_ item: LumaMessageAttachment, installed: String) -> RelaySupportPhotoRequest? {
        guard item.kind == .photo, RelaySupportAccess.available(installed: installed, flags: state.flags),
              RelaySupportAttachmentPolicy.canRead(item, world: state),
              let message = state.relaySupport?.messages.last(where: { $0.outgoing && ($0.attachments ?? []).contains(item) }) else { return nil }
        let request = RelaySupportPhotoRequest(epoch: supportGenerationEpoch, messageID: message.id, item: item)
        guard !(state.relaySupport?.messages ?? []).contains(where: { $0.photoAnalysisKey == request.key }) else { return nil }
        return request
    }

    @discardableResult
    func finishRelaySupportPhoto(_ request: RelaySupportPhotoRequest, labels: [String], installed: String, now: Date = Date()) -> Bool {
        guard request.epoch == supportGenerationEpoch,
              RelaySupportAccess.available(installed: installed, flags: state.flags),
              request.item.kind == .photo, RelaySupportAttachmentPolicy.canRead(request.item, world: state),
              RelaySupportPhotoAnalysis.valid(labels),
              var history = state.relaySupport,
              history.messages.contains(where: { $0.outgoing && $0.id == request.messageID && ($0.attachments ?? []).contains(request.item) }),
              !history.messages.contains(where: { $0.photoAnalysisKey == request.key }) else { return false }
        history.messages.append(.init(id: UUID().uuidString, text: RelaySupportPhotoAnalysis.reply(labels), at: now,
                                      outgoing: false, photoAnalysisKey: request.key))
        state.relaySupport = history
        save()
        return true
    }

    func relaySupportGenerationRequest(installed: String, sources: String) -> RelaySupportGenerationRequest? {
        guard RelaySupportAccess.available(installed: installed, flags: state.flags),
              let messages = state.relaySupport?.messages, messages.count >= 2 else { return nil }
        let reply = messages[messages.count - 1], question = messages[messages.count - 2]
        return RelaySupportGenerationRequest.prepare(question: question, fallback: reply,
            recent: Array(messages.dropLast(2).suffix(8)), flags: state.flags, installed: installed,
            sources: sources, epoch: supportGenerationEpoch,
            sharedDocuments: RelaySupportDocumentContext.excerpts(items: question.attachments ?? [], question: question.text, world: state))
    }

    @discardableResult
    func finishRelaySupportGeneration(_ request: RelaySupportGenerationRequest, text: String, installed: String, sources: String) -> Bool {
        guard request.epoch == supportGenerationEpoch, request.flags == state.flags,
              request.installed == installed, request.sources == sources,
              RelaySupportAccess.available(installed: installed, flags: state.flags),
              var history = state.relaySupport, history.messages.count >= 2,
              history.messages.last?.id == request.replyID,
              history.messages.last?.generatedOnDevice != true,
              history.messages[history.messages.count - 2].id == request.questionID,
              RelaySupportGenerationRequest.accepts(text, flags: state.flags, sources: sources, installed: installed) else { return false }
        let old = history.messages.removeLast()
        history.messages.append(.init(id: old.id, text: text.trimmingCharacters(in: .whitespacesAndNewlines), at: old.at,
            outgoing: false, guideID: old.guideID, packageID: old.packageID, generatedOnDevice: true))
        state.relaySupport = history
        save()
        return true
    }

    @discardableResult
    func shareRelaySupportDiagnostic(_ report: RelaySupportDiagnostic, installed: String, versions: String, sources: String, safeMode: Bool, now: Date = Date()) -> Bool {
        guard RelaySupportAccess.available(installed: installed, flags: state.flags),
              let current = RelaySupportDiagnostic.capture(packageID: report.packageID, installed: installed, versions: versions,
                                                            sources: sources, safeMode: safeMode, flags: state.flags),
              current == report else { return false }
        beginRelaySupport(installed: installed, now: now)
        guard var history = state.relaySupport else { return false }
        history.messages.append(.init(id: UUID().uuidString, text: "Shared package diagnostics", at: now, outgoing: true, diagnostic: report))
        history.messages.append(.init(id: UUID().uuidString, text: report.advice, at: now, outgoing: false,
                                      guideID: RelaySupportKnowledge.generalGuide("patchline-recovery")?.id, packageID: report.packageID))
        state.relaySupport = history
        save()
        return true
    }

    private func commitConnected(_ value:LumaConnectedState) {
        state.connectedWorld=value; save()
    }
    @discardableResult
    func saveMailDraft(id:String?, peer:Neighbor, subject:String, body:String, now:Date=Date()) -> String? {
        guard state.everydayArchiveRevision != nil, LumaMailCatalog.recipients(state).contains(peer),
              subject.count <= 200, body.count <= 4000 else { return nil }
        var c=connected
        let key=id ?? UUID().uuidString
        if let id {
            guard c.mail.contains(where:{$0.id==id && $0.kind=="draft"}) else{return nil}
        }
        if let old=c.mail.first(where:{$0.id==key}), old.kind != "draft" { return nil }
        guard c.mail.count < 250 || c.mail.contains(where:{$0.id==key}) else { return nil }
        c.mail.removeAll{$0.id==key}
        c.mailFolders.removeValue(forKey:key)
        c.mail.append(LumaMailRecord(id:key,peer:peer.id,sender:"Repair desk",subject:subject,body:body,date:now,kind:"draft"))
        commitConnected(c); return key
    }
    @discardableResult
    func sendConnectedMail(draftID:String?, peer:Neighbor, subject:String, body:String, now:Date=Date()) -> Bool {
        let subject=subject.trimmingCharacters(in:.whitespacesAndNewlines)
        let body=body.trimmingCharacters(in:.whitespacesAndNewlines)
        guard state.everydayArchiveRevision != nil,LumaMailCatalog.recipients(state).contains(peer),
              !subject.isEmpty,!body.isEmpty,subject.count<=200,body.count<=4000 else { return false }
        var c=connected
        guard c.mail.count+c.pendingMail.count<248,c.pendingMail.count<12 else { return false }
        if let draftID {
            guard c.mail.contains(where:{$0.id==draftID && $0.kind=="draft"}) else{return false}
            c.mail.removeAll{$0.id==draftID}
            c.mailFolders.removeValue(forKey:draftID)
        }
        let id=UUID().uuidString
        c.mail.append(LumaMailRecord(id:id,peer:peer.id,sender:"Repair desk",subject:subject,body:body,date:now,kind:"sent"))
        let due=now.addingTimeInterval(peer == .denise ? 45 : 30)
        let answer=LumaMailCatalog.response(to:peer,subject:subject,body:body)
        let reply=LumaMailRecord(id:"reply-"+id,peer:peer.id,sender:peer.name,subject:subject.hasPrefix("Re:") ? subject : "Re: "+subject,body:answer,date:due,kind:"inbox")
        c.pendingMail.append(LumaPendingMail(record:reply,dueAt:due))
        commitConnected(c); return true
    }
    func advanceConnectedMail(now:Date=Date()) {
        guard state.connectedWorld != nil else {return}
        var c=connected
        let due=c.pendingMail.filter{$0.dueAt<=now}
        guard !due.isEmpty else{return}
        for entry in due where !c.mail.contains(where:{$0.id==entry.record.id}) {
            if entry.record.id == InvestigationReview.mailID && !InvestigationReview.availableMail(state) { continue }
            if entry.record.id == InvestigationResolution.mailID && !InvestigationResolution.availableMail(state) { continue }
            c.mail.append(entry.record)
            addActivity(.init(id: "mail-" + entry.record.id, kind: .mail, date: entry.dueAt, title: entry.record.sender, detail: entry.record.subject, targetID: entry.record.id, channel: nil, author: nil), to: &c)
        }
        c.pendingMail.removeAll{$0.dueAt<=now}
        commitConnected(c)
    }
    func moveConnectedMail(_ id:String,folder:String) {
        guard ["archive","trash","original"].contains(folder),
              LumaMailCatalog.visible(state).contains(where:{$0.id==id}) else{return}
        var c=connected
        if folder=="original" {c.mailFolders.removeValue(forKey:id)}
        else {c.mailFolders[id]=folder}
        commitConnected(c)
    }
    private func addActivity(_ notice: LumaActivityNotice, to value: inout LumaConnectedState) {
        var journal = value.activityJournal ?? []
        guard !journal.contains(where: { $0.id == notice.id }) else { return }
        journal.append(notice)
        value.activityJournal = Array(journal.suffix(200))
    }
    func dismissActivity(_ id: String) {
        var value = connected
        guard let index = value.activityJournal?.firstIndex(where: { $0.id == id }) else { return }
        value.activityJournal?[index].dismissed = true
        commitConnected(value)
    }
    func recordTimerActivity(end: Double) {
        guard end.isFinite, end > 0 else { return }
        var value = connected
        addActivity(.init(id: "timer-" + String(end), kind: .timer, date: Date(timeIntervalSince1970: end), title: "Timer finished", detail: "Your timer has ended.", targetID: nil, channel: nil, author: nil), to: &value)
        commitConnected(value)
    }
    func advanceCommunityActivity(now: Date = Date()) {
        guard state.everydayArchiveRevision != nil else { return }
        var value = connected
        var activity = value.communityActivity ?? LumaCommunityActivityState(start: now)
        for release in LumaCommunityActivity.releases {
            guard now.timeIntervalSince(activity.start) >= release.delay,
                  let authored = LumaCommunityActivity.post(release, start: activity.start) else { continue }
            if !activity.posts.contains(where: { $0.id == authored.id }) {
                activity.posts.append(authored)
                let prefs = value.socialPreferences?[authored.channel.rawValue] ?? LumaSocialPreferences()
                if prefs.notificationsEnabled, prefs.followedPostAlerts ?? true,
                   value.follows.contains(authored.channel.rawValue + "|" + authored.author),
                   !prefs.mutedAuthors.contains(authored.author) {
                    addActivity(.init(id: "community-post-" + authored.id, kind: .social, date: now,
                        title: authored.author + " posted", detail: authored.body, targetID: authored.id,
                        channel: authored.channel, author: authored.author), to: &value)
                }
            }
            if now.timeIntervalSince(activity.start) >= release.delay + release.replyDelay,
               let stored = activity.posts.first(where: { $0.id == authored.id }),
               let reply = LumaCommunityActivity.reply(release, post: stored, start: activity.start),
               !activity.comments.contains(where: { $0.id == reply.id }) {
                activity.comments.append(reply)
            }
        }
        guard value.communityActivity != activity else { return }
        value.communityActivity = activity
        commitConnected(value)
    }

    func advanceSocialReplies(now: Date = Date()) {
        var value = connected
        let pending = value.pendingSocialReplies ?? []
        let due = pending.filter { $0.dueAt <= now }.sorted { ($0.dueAt, $0.reply.id) < ($1.dueAt, $1.reply.id) }
        guard !due.isEmpty else { return }
        for event in due {
            guard value.comments.count < 300,
                  !value.comments.contains(where: { $0.id == event.reply.id }),
                  LumaSocialCatalog.visible(event.channel, world: state).contains(where: { $0.id == event.reply.postID }) else { continue }
            value.comments.append(event.reply)
            let prefs = value.socialPreferences?[event.channel.rawValue] ?? LumaSocialPreferences()
            if prefs.notificationsEnabled && !prefs.mutedAuthors.contains(event.reply.author) {
                addActivity(.init(id: "social-" + event.reply.id, kind: .social, date: event.dueAt, title: event.reply.author + " replied", detail: event.reply.body, targetID: event.reply.postID, channel: event.channel, author: event.reply.author), to: &value)
            }
        }
        let delivered = Set(due.map { $0.reply.id })
        value.pendingSocialReplies = pending.filter { !delivered.contains($0.reply.id) }
        commitConnected(value)
    }
    func setDayblinkNotificationSettings(enabled: Bool, previews: Bool) {
        guard state.everydayArchiveRevision != nil else { return }
        var c = connected
        var d = c.dayblink ?? DayblinkState()
        d.notificationsEnabled = enabled; d.previewsEnabled = previews
        c.dayblink = d; commitConnected(c)
    }
    func setDayblinkMuted(_ friend: DayblinkFriend, muted: Bool) {
        guard state.everydayArchiveRevision != nil else { return }
        var c = connected
        var d = c.dayblink ?? DayblinkState()
        if muted { d.muted.insert(friend) } else { d.muted.remove(friend) }
        c.dayblink = d; commitConnected(c)
    }
    @discardableResult
    func openDayblink(_ id: String, friend: DayblinkFriend) -> Bool {
        var c = connected
        var d = c.dayblink ?? DayblinkState()
        guard let record = DayblinkArchive.records(state, friend: friend).first(where: { $0.id == id }),
              record.temporary, DayblinkArchive.image(for: record, state: d) != nil else { return false }
        d.opened.insert(id)
        c.dayblink = d
        if let index = c.activityJournal?.firstIndex(where: { $0.id == "dayblink-" + id }) { c.activityJournal?[index].dismissed = true }
        commitConnected(c)
        return true
    }
    @discardableResult
    func sendDayblink(friend: DayblinkFriend, text: String, now: Date = Date(), image: String? = nil) -> Bool {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard state.everydayArchiveRevision != nil, (!clean.isEmpty || image != nil), clean.count <= 500,
              image.map({ DayblinkArchive.publicImages.contains($0) }) ?? true else { return false }
        var c = connected
        var d = c.dayblink ?? DayblinkState()
        guard d.messages.count + d.pending.count < 198 else { return false }
        let id = UUID().uuidString
        let prior = d.messages.filter { $0.friend == friend && $0.id.hasPrefix("dayblink-reply-") }
        let waiting = d.pending.contains { $0.record.friend == friend }
        let recent = prior.contains { now.timeIntervalSince($0.date) < 45 }
        d.messages.append(.init(id: id, friend: friend, sender: "Repair desk", text: clean.isEmpty ? "Shared picture" : clean, date: now, image: image))
        if !waiting, !recent, let pending = DayblinkArchive.pendingReply(friend: friend, text: clean, id: id, now: now, previousCount: prior.count, sharedImage: image) {
            d.pending.append(pending)
        }
        c.dayblink = d; commitConnected(c)
        return true
    }
    func markDayblinkStoryViewed(_ id: String) {
        guard DayblinkArchive.activeStories(state).contains(where: { $0.id == id }),
              var d = connected.dayblink, !(d.viewedStories ?? []).contains(id) else { return }
        var c = connected
        d.viewedStories = (d.viewedStories ?? []).union([id])
        c.dayblink = d; commitConnected(c)
    }

    func advanceDayblink(now: Date = Date()) {
        guard state.everydayArchiveRevision != nil else { return }
        var c = connected
        var d = c.dayblink ?? DayblinkState()
        let original = d
        if d.storyStart == nil { d.storyStart = now }
        if let start = d.storyStart {
            var stories = d.stories ?? []
            for var story in DayblinkArchive.stories(start: start) where story.published <= now && !stories.contains(where: { $0.id == story.id }) {
                story.expired = story.expires <= now
                stories.append(story)
            }
            for i in stories.indices where stories[i].expires <= now { stories[i].expired = true }
            d.stories = stories
        }
        let due = d.pending.filter { $0.due <= now }.sorted { ($0.due, $0.record.id) < ($1.due, $1.record.id) }
        for event in due where !d.messages.contains(where: { $0.id == event.record.id }) {
            d.messages.append(event.record)
            if d.notificationsEnabled && !d.muted.contains(event.record.friend) {
                addActivity(.init(id: "dayblink-" + event.record.id, kind: .dayblink, date: event.due, title: event.record.friend.name, detail: "Sent a visual message", targetID: event.record.id, channel: nil, author: event.record.friend.id), to: &c)
            }
        }
        let delivered = Set(due.map { $0.record.id })
        d.pending.removeAll { delivered.contains($0.record.id) }
        guard d != original else { return }
        c.dayblink = d; commitConnected(c)
    }
    func advanceMotionwell(now: Date = Date()) {
        guard state.everydayArchiveRevision != nil else { return }
        var c = connected
        var m = c.motionwell ?? MotionwellState()
        let original = m
        if m.publicationStart == nil { m.publicationStart = now }
        guard let start = m.publicationStart else { return }
        for upload in MotionwellArchive.scheduled where now.timeIntervalSince(start) >= upload.delay &&
            !(m.published ?? []).contains(upload.clip.id) && upload.clip.url != nil {
            m.published = (m.published ?? []).union([upload.clip.id])
            if m.notificationsEnabled, m.subscriptions.contains(upload.clip.handle),
               !(m.mutedChannels ?? []).contains(upload.clip.handle) {
                addActivity(.init(id: "motionwell-" + upload.clip.id, kind: .motionwell,
                    date: now, title: upload.clip.creator, detail: upload.clip.title,
                    targetID: upload.clip.id, channel: nil, author: upload.clip.handle), to: &c)
            }
        }
        guard m != original else { return }
        c.motionwell = m; commitConnected(c)
    }

    func setMotionwellChannelAlerts(_ handle: String, enabled: Bool) {
        guard state.everydayArchiveRevision != nil,
              var m = connected.motionwell, m.subscriptions.contains(handle) else { return }
        var c = connected
        var muted = m.mutedChannels ?? []
        if enabled { muted.remove(handle) } else { muted.insert(handle) }
        m.mutedChannels = muted
        c.motionwell = m
        if !enabled {
            for i in (c.activityJournal ?? []).indices where c.activityJournal?[i].kind == .motionwell &&
                c.activityJournal?[i].author == handle {
                c.activityJournal?[i].dismissed = true
            }
        }
        commitConnected(c)
    }

    func markMotionwellUploadSeen(_ id: String) {
        guard var m = connected.motionwell, m.published?.contains(id) == true,
              !(m.seenUploads ?? []).contains(id),
              MotionwellArchive.visible(state).contains(where: { $0.id == id }) else { return }
        var c = connected
        m.seenUploads = (m.seenUploads ?? []).union([id])
        c.motionwell = m; commitConnected(c)
    }

    func toggleMotionwellSubscription(_ handle: String) {
        guard MotionwellArchive.visible(state).contains(where: { $0.handle == handle }) else { return }
        var c = connected
        var m = c.motionwell ?? MotionwellState()
        if !m.subscriptions.insert(handle).inserted {
            m.subscriptions.remove(handle)
            for i in (c.activityJournal ?? []).indices where c.activityJournal?[i].kind == .motionwell &&
                c.activityJournal?[i].author == handle {
                c.activityJournal?[i].dismissed = true
            }
        }
        c.motionwell = m; commitConnected(c)
    }
    func toggleMotionwellItem(_ id: String, saved: Bool) {
        guard MotionwellArchive.visible(state).contains(where: { $0.id == id }) else { return }
        var c = connected
        var m = c.motionwell ?? MotionwellState()
        if saved {
            if !m.saved.insert(id).inserted { m.saved.remove(id) }
        } else {
            if !m.likes.insert(id).inserted { m.likes.remove(id) }
        }
        c.motionwell = m; commitConnected(c)
    }
    func recordMotionwellWatch(_ id: String, seconds: Double, now: Date = Date()) {
        guard let clip = MotionwellArchive.visible(state).first(where: { $0.id == id }), seconds.isFinite, seconds >= 0 else { return }
        var c = connected
        var m = c.motionwell ?? MotionwellState()
        m.watch[id] = .init(seconds: min(Double(clip.seconds), seconds), lastWatched: now)
        c.motionwell = m; commitConnected(c)
    }
    func clearMotionwellHistory() {
        guard state.everydayArchiveRevision != nil else { return }
        var c = connected
        var m = c.motionwell ?? MotionwellState()
        m.watch.removeAll()
        c.motionwell = m; commitConnected(c)
    }
    @discardableResult
    func addMotionwellComment(_ id: String, text: String, now: Date = Date()) -> Bool {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard MotionwellArchive.visible(state).contains(where: { $0.id == id }), !clean.isEmpty, clean.count <= 500 else { return false }
        var c = connected
        var m = c.motionwell ?? MotionwellState()
        guard m.comments.count < 200 else { return false }
        m.comments.append(.init(id: UUID().uuidString, clipID: id, body: clean, date: now))
        c.motionwell = m; commitConnected(c); return true
    }
    func setMotionwellNotifications(enabled: Bool, previews: Bool) {
        guard state.everydayArchiveRevision != nil else { return }
        var c = connected
        var m = c.motionwell ?? MotionwellState()
        m.notificationsEnabled = enabled; m.previewsEnabled = previews
        if !enabled {
            for i in (c.activityJournal ?? []).indices where c.activityJournal?[i].kind == .motionwell {
                c.activityJournal?[i].dismissed = true
            }
        }
        c.motionwell = m; commitConnected(c)
    }
    func advanceHavenWatch(now: Date = Date()) {
        guard HavenWatchEvents.eligible(state) else { return }
        var c = connected
        if c.havenEvent == nil {
            c.havenEvent = HavenWatchEvent(id: HavenWatchEvents.archiveID, due: now.addingTimeInterval(8))
            commitConnected(c)
            return
        }
        guard var event = c.havenEvent, event.id == HavenWatchEvents.archiveID, !event.delivered, event.due <= now else { return }
        event.delivered = true
        c.havenEvent = event
        if c.havenWatch?.alertsEnabled ?? true {
            addActivity(.init(id: event.id, kind: .security, date: event.due,
                              title: HavenWatchEvents.title(event), detail: HavenWatchEvents.detail(event),
                              targetID: event.id, channel: nil, author: nil), to: &c)
        }
        commitConnected(c)
    }
    func advanceHavenFollowup(now:Date=Date(),priorJustDelivered:Bool=false) {
        guard HavenWatchEvents.followupEligible(state) else { return }
        var c=connected
        // After the main ending, optional historical exploration remains
        // possible. Resolve pending/new archive material silently, without
        // scheduling another scare or emitting a notification.
        if state.flags.contains(InvestigationResolution.completed) {
            guard c.havenFollowupEvent == nil ||
                (c.havenFollowupEvent?.id == HavenWatchEvents.followupID && c.havenFollowupEvent?.delivered == false) else{return}
            c.havenFollowupEvent=HavenWatchEvent(id:HavenWatchEvents.followupID,due:now,delivered:true)
            commitConnected(c)
            return
        }
        if c.havenFollowupEvent == nil {
            c.havenFollowupEvent=HavenWatchEvent(id:HavenWatchEvents.followupID,due:now.addingTimeInterval(45))
            commitConnected(c)
            return
        }
        guard var event=c.havenFollowupEvent,event.id == HavenWatchEvents.followupID,
              !event.delivered,event.due <= now else{return}
        // Avoid simultaneous overdue arrivals when returning to the phone.
        if priorJustDelivered {
            c.havenFollowupEvent=HavenWatchEvent(id:event.id,due:now.addingTimeInterval(15))
            commitConnected(c)
            return
        }
        if let prior=c.havenEvent,prior.delivered,now.timeIntervalSince(prior.due)<15 { return }
        event=HavenWatchEvent(id:event.id,due:now,delivered:true)
        c.havenFollowupEvent=event
        if c.havenWatch?.alertsEnabled ?? true {
            addActivity(.init(id:event.id,kind:.security,date:now,title:HavenWatchEvents.title(event),
                detail:HavenWatchEvents.detail(event),targetID:event.id,channel:nil,author:nil),to:&c)
        }
        commitConnected(c)
    }
    func recordVeilAnnotationReview(packages:String,safeMode:Bool) {
        guard VeilArchive.installed(state,packages:packages,safeMode:safeMode),
              VeilCommunity.reconstructionReady(state) else{return}
        if state.flags.insert(VeilCommunity.reconstructionMarker).inserted { save() }
    }
    func acknowledgeHavenEvent(_ id:String) {
        guard HavenWatchEvents.event(id,in:state) != nil else{return}
        if id == HavenWatchEvents.followupID {recordHavenFollowupOpened()}
        var value=connected
        if let index=value.activityJournal?.firstIndex(where:{$0.kind == .security && $0.targetID==id && !$0.dismissed}) {
            value.activityJournal?[index].dismissed=true
            commitConnected(value)
        }
    }
    func recordHavenFollowupOpened() {
        guard HavenWatchEvents.followup(state) != nil else{return}
        if state.flags.insert(HavenWatchEvents.followupOpened).inserted { save() }
    }
    func recordHavenSnapshotOpened(_ id:String) {
        guard HavenWatchArchive.frames(in:state).contains(where:{$0.id == id}) else { return }
        if state.flags.insert(HavenWatchArchive.marker(id)).inserted { save() }
    }
    @discardableResult
    func recordHavenCrossArchiveReview(_ answer:Int)->Bool {
        guard HavenCrossArchiveReview.accepts(answer,in:state) else { return false }
        if state.flags.insert(HavenCrossArchiveReview.marker).inserted { save() }
        return true
    }
    func setHavenWatch(_ preferences: HavenWatchPreferences) {
        guard state.everydayArchiveRevision != nil else { return }
        var value = connected
        var next = preferences
        next.favorites.formIntersection(Set(HavenWatchArchive.frames(in: state).map(\.id)))
        value.havenWatch = next
        if !next.alertsEnabled {
            for i in (value.activityJournal ?? []).indices where value.activityJournal?[i].kind == .security {
                value.activityJournal?[i].dismissed=true
            }
        }
        commitConnected(value)
    }
    func socialPreferences(_ channel: LumaSocialChannel) -> LumaSocialPreferences {
        connected.socialPreferences?[channel.rawValue] ?? LumaSocialPreferences()
    }
    func setSocialPreferences(_ value: LumaSocialPreferences, channel: LumaSocialChannel) {
        guard state.everydayArchiveRevision != nil else { return }
        var c = connected
        var values = c.socialPreferences ?? [:]
        values[channel.rawValue] = value
        c.socialPreferences = values
        for i in (c.activityJournal ?? []).indices {
            guard let notice = c.activityJournal?[i], notice.kind == .social, notice.channel == channel else { continue }
            if !value.notificationsEnabled || (notice.author.map { value.mutedAuthors.contains($0) } ?? false) ||
                (notice.id.hasPrefix("community-post-") && value.followedPostAlerts == false) {
                c.activityJournal?[i].dismissed = true
            }
        }
        commitConnected(c)
    }
    func toggleSocialMute(_ author: String, channel: LumaSocialChannel) {
        guard author != "Nora Bennett", author != "Repair desk",
              LumaSocialCatalog.visible(channel, world: state).contains(where: { $0.author == author }) else { return }
        var value = socialPreferences(channel)
        if !value.mutedAuthors.insert(author).inserted { value.mutedAuthors.remove(author) }
        setSocialPreferences(value, channel: channel)
    }
    func toggleSocial(_ action:LumaSocialAction,postID:String,channel:LumaSocialChannel) {
        guard let post=LumaSocialCatalog.visible(channel,world:state).first(where:{$0.id==postID}) else{return}
        var c=connected
        switch action {
        case .like: if !c.likes.insert(postID).inserted {c.likes.remove(postID)}
        case .save: if !c.savedPosts.insert(postID).inserted {c.savedPosts.remove(postID)}
        case .follow:
            let key=channel.rawValue+"|"+post.author
            if !c.follows.insert(key).inserted {
                c.follows.remove(key)
                for i in (c.activityJournal ?? []).indices {
                    guard let notice = c.activityJournal?[i], notice.id.hasPrefix("community-post-"),
                          notice.channel == channel, notice.author == post.author else { continue }
                    c.activityJournal?[i].dismissed = true
                }
            }
        }
        commitConnected(c)
    }
    @discardableResult
    func commentSocial(postID:String,channel:LumaSocialChannel,text:String,now:Date=Date())->Bool {
        let message=text.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !message.isEmpty,message.count<=600,let post = LumaSocialCatalog.visible(channel,world:state).first(where:{$0.id==postID}) else{return false}
        var c=connected
        guard c.comments.count<300 else{return false}
        let id = UUID().uuidString
        let hasPriorLocalComment = c.comments.contains { $0.postID == postID && $0.author == "Repair desk" }
        c.comments.append(LumaSocialComment(id:id,postID:postID,author:"Repair desk",body:message,date:now))
        var pending = c.pendingSocialReplies ?? []
        if !hasPriorLocalComment, pending.count < 12,
           let reply = LumaActivityCatalog.communityReply(post: post, text: message, id: id, now: now) {
            pending.append(reply)
            c.pendingSocialReplies = pending
        }
        commitConnected(c); return true
    }
    @discardableResult
    func publishSocial(channel:LumaSocialChannel,text:String,now:Date=Date())->Bool {
        let message=text.trimmingCharacters(in:.whitespacesAndNewlines)
        guard state.everydayArchiveRevision != nil,!message.isEmpty,message.count<=1000 else{return false}
        var c=connected
        guard c.posts.count<60 else{return false}
        c.posts.append(LumaSocialPost(id:UUID().uuidString,channel:channel,author:"Repair desk",handle:"repair-desk",body:message,date:now,portrait:nil,photo:nil,gate:nil))
        commitConnected(c);return true
    }
    func setWorkbenchConnection(_ connected:Bool) {
        guard state.everydayArchiveRevision != nil else{return}
        var c=self.connected;c.workbenchConnected=connected;commitConnected(c)
    }
    func setWorkbenchSelection(_ selection:[String],for challenge:WorkbenchChallenge) {
        guard state.everydayArchiveRevision != nil,connected.workbenchConnected,
              !connected.workbenchVerified.contains(challenge.rawValue) else{return}
        var c=connected
        var seen=Set<String>()
        c.workbenchSelections[challenge.rawValue]=Array(selection.filter{challenge.options.contains($0) && seen.insert($0).inserted}.prefix(challenge.required))
        commitConnected(c)
    }
    @discardableResult
    func verifyWorkbench(_ challenge:WorkbenchChallenge)->Bool {
        guard state.everydayArchiveRevision != nil,connected.workbenchConnected else{return false}
        if connected.workbenchVerified.contains(challenge.rawValue){return true}
        guard challenge.valid(connected.workbenchSelections[challenge.rawValue] ?? []) else{return false}
        var c=connected;c.workbenchVerified.insert(challenge.rawValue);commitConnected(c);return true
    }

    func updateDiagnostic(_ challenge: WorkbenchDiagnostic, values: [Int]) {
        guard WorkbenchDiagnosticCatalog.available(state).contains(challenge), challenge.accepts(values) else { return }
        var c = connected
        var records = c.diagnostics ?? [:]
        var progress = WorkbenchDiagnosticCatalog.progress(challenge, in: state)
        guard !progress.verified else { return }
        progress.values = values
        records[challenge.key] = progress; c.diagnostics = records
        commitConnected(c)
    }
    func revealDiagnosticHint(_ challenge: WorkbenchDiagnostic) {
        guard WorkbenchDiagnosticCatalog.available(state).contains(challenge) else { return }
        var c = connected
        var records = c.diagnostics ?? [:]
        var progress = WorkbenchDiagnosticCatalog.progress(challenge, in: state)
        guard !progress.verified, progress.hintLevel < challenge.hints.count else { return }
        progress.hintLevel += 1
        records[challenge.key] = progress; c.diagnostics = records
        commitConnected(c)
    }
    func resetDiagnostic(_ challenge: WorkbenchDiagnostic) {
        guard WorkbenchDiagnosticCatalog.available(state).contains(challenge) else { return }
        var c = connected
        var records = c.diagnostics ?? [:]
        var progress = WorkbenchDiagnosticCatalog.progress(challenge, in: state)
        guard !progress.verified else { return }
        progress.values = challenge.initial
        records[challenge.key] = progress; c.diagnostics = records
        commitConnected(c)
    }
    @discardableResult
    func verifyDiagnostic(_ challenge: WorkbenchDiagnostic) -> Bool {
        guard WorkbenchDiagnosticCatalog.available(state).contains(challenge) else { return false }
        var progress = WorkbenchDiagnosticCatalog.progress(challenge, in: state)
        guard challenge.valid(progress.values) else { return false }
        if progress.verified { return true }
        var c = connected
        var records = c.diagnostics ?? [:]
        progress.verified = true
        records[challenge.key] = progress; c.diagnostics = records
        commitConnected(c)
        return true
    }

    @discardableResult
    func completeAppliedReview(_ review: WorkbenchAppliedReview, choice: Int) -> Bool {
        guard review.available(in: state), review.accepts(choice) else { return false }
        var c = connected
        var completed = c.workbenchAppliedReviews ?? []
        if completed.insert(review.rawValue).inserted {
            c.workbenchAppliedReviews = completed
            commitConnected(c)
        }
        return true
    }

    func recordLumaDocumentOpened(_ id:String) {
        guard WorldDocumentCatalog.document(id,world:state) != nil else { return }
        if state.flags.insert(LumaAssistantEvidence.documentMarker(id)).inserted { save() }
    }
    func recordNoraFriendArchiveOpened() {
        guard NoraFriendArchive.ready(state) else { return }
        if state.flags.insert(NoraFriendArchive.marker).inserted { save() }
    }
    func recordSocialArchiveDraftOpened() {
        guard SocialArchiveReview.ready(state) else { return }
        if state.flags.insert(SocialArchiveReview.marker).inserted { save() }
    }
    func recordLumaSocialOpened(_ channel:LumaSocialChannel,postID:String) {
        guard LumaSocialCatalog.visible(channel,world:state).contains(where:{$0.id == postID}) else { return }
        if state.flags.insert(LumaAssistantEvidence.socialMarker(channel,postID)).inserted { save() }
    }
    @discardableResult
    func saveEvidenceConnection(_ first:String,_ second:String,relation:EvidenceConnection.Relation)->Bool {
        guard let entry=EvidenceConnection.make(first,second,relation:relation,in:state) else{return false}
        var c=connected
        var values=EvidenceConnection.visible(state)
        values.removeAll{$0.id==entry.id}
        values.insert(entry,at:0)
        c.evidenceConnections=Array(values.prefix(40))
        if c != connected {commitConnected(c)}
        return true
    }
    func removeEvidenceConnection(_ id:String) {
        var c=connected
        guard let entries=c.evidenceConnections else{return}
        let next=entries.filter{$0.id != id}
        guard next != entries else{return}
        c.evidenceConnections=next;commitConnected(c)
    }
    func rememberLumaSession(_ session:LumaAssistantSession?) {
        var c = connected
        let validated = LumaAssistantSession.validated(session,in:state)
        guard c.assistantSession != validated else { return }
        c.assistantSession = validated
        commitConnected(c)
    }
    func acknowledgeLumaBoundaries() {
        guard state.everydayArchiveRevision != nil else { return }
        if state.flags.insert(LumaAssistantTrust.acknowledgement).inserted { save() }
    }
    func inspectVeilReference(_ id:String) {
        guard VeilReferences.visible(state).contains(where:{$0.id == id}) else { return }
        if state.flags.insert(VeilReferences.marker(id)).inserted { save() }
    }
    func toggleVeilPageBookmark(_ id:String,packages:String,safeMode:Bool) {
        guard VeilArchive.installed(state,packages:packages,safeMode:safeMode),VeilArchive.pages(state).contains(where:{$0.id == id}) else { return }
        var c=connected
        var saved=VeilArchive.pageBookmarkIDs(state)
        if saved.contains(id) { saved.remove(id) } else { saved.insert(id) }
        c.veilPageBookmarks=saved
        commitConnected(c)
    }
    func recordVeilThreadOpened(_ id:String,packages:String,safeMode:Bool) {
        guard VeilArchive.installed(state,packages:packages,safeMode:safeMode),VeilCommunity.thread(id,in:state) != nil else { return }
        if state.flags.insert(VeilCommunity.openedMarker(id)).inserted { save() }
    }
    func toggleVeilThreadBookmark(_ id:String,packages:String,safeMode:Bool) {
        guard VeilArchive.installed(state,packages:packages,safeMode:safeMode),VeilCommunity.thread(id,in:state) != nil else { return }
        var c=connected
        var saved=VeilCommunity.bookmarkIDs(state)
        if saved.contains(id) { saved.remove(id) } else { saved.insert(id) }
        c.veilThreadBookmarks=saved
        commitConnected(c)
    }
    @discardableResult
    func recordImageInterpretation(_ asset:String,mode:ImageInterpretation.Mode,region:Int)->Bool {
        guard let finding=ImageInterpretation.accepts(asset,mode:mode,region:region,in:state) else{return false}
        var c=connected
        var findings=c.imageInterpretationFindings ?? []
        if findings.insert(finding.id).inserted {c.imageInterpretationFindings=findings;commitConnected(c)}
        return true
    }
    func recordCameraAnalysisOpened(_ asset:String) {
        guard RecoveredImageAnalysis.cameraAvailable(asset,in:state) else{return}
        if state.flags.insert(RecoveredImageAnalysis.cameraMarker(asset)).inserted {save()}
    }
    @discardableResult
    func recordPhotoFeatureMatch(_ id:String,first:Int,second:Int)->Bool {
        guard let c=PhotoFeatureMatch.accepts(id,first:first,second:second,in:state) else{return false}
        var value=connected
        var matches=value.photoFeatureMatches ?? []
        if matches.insert(c.id).inserted {value.photoFeatureMatches=matches;commitConnected(value)}
        return true
    }
    @discardableResult
    func recordRegionalLightReview(_ asset:String,dark:Int,bright:Int)->Bool {
        guard RecoveredImageAnalysis.completed(asset,in:state),
              let image=PortraitImages.load(asset),
              let sample=RecoveredImageAnalysis.regionalLight(image),
              RecoveredImageAnalysis.validLightPair(sample,dark:dark,bright:bright) else{return false}
        var c=connected
        var reviewed=c.regionalLightReviews ?? []
        if reviewed.insert(asset).inserted {c.regionalLightReviews=reviewed;commitConnected(c)}
        return true
    }
    @discardableResult
    func completeRecoveredImageAnalysis(_ asset:String,source:Int,limit:Int)->Bool {
        guard RecoveredImageAnalysis.accepts(asset,source:source,limit:limit,in:state) else{return false}
        var c=connected
        var reviewed=c.recoveredImageReviews ?? []
        if reviewed.insert(asset).inserted {c.recoveredImageReviews=reviewed;commitConnected(c)}
        return true
    }
    func recordVeilObservation(_ asset:String) {
        guard VeilArchive.media(state).contains(asset) else { return }
        if state.flags.insert("veil.viewed."+asset).inserted { save() }
    }
    @discardableResult
    func recordVeilDispute(_ answer:Int,packages:String,safeMode:Bool)->Bool {
        guard VeilArchive.installed(state,packages:packages,safeMode:safeMode),
              VeilCommunity.acceptsDispute(answer,in:state) else { return false }
        if state.flags.insert(VeilCommunity.disputeMarker).inserted { save() }
        return true
    }
    func recordVeilHomeIndexOpened() {
        guard VeilArchive.pages(state).contains(where:{$0.id == "home-index"}) else { return }
        if state.flags.insert("veil.home-index.opened").inserted { save() }
    }
    func recordVeilCorrespondenceOpened() {
        guard VeilArchive.authorized(state) else { return }
        if state.flags.insert("veil.correspondence.opened").inserted { save() }
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
