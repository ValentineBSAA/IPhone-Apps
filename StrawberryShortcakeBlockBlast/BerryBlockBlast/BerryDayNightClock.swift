import SwiftUI
import UIKit

/// Local day/night appearance only. This clock is NOT a real Moonberry market
/// or a gameplay timer and must never debit or award either currency.
enum BerryDayNightAppearance {
    static let storageKey = "berryberryblast.visual.night.v046"

    static func isNight(at date: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour >= 18
    }

    /// Calendar wall-time boundaries are authoritative: 6:00 AM and 6:00 PM
    /// in the phone's local time zone. Handles a restart, DST and clock edits.
    static func nextTransition(after date: Date,
                               calendar: Calendar = .autoupdatingCurrent) -> Date {
        let targetHour = isNight(at: date, calendar: calendar) ? 6 : 18
        let target = DateComponents(hour: targetHour, minute: 0, second: 0)
        return calendar.nextDate(after: date, matching: target,
                                 matchingPolicy: .nextTime,
                                 direction: .forward) ?? date.addingTimeInterval(3600)
    }

    /// A real 12-hour local clock with seconds. The calendar parameter
    /// enables deterministic, isolated preview and regression testing.
    static func clockText(_ date: Date,
                          calendar: Calendar = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "h:mm:ss a"
        return formatter.string(from: date)
    }

    static func remainingSeconds(at date: Date,
                                 calendar: Calendar = .autoupdatingCurrent) -> Int {
        let seconds = nextTransition(after: date, calendar: calendar).timeIntervalSince(date)
        // Ceil keeps 00:00:01 visible during the last fractional second,
        // rather than displaying zero before the real 6 AM/6 PM boundary.
        return max(0, Int(ceil(seconds)))
    }

    static func countdownText(at date: Date,
                              calendar: Calendar = .autoupdatingCurrent) -> String {
        let remaining = remainingSeconds(at: date, calendar: calendar)
        let formatted = String(format: "%02d:%02d:%02d",
                               remaining / 3600, (remaining % 3600) / 60,
                               remaining % 60)
        return "\(isNight(at: date, calendar: calendar) ? "Sunrise" : "Moonlight") in \(formatted)"
    }

    /// Virtual time for the permanent Developer Garden. No system-clock or
    /// owner data edits; just a chosen local wall-time on today's calendar date.
    static func previewTime(on day: Date = Date(), hour: Int, minute: Int,
                            second: Int, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        guard (0...23).contains(hour), (0...59).contains(minute),
              (0...59).contains(second) else { return nil }
        var values = calendar.dateComponents([.year, .month, .day], from: day)
        values.hour = hour
        values.minute = minute
        values.second = second
        return calendar.date(from: values)
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

/// Visible Home time and transition countdown are calculated from the CURRENT
/// local wall clock, not an accumulated timer or a future paid-shop deadline.
struct BerryLiveDayNightClock: View {
    @AppStorage(BerryDayNightAppearance.storageKey) private var isNight = false
    @Environment(\.scenePhase) private var phase
    @State private var now = Date()

    private var clock: String { BerryDayNightAppearance.clockText(now) }
    private var countdown: String { BerryDayNightAppearance.countdownText(at: now) }
    private var nightNow: Bool { BerryDayNightAppearance.isNight(at: now) }

    private func clockRow(compact: Bool) -> some View {
        HStack(spacing: 6) {
            if nightNow {
                // Reuse the actual bundled strawberry/moon clock art as a
                // compact night-time ornament, never as a second timekeeper.
                Image("Dev_Timers_Moon_Clock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 19, height: 19)
                    .accessibilityLabel("Night Garden")
            } else {
                Image(systemName: "sun.max.fill")
                    .accessibilityLabel("Day Garden")
            }
            Text(clock)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier("berry.home.clock.time")
            if !compact {
                Text(nightNow ? "Night Garden" : "Day Garden")
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            Spacer(minLength: 3)
            Text(countdown)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier("berry.home.clock.countdown")
        }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            clockRow(compact: false)
            clockRow(compact: true)
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(BerryStyle.chocolate)
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(isNight ? 0.84 : 0.91), in: Capsule())
        .accessibilityElement(children: .contain)
        .onAppear(perform: refresh)
        // The callbacks are redraw opportunities, NOT the source of elapsed
        // seconds. Each redraw samples Date() anew to avoid clock drift.
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            refresh()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.significantTimeChangeNotification)) { _ in
            refresh()
        }
        .onChange(of: phase) { newPhase in
            if newPhase == .active { refresh() }
        }
    }

    private func refresh() {
        let current = Date()
        now = current
        BerryDayNightAppearance.update(now: current)
    }
}

/// Read-only real-handler time fixtures reused by both the Developer Garden
/// State & Timer Lab and its Timers & Clocks tool. No actual phone time edits.
struct BerryClockTransitionPreview: View {
    @State private var selected = 0

    private struct Scenario: Identifiable {
        let id: Int
        let title: String
        let hour: Int
        let minute: Int
        let second: Int
    }

    private let scenarios: [Scenario] = [
        Scenario(id: 0, title: "Before Sunrise", hour: 5, minute: 59, second: 58),
        Scenario(id: 1, title: "At 6 AM", hour: 6, minute: 0, second: 0),
        Scenario(id: 2, title: "Before Moonlight", hour: 17, minute: 59, second: 58),
        Scenario(id: 3, title: "At 6 PM", hour: 18, minute: 0, second: 0)
    ]

    var body: some View {
        VStack(spacing: 10) {
            Text("VIRTUAL CLOCK • SAFE PREVIEW")
                .font(.caption.bold())
                .foregroundStyle(BerryStyle.strawberry)
            Text("Choose a simulated local time. This never changes your iPhone clock, game saves or wallet.")
                .font(.caption)
                .multilineTextAlignment(.center)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                ForEach(scenarios) { scenario in
                    Button(scenario.title) { selected = scenario.id }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .buttonStyle(.bordered)
                        .tint(BerryStyle.strawberry)
                        .accessibilityIdentifier("berry.developer.clock.preview.\(scenario.id)")
                }
            }
            let scenario = scenarios[selected]
            if let date = BerryDayNightAppearance.previewTime(
                hour: scenario.hour, minute: scenario.minute, second: scenario.second
            ) {
                Text("\(BerryDayNightAppearance.clockText(date)) • \(BerryDayNightAppearance.isNight(at: date) ? "Night" : "Day") Garden")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(BerryDayNightAppearance.countdownText(at: date))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .accessibilityIdentifier("berry.developer.clock.preview.countdown")
            }
            Text("Moonlight and Sunrise currently describe visual transitions. The real Moonberry shop is planned for Build 6.")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 15))
    }
}
