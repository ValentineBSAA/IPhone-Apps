import SwiftUI

/// Local-date based challenge history. Uses existing completion key for migration.
enum BerryDailyHistory {
    static let key = "berryblockblast.daily.history.v057"
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
        var values = completed
        values.insert(dateKey(for: Date()))
        UserDefaults.standard.set(values.sorted(), forKey: key)
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
                    BerryIcon(name: "DailyHarvest", size: 96)
                    Text("Daily Harvest Calendar")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Text("One daily challenge, refreshed at local midnight.")
                        .font(.subheadline).multilineTextAlignment(.center)
                    HStack(spacing: 8) {
                        info("Today", value: Date().formatted(.dateTime.month(.abbreviated).day()))
                        info("Streak", value: "🍓 \(BerryDailyHistory.streak)")
                        info("Completed", value: "\(BerryDailyHistory.completed.count)")
                    }
                    VStack(spacing: 7) {
                        Text("TODAY'S OBJECTIVE").font(.caption.bold())
                        Text("Score \(goal) points").font(.title3.bold())
                        Text(BerryDailyHistory.completed.contains(BerryDailyHistory.dateKey(for: Date())) ?
                             "✓ Today's challenge completed" : "Not completed yet")
                            .foregroundStyle(BerryStyle.leaf)
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
                                let today = Calendar.current.isDateInToday(day)
                                let future = day > Date()
                                VStack(spacing: 3) {
                                    Text("\(Calendar.current.component(.day, from: day))")
                                        .font(.system(size: 12, weight: .bold))
                                    Image(systemName: complete ? "checkmark.seal.fill" : today ? "leaf.fill" : "circle")
                                        .font(.system(size: 11))
                                }
                                .foregroundStyle(today ? BerryStyle.strawberry : complete ? BerryStyle.leaf : BerryStyle.chocolate)
                                .opacity(future ? 0.3 : 1)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(today ? BerryStyle.softPink : Color.white,
                                            in: RoundedRectangle(cornerRadius: 11))
                                .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)), \(complete ? "complete" : (future ? "upcoming" : "not completed"))")
                            } else { Color.clear.frame(height: 42) }
                        }
                    }
                    Text("✓ Completed   🌱 Today   ○ Not completed")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Rewards are awarded once per completed daily challenge. Missed days stay visible, but aren't retroactively playable.")
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
