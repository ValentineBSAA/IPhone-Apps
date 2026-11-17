import Foundation

/// Fast fixed-duration challenges under a single Berry Blitz mode card.
/// No between-session board save, no extension bonuses, no score ceiling.
enum BerryBlitzVariant: String, CaseIterable, Identifiable {
    case quick60 = "Quick Jam"
    case rush120 = "Berry Rush"
    case garden300 = "Garden Sprint"
    case marathon600 = "Berry Marathon"
    var id: String { rawValue }
    var seconds: Int {
        switch self {
        case .quick60: return 60
        case .rush120: return 120
        case .garden300: return 300
        case .marathon600: return 600
        }
    }
    var subtitle: String {
        switch self {
        case .quick60: return "1 minute · Quick score race"
        case .rush120: return "2 minutes · Classic Berry Rush"
        case .garden300: return "5 minutes · Build bigger combos"
        case .marathon600: return "10 minutes · Long-play strawberry challenge"
        }
    }
    var icon: String { self == .marathon600 ? "hourglass" : "bolt.fill" }
    var bestScoreKey: String {
        switch self {
        case .quick60: return "berryblockblast.blitz.best.quick60.v056b2"
        case .rush120: return "berryblockblast.blitz.best.rush120.v056b2"
        case .garden300: return "berryblockblast.blitz.best.garden300.v058"
        case .marathon600: return "berryblockblast.blitz.best.marathon600.v058"
        }
    }
    static var selected: Self {
        BerryBlitzVariant(rawValue: UserDefaults.standard.string(forKey: "berryblockblast.blitz.variant.v056b2") ?? "") ?? .rush120
    }
}
