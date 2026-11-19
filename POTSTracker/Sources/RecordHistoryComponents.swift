import SwiftUI
import CoreData

/// Sheet state stores an object ID, never a deleted managed object.
struct RecordEditRoute: Identifiable {
    let objectID: NSManagedObjectID
    var id: NSManagedObjectID { objectID }
}

struct RecordEditDestination: View {
    @Environment(\.managedObjectContext) private var context
    let objectID: NSManagedObjectID

    var body: some View {
        Group {
            if let record = try? context.existingObject(with: objectID) as? POTSLogEntry,
               !record.isDeleted {
                if record.category == LogCategory.journal.rawValue {
                    JournalProtected {
                        EntryEditor(category: .journal, editing: record)
                    }
                } else {
                    EntryEditor(category: LogCategory(rawValue: record.category) ?? .journal, editing: record)
                }
            } else {
                Text("This entry is no longer available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(24)
            }
        }
    }
}

/// Immutable display data. Deleting a Core Data object never leaves a visible row
/// trying to read properties from an invalidated NSManagedObject.
struct RecordSnapshot: Identifiable, Equatable {
    let id: NSManagedObjectID
    let category: String
    let title: String
    let recordedAt: Date
    let severity: Int16
    let firstValue: Int32
    let secondValue: Int32
    let posture: String
    let notes: String

    init(_ entry: POTSLogEntry) {
        id = entry.objectID
        category = entry.category
        title = entry.title
        recordedAt = entry.recordedAt
        severity = entry.severity
        firstValue = entry.firstValue
        secondValue = entry.secondValue
        posture = entry.posture
        notes = entry.notes
    }

    static func snapshots(of entries: [POTSLogEntry]) -> [RecordSnapshot] {
        entries.filter { !$0.isDeleted && $0.managedObjectContext != nil }
            .map(RecordSnapshot.init)
    }

    var type: LogCategory? { LogCategory(rawValue: category) }

    var detail: String {
        switch type {
        case .heartRate:
            return "\(firstValue) bpm" + (posture.isEmpty ? "" : " · \(posture)")
        case .bloodPressure:
            return "\(firstValue)/\(secondValue) mmHg" + (posture.isEmpty ? "" : " · \(posture)")
        case .symptom:
            return severity < 0 ? "Symptom recorded" : "Severity \(severity)/10"
        case .checkIn:
            return CheckInFormat.shortDetail(
                feeling: CheckInFormat.feeling(title: title, posture: posture),
                notes: notes
            )
        case .journal, .none:
            return notes.isEmpty ? "Journal entry" : notes
        }
    }

    var categoryLabel: String {
        switch type {
        case .symptom: return "Symptoms"
        case .heartRate: return "Heart rate"
        case .bloodPressure: return "Blood pressure"
        case .journal: return "Journal"
        case .checkIn: return "Check-ins"
        case .none: return "Other"
        }
    }

    var symbol: String { type?.symbol ?? "doc.text" }
}

enum RecordStore {
    /// Find by stable ID only at action time. Never delete a managed object retained
    /// by a disappearing SwiftUI row. Caller shows an error if saving fails.
    @discardableResult
    static func delete(_ id: NSManagedObjectID, in context: NSManagedObjectContext) throws -> Bool {
        guard let entry = try context.existingObject(with: id) as? POTSLogEntry,
              !entry.isDeleted else { return false }
        context.delete(entry)
        do {
            try POTSData.save(context)
            return true
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Delete an entire day, category or lifetime collection in one transaction.
    /// Every ID is resolved at confirmation time. A failed save rolls back
    /// the whole operation, avoiding partially deleted local health records.
    @discardableResult
    static func delete(_ ids: [NSManagedObjectID], in context: NSManagedObjectContext) throws -> Int {
        var deleted = 0
        for id in Set(ids) {
            guard let entry = try? context.existingObject(with: id) as? POTSLogEntry,
                  !entry.isDeleted else { continue }
            context.delete(entry)
            deleted += 1
        }
        do {
            try POTSData.save(context)
            return deleted
        } catch {
            context.rollback()
            throw error
        }
    }
}

struct RecordDayGroup: Identifiable {
    let day: Date
    let records: [RecordSnapshot]
    var id: Date { day }

    static func group(_ items: [RecordSnapshot], calendar: Calendar = .current) -> [RecordDayGroup] {
        let days = Dictionary(grouping: items) { calendar.startOfDay(for: $0.recordedAt) }
        return days.keys.sorted(by: >).map { day in
            RecordDayGroup(day: day, records: (days[day] ?? []).sorted { $0.recordedAt > $1.recordedAt })
        }
    }

    var categories: [RecordCategoryGroup] {
        let groups = Dictionary(grouping: records, by: \.category)
        return groups.keys.sorted(by: { firstIndex($0) < firstIndex($1) }).map { name in
            RecordCategoryGroup(category: name, day: day, records: (groups[name] ?? []).sorted { $0.recordedAt > $1.recordedAt })
        }
    }

    private func firstIndex(_ category: String) -> Int {
        ["checkIn", "symptom", "heartRate", "bloodPressure", "journal"].firstIndex(of: category) ?? 999
    }
}

struct RecordCategoryGroup: Identifiable {
    let category: String
    let day: Date
    let records: [RecordSnapshot]
    var id: String { "\(day.timeIntervalSince1970)-\(category)" }
    var label: String { records.first?.categoryLabel ?? "Other" }
    var icon: String { records.first?.symbol ?? "doc.text" }
}

/// Three-level History: date → category → individual entry.
/// Each visible surface has full-width native-feeling flick controls.
struct RecordTreeView: View {
    let records: [RecordSnapshot]
    let onEdit: (NSManagedObjectID) -> Void
    let onDelete: (NSManagedObjectID) -> Void
    let onDeleteGroup: ([NSManagedObjectID], String) -> Void

    @State private var expandedDays = Set<Date>()
    @State private var expandedCategories = Set<String>()

    var body: some View {
        LazyVStack(spacing: 11) {
            ForEach(RecordDayGroup.group(records)) { day in
                VStack(spacing: 0) {
                    HistorySwipeSurface(
                        leadingTitle: expandedDays.contains(day.id) ? "Close" : "Open",
                        leadingSymbol: expandedDays.contains(day.id) ? "chevron.up" : "chevron.down",
                        trailingTitle: "Delete day",
                        accessibilityTitle: "\(day.day.formatted(date: .complete, time: .omitted)), \(day.records.count) entries",
                        onTap: { toggleDay(day.id) },
                        onLeading: { toggleDay(day.id) },
                        onTrailing: {
                            onDeleteGroup(
                                day.records.map(\.id),
                                day.day.formatted(date: .complete, time: .omitted)
                            )
                        }
                    ) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.potsTeal)
                                .frame(width: 25)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(day.day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                    .font(.subheadline.weight(.semibold))
                                Text("\(day.categories.count) \(day.categories.count == 1 ? "category" : "categories")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 6)
                            Text("\(day.records.count)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Color.potsTeal)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Color.potsTeal.opacity(0.09), in: Capsule())
                            Image(systemName: expandedDays.contains(day.id) ? "chevron.down" : "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 11)
                    }
                    if expandedDays.contains(day.id) {
                        VStack(spacing: 5) {
                            ForEach(day.categories) { group in
                                categoryNode(group)
                            }
                        }
                        .padding(.top, 6)
                        .padding(.leading, 12)
                    }
                }
                .padding(8)
                .background(
                    Color.potsSurface,
                    in: RoundedRectangle(cornerRadius: 19)
                )
                .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(Color.potsTeal.opacity(0.08)))
            }
        }
    }

    @ViewBuilder
    private func categoryNode(_ group: RecordCategoryGroup) -> some View {
        VStack(spacing: 5) {
            HistorySwipeSurface(
                leadingTitle: expandedCategories.contains(group.id) ? "Close" : "Open",
                leadingSymbol: expandedCategories.contains(group.id) ? "chevron.up" : "chevron.down",
                trailingTitle: "Delete group",
                accessibilityTitle: "\(group.label), \(group.records.count) entries",
                onTap: { toggleCategory(group) },
                onLeading: { toggleCategory(group) },
                onTrailing: {
                    onDeleteGroup(
                        group.records.map(\.id),
                        "\(group.label) on \(group.day.formatted(date: .abbreviated, time: .omitted))"
                    )
                }
            ) {
                HStack(spacing: 10) {
                    Image(systemName: group.icon)
                        .frame(width: 22)
                        .foregroundStyle(Color.potsTeal)
                    Text(group.label).font(.subheadline.weight(.medium))
                    Spacer(minLength: 5)
                    Text("\(group.records.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Image(systemName: expandedCategories.contains(group.id) ? "chevron.down" : "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption2.weight(.medium))
                }
                .padding(.horizontal, 10)
            }

            if expandedCategories.contains(group.id) {
                LazyVStack(spacing: 6) {
                    ForEach(group.records) { record in
                        RecordSwipeRow(
                            record: record,
                            onEdit: { onEdit(record.id) },
                            onDelete: { onDelete(record.id) }
                        )
                    }
                }
                .padding(.leading, 11)
            }
        }
    }

    private func toggleDay(_ id: Date) {
        if !expandedDays.insert(id).inserted { expandedDays.remove(id) }
    }

    private func toggleCategory(_ group: RecordCategoryGroup) {
        if !expandedCategories.insert(group.id).inserted { expandedCategories.remove(group.id) }
    }
}

/// Swiping anywhere on a saved row feels like a normal short flick.
/// It reveals actions or, with a full swipe, opens the action; deletion always
/// requires the confirmation owned by the persistent History screen.
struct RecordSwipeRow: View {
    let record: RecordSnapshot
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HistorySwipeSurface(
            leadingTitle: "Edit",
            leadingSymbol: "pencil",
            trailingTitle: "Delete",
            accessibilityTitle: "\(record.title), \(record.detail)",
            onTap: onEdit,
            onLeading: onEdit,
            onTrailing: onDelete
        ) {
            HStack(spacing: 10) {
                Image(systemName: record.symbol)
                    .foregroundStyle(Color.potsTeal)
                    .frame(width: 23)
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(record.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 5)
                Text(record.recordedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 11)
        }
    }
}
