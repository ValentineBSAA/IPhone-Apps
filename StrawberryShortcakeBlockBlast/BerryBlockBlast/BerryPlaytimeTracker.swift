import SwiftUI

/// Private, offline playtime journal. Foreground app totals retain their
/// 0.5.9 UserDefaults keys; all mode-level records use new additive keys.
/// Background, locked, paused and results-screen time is never credited
/// to a gameplay mode. Records can be viewed in Personal Records.
@MainActor
final class BerryPlaytimeTracker: ObservableObject {
    static let shared = BerryPlaytimeTracker()

    private static let daysKey = "berryberryblast.playtime.days.v059"
    private static let lifetimeKey = "berryberryblast.playtime.lifetime.v059"
    private static let modesKey = "berryberryblast.playtime.modes.v059"
    private static let modeDaysKey = "berryberryblast.playtime.modeDays.v059"
    private static let sessionsKey = "berryberryblast.playtime.sessions.v059"
    private static let historyLimit = 300

    @Published private(set) var secondsByDay: [String: Double]
    @Published private(set) var lifetimeSeconds: Double
    @Published private(set) var sessionSeconds: Double = 0
    @Published private(set) var secondsByMode: [String: Double]
    @Published private(set) var secondsByDayAndMode: [String: [String: Double]]
    @Published private(set) var modeSessions: [ModeSession]

    private var lastCheckpoint: Date?
    private var timer: Timer?
    private var selectedMode: (id: String, title: String)?
    private var modeCanCount = false
    private var activeSessionID: UUID?

    struct ModeEntry: Identifiable {
        let id: String
        let title: String
        let art: String
    }

    /// Match the same twelve modes displayed in Personal Best scores.
    static let modeCatalog: [ModeEntry] = [
        ModeEntry(id: "classic", title: "Berry Classic", art: "BerryClassic"),
        ModeEntry(id: "endless-8", title: "Sweet Endless 8×8", art: "SweetEndless"),
        ModeEntry(id: "endless-12", title: "Sweet Endless 12×12", art: "SweetEndless"),
        ModeEntry(id: "endless-24", title: "Sweet Endless 24×24", art: "SweetEndless"),
        ModeEntry(id: "story", title: "Berry Story", art: "BerryStory"),
        ModeEntry(id: "daily", title: "Daily Harvest", art: "DailyHarvest"),
        ModeEntry(id: "cozy", title: "Cozy Cottage", art: "CottageDecorations"),
        ModeEntry(id: "nightmare", title: "Strawberry Nightmare", art: "BerryClassic"),
        ModeEntry(id: "blitz-60", title: "Quick Jam · 1 min", art: "Milestone"),
        ModeEntry(id: "blitz-120", title: "Berry Rush · 2 min", art: "Milestone"),
        ModeEntry(id: "blitz-300", title: "Garden Sprint · 5 min", art: "Milestone"),
        ModeEntry(id: "blitz-600", title: "Berry Marathon · 10 min", art: "Milestone")
    ]

    struct ModeSession: Codable, Identifiable {
        let id: UUID
        let modeID: String
        let title: String
        let startedAt: Date
        var endedAt: Date
        var activeSeconds: Double

        /// Local date/time are formatted on the player's iPhone. No
        /// historical timestamps are made up when enabling tracking.
        var dayLabel: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: startedAt)
        }
        var timeRange: String {
            BerryPlaytimeTracker.clock(startedAt) + " – " +
                BerryPlaytimeTracker.clock(endedAt)
        }
    }

    private init() {
        secondsByDay = UserDefaults.standard.dictionary(forKey: Self.daysKey)
            as? [String: Double] ?? [:]
        lifetimeSeconds = max(0, UserDefaults.standard.double(forKey: Self.lifetimeKey))
        secondsByMode = UserDefaults.standard.dictionary(forKey: Self.modesKey)
            as? [String: Double] ?? [:]
        secondsByDayAndMode = (UserDefaults.standard.data(forKey: Self.modeDaysKey))
            .flatMap { try? JSONDecoder().decode([String: [String: Double]].self, from: $0) } ?? [:]
        modeSessions = (UserDefaults.standard.data(forKey: Self.sessionsKey))
            .flatMap { try? JSONDecoder().decode([ModeSession].self, from: $0) } ?? []
    }

    var todaySeconds: Double {
        secondsByDay[Self.dayID(for: Date()), default: 0]
    }

    var daysPlayed: Int {
        secondsByDay.values.filter { $0 > 0 }.count
    }

    var recentSessions: [ModeSession] {
        Array(modeSessions.filter { $0.activeSeconds > 0 }.reversed())
    }

    func modeSeconds(for id: String) -> Double {
        secondsByMode[id, default: 0]
    }

    func modeSecondsToday(for id: String) -> Double {
        secondsByDayAndMode[Self.dayID(for: Date())]?[id] ?? 0
    }

    func latestModeSession(for id: String) -> ModeSession? {
        modeSessions.last(where: { $0.modeID == id && $0.activeSeconds > 0 })
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

    /// Called by a visible puzzle view. Does not reset the overall app timer.
    /// Each fresh foreground visit creates one dated session for this mode.
    func enterMode(_ id: String, title: String) {
        guard selectedMode?.id != id || selectedMode?.title != title else { return }
        checkpoint()
        activeSessionID = nil
        selectedMode = (id, title)
        modeCanCount = true
        beginModeSegment(at: Date())
    }

    /// Pause/resume mode timing for game overlays, victory or a manual pause.
    /// The overall time spent inside the app is still recorded separately.
    func setModePlaying(_ enabled: Bool) {
        guard modeCanCount != enabled else { return }
        checkpoint()
        if !enabled { activeSessionID = nil }
        modeCanCount = enabled
        if enabled { beginModeSegment(at: Date()) }
    }

    func leaveMode() {
        checkpoint()
        activeSessionID = nil
        selectedMode = nil
        modeCanCount = false
    }

    func scenePhaseDidChange(_ phase: ScenePhase) {
        if phase == .active {
            guard lastCheckpoint == nil else { return }
            sessionSeconds = 0
            lastCheckpoint = Date()
            beginModeSegment(at: Date())
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.checkpoint() }
            }
        } else {
            checkpoint()
            activeSessionID = nil
            lastCheckpoint = nil
            timer?.invalidate()
            timer = nil
        }
    }

    private func beginModeSegment(at now: Date) {
        guard lastCheckpoint != nil, modeCanCount,
              let selectedMode, activeSessionID == nil else { return }
        let id = UUID()
        activeSessionID = id
        modeSessions.append(ModeSession(id: id, modeID: selectedMode.id,
                                        title: selectedMode.title, startedAt: now,
                                        endedAt: now, activeSeconds: 0))
        if modeSessions.count > Self.historyLimit {
            modeSessions.removeFirst(modeSessions.count - Self.historyLimit)
        }
    }

    /// The same 25-second safety cap as legacy 0.5.9 overall tracking.
    /// Credit mode time only if the mode is visible, active and unpaused.
    func checkpoint(now: Date = Date()) {
        guard let last = lastCheckpoint else { return }
        let elapsed = max(0, min(25, now.timeIntervalSince(last)))
        lastCheckpoint = now
        guard elapsed > 0 else { return }
        let start = now.addingTimeInterval(-elapsed)
        let slices = Self.segments(from: start, to: now)
        for segment in slices {
            secondsByDay[segment.day, default: 0] += segment.seconds
        }
        sessionSeconds += elapsed
        lifetimeSeconds += elapsed

        if modeCanCount, let selectedMode, let id = activeSessionID {
            secondsByMode[selectedMode.id, default: 0] += elapsed
            for segment in slices {
                var daily = secondsByDayAndMode[segment.day, default: [:]]
                daily[selectedMode.id, default: 0] += segment.seconds
                secondsByDayAndMode[segment.day] = daily
            }
            if let index = modeSessions.firstIndex(where: { $0.id == id }) {
                modeSessions[index].endedAt = now
                modeSessions[index].activeSeconds += elapsed
            }
        }
        UserDefaults.standard.set(secondsByDay, forKey: Self.daysKey)
        UserDefaults.standard.set(lifetimeSeconds, forKey: Self.lifetimeKey)
        UserDefaults.standard.set(secondsByMode, forKey: Self.modesKey)
        if let data = try? JSONEncoder().encode(secondsByDayAndMode) {
            UserDefaults.standard.set(data, forKey: Self.modeDaysKey)
        }
        if let data = try? JSONEncoder().encode(modeSessions) {
            UserDefaults.standard.set(data, forKey: Self.sessionsKey)
        }
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

    nonisolated static func clock(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }

    /// Split foreground playtime at local midnight, including DST changes.
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
