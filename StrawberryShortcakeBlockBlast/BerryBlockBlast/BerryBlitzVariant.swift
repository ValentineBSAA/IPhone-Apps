import Foundation

/// Fixed-duration score chases with independent personal bests, all offline.
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
        case .quick60: return "1 minute · Fast and frantic"
        case .rush120: return "2 minutes · Chase your biggest score"
        case .garden300: return "5 minutes · Build juicy combinations"
        case .marathon600: return "10 minutes · The ultimate berry rush"
        }
    }
    var icon: String {
        switch self {
        case .quick60: return "timer"
        case .rush120: return "bolt.fill"
        case .garden300: return "leaf.fill"
        case .marathon600: return "star.fill"
        }
    }
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
