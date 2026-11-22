import SwiftUI
import UserNotifications

@main
struct DaySixApp: App {
    @UIApplicationDelegateAdaptor(DaySixLifecycleDelegate.self)
    private var lifecycleDelegate
    @StateObject private var store = DaySixStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DaySixRootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onAppear {
                    RenewalAudit.reconcileSelfSignature()
                    store.reload()
                    BackgroundRenewalWatchdog.schedule()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        RenewalAudit.reconcileSelfSignature()
                        store.reload()
                        BackgroundRenewalWatchdog.schedule()
                    } else if phase == .background {
                        BackgroundRenewalWatchdog.schedule()
                    }
                }
        }
    }
}

struct TrackedApp: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var bundleID: String
    var installedAt: Date = .now
    var lastVerifiedRenewal: Date = .now
    var sourceURL: String = ""
    var lastAttempt: Date? = nil

    var refreshDueAt: Date { RenewalPolicy.renewAt(expiration: expiresAt) }
    var expiresAt: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: lastVerifiedRenewal)
            ?? lastVerifiedRenewal.addingTimeInterval(7 * 86_400)
    }
    var isDue: Bool { Date.now >= refreshDueAt }
    var isExpired: Bool { Date.now >= expiresAt }
    var daysLeft: Int {
        max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: expiresAt)).day ?? 0)
    }
}

enum DaySixStorage {
    static let appsKey = "daysix.trackedApps.v1"
    static let remindersKey = "daysix.remindersEnabled.v1"

    static func read() -> [TrackedApp] {
        guard let data = UserDefaults.standard.data(forKey: appsKey),
              let decoded = try? JSONDecoder().decode([TrackedApp].self, from: data) else {
            return []
        }
        return decoded
    }

    static func write(_ apps: [TrackedApp]) {
        guard let encoded = try? JSONEncoder().encode(apps) else { return }
        UserDefaults.standard.set(encoded, forKey: appsKey)
    }
}

@MainActor
final class DaySixStore: ObservableObject {
    @Published private(set) var apps: [TrackedApp] = []
    @Published var remindersEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(remindersEnabled, forKey: DaySixStorage.remindersKey)
            syncNotifications()
        }
    }

    init() {
        apps = DaySixStorage.read()
        if UserDefaults.standard.object(forKey: DaySixStorage.remindersKey) != nil {
            remindersEnabled = UserDefaults.standard.bool(forKey: DaySixStorage.remindersKey)
        }
        syncNotifications()
    }

    var dueApps: [TrackedApp] { apps.filter(\.isDue) }
    // DaySix counts itself, even when the user has not registered any other apps.
    var selfExpiresAt: Date? { SelfProvisioning.effectiveExpiry }
    var selfRefreshDueAt: Date? { SelfProvisioning.refreshDueAt }
    var selfIsDue: Bool { SelfProvisioning.isDue }
    var urgentCount: Int { dueApps.count + (selfIsDue ? 1 : 0) }
    var nextDate: Date? {
        (apps.map(\.refreshDueAt) + [selfRefreshDueAt].compactMap { $0 }).min()
    }

    func reload() {
        apps = DaySixStorage.read()
        syncNotifications()
    }

    func add(name: String, bundleID: String, lastVerifiedRenewal: Date, sourceURL: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        apps.append(TrackedApp(name: cleanName,
                               bundleID: bundleID.trimmingCharacters(in: .whitespacesAndNewlines),
                               lastVerifiedRenewal: lastVerifiedRenewal,
                               sourceURL: sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)))
        persist()
    }

    func delete(_ app: TrackedApp) {
        apps.removeAll { $0.id == app.id }
        persist()
    }

    // Only call after the user verifies a successful refresh in the signing app.
    func verifyRenewed(_ app: TrackedApp) {
        guard let index = apps.firstIndex(where: { $0.id == app.id }) else { return }
        apps[index].lastVerifiedRenewal = .now
        apps[index].lastAttempt = .now
        persist()
    }

    func persist() {
        DaySixStorage.write(apps)
        syncNotifications()
    }

    func requestNotificationPermission() {
        Task {
            let granted = (try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            if granted { syncNotifications() }
        }
    }

    func syncNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                    || settings.authorizationStatus == .ephemeral else {
                // Apple's notification permission is authoritative. If the
                // user later enables notifications in iPhone Settings,
                // DaySix reschedules on its next foreground transition.
                return
            }
            center.getPendingNotificationRequests { pending in
            let ours = pending.map(\.identifier).filter { $0.hasPrefix("daysix.") }
            guard UserDefaults.standard.object(forKey: DaySixStorage.remindersKey) == nil
                    || UserDefaults.standard.bool(forKey: DaySixStorage.remindersKey) else {
                center.removePendingNotificationRequests(withIdentifiers: ours)
                return
            }

            // Keep already-pending due warnings intact. Removing all
            // requests on every foreground transition could silently erase
            // the 90-second immediate alert after a due threshold passed.
            let activeApps = DaySixStorage.read().prefix(24)
            var desiredIDs = Set<String>()
            if let selfExpiry = SelfProvisioning.effectiveExpiry,
               selfExpiry > Date.now {
                if DaySixNotificationPreferences.preflight {
                    desiredIDs.insert("daysix.self.preflight")
                }
                if DaySixNotificationPreferences.due {
                    desiredIDs.insert("daysix.self.due")
                }
                if DaySixNotificationPreferences.critical {
                    desiredIDs.insert("daysix.self.critical")
                }
            }
            for app in activeApps where app.expiresAt > Date.now {
                if DaySixNotificationPreferences.preflight {
                    desiredIDs.insert("daysix.\(app.id.uuidString).preflight")
                }
                if DaySixNotificationPreferences.due {
                    desiredIDs.insert("daysix.\(app.id.uuidString).due")
                }
            }
            let staleIDs = ours.filter { !desiredIDs.contains($0) }
            if !staleIDs.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: staleIDs)
            }
            // Reminders are scheduled at their actual time whenever possible.
            // For an already-passed due threshold, use a persisted expiry token
            // to avoid spamming another alert every time DaySix comes forward.
            // A new signing expiration resets the token naturally.
            func dueTrigger(for expiry: Date, at target: Date,
                            key: String) -> UNNotificationTrigger? {
                if target > Date.now.addingTimeInterval(90) {
                    return UNTimeIntervalNotificationTrigger(
                        timeInterval: target.timeIntervalSinceNow, repeats: false)
                }
                let recorded = UserDefaults.standard.object(forKey: key) as? Date
                guard recorded != expiry else { return nil }
                UserDefaults.standard.set(expiry, forKey: key)
                return UNTimeIntervalNotificationTrigger(
                    timeInterval: 90, repeats: false)
            }

            // Reminder for DaySix's own Apple provisioning profile (or its
            // explicitly labeled manual fallback). This is only a warning,
            // never a verified signing operation.
            if let dueDate = SelfProvisioning.refreshDueAt,
               let expires = SelfProvisioning.effectiveExpiry,
               expires > Date.now {
                // Two-day preflight (or earlier for a larger lead-time
                // setting) gives users a chance to repair a broken signer
                // before the requested day-six automatic refresh.
                let preflightDate = RenewalPolicy.preflightAt(expiration: expires)
                if DaySixNotificationPreferences.preflight
                   && preflightDate > Date.now.addingTimeInterval(120) {
                    let preflight = UNMutableNotificationContent()
                    preflight.title = "DaySix • Signing check coming up"
                    preflight.body = "Check SideStore pairing, Apple sign-in and LocalDevVPN before DaySix's renewal window."
                    preflight.sound = .default
                    center.add(UNNotificationRequest(
                        identifier: "daysix.self.preflight",
                        content: preflight,
                        trigger: UNTimeIntervalNotificationTrigger(
                            timeInterval: preflightDate.timeIntervalSinceNow,
                            repeats: false)))
                }

                let renewalNotice = UNMutableNotificationContent()
                renewalNotice.title = "DaySix • Refresh its own signature"
                renewalNotice.body = "DaySix's signing profile is due. Open SideStore and check that DaySix is renewed."
                renewalNotice.sound = .default
                // If the threshold passed while the phone was asleep, issue
                // one near-term reminder and a final six-hour warning.
                if DaySixNotificationPreferences.due,
                   let trigger = dueTrigger(
                    for: expires, at: dueDate,
                    key: "daysix.alert.self.dueExpiry") {
                    center.add(UNNotificationRequest(
                        identifier: "daysix.self.due",
                        content: renewalNotice, trigger: trigger))
                }
                let criticalDate = expires.addingTimeInterval(-6 * 60 * 60)
                if DaySixNotificationPreferences.critical
                   && criticalDate > Date.now.addingTimeInterval(120) {
                    let warning = UNMutableNotificationContent()
                    warning.title = "DaySix • Signature expires soon"
                    warning.body = "Less than six hours remain. Verify a successful refresh in SideStore."
                    warning.sound = .default
                    center.add(UNNotificationRequest(
                        identifier: "daysix.self.critical", content: warning,
                        trigger: UNTimeIntervalNotificationTrigger(
                            timeInterval: criticalDate.timeIntervalSinceNow, repeats: false)))
                }
            }
            for app in DaySixStorage.read().prefix(24) {
                // Also warn when the user adds an already due, but not yet
                // expired app. A local reminder cannot perform code signing.
                guard app.expiresAt > Date.now else { continue }
                let dueDate = max(Date.now.addingTimeInterval(90), app.refreshDueAt)
                let preflightDate = RenewalPolicy.preflightAt(expiration: app.expiresAt)
                if DaySixNotificationPreferences.preflight
                   && preflightDate > Date.now.addingTimeInterval(120) {
                    let preflight = UNMutableNotificationContent()
                    preflight.title = "DaySix • Signing health check"
                    preflight.body = "\(app.name) needs renewal soon. Check that SideStore and LocalDevVPN still work."
                    preflight.sound = .default
                    center.add(UNNotificationRequest(
                        identifier: "daysix.\(app.id.uuidString).preflight",
                        content: preflight,
                        trigger: UNTimeIntervalNotificationTrigger(
                            timeInterval: preflightDate.timeIntervalSinceNow,
                            repeats: false)))
                }

                let content = UNMutableNotificationContent()
                content.title = "DaySix • Refresh needed"
                content.body = "\(app.name) is due for renewal. Open SideStore and verify it succeeds before expiration."
                content.sound = .default
                if DaySixNotificationPreferences.due,
                   let trigger = dueTrigger(
                    for: app.expiresAt, at: dueDate,
                    key: "daysix.alert.\(app.id.uuidString).dueExpiry") {
                    center.add(UNNotificationRequest(
                        identifier: "daysix.\(app.id.uuidString).due",
                        content: content, trigger: trigger))
                }
            }
            }
        }
    }
}
