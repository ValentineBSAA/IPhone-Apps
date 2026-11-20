import SwiftUI
import UIKit

/// Build 4.6: strictly cosmetic local 6 AM / 6 PM transitions. This is not
/// Moonberry shop logic and never changes an active game or saved economy.
enum BerryDayNightAppearance {
    static let storageKey = "berryberryblast.visual.night.v046"

    static func isNight(at date: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour >= 18
    }

    static func nextTransition(after date: Date,
                               calendar: Calendar = .autoupdatingCurrent) -> Date {
        let targetHour = isNight(at: date, calendar: calendar) ? 6 : 18
        let target = DateComponents(hour: targetHour, minute: 0, second: 0)
        return calendar.nextDate(after: date, matching: target,
                                 matchingPolicy: .nextTime,
                                 direction: .forward) ?? date.addingTimeInterval(3600)
    }

    static func clockText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    static func update(now: Date = Date(), defaults: UserDefaults = .standard) {
        let newValue = isNight(at: now)
        if defaults.object(forKey: storageKey) as? Bool != newValue {
            defaults.set(newValue, forKey: storageKey)
        }
    }

    static func nightCounterpart(for original: String) -> String? {
        switch original {
        case "BBBIconHome": return "Night_Home"
        case "BBBIconPause": return "Night_Pause"
        case "BBBIconSettings": return "Night_Settings"
        case "BBBIconHelp": return "Night_Help"
        case "BBBIconTools": return "Night_Special_Tools"
        case "SweetEndless": return "Night_Sweet_Endless"
        case "Strawberry_Currency": return "Night_Strawberry_Currency"
        case "BBBIconBoard", "Board_Theme_Icon": return "Night_Board_Theme_Icon"
        case "UndoIcon": return "Night_Rotate"
        case "SeedIcon": return "Night_Seed"
        case "StorageIcon": return "Night_Storage"
        default: return nil
        }
    }

    static func assetName(for original: String, night: Bool) -> String {
        guard night, let candidate = nightCounterpart(for: original),
              UIImage(named: candidate) != nil else { return original }
        return candidate
    }
}

/// The 12-hour display is a visual indicator, not an in-game economy timer.
struct BerryLiveDayNightClock: View {
    @AppStorage(BerryDayNightAppearance.storageKey) private var isNight = false
    @Environment(\.scenePhase) private var phase
    @State private var now = Date()

    var body: some View {
        let until = max(0, Int(ceil(
            BerryDayNightAppearance.nextTransition(after: now).timeIntervalSince(now) / 60)))
        HStack(spacing: 7) {
            Image(systemName: isNight ? "moon.stars.fill" : "sun.max.fill")
            Text(BerryDayNightAppearance.clockText(now))
                .monospacedDigit()
            Text(isNight ? "Night Garden" : "Day Garden")
            Spacer(minLength: 3)
            Text("\(isNight ? "Sunrise" : "Moonlight") in \(until / 60)h \(until % 60)m")
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(BerryStyle.chocolate)
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(.white.opacity(isNight ? 0.84 : 0.91), in: Capsule())
        .accessibilityLabel("Local time \(BerryDayNightAppearance.clockText(now)). \(isNight ? "Night" : "Day") Garden.")
        .onAppear { now = Date(); BerryDayNightAppearance.update(now: now) }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { date in
            now = date
            BerryDayNightAppearance.update(now: date)
        }
        .onChange(of: phase) { value in
            if value == .active {
                now = Date()
                BerryDayNightAppearance.update(now: now)
            }
        }
    }
}
