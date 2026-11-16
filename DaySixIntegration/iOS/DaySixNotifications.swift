import Foundation
import UserNotifications
import UIKit
import DaySixIntegration

@MainActor
struct DaySixNotifications {
    /// Requests the system prompt, causing the app to appear in iOS notification settings.
    static func requestPermission() async throws -> Bool {
        try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
    }

    static func scheduleRenewalReminder(appName: String, appIdentifier: String, plan: RenewalPlan) async throws {
        let notification = UNMutableNotificationContent()
        notification.title = "Time to renew \(appName)"
        notification.body = "DaySix is ready to refresh this app before its signing expires."
        notification.sound = .default
        notification.categoryIdentifier = "DAYSIX_RENEWAL"

        let secondsUntil = plan.firstAttemptAt.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, secondsUntil), repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "daysix.renew.\(appIdentifier)",
            content: notification,
            trigger: trigger
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    static func openIOSNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}