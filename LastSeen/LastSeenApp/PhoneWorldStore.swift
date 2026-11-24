import Foundation
import SwiftUI

/// Fictional everyday life surrounding the horror. It does not access real
/// Contacts, Messages, Calendar, Mail, Photos, or device communication data.
enum Neighbor: String, CaseIterable, Identifiable, Codable {
    case maya, denise

    var id: String { rawValue }
    var name: String {
        switch self {
        case .maya: return "Maya Brooks"
        case .denise: return "Denise Hall"
        }
    }
    var subtitle: String {
        switch self {
        case .maya: return "Friend"
        case .denise: return "Building office"
        }
    }
    var initials: String { self == .maya ? "MB" : "DH" }

    // Both portraits are existing, approved images. They are assigned as
    // unique character headshots rather than leaving new contacts as initials.
    // Keep these assignments stable across relaunch and story progression.
    var portraitAssetName: String {
        switch self {
        case .maya: return "Contact_Maya"
        case .denise: return "Contact_Denise"
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

struct PhoneWorld: Codable {
    var version: Int = 1
    var createdAt: Date
    var threads: [String: [NeighborMessage]]
    var progress: [String: Int] = [:]
    var flags: Set<String> = []
    var notes: [PhoneNote]
    var events: [PhoneEvent]
    var soundEnabled: Bool = true
}

/// This is a separate *fictional world save* while compatibility with existing
/// v1.0.x story data is maintained. It survives app restarts and story replays.
@MainActor
final class PhoneWorldStore: ObservableObject {
    @Published private(set) var state: PhoneWorld
    private let persistToDisk: Bool
    private let storageURL: URL

    static var saveURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("lastseen-world-v1.json")
    }

    init(initial: PhoneWorld? = nil, persistToDisk: Bool = true, now: Date = Date(), storageURL: URL = PhoneWorldStore.saveURL) {
        self.persistToDisk = persistToDisk
        self.storageURL = storageURL
        if let initial {
            state = initial
        } else if persistToDisk,
            let data = try? Data(contentsOf: storageURL),
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
        for i in messages.indices { messages[i].read = true }
        state.threads[neighbor.id] = messages
        save()
    }

    func choices(_ neighbor: Neighbor) -> [String] {
        let stage = state.progress[neighbor.id] ?? 0
        if stage == 0 {
            switch neighbor {
            case .maya: return ["Coffee sounds good!", "I might be busy this week.", "How's work going?"]
            case .denise: return ["Thanks for letting me know.", "Do you know what time the elevator will be checked?"]
            }
        }
        if stage == 1 {
            switch neighbor {
            case .maya: return ["I'll text you when I know.", "See you soon!"]
            case .denise: return ["Perfect, thank you.", "Could you send an update if that changes?"]
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
        guard let index = state.notes.firstIndex(where: { $0.id == id }) else { return }
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
