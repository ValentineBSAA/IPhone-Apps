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
        let now = Date.now
        guard RenewalPolicy.automaticallyRequestRefresh else {
            return .result(value: false)
        }

        // SideStore must manage DaySix for this request to actually re-sign it.
        // Still include it in scheduling, rather than depending on a user's
        // manually entered tracked-app card.
        let selfDue: Bool
        if let expiry = SelfProvisioning.effectiveExpiry {
            let lastSelfAttempt = UserDefaults.standard.object(
                forKey: "daysix.lastSelfRenewalAttempt") as? Date
            selfDue = RenewalPolicy.dueAndRetryable(
                expiration: expiry, lastAttempt: lastSelfAttempt, now: now)
        } else {
            selfDue = false
        }

        let otherAppDue = DaySixStorage.read().contains { app in
            RenewalPolicy.dueAndRetryable(
                expiration: app.expiresAt, lastAttempt: app.lastAttempt, now: now)
        }
        return .result(value: selfDue || otherAppDue)
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
        for index in apps.indices
        where RenewalPolicy.dueAndRetryable(
            expiration: apps[index].expiresAt,
            lastAttempt: apps[index].lastAttempt,
            now: now) {
            apps[index].lastAttempt = now
            changed += 1
        }
        if changed > 0 { DaySixStorage.write(apps) }
        let lastSelfAttempt = UserDefaults.standard.object(
            forKey: "daysix.lastSelfRenewalAttempt") as? Date
        if let expiry = SelfProvisioning.effectiveExpiry,
           RenewalPolicy.dueAndRetryable(
               expiration: expiry, lastAttempt: lastSelfAttempt, now: now) {
            // This is an ATTEMPT, not verified Apple signing.
            UserDefaults.standard.set(now, forKey: "daysix.lastSelfRenewalAttempt")
            changed += 1
        }
        if changed > 0 {
            RenewalAudit.record(
                .automationAttempt,
                "A SideStore refresh was requested by the Shortcuts workflow. Check the signing expiration to verify success.")
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
