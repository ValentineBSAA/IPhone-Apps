import UIKit
import UserNotifications

/// The OS owns notification presentation. We never draw fake lock-screen alerts.
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()
    static let storyNotificationID = "lastseen-next-story-message"
    static let replyCategory = "LASTSEEN_REPLY"
    static let replyAction = "LASTSEEN_TEXT_REPLY"
    static let replyStorageKey = "lastseen.pendingNotificationReply"

    @MainActor weak var store: GameStore?

    static func install() {
        let center = UNUserNotificationCenter.current()
        center.delegate = shared
        let reply = UNTextInputNotificationAction(
            identifier: replyAction,
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type one of your story replies"
        )
        let category = UNNotificationCategory(
            identifier: replyCategory,
            actions: [reply],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    // Do not show a second native banner on top of an already visible conversation.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([])
    }

    // Quick replies are forwarded into the authored story engine. Unknown text is
    // retained as a draft and never falsely marked as sent to a character.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        guard response.actionIdentifier == Self.replyAction,
              let reply = response as? UNTextInputNotificationResponse,
              let thread = response.notification.request.content.userInfo["thread"] as? String,
              !reply.userText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completionHandler()
            return
        }

        let value = ["text": reply.userText, "thread": thread]
        UserDefaults.standard.set(value, forKey: Self.replyStorageKey)
        Task { @MainActor in
            if let store = self.store {
                store.handleNotificationReply(reply.userText, thread: thread)
                UserDefaults.standard.removeObject(forKey: Self.replyStorageKey)
            }
            completionHandler()
        }
    }
}

final class LastSeenAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        NotificationRouter.install()
        return true
    }
}
