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
    static var homeLabel: String { "🍓 v\(marketingVersion) • B\(buildNumber) • I6 QA" }
    static let revisionName = "I6 DEVICE QA"
    static let sourceBranch = "feature/berry-i6-internal-device-qa-build48"
    static var settingsLabel: String {
        "Berry Berry Blast v\(marketingVersion) • Build \(buildNumber) • I6 QA"
    }
}
