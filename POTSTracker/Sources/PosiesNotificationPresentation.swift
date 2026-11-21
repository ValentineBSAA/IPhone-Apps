import Foundation
import UserNotifications
import UIKit

enum PosiesReminderPresentation {
    static let categoryIdentifier = "POSIES_GENTLE_REMINDER"
    static let snoozeIdentifier = "POSIES_SNOOZE_15"
    static let openIdentifier = "POSIES_OPEN"

    static func title(for type: String, revealType: Bool) -> String {
        guard revealType else { return "POTS & Posies 🌸" }
        switch type {
        case "Medication": return "A gentle medication reminder 🌸"
        case "Refill": return "A note about your refill 🌸"
        case "Hydration": return "A little hydration reminder 🌸"
        case "Blood Pressure": return "A moment to record a reading 🌸"
        case "Heart Rate": return "A moment to check in 🌸"
        case "Rest": return "A gentle rest reminder 🌸"
        case "Journal": return "A quiet moment for your journal 🌸"
        default: return "POTS & Posies 🌸"
        }
    }

    static let body = "Your reminder is here whenever you're ready."
}

/// Native banners keep Apple's typography and privacy rules. A matching
/// soft-pink floral illustration can appear when a notification expands.
/// Do not promise custom Lock Screen colors or unrestricted layouts.
enum PosiesNotificationArtwork {
    static func attachment() -> UNNotificationAttachment? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("posies-notification-flower.png")
        if !FileManager.default.fileExists(atPath: url.path) {
            let size = CGSize(width: 360, height: 180)
            let renderer = UIGraphicsImageRenderer(size: size)
            let data = renderer.pngData { context in
                let rectangle = CGRect(origin: .zero, size: size)
                UIColor(red: 0.996, green: 0.950, blue: 0.968, alpha: 1).setFill()
                context.fill(rectangle)
                let blush = UIColor(red: 0.61, green: 0.19, blue: 0.39, alpha: 1)
                let circle = CGRect(x: 144, y: 35, width: 72, height: 72)
                blush.setFill()
                UIBezierPath(ovalIn: circle).fill()
                if let symbol = UIImage(systemName: "heart.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                    symbol.draw(in: CGRect(x: 164, y: 54, width: 32, height: 30))
                }
                let label = "POTS & Posies"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                    .foregroundColor: blush
                ]
                let textSize = (label as NSString).size(withAttributes: attributes)
                (label as NSString).draw(
                    at: CGPoint(x: (size.width - textSize.width) / 2, y: 119),
                    withAttributes: attributes
                )
            }
            do { try data.write(to: url, options: .atomic) }
            catch { return nil }
        }
        return try? UNNotificationAttachment(identifier: "posies-flower", url: url, options: nil)
    }
}

/// Local-only notification actions. Snooze doesn't log a medication as
/// taken, and tapping a reminder never makes medical claims.
final class PosiesNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([
            UNNotificationCategory(identifier: PosiesReminderPresentation.categoryIdentifier, actions: [
                UNNotificationAction(identifier: PosiesReminderPresentation.snoozeIdentifier,
                                     title: "In 15 minutes", options: []),
                UNNotificationAction(identifier: PosiesReminderPresentation.openIdentifier,
                                     title: "Open POTS & Posies", options: [.foreground])
            ], intentIdentifiers: [], options: [])
        ])
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        guard response.actionIdentifier == PosiesReminderPresentation.snoozeIdentifier else {
            completionHandler()
            return
        }
        let copy = (response.notification.request.content.mutableCopy() as? UNMutableNotificationContent)
            ?? UNMutableNotificationContent()
        copy.title = "POTS & Posies 🌸"
        copy.body = PosiesReminderPresentation.body
        copy.userInfo = [:]
        let request = UNNotificationRequest(
            identifier: "posies-snooze-" + UUID().uuidString,
            content: copy,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
        )
        center.add(request) { _ in completionHandler() }
    }
}
