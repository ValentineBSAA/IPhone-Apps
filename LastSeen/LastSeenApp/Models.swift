import Foundation

enum MessageKind: String, Codable {
    case text
    case photograph
    case voiceNote
}

struct GameMessage: Identifiable, Codable, Equatable {
    let id: String
    let thread: String
    let sender: String
    let body: String
    let kind: MessageKind
    let createdAt: Date
    var isRead: Bool

    var isOutgoing: Bool { sender == "player" }
}

struct StoryBeat {
    let thread: String
    let sender: String
    let body: String
    let kind: MessageKind
    let delay: Double

    init(_ thread: String, _ sender: String, _ body: String,
         kind: MessageKind = .text, delay: Double = 1.7) {
        self.thread = thread
        self.sender = sender
        self.body = body
        self.kind = kind
        self.delay = delay
    }
}

struct StoryChoice: Identifiable {
    let id: String
    let title: String
    let next: String
    var requiredClues: [String] = []
}

struct StoryScene {
    let id: String
    let beats: [StoryBeat]
    let choices: [StoryChoice]
    var next: String? = nil
    var ending: String? = nil
    var endingDetail: String? = nil
}

enum Contact: String, CaseIterable, Identifiable {
    case nora, eli, unit7
    var id: String { rawValue }

    var name: String {
        switch self {
        case .nora: return "Nora Bennett"
        case .eli: return "Eli Mercer"
        case .unit7: return "Unknown Number"
        }
    }

    var initials: String {
        switch self {
        case .nora: return "NB"
        case .eli: return "EM"
        case .unit7: return "?"
        }
    }

    var subtitle: String {
        switch self {
        case .nora: return "Apartment 402"
        case .eli: return "Night caretaker"
        case .unit7: return "Unlisted contact"
        }
    }

    var tint: String {
        switch self {
        case .nora: return "nora"
        case .eli: return "eli"
        case .unit7: return "unit7"
        }
    }
}

struct SavedGame: Codable {
    var sceneID: String = "opening"
    var nextBeatIndex: Int = 0
    var choiceReady: Bool = false
    var messages: [GameMessage] = []
    var visitedChoices: [String] = []
    var clues: Set<String> = []
    var readThreads: Set<String> = []
    var endingID: String? = nil
    var notificationsEnabled: Bool = false
    var audioEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var slowerText: Bool = false
    var lastSaved: Date = Date()
    var schemaVersion: Int = 1
}
