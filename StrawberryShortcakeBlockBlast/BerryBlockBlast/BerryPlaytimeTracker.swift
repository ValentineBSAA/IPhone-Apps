import SwiftUI

/// Private, on-device playtime tracking. Counts foreground time anywhere in
/// Berry Berry Blast (including Village and puzzles), not time spent in the
/// background, on the lock screen or while the app is suspended.
///
/// New 0.5.9 keys are additive: no earlier saves or berry wallets are touched.
@MainActor
final class BerryPlaytimeTracker: ObservableObject {
    static let shared = BerryPlaytimeTracker()

    private static let daysKey = "berryberryblast.playtime.days.v059"
    private static let lifetimeKey = "berryberryblast.playtime.lifetime.v059"

    @Published private(set) var secondsByDay: [String: Double]
    @Published private(set) var lifetimeSeconds: Double
    @Published private(set) var sessionSeconds: Double = 0

    private var lastCheckpoint: Date?
    private var timer: Timer?

    private init() {
        secondsByDay = UserDefaults.standard.dictionary(forKey: Self.daysKey) as? [String: Double] ?? [:]
        lifetimeSeconds = max(0, UserDefaults.standard.double(forKey: Self.lifetimeKey))
    }

    var todaySeconds: Double {
        secondsByDay[Self.dayID(for: Date()), default: 0]
    }

    var daysPlayed: Int {
        secondsByDay.values.filter { $0 > 0 }.count
    }

    struct DailyRecord: Identifiable {
        let id: String
        let label: String
        let seconds: Double
    }

    var lastSevenDays: [DailyRecord] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else {
                return nil
            }
            return DailyRecord(id: Self.dayID(for: day, calendar: calendar),
                               label: Self.dayLabel(for: day),
                               seconds: secondsByDay[Self.dayID(for: day, calendar: calendar), default: 0])
        }
    }

    func scenePhaseDidChange(_ phase: ScenePhase) {
        if phase == .active {
            guard lastCheckpoint == nil else { return } // no duplicate timers
            sessionSeconds = 0
            lastCheckpoint = Date()
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.checkpoint()
                }
            }
        } else {
            checkpoint()
            lastCheckpoint = nil
            timer?.invalidate()
            timer = nil
        }
    }

    /// Save an active foreground segment at least once every ten seconds.
    /// A suspended process cannot claim hours of "play" on its next callback.
    func checkpoint(now: Date = Date()) {
        guard let last = lastCheckpoint else { return }
        let elapsed = max(0, min(25, now.timeIntervalSince(last)))
        lastCheckpoint = now
        guard elapsed > 0 else { return }
        let start = now.addingTimeInterval(-elapsed)
        for segment in Self.segments(from: start, to: now) {
            secondsByDay[segment.day, default: 0] += segment.seconds
        }
        sessionSeconds += elapsed
        lifetimeSeconds += elapsed
        UserDefaults.standard.set(secondsByDay, forKey: Self.daysKey)
        UserDefaults.standard.set(lifetimeSeconds, forKey: Self.lifetimeKey)
    }

    static func dayID(for date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    /// Split the counted interval at local midnight, including DST changes.
    /// Pure function so date accounting can be tested without app lifecycle.
    static func segments(from start: Date, to end: Date,
                         calendar: Calendar = .current) -> [(day: String, seconds: Double)] {
        guard end > start else { return [] }
        var current = start
        var results: [(day: String, seconds: Double)] = []
        while current < end {
            let midnight = calendar.startOfDay(for: current)
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: midnight),
                  tomorrow > current else { break }
            let segmentEnd = min(tomorrow, end)
            results.append((dayID(for: current, calendar: calendar),
                            segmentEnd.timeIntervalSince(current)))
            current = segmentEnd
        }
        return results
    }

    static func display(_ seconds: Double) -> String {
        let whole = max(0, Int(seconds.rounded(.down)))
        let hours = whole / 3_600
        let minutes = (whole % 3_600) / 60
        let remainder = whole % 60
        return hours > 0 ? "\(hours)h \(minutes)m" :
            "\(minutes)m \(remainder)s"
    }
}
