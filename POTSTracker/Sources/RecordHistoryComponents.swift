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
                EntryEditor(category: LogCategory(rawValue: record.category) ?? .journal, editing: record)
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

/// A compact expandable tree: date -> tracker type -> entry.
/// All groups start collapsed. Even hundreds of records won't become a wall of cards.
struct RecordTreeView: View {
    let records: [RecordSnapshot]
    let onEdit: (NSManagedObjectID) -> Void
    let onDelete: (NSManagedObjectID) -> Void
    @State private var expandedDays = Set<Date>()
    @State private var expandedCategories = Set<String>()

    var body: some View {
        LazyVStack(spacing: 9) {
            ForEach(RecordDayGroup.group(records)) { day in
                VStack(spacing: 0) {
                    Button {
                        toggleDay(day.id)
                    } label: {
                        HStack(spacing: 11) {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.potsTeal)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(day.day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                    .font(.subheadline.weight(.semibold))
                                Text("\(day.categories.count) \(day.categories.count == 1 ? "category" : "categories")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(day.records.count)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Color.potsTeal)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Color.potsTeal.opacity(0.09), in: Capsule())
                            Image(systemName: expandedDays.contains(day.id) ? "chevron.down" : "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(15)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(day.day.formatted(date: .complete, time: .omitted)), \(day.records.count) entries")
                    .accessibilityHint(expandedDays.contains(day.id) ? "Collapse date" : "Expand date")

                    if expandedDays.contains(day.id) {
                        Divider().padding(.leading, 15)
                        VStack(spacing: 0) {
                            ForEach(day.categories) { group in
                                categoryNode(group)
                            }
                        }
                        .padding(.leading, 14)
                        .padding(.trailing, 12)
                        .padding(.bottom, 7)
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.potsTeal.opacity(0.08)))
            }
        }
    }

    @ViewBuilder
    private func categoryNode(_ group: RecordCategoryGroup) -> some View {
        Button {
            if !expandedDays.contains(group.day) { expandedDays.insert(group.day) }
            if !expandedCategories.insert(group.id).inserted { expandedCategories.remove(group.id) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: group.icon)
                    .frame(width: 20)
                    .foregroundStyle(Color.potsTeal)
                Text(group.label).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(group.records.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Image(systemName: expandedCategories.contains(group.id) ? "chevron.down" : "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(expandedCategories.contains(group.id) ? "Collapse entries" : "Show individual entries")

        if expandedCategories.contains(group.id) {
            VStack(spacing: 0) {
                ForEach(group.records) { record in
                    RecordSwipeRow(record: record, onEdit: { onEdit(record.id) }, onDelete: { onDelete(record.id) })
                    if record.id != group.records.last?.id {
                        Divider().padding(.leading, 8)
                    }
                }
            }
            .padding(.leading, 10)
            .background(Color.potsTeal.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func toggleDay(_ id: Date) {
        if !expandedDays.insert(id).inserted { expandedDays.remove(id) }
    }
}

/// Swipe right reveals Edit; swipe left reveals Delete, which still asks
/// for confirmation. Tap a row to edit. VoiceOver and long press also work.
struct RecordSwipeRow: View {
    let record: RecordSnapshot
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var reveal: Int = 0

    private let railWidth: CGFloat = 77

    var body: some View {
        ZStack(alignment: .center) {
            HStack(spacing: 0) {
                Button {
                    reveal = 0
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .frame(width: railWidth, height: 62)
                        .foregroundStyle(.white)
                        .background(Color.potsTeal, in: RoundedRectangle(cornerRadius: 11))
                }
                .accessibilityLabel("Edit entry")
                Spacer()
                Button {
                    reveal = 0
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .frame(width: railWidth, height: 62)
                        .foregroundStyle(.white)
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 11))
                }
                .accessibilityLabel("Delete entry")
            }

            Button {
                if reveal == 0 { onEdit() } else { reveal = 0 }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: record.symbol)
                        .foregroundStyle(Color.potsTeal)
                        .frame(width: 21)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Text(record.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 4)
                    Text(record.recordedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 62)
                .padding(.horizontal, 8)
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 11))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: CGFloat(reveal) * railWidth)
            .simultaneousGesture(
                DragGesture(minimumDistance: 25)
                    .onEnded { gesture in
                        let dx = gesture.translation.width
                        let dy = gesture.translation.height
                        guard abs(dx) > 55, abs(dx) > abs(dy) * 1.35 else { return }
                        withAnimation(.easeOut(duration: 0.18)) {
                            reveal = dx > 0 ? 1 : -1
                        }
                    }
            )
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .contextMenu {
            Button(action: onEdit) { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive, action: { onDelete() }) { Label("Delete", systemImage: "trash") }
        }
        .accessibilityAction(named: "Edit") { onEdit() }
        .accessibilityAction(named: "Delete") { onDelete() }

    }
}