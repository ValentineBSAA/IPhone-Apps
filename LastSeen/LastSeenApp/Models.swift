import Foundation

enum MessageKind: String, Codable {
    case text
    case photograph
    case voiceNote
    case call
}

struct GameMessage: Identifiable, Codable, Equatable {
    let id: String
    let thread: String
    let sender: String
    let body: String
    let kind: MessageKind
    let createdAt: Date
    var isRead: Bool
    var photoAssetName: String? = nil

    var isOutgoing: Bool { sender == "player" }
}

struct StoryBeat {
    let thread: String
    let sender: String
    let body: String
    let kind: MessageKind
    let delay: Double
    let asset: String?

    init(_ thread: String, _ sender: String, _ body: String,
         kind: MessageKind = .text, delay: Double = 1.7, asset: String? = nil) {
        self.thread = thread
        self.sender = sender
        self.body = body
        self.kind = kind
        self.delay = delay
        self.asset = asset
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
    var activeThread: String? = nil
    var stories: [String: StorySlot]? = nil
    var schemaVersion: Int = 2
}


/// An independent, persistable conversation. Inactive threads never run timers.
struct StorySlot: Codable {
    var sceneID: String
    var nextBeatIndex: Int = 0
    var choiceReady: Bool = false
    var messages: [GameMessage] = []
    var visitedChoices: [String] = []
    var clues: Set<String> = []
    var readThreads: Set<String> = []
    var endingID: String? = nil

    init(sceneID: String) {
        self.sceneID = sceneID
    }

    init(capturing state: SavedGame) {
        sceneID = state.sceneID
        nextBeatIndex = state.nextBeatIndex
        choiceReady = state.choiceReady
        messages = state.messages
        visitedChoices = state.visitedChoices
        clues = state.clues
        readThreads = state.readThreads
        endingID = state.endingID
    }

    func restore(into state: inout SavedGame) {
        state.sceneID = sceneID
        state.nextBeatIndex = nextBeatIndex
        state.choiceReady = choiceReady
        state.messages = messages
        state.visitedChoices = visitedChoices
        state.clues = clues
        state.readThreads = readThreads
        state.endingID = endingID
    }
}
