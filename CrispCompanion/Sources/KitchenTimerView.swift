import SwiftUI
import UserNotifications

struct KitchenTimerView: View {
    @State private var minutes = 15
    @AppStorage("manualTimerEndTimestamp") private var endTimestamp: Double = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeading(eyebrow: "KITCHEN TOOLS", title: "Your little sous-chef.", subtitle: "A manual timer with optional local reminders.")
                CrispCard {
                    Label("Independent kitchen timer", systemImage: "timer")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("This timer does not read, start, or stop the air fryer.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let seconds = max(0, Int(endTimestamp - context.date.timeIntervalSince1970))
                        VStack(spacing: 6) {
                            Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                                .font(.system(size: 62, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(CrispPalette.cream)
                            Text(endTimestamp > 0 ? (seconds > 0 ? "COUNTDOWN RUNNING" : "TIMER FINISHED") : "READY")
                                .font(.caption.weight(.bold)).tracking(2)
                                .foregroundColor(CrispPalette.muted)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 24)
                    }
                    Stepper("Set \(minutes) minutes", value: $minutes, in: 1...120)
                        .font(.headline).foregroundColor(CrispPalette.cream)
                    HStack(spacing: 12) {
                        Button {
                            endTimestamp = Date().addingTimeInterval(TimeInterval(minutes * 60)).timeIntervalSince1970
                            scheduleNotification(minutes: minutes)
                        } label: {
                            Label("Start timer", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).tint(CrispPalette.gold).foregroundColor(CrispPalette.background)
                        Button {
                            endTimestamp = 0
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["crisp-manual-timer"])
                        } label: {
                            Label("Clear", systemImage: "xmark").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                CrispCard {
                    Label("A gentle reminder", systemImage: "bell.badge")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Notifications are requested only when you start a timer. They describe your manual timer, not an actual cooking-complete event.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                }
            }
            .padding(20)
        }
        .background(CrispPalette.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func scheduleNotification(minutes: Int) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Your kitchen timer is up"
            content.body = "Your manual Crisp Companion timer has finished. Check your food and appliance."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
            center.removePendingNotificationRequests(withIdentifiers: ["crisp-manual-timer"])
            center.add(UNNotificationRequest(identifier: "crisp-manual-timer", content: content, trigger: trigger))
        }
    }
}
