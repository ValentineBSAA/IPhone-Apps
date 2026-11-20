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
    @AppStorage("journalLockEnabled") private var journalLockEnabled = false
    @ObservedObject private var journalAccess = JournalAccess.shared
    @State private var journalUnlockError: String?
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
    private var fullEntries: [RecordSnapshot] {
        let hidePrivate = journalLockEnabled && !journalAccess.unlocked
        return RecordSnapshot.snapshots(of: Array(entries).filter {
            !hidePrivate || $0.category != LogCategory.journal.rawValue
        })
    }

    private var filteredEntries: [RecordSnapshot] {
        switch period {
        case .week:
            let days = DateTracking.lastSevenDays()
            guard let earliest = days.first else { return [] }
            return fullEntries.filter { entry in
                entry.recordedAt >= earliest && entry.recordedAt <= Date()
                    && (selectedDay == nil || cal.isDate(entry.recordedAt, inSameDayAs: selectedDay!))
            }
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
                historyWelcome
                periodChooser

                switch period {
                case .week: weekOverview
                case .month: monthOverview
                case .year: yearOverview
                case .all: lifetimeOverview
                }

                if journalLockEnabled && !journalAccess.unlocked {
                    GlassCard {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield")
                                .foregroundStyle(Color.potsTeal)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Journal records hidden")
                                    .font(.subheadline.weight(.semibold))
                                Text("Unlock to view private notes and include them in full-history deletion.")
                                    .font(.caption)
                                    .foregroundStyle(Color.potsSecondary)
                            }
                            Spacer()
                            Button("Unlock") {
                                journalAccess.authenticate(reason: "View private Journal history") { success, error in
                                    if !success { journalUnlockError = error }
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                if filteredEntries.isEmpty {
                    GlassCard {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.title2)
                                .foregroundStyle(Color.potsTeal)
                            Text("A fresh page")
                                .font(.headline)
                            Text("No entries in this range.")
                                .font(.subheadline)
                                .foregroundStyle(Color.potsSecondary)
                            NavigationLink {
                                EntryEditor(category: .symptom)
                            } label: {
                                Label("Add an entry", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity, minHeight: 45)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.potsButtonFill)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your records")
                                .font(.title3.weight(.bold))

                        }
                        Spacer()
                        Text("\(filteredEntries.count)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Color.potsTeal)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.potsTeal.opacity(0.11), in: Capsule())
                            .accessibilityLabel("\(filteredEntries.count) saved entries")
                    }
                    RecordTreeView(
                        records: filteredEntries,
                        onEdit: { id in editingRoute = RecordEditRoute(objectID: id) },
                        onDelete: { id in requestDelete([id], label: "this entry") },
                        onDeleteGroup: { ids, label in requestDelete(ids, label: label) }
                    )
                    if period == .all && (!journalLockEnabled || journalAccess.unlocked) {
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
                                        .foregroundStyle(Color.potsSecondary)
                                }
                                Spacer(minLength: 6)
                                Text("\(fullEntries.count)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(Color.potsSecondary)
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
                guard !journalLockEnabled || journalAccess.unlocked else {
                    deleteError = "Unlock Journal first so Clear All includes every saved record."
                    return
                }
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
        .alert("Journal access unsuccessful", isPresented: Binding(
            get: { journalUnlockError != nil },
            set: { if !$0 { journalUnlockError = nil } }
        )) {
            Button("OK") { journalUnlockError = nil }
        } message: {
            Text(journalUnlockError ?? "Try again.")
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

    /// An editorial header; counts describe saved entries, not wellness.
    private var historyWelcome: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2.weight(.light))
                    .foregroundStyle(Color.potsTeal)
                    .frame(width: 54, height: 54)
                    .background(Color.potsTeal.opacity(0.11), in: RoundedRectangle(cornerRadius: 17))
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your story, day by day")
                        .font(.title3.bold())
                    Text("A gentle space for the things you've chosen to record.")
                        .font(.subheadline)
                        .foregroundStyle(Color.potsSecondary)
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.potsTeal)
                        Text("\(fullEntries.count) visible \(fullEntries.count == 1 ? "entry" : "entries")")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.potsSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var periodChooser: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Explore your timeline")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.potsSecondary)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                periodCard(.week, symbol: "calendar", hint: "Last 7 days")
                periodCard(.month, symbol: "calendar", hint: "By date")
                periodCard(.year, symbol: "calendar.badge.clock", hint: "All 12 months")
                periodCard(.all, symbol: "clock.arrow.circlepath", hint: "Every saved entry")
            }
        }
    }

    private func periodCard(_ choice: HistoryPeriod, symbol: String, hint: String) -> some View {
        let chosen = period == choice
        return Button {
            guard period != choice else { return }
            withAnimation(.easeInOut(duration: 0.20)) {
                period = choice
                selectedDay = nil
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 30)
                    .foregroundStyle(chosen ? Color.potsTeal : Color.potsSecondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(choice.rawValue)
                        .font(.subheadline.weight(.semibold))
                    Text(hint)
                        .font(.caption2)
                        .foregroundStyle(Color.potsSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if chosen {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.potsTeal)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(chosen ? Color.potsSurfaceMuted : Color.potsSurface,
                        in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .strokeBorder(chosen ? Color.potsStroke : Color.potsStroke.opacity(0.40), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(choice.rawValue), \(hint)")
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
    }

    private var weekOverview: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Your last seven days")
                            .font(.headline)
                        Text("Tap a day to see just its records")
                            .font(.caption)
                            .foregroundStyle(Color.potsSecondary)
                    }
                    Spacer()
                    if selectedDay != nil {
                        Button("Show all") {
                            withAnimation(.easeInOut(duration: 0.18)) { selectedDay = nil }
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
                HStack(spacing: 6) {
                    ForEach(DateTracking.lastSevenDays(), id: \.self) { day in
                        let count = fullEntries.filter { cal.isDate($0.recordedAt, inSameDayAs: day) }.count
                        let selected = selectedDay.map { cal.isDate($0, inSameDayAs: day) } == true
                        let today = cal.isDateInToday(day)
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selectedDay = selected ? nil : day
                            }
                        } label: {
                            VStack(spacing: 7) {
                                Text(day.formatted(.dateTime.weekday(.narrow)))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Color.potsSecondary)
                                Text(day.formatted(.dateTime.day()))
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(selected ? Color.white : Color.primary)
                                Circle()
                                    .fill(count > 0 ? (selected ? Color.white : Color.potsTeal) : Color.clear)
                                    .frame(width: 6, height: 6)
                            }
                            .frame(maxWidth: .infinity, minHeight: 78)
                            .background(selected ? Color.potsButtonFill : (today ? Color.potsSurfaceMuted : Color.potsBackground),
                                        in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(selected || today ? Color.potsTeal.opacity(0.43) : Color.potsTeal.opacity(0.07)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(day.formatted(date: .complete, time: .omitted)), \(count == 0 ? "not recorded" : "\(count) entries")")
                        .accessibilityAddTraits(selected ? [.isSelected] : [])
                    }
                }

            }
        }
    }

    private var monthOverview: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("A month at a glance")
                        .font(.headline)
                    Text("Select a date to see the entries from that day.")
                        .font(.caption)
                        .foregroundStyle(Color.potsSecondary)
                }
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
                            .foregroundStyle(Color.potsSecondary)
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
                                    ? Color.potsTeal.opacity(0.22) : (count == 0 ? Color.potsBackground : Color.potsTeal.opacity(0.08)),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.potsTeal.opacity(count == 0 ? 0.04 : 0.16)))
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your year in moments")
                        .font(.headline)
                    Text("Choose any month to explore its saved entries.")
                        .font(.caption)
                        .foregroundStyle(Color.potsSecondary)
                }
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
                            VStack(alignment: .leading, spacing: 9) {
                                HStack {
                                    Circle()
                                        .fill(monthEntries.isEmpty ? Color.potsTertiary.opacity(0.55) : Color.potsTeal)
                                        .frame(width: 7, height: 7)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(Color.potsTertiary)
                                }
                                Text(date.formatted(.dateTime.month(.wide)))
                                    .font(.subheadline.weight(.semibold))
                                Text(monthEntries.isEmpty ? "Not recorded" : "\(monthEntries.count) entries")
                                    .font(.caption)
                                    .foregroundStyle(monthEntries.isEmpty ? Color.potsSecondary : Color.potsTeal)
                            }
                            .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
                            .padding(.horizontal, 12)
                            .background(monthEntries.isEmpty ? Color.potsBackground : Color.potsSurfaceMuted,
                                        in: RoundedRectangle(cornerRadius: 15))
                            .overlay(RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(Color.potsTeal.opacity(monthEntries.isEmpty ? 0.06 : 0.20)))
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
                        .font(.caption).foregroundStyle(Color.potsSecondary)
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