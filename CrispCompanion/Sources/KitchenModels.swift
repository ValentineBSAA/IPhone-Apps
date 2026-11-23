import Foundation

enum FryerPreset: String, CaseIterable, Identifiable, Codable {
    case airFry, broil, roast, bake, reheat, frozen, fries, steak, chicken, seafood, vegetables

    var id: String { rawValue }
    var name: String {
        switch self {
        case .airFry: return "Air Fry"
        case .broil: return "Broil"
        case .roast: return "Roast"
        case .bake: return "Bake"
        case .reheat: return "Reheat"
        case .frozen: return "Frozen"
        case .fries: return "Fries"
        case .steak: return "Steak"
        case .chicken: return "Chicken"
        case .seafood: return "Seafood"
        case .vegetables: return "Veggies"
        }
    }
    var symbol: String {
        switch self {
        case .airFry: return "flame"
        case .broil: return "sun.max"
        case .roast: return "fork.knife"
        case .bake: return "birthday.cake"
        case .reheat: return "arrow.clockwise"
        case .frozen: return "snowflake"
        case .fries: return "takeoutbag.and.cup.and.straw"
        case .steak: return "circle.grid.2x2"
        case .chicken: return "bird"
        case .seafood: return "fish"
        case .vegetables: return "leaf"
        }
    }
    // Planning suggestions only, NOT manufacturer defaults or device commands.
    var suggestedFahrenheit: Int {
        switch self {
        case .airFry, .frozen, .fries: return 390
        case .broil: return 400
        case .roast, .steak: return 385
        case .bake: return 325
        case .reheat: return 325
        case .chicken: return 380
        case .seafood: return 375
        case .vegetables: return 375
        }
    }
    var suggestedMinutes: Int {
        switch self {
        case .airFry: return 18
        case .broil: return 8
        case .roast: return 22
        case .bake: return 20
        case .reheat: return 6
        case .frozen: return 15
        case .fries: return 17
        case .steak: return 11
        case .chicken: return 20
        case .seafood: return 10
        case .vegetables: return 9
        }
    }
}

struct SavedRecipe: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var temperatureF: Int
    var minutes: Int
    var notes: String = ""

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && (175...400).contains(temperatureF)
        && (1...60).contains(minutes)
    }
}

struct LiveFryerStatus: Codable {
    let connected: Bool
    let cooking: Bool
    let temperatureF: Int?
    let minutesRemaining: Int?
    let preset: String?
    let message: String?
    let updatedAt: String?
}
