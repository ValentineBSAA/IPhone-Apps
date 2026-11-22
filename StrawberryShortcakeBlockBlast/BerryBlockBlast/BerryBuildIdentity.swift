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
    static var homeLabel: String { "🍓 v\(marketingVersion) • B\(buildNumber) • I8 QA" }
    static let revisionName = "I8 POLISH QA"
    static let sourceBranch = "feature/berry-i8-build51-native-done-notice-preview"
    static var settingsLabel: String {
        "Berry Berry Blast v\(marketingVersion) • Build \(buildNumber) • I8 QA"
    }
}
