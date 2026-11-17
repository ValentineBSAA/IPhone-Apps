import Foundation

/// Fast fixed-duration challenges under a single Berry Blitz mode card.
/// No between-session board save, no extension bonuses, no score ceiling.
enum BerryBlitzVariant: String, CaseIterable, Identifiable {
    case quick60 = "Quick Jam"
    case rush120 = "Berry Rush"
    var id: String { rawValue }
    var seconds: Int { self == .quick60 ? 60 : 120 }
    var subtitle: String { self == .quick60 ? "60 seconds · Fast and frantic" : "2 minutes · Chase your biggest score" }
    var icon: String { self == .quick60 ? "timer" : "bolt.fill" }
    var bestScoreKey: String { self == .quick60
        ? "berryblockblast.blitz.best.quick60.v056b2"
        : "berryblockblast.blitz.best.rush120.v056b2" }
    static var selected: Self {
        BerryBlitzVariant(rawValue: UserDefaults.standard.string(forKey: "berryblockblast.blitz.variant.v056b2") ?? "") ?? .rush120
    }
}
