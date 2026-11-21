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
    static var homeLabel: String { "🍓 v\(marketingVersion) • B\(buildNumber) • I7 QA" }
    static let revisionName = "I7 SECONDS QA"
    static let sourceBranch = "feature/berry-i7-live-clock-seconds-b49"
    static var settingsLabel: String {
        "Berry Berry Blast v\(marketingVersion) • Build \(buildNumber) • I7 QA"
    }
}
