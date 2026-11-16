import BackgroundTasks
import Foundation
import UIKit
import UserNotifications

/// Extra, opportunistic safety net for Apple's BGAppRefreshTask API.
///
/// BGTaskScheduler decides whether and when to execute this work. This task
/// never attempts signing, opens SideStore, runs Shortcuts, or maintains a
/// fake persistent foreground/background service. It only evaluates the
/// local signing dates and can display a rescue notification.
final class DaySixLifecycleDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
                        [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Required to present real iOS banners and sounds even while the
        // DaySix screen is foregrounded (including a five-second test).
        UNUserNotificationCenter.current().delegate = self
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundRenewalWatchdog.identifier,
            using: nil) { task in
                guard let task = task as? BGAppRefreshTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                BackgroundRenewalWatchdog.handle(task)
            }
        BackgroundRenewalWatchdog.schedule()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        BackgroundRenewalWatchdog.schedule()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        // The system's own notification authorization, Focus and sound
        // preferences still override these presentation options.
        [.banner, .list, .sound]
    }
}

enum BackgroundRenewalWatchdog {
    static let identifier = "com.valentinebsaa.daysix.refresh"
    static let checkedKey = "daysix.background.lastChecked.v1"
    private static let notifiedSelfKey = "daysix.background.selfNotifiedExpiry.v1"

    static var lastChecked: Date? {
        UserDefaults.standard.object(forKey: checkedKey) as? Date
    }

    static func schedule(now: Date = .now) {
        // Reuse a single pending request. EarliestBeginDate only describes
        // our *preference*; Apple is free to postpone or skip the task.
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        let request = BGAppRefreshTaskRequest(identifier: identifier)

        // Recheck occasionally and preferentially near the next renewal.
        let expirations = [SelfProvisioning.effectiveExpiry].compactMap { $0 }
            + DaySixStorage.read().map(\.expiresAt)
        let nextWindow = expirations
            .filter { $0 > now }
            .map { RenewalPolicy.renewAt(expiration: $0) }
            .min()
        let desiredDelay: TimeInterval
        if let nextWindow {
            desiredDelay = min(12 * 3600, max(2 * 3600,
                                nextWindow.timeIntervalSince(now)))
        } else {
            desiredDelay = 12 * 3600
        }
        request.earliestBeginDate = now.addingTimeInterval(desiredDelay)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Expected when Background App Refresh is disabled, restricted,
            // or the system refuses the request. Local notifications and
            // user-configured Shortcuts remain independent fallbacks.
        }
    }

    static func handle(_ task: BGAppRefreshTask) {
        schedule()
        let worker = Task {
            RenewalAudit.reconcileSelfSignature()
            let now = Date.now
            UserDefaults.standard.set(now, forKey: checkedKey)

            // An opportunistic safety alert. We do NOT count this as a
            // signing attempt, successful renewal, or a guarantee.
            if DaySixNotificationPreferences.critical,
               (UserDefaults.standard.object(forKey: DaySixStorage.remindersKey) == nil
                || UserDefaults.standard.bool(forKey: DaySixStorage.remindersKey)),
               let expiry = SelfProvisioning.effectiveExpiry,
               expiry > now,
               RenewalPolicy.isDue(expiration: expiry, now: now) {
                let previouslyNotified = UserDefaults.standard.object(
                    forKey: notifiedSelfKey) as? Date
                if previouslyNotified != expiry {
                    let content = UNMutableNotificationContent()
                    content.title = "DaySix still needs renewal"
                    content.body = "Apple allowed a background check. DaySix is near expiry; confirm the SideStore refresh."
                    content.sound = .default
                    let request = UNNotificationRequest(
                        identifier: "daysix.background.self.",
                        content: content, trigger: nil)
                    do {
                        try await UNUserNotificationCenter.current().add(request)
                        UserDefaults.standard.set(expiry, forKey: notifiedSelfKey)
                    } catch {
                        // Notifications may be unauthorized or disabled.
                    }
                }
            }
            task.setTaskCompleted(success: !Task.isCancelled)
        }
        task.expirationHandler = {
            worker.cancel()
        }
    }
}
