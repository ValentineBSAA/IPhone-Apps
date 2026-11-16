import AppIntents
import Foundation

/// Returns true when DaySix *itself* OR a manually tracked app reaches
/// the day-six threshold. SideStore still performs actual signing.
struct CheckDaySixRefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "Check DaySix Refresh"
    static var description = IntentDescription(
        "Checks both DaySix's own provisioning expiry and tracked apps for day-six renewal.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let due = SelfProvisioning.isDue || DaySixStorage.read().contains { $0.isDue }
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
        if SelfProvisioning.isDue {
            // Never declare renewal successful based on an attempt alone.
            UserDefaults.standard.set(now, forKey: "daysix.lastSelfRenewalAttempt")
            changed += 1
        }
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
