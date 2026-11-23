import Foundation

enum FryerPreset: String, CaseIterable, Identifiable, Codable {
    case airFry, broil, roast, bake, reheat, frozen, fries, steak, chicken, seafood, vegetables, keepWarm

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
        case .keepWarm: return "Keep Warm"
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
        case .keepWarm: return "thermometer.medium"
        }
    }
    // Published CAF-P583S-KUS manual defaults, not live hardware values.
    // Local recipe planning only; these never send commands to the appliance.
    var suggestedFahrenheit: Int {
        switch self {
        case .airFry: return 360
        case .broil: return 400
        case .roast: return 400
        case .bake: return 320
        case .reheat: return 350
        case .frozen: return 395
        case .fries: return 385
        case .steak: return 400
        case .chicken: return 390
        case .seafood: return 375
        case .vegetables: return 385
        case .keepWarm: return 175
        }
    }
    var suggestedMinutes: Int {
        switch self {
        case .airFry: return 10
        case .broil: return 10
        case .roast: return 10
        case .bake: return 20
        case .reheat: return 5
        case .frozen: return 12
        case .fries: return 20
        case .steak: return 8
        case .chicken: return 20
        case .seafood: return 8
        case .vegetables: return 6
        case .keepWarm: return 30
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
