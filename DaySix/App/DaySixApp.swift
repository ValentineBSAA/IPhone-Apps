import SwiftUI
import UserNotifications

@main
struct DaySixApp: App {
    @StateObject private var store = DaySixStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DaySixRootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.reload() }
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

    var refreshDueAt: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: lastVerifiedRenewal)
            ?? lastVerifiedRenewal.addingTimeInterval(6 * 86_400)
    }
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
    var urgentCount: Int { dueApps.count }
    var nextDate: Date? { apps.map(\.refreshDueAt).min() }

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
        center.getPendingNotificationRequests { pending in
            let ours = pending.map(\.identifier).filter { $0.hasPrefix("daysix.") }
            center.removePendingNotificationRequests(withIdentifiers: ours)
            guard UserDefaults.standard.object(forKey: DaySixStorage.remindersKey) == nil
                    || UserDefaults.standard.bool(forKey: DaySixStorage.remindersKey) else {
                return
            }
            for app in DaySixStorage.read() {
                let dueDate = max(Date.now.addingTimeInterval(90), app.refreshDueAt)
                let content = UNMutableNotificationContent()
                content.title = "DaySix • Refresh needed"
                content.body = "\(app.name) is due for renewal. Open SideStore and verify it succeeds before expiration."
                content.sound = .default
                let request = UNNotificationRequest(
                    identifier: "daysix.\(app.id.uuidString).due",
                    content: content,
                    trigger: UNTimeIntervalNotificationTrigger(
                        timeInterval: max(60, dueDate.timeIntervalSinceNow), repeats: false))
                center.add(request)
            }
        }
    }
}
