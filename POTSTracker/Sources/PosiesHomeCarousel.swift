import SwiftUI
import CoreData

/// One intentionally focused action per page. No duplicate tracker buttons:
/// the Log grid, pinned shortcuts and check-in module remain their own modules.
enum PosiesHomePage: Int, CaseIterable, Identifiable {
    case today, week, wellness, upcoming
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .today: return "Today"
        case .week: return "Your week"
        case .wellness: return "Daily wellbeing"
        case .upcoming: return "Coming up"
        }
    }
}

struct PosiesHomeCarousel: View {
    let records: [RecordSnapshot]
    let roomy: Bool
    let openLog: () -> Void

    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("posiesReminderRulesV1") private var storedReminders = ""
    @AppStorage("posiesQuietStartHour") private var quietStartHour = 22
    @AppStorage("posiesQuietEndHour") private var quietEndHour = 8
    @State private var page: PosiesHomePage = .today

    private var calendar: Calendar { .current }
    private var today: [RecordSnapshot] {
        records.filter { calendar.isDateInToday($0.recordedAt) }
    }
    private var week: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0 - 6, to: today) }
    }
    private var reminderRules: [PosiesReminder] {
        guard let data = storedReminders.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([PosiesReminder].self, from: data)) ?? []
    }
    private var nextReminder: (PosiesReminder, Date)? {
        let now = Date()
        return reminderRules
            .filter { $0.enabled && !PosiesReminder.withinQuietHours(
                hour: $0.hour, start: quietStartHour, end: quietEndHour) }
            .compactMap { rule -> (PosiesReminder, Date)? in
                let dates = (0..<8).compactMap { offset -> Date? in
                    guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
                    let weekday = calendar.component(.weekday, from: day)
                    guard rule.weekdays.contains(weekday) else { return nil }
                    let components = calendar.dateComponents([.year, .month, .day], from: day)
                    guard let candidate = calendar.date(from: DateComponents(
                        year: components.year, month: components.month, day: components.day,
                        hour: rule.hour, minute: rule.minute)), candidate > now else { return nil }
                    return candidate
                }
                guard let first = dates.min() else { return nil }
                return (rule, first)
            }
            .min { $0.1 < $1.1 }
    }
    private var carouselHeight: CGFloat {
        if textSize.isAccessibilitySize { return roomy ? 440 : 420 }
        return roomy ? 295 : 274
    }

    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $page) {
                ForEach(PosiesHomePage.allCases) { item in
                    GlassCard {
                        pageContents(item)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                    .padding(.horizontal, 1)
                    .tag(item)
                    .accessibilityLabel(item.title)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: carouselHeight)
            .accessibilityHint("Swipe horizontally to explore Home cards.")

            HStack(spacing: 14) {
                Button {
                    changePage(max(0, page.rawValue - 1))
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 42, height: 34)
                }
                .disabled(page == .today)
                .accessibilityLabel("Previous Home card")

                Spacer()
                HStack(spacing: 8) {
                    ForEach(PosiesHomePage.allCases) { item in
                        Button {
                            changePage(item.rawValue)
                        } label: {
                            Capsule()
                                .fill(page == item ? Color.potsTeal : Color.potsTertiary.opacity(0.50))
                                .frame(width: page == item ? 23 : 8, height: 8)
                                .frame(minWidth: 32, minHeight: 34)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(item.title), card \(item.rawValue + 1) of 4")
                        .accessibilityAddTraits(page == item ? [.isSelected] : [])
                    }
                }
                Spacer()

                Button {
                    changePage(min(3, page.rawValue + 1))
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 42, height: 34)
                }
                .disabled(page == .upcoming)
                .accessibilityLabel("Next Home card")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.potsTeal)
            .buttonStyle(.plain)
            .accessibilityElement(children: .contain)
        }
    }

    private func changePage(_ index: Int) {
        guard let selected = PosiesHomePage(rawValue: index) else { return }
        if reduceMotion { page = selected }
        else { withAnimation(.easeInOut(duration: 0.22)) { page = selected } }
    }

    @ViewBuilder
    private func pageContents(_ item: PosiesHomePage) -> some View {
        switch item {
        case .today: todayPage
        case .week: weekPage
        case .wellness: wellnessPage
        case .upcoming: upcomingPage
        }
    }

    private var todayPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today").font(.title3.bold())
                    Text(today.isEmpty ? "A fresh page for today" : "Your records at a glance")
                        .font(.subheadline).foregroundStyle(Color.potsSecondary)
                }
                Spacer(minLength: 6)
                countBadge(today.count)
            }
            Spacer(minLength: 2)
            HStack(spacing: 11) {
                Image(systemName: "heart.text.square")
                    .font(.title2).foregroundStyle(Color.potsTeal)
                VStack(alignment: .leading, spacing: 3) {
                    Text(today.contains { $0.category == LogCategory.checkIn.rawValue }
                         ? "Check-in recorded" : "No check-in recorded")
                        .font(.subheadline.weight(.semibold))
                    Text("You decide what to record.")
                        .font(.caption).foregroundStyle(Color.potsSecondary)
                }
            }
            Spacer(minLength: 1)
            Button(action: openLog) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add an entry")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 15)
                .frame(minHeight: roomy ? 56 : 48)
                .foregroundStyle(.white)
                .background(Color.potsButtonFill, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private var weekPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                pageHeader("Your week", subtitle: "Days you chose to record")
                Spacer()
                Image(systemName: "calendar").foregroundStyle(Color.potsTeal)
            }
            Spacer(minLength: 2)
            HStack(spacing: 4) {
                ForEach(week, id: \.self) { day in
                    let count = records.filter { calendar.isDate($0.recordedAt, inSameDayAs: day) }.count
                    VStack(spacing: 5) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.potsSecondary)
                        Text(day.formatted(.dateTime.day()))
                            .font(.subheadline.weight(.semibold))
                        Circle()
                            .fill(count > 0 ? Color.potsTeal : Color.clear)
                            .frame(width: 7, height: 7)
                    }
                    .frame(maxWidth: .infinity, minHeight: 74)
                    .background(calendar.isDateInToday(day)
                                ? Color.potsSurfaceMuted : Color.potsBackground,
                                in: RoundedRectangle(cornerRadius: 13))
                    .accessibilityLabel("\(day.formatted(date: .complete, time: .omitted)), \(count == 0 ? "not recorded" : "\(count) records")")
                }
            }
            Text("Blank days are unknown, not symptom-free.")
                .font(.caption).foregroundStyle(Color.potsSecondary)
            Spacer(minLength: 0)
            NavigationLink {
                PosiesCalendarView()
            } label: {
                Label("Open calendar", systemImage: "calendar.badge.clock")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
        }
    }

    private var wellnessPage: some View {
        let water = today.filter { $0.category == LogCategory.hydration.rawValue }
        let volume = water.reduce(0) { $0 + Int($1.firstValue) }
        let sleep = today.filter { $0.category == LogCategory.sleep.rawValue }
        let rest = sleep.reduce(0) { $0 + Int($1.firstValue) }
        let medications = today.filter { $0.category == LogCategory.medications.rawValue }
        return VStack(alignment: .leading, spacing: 12) {
            pageHeader("Daily wellbeing", subtitle: "Only what you recorded")
            VStack(spacing: 9) {
                summaryRow("drop.fill", title: "Hydration",
                           detail: water.isEmpty ? "Not recorded" : "\(volume) mL recorded")
                summaryRow("moon.stars.fill", title: "Sleep & rest",
                           detail: sleep.isEmpty ? "Not recorded" : "\(rest) minutes recorded")
                summaryRow("pills.fill", title: "Medication notes",
                           detail: medications.isEmpty ? "Not recorded" : "\(medications.count) entries")
            }
            Spacer(minLength: 1)
            Text("These are notes, not daily goals or health ratings.")
                .font(.caption).foregroundStyle(Color.potsSecondary)
        }
    }

    private var upcomingPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            pageHeader("Coming up", subtitle: "Your optional reminders")
            Spacer(minLength: 1)
            if let (rule, when) = nextReminder {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(Color.potsTeal).font(.title2)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(rule.name).font(.headline).lineLimit(2)
                        Text(when.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        Text("A reminder never means an entry is complete.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                    Spacer()
                }
            } else {
                Label("Nothing scheduled", systemImage: "bell.slash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.potsSecondary)
                Text("Your day doesn't need a checklist.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
            Spacer(minLength: 1)
            NavigationLink {
                PosiesRemindersView()
            } label: {
                Label("Manage reminders", systemImage: "bell")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
        }
    }

    private func pageHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.bold())
            Text(subtitle).font(.subheadline).foregroundStyle(Color.potsSecondary)
        }
    }

    private func summaryRow(_ symbol: String, title: String, detail: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.subheadline).foregroundStyle(Color.potsTeal).frame(width: 22)
            Text(title).font(.subheadline.weight(.semibold))
            Spacer(minLength: 5)
            Text(detail).font(.subheadline).foregroundStyle(Color.potsSecondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2).minimumScaleFactor(0.8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 9)
        .background(Color.potsSurfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }

    private func countBadge(_ count: Int) -> some View {
        Text("\(count) \(count == 1 ? "entry" : "entries")")
            .font(.caption.weight(.semibold)).monospacedDigit()
            .foregroundStyle(Color.potsTeal)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Color.potsTeal.opacity(0.10), in: Capsule())
    }
}
