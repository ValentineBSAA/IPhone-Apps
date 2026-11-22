import SwiftUI
import UIKit
import UserNotifications

/// These switches govern which local notifications DaySix schedules.
/// They never override Apple's iOS notification authorization, Focus,
/// sounds, banners, Lock Screen and delivery settings.
enum DaySixNotificationPreferences {
    static let preflightKey = "daysix.notify.preflightEnabled.v1"
    static let dueKey = "daysix.notify.dueEnabled.v1"
    static let criticalKey = "daysix.notify.criticalEnabled.v1"

    static func enabled(_ key: String) -> Bool {
        UserDefaults.standard.object(forKey: key) == nil
            || UserDefaults.standard.bool(forKey: key)
    }

    static var preflight: Bool { enabled(preflightKey) }
    static var due: Bool { enabled(dueKey) }
    static var critical: Bool { enabled(criticalKey) }
}

/// Actual native UserNotifications status and preferences, not a substitute
/// for the iPhone Settings → Apps → DaySix → Notifications system page.
struct DaySixNotificationSettingsView: View {
    @EnvironmentObject private var store: DaySixStore

    @AppStorage(DaySixNotificationPreferences.preflightKey)
    private var preflightEnabled = true
    @AppStorage(DaySixNotificationPreferences.dueKey)
    private var dueEnabled = true
    @AppStorage(DaySixNotificationPreferences.criticalKey)
    private var criticalEnabled = true

    @State private var authorization: UNAuthorizationStatus = .notDetermined
    @State private var soundSetting: UNNotificationSetting = .notSupported
    @State private var alertSetting: UNNotificationSetting = .notSupported
    @State private var badgeSetting: UNNotificationSetting = .notSupported
    @State private var testMessage = ""

    private var permissionGranted: Bool {
        authorization == .authorized || authorization == .provisional
            || authorization == .ephemeral
    }

    private var authorizationDescription: String {
        switch authorization {
        case .notDetermined: return "Not requested"
        case .denied: return "Disabled in iPhone Settings"
        case .authorized: return "Allowed by iOS"
        case .provisional: return "Quietly allowed by iOS"
        case .ephemeral: return "Temporarily allowed"
        @unknown default: return "Unknown"
        }
    }

    var body: some View {
        DaySixBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    SectionHeading(
                        title: "Notifications",
                        subtitle: "Real iPhone banners, sounds, and signature-expiration alerts.")

                    GlassCard {
                        VStack(alignment: .leading, spacing: 13) {
                            Label("Apple Notification Permission",
                                  systemImage: "bell.badge.fill")
                                .font(.headline)
                                .foregroundStyle(DS.mint)

                            HStack(spacing: 10) {
                                Image(systemName: permissionGranted
                                      ? "checkmark.circle.fill"
                                      : "exclamationmark.circle.fill")
                                    .foregroundStyle(permissionGranted ? DS.mint : DS.amber)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(authorizationDescription)
                                        .font(.subheadline.bold())
                                    Text("Managed by iOS, not by DaySix")
                                        .font(.caption)
                                        .foregroundStyle(DS.muted)
                                }
                            }

                            if authorization == .notDetermined {
                                GlowButton(title: "Enable iPhone Notifications",
                                           symbol: "bell.badge") {
                                    requestPermission()
                                }
                            }

                            Button {
                                openSystemNotificationSettings()
                            } label: {
                                Label("Open iPhone Notification Settings",
                                      systemImage: "gearshape.arrow.triangle.2.circlepath")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(DS.mint)
                            }

                            Text("In iPhone Settings → Apps → DaySix → Notifications, choose banners, Lock Screen alerts, Notification Center, sounds, badges, and delivery preferences. DaySix cannot change those system options itself.")
                                .font(.footnote)
                                .foregroundStyle(DS.muted)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 11) {
                            Label("iOS Delivery Readiness", systemImage: "iphone.radiowaves.left.and.right")
                                .font(.headline)
                                .foregroundStyle(DS.violet)
                            statusRow("Visual alerts", enabled: alertSetting == .enabled)
                            statusRow("Notification sounds", enabled: soundSetting == .enabled)
                            statusRow("App icon badges", enabled: badgeSetting == .enabled)
                            Text("Focus, Silent Mode and Scheduled Summary can also affect what you see or hear. These statuses come from Apple's notification settings.")
                                .font(.caption)
                                .foregroundStyle(DS.muted)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 13) {
                            Label("DaySix Alert Types", systemImage: "slider.horizontal.3")
                                .font(.headline)
                                .foregroundStyle(DS.mint)

                            Toggle("Signature reminders enabled",
                                   isOn: $store.remindersEnabled)
                                .tint(DS.mint)

                            Toggle("Early signing health checks",
                                   isOn: $preflightEnabled)
                                .tint(DS.mint)
                                .disabled(!store.remindersEnabled)

                            Toggle("Day-six renewal due alerts",
                                   isOn: $dueEnabled)
                                .tint(DS.mint)
                                .disabled(!store.remindersEnabled)

                            Toggle("Six-hour emergency reminders",
                                   isOn: $criticalEnabled)
                                .tint(DS.mint)
                                .disabled(!store.remindersEnabled)

                            Text("These switches control DaySix's reminders only. iOS controls the actual alert style, sounds and permission.")
                                .font(.footnote)
                                .foregroundStyle(DS.muted)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Test a Real iPhone Alert", systemImage: "bell.and.waves.left.and.right")
                                .font(.headline)
                                .foregroundStyle(DS.violet)
                            Text("Schedule a genuine local notification in five seconds, including the default iOS sound. This tests notification delivery, not whether signing or automatic renewal succeeds.")
                                .font(.footnote)
                                .foregroundStyle(DS.muted)
                            GlowButton(title: "Send Test Notification",
                                       symbol: "bell.badge.fill") {
                                sendTest()
                            }
                            .disabled(!permissionGranted)
                            if !testMessage.isEmpty {
                                Text(testMessage)
                                    .font(.caption)
                                    .foregroundStyle(DS.muted)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("iPhone Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshStatus() }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification)) { _ in
                Task { await refreshStatus() }
            }
        .onChange(of: preflightEnabled) { _, _ in store.syncNotifications() }
        .onChange(of: dueEnabled) { _, _ in store.syncNotifications() }
        .onChange(of: criticalEnabled) { _, _ in store.syncNotifications() }
    }

    private func statusRow(_ label: String, enabled: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: enabled ? "checkmark.circle.fill" : "minus.circle")
                .foregroundStyle(enabled ? DS.mint : DS.amber)
            Text(label).font(.subheadline)
            Spacer()
            Text(enabled ? "On" : "Off")
                .font(.caption.bold())
                .foregroundStyle(enabled ? DS.mint : DS.muted)
        }
    }

    private func requestPermission() {
        Task {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
            store.syncNotifications()
        }
    }

    private func openSystemNotificationSettings() {
        guard let url = URL(
            string: UIApplication.openNotificationSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
    }

    private func sendTest() {
        Task {
            let content = UNMutableNotificationContent()
            content.title = "DaySix Notifications Work"
            content.body = "This is a real iPhone notification. DaySix can warn before your signing profile expires."
            content.sound = .default
            content.categoryIdentifier = "DAYSIX_SIGNING_REMINDER"
            let request = UNNotificationRequest(
                identifier: "daysix-test.manual",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(
                    timeInterval: 5, repeats: false))
            do {
                try await UNUserNotificationCenter.current().add(request)
                testMessage = "Test scheduled. You should receive a local iPhone alert in about five seconds."
            } catch {
                testMessage = "iOS could not schedule the test: \(error.localizedDescription)"
            }
        }
    }

    private func refreshStatus() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        authorization = status.authorizationStatus
        soundSetting = status.soundSetting
        alertSetting = status.alertSetting
        badgeSetting = status.badgeSetting
    }
}
