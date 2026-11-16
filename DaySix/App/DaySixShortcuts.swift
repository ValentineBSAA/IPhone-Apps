import AppIntents
import Foundation

/// Returns a boolean so iOS Shortcuts can run SideStore ONLY when a tracked
/// app has reached day six. This intent does not perform code signing itself.
struct CheckDaySixRefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "Check DaySix Refresh"
    static var description = IntentDescription(
        "Returns true if any tracked app is due to be refreshed on day six.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let due = DaySixStorage.read().contains { $0.isDue }
        return .result(value: due)
    }
}

/// An attempt is NOT evidence of successful signing. It is recorded separately
/// from the last user-verified expiration date.
struct RecordDaySixAttemptIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Refresh Attempt"
    static var description = IntentDescription(
        "Records that Shortcuts attempted a SideStore refresh without claiming it succeeded.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        var apps = DaySixStorage.read()
        let now = Date.now
        var changed = 0
        for index in apps.indices where apps[index].isDue {
            apps[index].lastAttempt = now
            changed += 1
        }
        if changed > 0 { DaySixStorage.write(apps) }
        return .result(value: changed)
    }
}

struct DaySixAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckDaySixRefreshIntent(),
            phrases: [
                "Check \(.applicationName) renewals",
                "Are any \(.applicationName) apps due"
            ],
            shortTitle: "Check Renewals",
            systemImageName: "arrow.clockwise.shield")
    }
}
