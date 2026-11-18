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

    /// At local midnight, a still-open attempt from yesterday expires as
    /// a loss. The new calendar day remains unspent and may start normally.
    static func expirePriorAttemptIfNeeded(defaults: UserDefaults = .standard) {
        guard var record = loadAttempt(defaults: defaults),
              record.outcome == .active,
              record.day != dateKey(for: Date()) else { return }
        var results = defaults.dictionary(forKey: resultsKey) as? [String:String] ?? [:]
        if results[record.day] == nil || results[record.day] == Outcome.active.rawValue {
            results[record.day] = Outcome.lost.rawValue
            defaults.set(results, forKey: resultsKey)
        }
        record.outcome = .lost
        record.engine = nil
        if let saved = try? JSONEncoder().encode(record) {
            defaults.set(saved, forKey: attemptKey)
        }
    }

    /// Consumes the day's attempt immediately, before the first placement.
    /// Existing in-progress attempts can resume, but finished ones cannot.
    @discardableResult
    static func beginToday(defaults: UserDefaults = .standard) -> Bool {
        expirePriorAttemptIfNeeded(defaults: defaults)
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
        if outcome() == .lost { return 1 }
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
        if outcome() == .won || outcome() == .lost { return 0 }
        return reward(forStreakDay: nextStreakDay)
    }
    static var streak: Int {
        if outcome() == .lost { return 0 }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let berryPink = Color(red: 0.99, green: 0.80, blue: 0.84)
    private let berryDark = Color(red: 0.47, green: 0.17, blue: 0.27)
    private let berryGold = Color(red: 0.95, green: 0.67, blue: 0.21)
    private let greenLeaf = Color(red: 0.28, green: 0.57, blue: 0.34)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let summaryColumns = [GridItem(.flexible(), spacing: 9),
                                  GridItem(.flexible(), spacing: 9)]
    private let rewardColumns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 4)

    private var monthStart: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month],
                                                                   from: month)) ?? month
    }
    private var offset: Int {
        (Calendar.current.component(.weekday, from: monthStart)
         - Calendar.current.firstWeekday + 7) % 7
    }
    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }
    private func date(at gridIndex: Int) -> Date? {
        let number = gridIndex - offset
        guard (0..<daysInMonth).contains(number) else { return nil }
        return Calendar.current.date(byAdding: .day, value: number, to: monthStart)
    }
    private var weekdayHeadings: [String] {
        let names = Calendar.current.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { names[($0 + Calendar.current.firstWeekday - 1) % 7] }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    hero
                    progressSummary
                    dailyObjective
                    berryCalendar
                    streakRewards
                    rulesFooter
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .background {
                LinearGradient(colors: [BerryStyle.softPink,
                                        Color(red: 1, green: 0.98, blue: 0.91),
                                        Color(red: 1, green: 0.89, blue: 0.90)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("🍓 The Harvest Almanac")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(berryDark)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .tint(BerryStyle.strawberry)
                }
            }
        }
        .presentationDetents([.large])
        .accessibilityIdentifier("berry-harvest-almanac")
    }

    private var hero: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(LinearGradient(
                        colors: [.white, Color(red: 1, green: 0.92, blue: 0.84)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                RoundedRectangle(cornerRadius: 25)
                    .strokeBorder(berryGold.opacity(0.65), lineWidth: 2)
                HStack(spacing: 11) {
                    BerryIcon(name: "BerryDailyHarvestHeader", size: 110)
                        .frame(width: 112, height: 108)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("THE DAILY")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(1.6)
                            .foregroundStyle(BerryStyle.strawberry)
                        Text("Harvest Garden")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(berryDark)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Grow one sweet memory every day")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(berryDark.opacity(0.75))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
            }
            .frame(height: 125)
            Text("Every berry tells a story. Your calendar remembers wins, losses and fresh starts.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(berryDark.opacity(0.78))
                .multilineTextAlignment(.center)
            }
    }

    private var progressSummary: some View {
        LazyVGrid(columns: summaryColumns, spacing: 9) {
            infoCard("Current Streak", value: "🍓 \(BerryDailyHistory.streak)",
                     symbol: "flame.fill", accent: BerryStyle.strawberry)
            infoCard("Sweet Victories", value: "\(BerryDailyHistory.wins)",
                     symbol: "trophy.fill", accent: berryGold)
            infoCard("Gardens Lost", value: "\(BerryDailyHistory.losses)",
                     symbol: "leaf.fill", accent: berryDark)
            infoCard("Next Harvest", value: "🍓 \(BerryDailyHistory.rewardToday)",
                     symbol: "gift.fill", accent: greenLeaf)
        }
    }

    private func infoCard(_ label: String, value: String,
                          symbol: String, accent: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 33, height: 34)
                .background(accent.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.35)
                    .foregroundStyle(berryDark.opacity(0.74))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(value)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(berryDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(.white.opacity(0.96),
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(berryPink, lineWidth: 1))
    }

    private var dailyObjective: some View {
        HStack(spacing: 10) {
            Image(systemName: "target")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(BerryStyle.strawberry)
            VStack(alignment: .leading, spacing: 3) {
                Text("TODAY'S BERRY QUEST")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(berryDark.opacity(0.8))
                Text("Reach \(goal) points")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(berryDark)
                Text(todayStatus)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(berryDark.opacity(0.79))
            }
            Spacer(minLength: 0)
            Text(todayEmblem)
                .font(.system(size: 29))
                .accessibilityHidden(true)
        }
        .padding(12)
        .background(.white.opacity(0.98),
                    in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19)
                    .strokeBorder(berryGold.opacity(0.65), lineWidth: 1.5))
    }

    private var todayStatus: String {
        switch BerryDailyHistory.outcome() {
        case .won: return "Harvest complete! Your berries are safe."
        case .lost: return "Today's attempt ended. A new garden blooms tomorrow."
        case .active: return "Your garden is still growing. Resume today's attempt."
        case .none: return "Your first attempt is ready to bloom."
        }
    }
    private var todayEmblem: String {
        switch BerryDailyHistory.outcome() {
        case .won: return "🏆"
        case .lost: return "🍂"
        case .active: return "🌱"
        case .none: return "🍓"
        }
    }

    private var berryCalendar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                monthArrow("chevron.left", accessibility: "Previous month") {
                    moveMonth(-1)
                }
                Spacer(minLength: 0)
                VStack(spacing: 2) {
                    Text("THE BERRY PATCH")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(BerryStyle.strawberry)
                    Text(monthStart.formatted(.dateTime.month(.wide).year()))
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(berryDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                Spacer(minLength: 0)
                monthArrow("chevron.right", accessibility: "Next month",
                           disabled: Calendar.current.isDate(
                               monthStart, equalTo: Date(), toGranularity: .month)) {
                    moveMonth(1)
                }
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdayHeadings[index])
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(berryDark.opacity(0.78))
                        .frame(maxWidth: .infinity, minHeight: 20)
                }
                ForEach(0..<42, id: \.self) { index in
                    if let day = date(at: index) {
                        dayTile(day)
                    } else {
                        Color.clear.frame(height: 54).accessibilityHidden(true)
                    }
                }
            }
            LazyVGrid(columns: summaryColumns, spacing: 7) {
                legendTile("🍓", "Won")
                legendTile("🍂", "Lost")
                legendTile("🌱", "Today or active")
                legendTile("🌸", "Coming soon")
            }
        }
        .padding(11)
        .background(.white.opacity(0.96),
                    in: RoundedRectangle(cornerRadius: 23))
        .overlay {
            RoundedRectangle(cornerRadius: 23)
                .strokeBorder(BerryStyle.strawberry.opacity(0.42),
                              lineWidth: 2)
        }
        .shadow(color: BerryStyle.strawberry.opacity(0.1), radius: 9, y: 4)
    }

    private func dayTile(_ date: Date) -> some View {
        let key = BerryDailyHistory.dateKey(for: date)
        let completed = BerryDailyHistory.completed.contains(key)
        let outcome = BerryDailyHistory.outcome(on: date)
        let lost = !completed && outcome == .lost
        let active = !completed && outcome == .active
        let today = Calendar.current.isDateInToday(date)
        let future = date > Date()
        let symbol: String = completed ? "🍓" : lost ? "🍂" :
            active ? "🌱" : today ? "🌼" : future ? "🌸" : "·"
        let stroke = today ? BerryStyle.strawberry :
            completed ? greenLeaf : berryPink
        let fill = today ? BerryStyle.softPink :
            completed ? Color(red: 0.89, green: 0.97, blue: 0.86) :
            lost ? Color(red: 1.0, green: 0.91, blue: 0.83) :
            Color(red: 1, green: 0.98, blue: 0.96)
        return VStack(spacing: 0) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(berryDark)
            Text(symbol)
                .font(.system(size: 19))
                .opacity(future ? 0.6 : 1)
                .frame(height: 26)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(fill, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(stroke, lineWidth: today ? 2.2 : 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)): " +
            (completed ? "harvest won" : lost ? "harvest lost" :
             active ? "attempt in progress" : today ? "today, available" :
             future ? "upcoming" : "not attempted"))
        .accessibilityIdentifier("harvest-day-\(key)")
    }

    private func legendTile(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Text(symbol).font(.system(size: 14)).accessibilityHidden(true)
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(berryDark)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 7).padding(.vertical, 5)
        .background(BerryStyle.cream,
                    in: RoundedRectangle(cornerRadius: 10))
        .accessibilityLabel(text)
    }

    private func monthArrow(_ symbol: String, accessibility: String,
                            disabled: Bool = false,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(disabled ? .gray : BerryStyle.strawberry)
                .frame(width: 42, height: 42)
                .background(BerryStyle.softPink,
                            in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(accessibility)
    }

    private var streakRewards: some View {
        VStack(spacing: 9) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundStyle(BerryStyle.strawberry)
                Text("THE SEVEN-DAY STRAWBERRY TRAIL")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(berryDark)
                Spacer(minLength: 0)
            }
            LazyVGrid(columns: rewardColumns, spacing: 7) {
                ForEach(1...7, id: \.self) { day in
                    let earned = day <= min(7, BerryDailyHistory.streak)
                    let current = day == min(7, BerryDailyHistory.nextStreakDay)
                    VStack(spacing: 5) {
                        Text(day == 7 ? "👑" : earned ? "🍓" : "🌷")
                            .font(.system(size: 24))
                            .accessibilityHidden(true)
                        Text("DAY \(day)")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                        Text("🍓 \(BerryDailyHistory.reward(forStreakDay: day))")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .lineLimit(1).minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(berryDark)
                    .frame(maxWidth: .infinity, minHeight: 85)
                    .background(earned ?
                        Color(red: 0.89, green: 0.96, blue: 0.84) :
                        current ? BerryStyle.softPink : .white,
                        in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(earned ? greenLeaf :
                            current ? BerryStyle.strawberry : berryPink,
                            lineWidth: current ? 2 : 1))
                    .accessibilityLabel("Day \(day): \(BerryDailyHistory.reward(forStreakDay: day)) berries" +
                                        (earned ? ", earned" : current ? ", next" : ", locked"))
                }
            }
            Text(BerryDailyHistory.outcome() == .lost ?
                 "The streak has ended today. Plant a new one tomorrow." :
                 BerryDailyHistory.rewardToday > 0 ?
                 "Finish today's challenge to earn 🍓 \(BerryDailyHistory.rewardToday)." :
                 "Today's harvest is settled. The next flower opens at midnight.")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(berryDark)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .background(.white.opacity(0.96),
                    in: RoundedRectangle(cornerRadius: 20))
    }

    private var rulesFooter: some View {
        VStack(spacing: 8) {
            TimelineView(.periodic(from: .now, by: 60)) { tick in
                let next = Calendar.current.date(
                    byAdding: .day, value: 1,
                    to: Calendar.current.startOfDay(for: tick.date)) ?? tick.date
                let seconds = max(0, Int(next.timeIntervalSince(tick.date)))
                Label("Next garden: \(seconds / 3600)h \((seconds % 3600) / 60)m",
                      systemImage: "clock.fill")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
            }
            Text("One attempt per day. Wins grow your streak and earn berries. " +
                 "You may resume an unfinished attempt on the same day. " +
                 "Your next fresh garden begins at local midnight.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(berryDark.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 9)
    }

    private func moveMonth(_ increment: Int) {
        guard let next = Calendar.current.date(
            byAdding: .month, value: increment, to: monthStart),
            next <= Calendar.current.startOfDay(for: Date()) else { return }
        month = next
    }
}
