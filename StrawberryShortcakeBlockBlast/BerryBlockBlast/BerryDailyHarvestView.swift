import SwiftUI

/// Local-date based challenge history. Uses existing completion key for migration.
enum BerryDailyHistory {
    static let key = "berryblockblast.daily.history.v057"
    private static let attemptKey = "berryberryblast.daily.attempt.v0510"
    private static let resultsKey = "berryberryblast.daily.outcomes.v0510"

    enum Outcome: String, Codable { case active, won, lost }

    /// One dated active attempt. Loss/win status is also stored separately so
    /// a cleared or malformed snapshot cannot grant a second attempt.
    struct Attempt: Codable {
        let day: String
        var outcome: Outcome
        var engine: BerryEngine?
    }

    static func outcome(on date: Date = Date(),
                        defaults: UserDefaults = .standard) -> Outcome? {
        let day = dateKey(for: date)
        let old = defaults.string(forKey: "berryblockblast.daily.completed") ?? ""
        let previouslyCompleted = defaults.stringArray(forKey: key) ?? []
        if old == day || previouslyCompleted.contains(day) { return .won }
        if let result = (defaults.dictionary(forKey: resultsKey) as? [String: String])?[day],
           let decoded = Outcome(rawValue: result) { return decoded }
        guard let record = loadAttempt(defaults: defaults), record.day == day else { return nil }
        return record.outcome
    }

    private static func loadAttempt(defaults: UserDefaults = .standard) -> Attempt? {
        guard let data = defaults.data(forKey: attemptKey) else { return nil }
        return try? JSONDecoder().decode(Attempt.self, from: data)
    }

    static func activeEngine(defaults: UserDefaults = .standard) -> BerryEngine? {
        guard outcome(defaults: defaults) == .active,
              let record = loadAttempt(defaults: defaults),
              record.day == dateKey(for: Date()) else { return nil }
        return record.engine
    }

    /// Consumes the day's attempt immediately, before the first placement.
    /// Existing in-progress attempts can resume, but finished ones cannot.
    @discardableResult
    static func beginToday(defaults: UserDefaults = .standard) -> Bool {
        if let current = outcome(defaults: defaults) { return current == .active }
        let attempt = Attempt(day: dateKey(for: Date()), outcome: .active, engine: nil)
        if let encoded = try? JSONEncoder().encode(attempt) {
            defaults.set(encoded, forKey: attemptKey)
            var outcomes = defaults.dictionary(forKey: resultsKey) as? [String:String] ?? [:]
            outcomes[attempt.day] = Outcome.active.rawValue
            defaults.set(outcomes, forKey: resultsKey)
            return true
        }
        return false
    }

    static func saveActiveEngine(_ engine: BerryEngine,
                                 defaults: UserDefaults = .standard) {
        guard outcome(defaults: defaults) == .active,
              let record = loadAttempt(defaults: defaults),
              record.day == dateKey(for: Date()) else { return }
        let update = Attempt(day: record.day, outcome: .active, engine: engine)
        if let encoded = try? JSONEncoder().encode(update) {
            defaults.set(encoded, forKey: attemptKey)
        }
    }

    private static func finishToday(_ outcome: Outcome,
                                    defaults: UserDefaults = .standard) {
        guard outcome == .won || outcome == .lost,
              self.outcome(defaults: defaults) == .active else { return }
        let day = dateKey(for: Date())
        var outcomes = defaults.dictionary(forKey: resultsKey) as? [String:String] ?? [:]
        outcomes[day] = outcome.rawValue
        defaults.set(outcomes, forKey: resultsKey)
        let completed = Attempt(day: day, outcome: outcome, engine: nil)
        if let encoded = try? JSONEncoder().encode(completed) {
            defaults.set(encoded, forKey: attemptKey)
        }
    }

    static func markLostToday(defaults: UserDefaults = .standard) {
        finishToday(.lost, defaults: defaults)
    }

    static var losses: Int {
        let results = UserDefaults.standard.dictionary(forKey: resultsKey) as? [String:String] ?? [:]
        return results.values.filter { $0 == Outcome.lost.rawValue }.count
    }

    static var wins: Int {
        let old = completed
        let results = UserDefaults.standard.dictionary(forKey: resultsKey) as? [String:String] ?? [:]
        return Set(results.filter { $0.value == Outcome.won.rawValue }.map { $0.key })
            .union(old).count
    }

    static func dateKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 1970,
                      components.month ?? 1, components.day ?? 1)
    }
    static var completed: Set<String> {
        let legacy = UserDefaults.standard.string(forKey: "berryblockblast.daily.completed") ?? ""
        let entries = UserDefaults.standard.stringArray(forKey: key) ?? []
        return Set(entries + (legacy.isEmpty ? [] : [legacy]))
    }
    static func markCompleteToday() {
        guard outcome() == .active else { return }
        finishToday(.won)
        var values = completed
        values.insert(dateKey(for: Date()))
        UserDefaults.standard.set(values.sorted(), forKey: key)
    }
    /// Award for a new challenge completion, based on yesterday's intact
    /// streak. Day 7 and every further consecutive day pay 50 berries.
    static let rewardLadder = [10, 15, 20, 25, 30, 40, 50]
    static func reward(forStreakDay day: Int) -> Int {
        rewardLadder[min(6, max(0, day - 1))]
    }
    static var nextStreakDay: Int {
        let today = Calendar.current.startOfDay(for: Date())
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else { return 1 }
        guard completed.contains(dateKey(for: yesterday)) else { return 1 }
        var cursor = yesterday
        var count = 0
        while completed.contains(dateKey(for: cursor)) {
            count += 1
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return min(10000, count + 1)
    }
    static var rewardToday: Int {
        if completed.contains(dateKey(for: Date())) { return 0 }
        return reward(forStreakDay: nextStreakDay)
    }
    static var streak: Int {
        let dates = completed
        var day = Calendar.current.startOfDay(for: Date())
        if !dates.contains(dateKey(for: day)),
           let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }
        var count = 0
        while dates.contains(dateKey(for: day)) {
            count += 1
            guard let prior = Calendar.current.date(byAdding: .day, value: -1, to: day) else { break }
            day = prior
        }
        return count
    }
}

struct BerryDailyHarvestView: View {
    let goal: Int
    @Environment(\.dismiss) private var dismiss
    @State private var month = Calendar.current.startOfDay(for: Date())
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    private var monthStart: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: month)) ?? month
    }
    private var offset: Int {
        (Calendar.current.component(.weekday, from: monthStart) - Calendar.current.firstWeekday + 7) % 7
    }
    private var totalDays: Int {
        Calendar.current.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }
    private func date(at index: Int) -> Date? {
        let dayNumber = index - offset
        guard (0..<totalDays).contains(dayNumber) else { return nil }
        return Calendar.current.date(byAdding: .day, value: dayNumber, to: monthStart)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image("BerryDailyHarvestHeader").resizable().scaledToFit()
                        .frame(maxWidth: 330).frame(height: 103)
                        .accessibilityHidden(true)
                    Text("Daily Harvest Calendar")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Text("One attempt per day. Win or lose, there are no retries. An unfinished game can resume later today. New challenges unlock at local midnight.")
                        .font(.subheadline).multilineTextAlignment(.center)
                    HStack(spacing: 8) {
                        info("Today", value: Date().formatted(.dateTime.month(.abbreviated).day()))
                        info("Streak", value: "🍓 \(BerryDailyHistory.streak)")
                        info("Completed", value: "\(BerryDailyHistory.completed.count)")
                    }
                    VStack(spacing: 9) {
                        Text("🍓 STREAK REWARD LADDER")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                        HStack(spacing: 3) {
                            ForEach(1...7, id: \.self) { day in
                                VStack(spacing: 3) {
                                    Text("Day \(day)").font(.system(size: 9, weight: .bold))
                                    Text("🍓\(BerryDailyHistory.reward(forStreakDay: day))")
                                        .font(.system(size: 10, weight: .black))
                                        .minimumScaleFactor(0.7)
                                }
                                .foregroundStyle(day <= BerryDailyHistory.streak ? BerryStyle.leaf : BerryStyle.strawberry)
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .background(day == min(7, BerryDailyHistory.nextStreakDay) ?
                                            BerryStyle.softPink : Color.white, in: RoundedRectangle(cornerRadius: 9))
                            }
                        }
                        Text(BerryDailyHistory.rewardToday > 0 ?
                             "Complete today's harvest for 🍓 \(BerryDailyHistory.rewardToday)" :
                             "Today's reward collected. Come back tomorrow!")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                    }
                    .padding(11)
                    .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 17))
                    VStack(spacing: 7) {
                        Text("TODAY'S OBJECTIVE").font(.caption.bold())
                        BerryCandyNumber(value: "Score \(goal) points", size: 21)
                        Text(BerryDailyHistory.outcome() == .won ? "✓ Won today!" :
                             BerryDailyHistory.outcome() == .lost ? "✕ Lost today · No retries" :
                             BerryDailyHistory.outcome() == .active ? "▶ Your one attempt is in progress" :
                             "Ready for your one daily attempt")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(BerryDailyHistory.outcome() == .lost ?
                                BerryStyle.strawberry : BerryStyle.leaf)
                        HStack(spacing: 10) {
                            BerryCandyNumber(value: "\(BerryDailyHistory.wins) Wins", size: 15)
                            BerryCandyNumber(value: "\(BerryDailyHistory.losses) Losses", size: 15)
                        }
                    }
                    .padding(14).frame(maxWidth: .infinity)
                    .background(.white, in: RoundedRectangle(cornerRadius: 20))
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        let now = context.date
                        let next = Calendar.current.date(byAdding: .day, value: 1,
                                          to: Calendar.current.startOfDay(for: now)) ?? now
                        let seconds = max(0, Int(next.timeIntervalSince(now)))
                        Text("Next challenge in \(seconds / 3600)h \((seconds % 3600) / 60)m")
                            .font(.subheadline.bold()).foregroundStyle(BerryStyle.strawberry)
                    }
                    HStack {
                        Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
                        Spacer()
                        Text(monthStart.formatted(.dateTime.month(.wide).year()))
                            .font(.title3.bold())
                        Spacer()
                        Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
                            .disabled(Calendar.current.isDate(month, equalTo: Date(), toGranularity: .month))
                    }
                    .foregroundStyle(BerryStyle.chocolate)
                    .padding(.horizontal, 8)
                    let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
                    let headings = (0..<7).map { symbols[($0 + Calendar.current.firstWeekday - 1) % 7] }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                        ForEach(0..<7, id: \.self) { index in
                            Text(headings[index]).font(.caption.bold()).foregroundStyle(.secondary)
                        }
                        ForEach(0..<42, id: \.self) { index in
                            if let day = date(at: index) {
                                let complete = BerryDailyHistory.completed.contains(BerryDailyHistory.dateKey(for: day))
                                let lost = BerryDailyHistory.outcome(on: day) == .lost
                                let today = Calendar.current.isDateInToday(day)
                                let future = day > Date()
                                VStack(spacing: 3) {
                                    Text("\(Calendar.current.component(.day, from: day))")
                                        .font(.system(size: 12, weight: .bold))
                                    Image(systemName: complete ? "checkmark.seal.fill" :
                                          lost ? "xmark.circle.fill" : today ? "leaf.fill" : "circle")
                                        .font(.system(size: 11))
                                }
                                .foregroundStyle(lost ? Color(red: 0.70, green: 0.18, blue: 0.31) :
                                    today ? BerryStyle.strawberry : complete ? BerryStyle.leaf : BerryStyle.chocolate)
                                .opacity(future ? 0.3 : 1)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(today ? BerryStyle.softPink : Color.white,
                                            in: RoundedRectangle(cornerRadius: 11))
                                .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)), \(complete ? "won" : lost ? "lost" : (future ? "upcoming" : "not attempted"))")
                            } else { Color.clear.frame(height: 42) }
                        }
                    }
                    Text("✓ Won   ✕ Lost   🌱 Today   ○ Not attempted")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("One attempt per calendar day. Only a win earns the streak reward. Losing ends the attempt; leaving early preserves the same day's board.")
                        .font(.footnote).multilineTextAlignment(.center).foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .background(BerryStyle.cream.ignoresSafeArea())
            .navigationTitle("Daily Harvest")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.presentationDetents([.large])
    }
    private func changeMonth(_ amount: Int) {
        if let changed = Calendar.current.date(byAdding: .month, value: amount, to: monthStart) {
            month = changed
        }
    }
    private func info(_ heading: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(heading).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.system(size: 14, weight: .black, design: .rounded))
                .minimumScaleFactor(0.75).lineLimit(1)
        }
        .foregroundStyle(BerryStyle.chocolate)
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
    }
}
