import Foundation

/// The single source of truth for player-visible build labels.
/// Never hand-edit version strings in individual views.
enum BerryBuildIdentity {
    static var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }
    static var homeLabel: String { "🍓 B4.6 VISUAL LAB • v\(marketingVersion)" }
    static let revisionName = "BUILD 4.6 • VISUAL LAB"
    static let sourceBranch = "feature/berry-build4-r7-night-bounce-qa"
    static var settingsLabel: String {
        "Berry Berry Blast v\(marketingVersion) • Build 4.6 • VISUAL LAB (internal \(buildNumber))"
    }
}
