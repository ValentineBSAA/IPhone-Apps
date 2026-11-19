import SwiftUI
import CoreData

enum HistoryPeriod: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case all = "All"

    var id: String { rawValue }
}

/// Real journal history. Every view reads the persisted Core Data entries:
/// no fabricated graph values and no cap on lifetime records.
struct HistoryScreenView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var entries: FetchedResults<POTSLogEntry>

    @State private var period: HistoryPeriod = .week
    @State private var month: Date = Date()
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedDay: Date?
    @State private var editingRoute: RecordEditRoute?
    @State private var pendingDeletionIDs: [NSManagedObjectID] = []
    @State private var pendingDeletionLabel = "this entry"
    @State private var confirmDeletion = false
    @State private var confirmClearAll = false
    @State private var clearPhrase = ""
    @State private var deleteError: String?

    private var cal: Calendar { .current }
    private var fullEntries: [RecordSnapshot] { RecordSnapshot.snapshots(of: Array(entries)) }

    private var filteredEntries: [RecordSnapshot] {
        switch period {
        case .week:
            let days = DateTracking.lastSevenDays()
            guard let earliest = days.first else { return [] }
            return fullEntries.filter { $0.recordedAt >= earliest && $0.recordedAt <= Date() }
        case .month:
            return fullEntries.filter { entry in
                cal.isDate(entry.recordedAt, equalTo: month, toGranularity: .month)
                    && (selectedDay == nil || cal.isDate(entry.recordedAt, inSameDayAs: selectedDay!))
            }
        case .year:
            return fullEntries.filter { cal.component(.year, from: $0.recordedAt) == year }
        case .all:
            return fullEntries
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                Text("Browse your entries by date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Picker("History range", selection: $period) {
                    ForEach(HistoryPeriod.allCases) { choice in
                        Text(choice.rawValue).tag(choice)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: period) { _ in selectedDay = nil }

                switch period {
                case .week: weekOverview
                case .month: monthOverview
                case .year: yearOverview
                case .all: lifetimeOverview
                }

                if filteredEntries.isEmpty {
                    Text("Nothing recorded for this period.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 3)
                        .padding(.top, 3)
                } else {
                    HStack {
                        Text("Saved entries")
                            .font(.headline)
                        Spacer()
                        Text("\(filteredEntries.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text("Open a day, then a category. Swipe a row left to remove, right to edit or open.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    RecordTreeView(
                        records: filteredEntries,
                        onEdit: { id in editingRoute = RecordEditRoute(objectID: id) },
                        onDelete: { id in requestDelete([id], label: "this entry") },
                        onDeleteGroup: { ids, label in requestDelete(ids, label: label) }
                    )
                    if period == .all {
                        HistorySwipeSurface(
                            leadingTitle: "Week",
                            leadingSymbol: "calendar",
                            trailingTitle: "Clear all",
                            accessibilityTitle: "Clear all saved history, \(fullEntries.count) records",
                            onTap: { clearPhrase = ""; confirmClearAll = true },
                            onLeading: { period = .week },
                            onTrailing: { clearPhrase = ""; confirmClearAll = true }
                        ) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Clear all saved history")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text("Swipe left, then confirm. Cannot be undone.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 6)
                                Text("\(fullEntries.count)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 13)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(18)
            .padding(.bottom, 20)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingRoute) { route in
            RecordEditDestination(objectID: route.objectID)
        }
        .confirmationDialog(
            "Delete \(pendingDeletionLabel)?",
            isPresented: $confirmDeletion,
            titleVisibility: .visible
        ) {
            Button("Delete \(pendingDeletionIDs.count) \(pendingDeletionIDs.count == 1 ? "entry" : "entries") permanently", role: .destructive) {
                let ids = pendingDeletionIDs
                pendingDeletionIDs = []
                do {
                    try RecordStore.delete(ids, in: context)
                } catch {
                    deleteError = error.localizedDescription
                }
            }
        } message: {
            Text("The selected records will be removed together. This cannot be undone; backup and export are not available yet.")
        }
        .alert("Clear every saved record?", isPresented: $confirmClearAll) {
            TextField("Type DELETE", text: $clearPhrase)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            Button("Delete all history", role: .destructive) {
                guard clearPhrase.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "DELETE" else { return }
                do {
                    try RecordStore.delete(fullEntries.map(\.id), in: context)
                } catch {
                    deleteError = error.localizedDescription
                }
                clearPhrase = ""
            }
            .disabled(clearPhrase.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() != "DELETE")
            Button("Cancel", role: .cancel) { clearPhrase = "" }
        } message: {
            Text("Every saved entry on this iPhone will be permanently deleted, across all dates and trackers. Backup and export aren't ready. Type DELETE to confirm.")
        }
        .alert("Could not delete entry", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK") { deleteError = nil }
        } message: {
            Text(deleteError ?? "Try again.")
        }
    }

    private var weekOverview: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 11) {
                Text("Last seven days")
                    .font(.headline)
                HStack(spacing: 5) {
                    ForEach(DateTracking.lastSevenDays(), id: \.self) { day in
                        let count = fullEntries.filter { cal.isDate($0.recordedAt, inSameDayAs: day) }.count
                        VStack(spacing: 6) {
                            Text(day.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(count == 0 ? "–" : "\(count)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(count == 0 ? Color.secondary : Color.potsTeal)
                                .frame(maxWidth: .infinity, minHeight: 38)
                                .background(count == 0 ? Color.secondary.opacity(0.08) : Color.potsTeal.opacity(0.12),
                                            in: RoundedRectangle(cornerRadius: 11))
                            Text(day.formatted(.dateTime.day()))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(day.formatted(date: .complete, time: .omitted)): \(count == 0 ? "not recorded" : "\(count) entries")")
                    }
                }
                Text("A dash means not recorded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var monthOverview: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button {
                        shiftMonth(-1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(minWidth: 42, minHeight: 42)
                    }
                    .accessibilityLabel("Previous month")
                    Spacer()
                    Text(month.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)
                    Spacer()
                    Button {
                        shiftMonth(1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(minWidth: 42, minHeight: 42)
                    }
                    .accessibilityLabel("Next month")
                }
                .buttonStyle(.plain)

                let weekdays = orderedWeekdayLabels()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                    ForEach(Array(weekdays.enumerated()), id: \.offset) { _, label in
                        Text(label).font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(Array(monthCells().enumerated()), id: \.offset) { _, item in
                        if let day = item {
                            let count = fullEntries.filter { cal.isDate($0.recordedAt, inSameDayAs: day) }.count
                            Button {
                                if let current = selectedDay, cal.isDate(current, inSameDayAs: day) {
                                    selectedDay = nil
                                } else {
                                    selectedDay = day
                                }
                            } label: {
                                VStack(spacing: 2) {
                                    Text(day.formatted(.dateTime.day()))
                                        .font(.subheadline.weight(count == 0 ? .regular : .semibold))
                                    Circle()
                                        .fill(count == 0 ? Color.clear : Color.potsTeal)
                                        .frame(width: 4, height: 4)
                                }
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .foregroundStyle(.primary)
                                .background(
                                    selectedDay.map { cal.isDate($0, inSameDayAs: day) } == true
                                    ? Color.potsTeal.opacity(0.22) : Color.secondary.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(day.formatted(date: .complete, time: .omitted)), \(count == 0 ? "not recorded" : "\(count) entries")")
                        } else {
                            Color.clear.frame(height: 42)
                        }
                    }
                }
                if selectedDay != nil {
                    Button("Show entire month") { selectedDay = nil }
                        .font(.caption.weight(.semibold))
                }
            }
        }
    }

    private var yearOverview: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Button { year -= 1 } label: {
                        Image(systemName: "chevron.left").frame(minWidth: 42, minHeight: 42)
                    }
                    .accessibilityLabel("Previous year")
                    Spacer()
                    Text(String(year)).font(.headline.monospacedDigit())
                    Spacer()
                    Button { year += 1 } label: {
                        Image(systemName: "chevron.right").frame(minWidth: 42, minHeight: 42)
                    }
                    .accessibilityLabel("Next year")
                }
                .buttonStyle(.plain)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)], spacing: 9) {
                    ForEach(1...12, id: \.self) { monthNumber in
                        let date = cal.date(from: DateComponents(year: year, month: monthNumber, day: 1)) ?? Date()
                        let monthEntries = fullEntries.filter {
                            cal.isDate($0.recordedAt, equalTo: date, toGranularity: .month)
                        }
                        Button {
                            month = date
                            selectedDay = nil
                            period = .month
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(date.formatted(.dateTime.month(.wide)))
                                    .font(.subheadline.weight(.semibold))
                                Text(monthEntries.isEmpty ? "Not recorded" : "\(monthEntries.count) entries")
                                    .font(.caption)
                                    .foregroundStyle(monthEntries.isEmpty ? Color.secondary : Color.potsTeal)
                            }
                            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                            .padding(.horizontal, 12)
                            .background(Color.potsTeal.opacity(monthEntries.isEmpty ? 0.04 : 0.10),
                                        in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    private var lifetimeOverview: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(Color.potsTeal)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your full record").font(.headline)
                    Text("All entries are available, with no paid history limit.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(fullEntries.count)")
                    .font(.title2.monospacedDigit().bold())
            }
        }
    }

    private func requestDelete(_ ids: [NSManagedObjectID], label: String) {
        guard !ids.isEmpty else { return }
        pendingDeletionIDs = ids
        pendingDeletionLabel = label
        confirmDeletion = true
    }

    private func shiftMonth(_ delta: Int) {
        month = cal.date(byAdding: .month, value: delta, to: month) ?? month
        selectedDay = nil
    }

    private func orderedWeekdayLabels() -> [String] {
        let labels = cal.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { labels[(cal.firstWeekday - 1 + $0) % 7] }
    }

    private func monthCells() -> [Date?] {
        guard let start = cal.dateInterval(of: .month, for: month)?.start,
              let days = cal.range(of: .day, in: .month, for: month) else { return [] }
        let first = (cal.component(.weekday, from: start) - cal.firstWeekday + 7) % 7
        let blanks: [Date?] = Array(repeating: nil, count: first)
        let dates: [Date?] = days.compactMap { day in
            cal.date(byAdding: .day, value: day - 1, to: start)
        }.map { Optional($0) }
        return blanks + dates
    }
}