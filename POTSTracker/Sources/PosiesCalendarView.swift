import SwiftUI
import CoreData

/// Calendar records only the dates actually present in local storage.
/// Blank dates are unknown, not symptom-free.
struct PosiesCalendarView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var entries: FetchedResults<POTSLogEntry>
    @AppStorage("journalLockEnabled") private var journalLockEnabled = false
    @ObservedObject private var access = JournalAccess.shared
    @State private var displayedMonth = Calendar.current.startOfDay(for: Date())
    @State private var selectedDay = Calendar.current.startOfDay(for: Date())
    @State private var showingYear = false
    @State private var editingRoute: RecordEditRoute?

    private var calendar: Calendar { .current }
    private var visibleRecords: [RecordSnapshot] {
        RecordSnapshot.snapshots(of: Array(entries).filter {
            !journalLockEnabled || access.unlocked || $0.category != LogCategory.journal.rawValue
        })
    }
    private var dailyRecords: [RecordSnapshot] {
        visibleRecords.filter { calendar.isDate($0.recordedAt, inSameDayAs: selectedDay) }
            .sorted { $0.recordedAt > $1.recordedAt }
    }
    private var beginning: Date {
        calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
    }
    private var monthCells: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let offset = (calendar.component(.weekday, from: beginning) - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: offset) +
            range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: beginning) }.map { Optional($0) }
    }
    private var weekdayLabels: [String] {
        let labels = calendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { labels[(calendar.firstWeekday - 1 + $0) % 7] }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 13) {
                        HStack {
                            PosiesFeatureSectionTitle(featureID: "calendar",
                                                       title: "Your calendar", artworkSize: 37)
                            Spacer()
                            Button(showingYear ? "Close year" : "Year") {
                                withAnimation(.easeInOut(duration: 0.2)) { showingYear.toggle() }
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                        HStack {
                            Button { shift(-1) } label: {
                                Image(systemName: "chevron.left").frame(minWidth: 44, minHeight: 44)
                            }.accessibilityLabel("Previous month")
                            Spacer()
                            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                                .font(.headline)
                            Spacer()
                            Button { shift(1) } label: {
                                Image(systemName: "chevron.right").frame(minWidth: 44, minHeight: 44)
                            }.accessibilityLabel("Next month")
                        }
                        .buttonStyle(.plain)

                        if showingYear {
                            yearGrid
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 7) {
                                ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { _, symbol in
                                    Text(symbol).font(.caption2.weight(.semibold))
                                        .foregroundStyle(Color.potsSecondary)
                                }
                                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                                    if let day = date {
                                        let count = countOn(day)
                                        let chosen = calendar.isDate(day, inSameDayAs: selectedDay)
                                        Button {
                                            selectedDay = day
                                        } label: {
                                            VStack(spacing: 3) {
                                                Text(day.formatted(.dateTime.day()))
                                                    .font(.subheadline.weight(chosen ? .bold : .medium))
                                                Circle()
                                                    .fill(count > 0 ? (chosen ? Color.white : Color.potsTeal) : Color.clear)
                                                    .frame(width: 5, height: 5)
                                            }
                                            .foregroundStyle(chosen ? Color.white : Color.primary)
                                            .frame(maxWidth: .infinity, minHeight: 47)
                                            .background(chosen ? Color.potsButtonFill :
                                                        (count > 0 ? Color.potsSurfaceMuted : Color.potsBackground),
                                                        in: RoundedRectangle(cornerRadius: 12))
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("\(day.formatted(date: .complete, time: .omitted)), \(count == 0 ? "not recorded" : "\(count) records")")
                                    } else {
                                        Color.clear.frame(height: 47)
                                    }
                                }
                            }
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(selectedDay.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                            Spacer()
                            Text("\(dailyRecords.count) \(dailyRecords.count == 1 ? "entry" : "entries")")
                                .font(.caption.monospacedDigit()).foregroundStyle(Color.potsSecondary)
                        }
                        if dailyRecords.isEmpty {
                            Text("Nothing recorded for this date.")
                                .font(.subheadline).foregroundStyle(Color.potsSecondary)
                            NavigationLink {
                                EntryEditor(category: .symptom)
                            } label: {
                                Label("Add an entry", systemImage: "plus.circle")
                                    .font(.subheadline.weight(.semibold))
                            }
                        } else {
                            ForEach(dailyRecords) { record in
                                Button { editingRoute = RecordEditRoute(objectID: record.id) } label: {
                                    HStack(spacing: 10) {
                                        PosiesFeatureIcon(featureID: record.category, width: 32)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(record.categoryLabel).font(.subheadline.weight(.semibold))
                                            Text(record.detail).font(.caption)
                                                .foregroundStyle(Color.potsSecondary).lineLimit(2)
                                        }
                                        Spacer()
                                        Text(record.recordedAt.formatted(date: .omitted, time: .shortened))
                                            .font(.caption2).foregroundStyle(Color.potsSecondary)
                                        Image(systemName: "chevron.right").font(.caption2)
                                    }
                                    .frame(minHeight: 54)
                                }
                                .buttonStyle(.plain)
                                if record.id != dailyRecords.last?.id { Divider() }
                            }
                        }
                    }
                }
                Text("Missing days mean not recorded, not symptom-free.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingRoute) { route in
            RecordEditDestination(objectID: route.objectID)
        }
    }

    private var yearGrid: some View {
        let year = calendar.component(.year, from: displayedMonth)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
            ForEach(1...12, id: \.self) { monthNumber in
                let monthDate = calendar.date(from: DateComponents(year: year, month: monthNumber, day: 1)) ?? Date()
                let count = visibleRecords.filter { calendar.isDate($0.recordedAt, equalTo: monthDate, toGranularity: .month) }.count
                Button {
                    displayedMonth = monthDate
                    selectedDay = monthDate
                    showingYear = false
                } label: {
                    VStack(spacing: 4) {
                        Text(monthDate.formatted(.dateTime.month(.abbreviated)))
                            .font(.subheadline.weight(.semibold))
                        Text(count == 0 ? "No entries" : "\(count) entries")
                            .font(.caption2).foregroundStyle(Color.potsSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 65)
                    .background(count > 0 ? Color.potsSurfaceMuted : Color.potsBackground,
                                in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func countOn(_ day: Date) -> Int {
        visibleRecords.filter { calendar.isDate($0.recordedAt, inSameDayAs: day) }.count
    }
    private func shift(_ delta: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: delta, to: beginning) ?? beginning
        selectedDay = calendar.startOfDay(for: displayedMonth)
    }
}
