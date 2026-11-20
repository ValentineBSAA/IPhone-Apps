import SwiftUI
import CoreData
import UIKit

/// Additional typed entry fields are kept in the existing non-private "source"
/// string column. This avoids a schema migration while old manual entries stay
/// readable. The freeform notes remain in their original field.
struct PosiesEntryExtras: Codable, Equatable {
    var dose: String = ""
    var context: String = ""
    var quality: String = ""
    var recordSource: String = "manual"
    // Optional fields decode from v0.2.4/v0.2.5 records without a
    // storage migration or loss of earlier dose/context/quality metadata.
    var tags: [String]?
    var recovery: String?
    var startAt: Date?
    var endAt: Date?
    static let marker = "posies-extra-v1:"

    init(dose: String = "", context: String = "", quality: String = "",
         recordSource: String = "manual", tags: [String]? = nil,
         recovery: String? = nil, startAt: Date? = nil, endAt: Date? = nil) {
        self.dose = dose
        self.context = context
        self.quality = quality
        self.recordSource = recordSource
        self.tags = tags
        self.recovery = recovery
        self.startAt = startAt
        self.endAt = endAt
    }

    static func read(_ stored: String) -> PosiesEntryExtras {
        guard stored.hasPrefix(marker),
              let data = Data(base64Encoded: String(stored.dropFirst(marker.count))),
              let result = try? JSONDecoder().decode(PosiesEntryExtras.self, from: data) else {
            return PosiesEntryExtras()
        }
        return result
    }

    func stored() -> String {
        guard let encoded = try? JSONEncoder().encode(self) else { return "manual" }
        return Self.marker + encoded.base64EncodedString()
    }
}

struct ExpandedEntryEditor: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lowEnergyMode") private var lowEnergyMode = false

    let category: LogCategory
    let editing: POTSLogEntry?

    @State private var title: String
    @State private var firstValue: String
    @State private var secondValue: String
    @State private var positionOrStatus: String
    @State private var dose: String
    @State private var contextText: String
    @State private var quality: String
    @State private var notes: String
    @State private var recordedAt: Date
    @State private var errorText: String?
    @State private var saving = false
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var previousEntries: FetchedResults<POTSLogEntry>
    @State private var selectedTags: Set<String>
    @State private var recovery: String
    @State private var useTimeRange: Bool
    @State private var sleepStart: Date
    @State private var sleepEnd: Date

    private let fluidTypes = ["Water", "Electrolyte drink", "Other drink", "Food / fluid"]
    private let sleepKinds = ["Sleep", "Rest"]
    private let medStatuses = ["Taken", "Skipped", "Planned", "Other"]
    private let positions = ["Lying down", "Sitting", "Standing", "Other"]

    init(category: LogCategory, editing: POTSLogEntry? = nil) {
        self.category = category
        self.editing = editing
        let extra = editing.map { PosiesEntryExtras.read($0.source) } ?? PosiesEntryExtras()
        let defaultTitle: String
        switch category {
        case .hydration: defaultTitle = "Water"
        case .sleep: defaultTitle = "Sleep"
        default: defaultTitle = ""
        }
        _title = State(initialValue: editing?.title ?? defaultTitle)
        _firstValue = State(initialValue: editing == nil || editing!.firstValue <= 0 ? "" : String(editing!.firstValue))
        _secondValue = State(initialValue: editing == nil || editing!.secondValue <= 0 ? "" : String(editing!.secondValue))
        _positionOrStatus = State(initialValue: editing?.posture.isEmpty == false ? editing!.posture :
            (category == .posture ? "Sitting" : ""))
        _dose = State(initialValue: extra.dose)
        _contextText = State(initialValue: extra.context)
        _quality = State(initialValue: extra.quality)
        _notes = State(initialValue: editing?.notes ?? "")
        _recordedAt = State(initialValue: editing?.recordedAt ?? Date())
        _selectedTags = State(initialValue: Set(extra.tags ?? []))
        _recovery = State(initialValue: extra.recovery ?? "")
        _useTimeRange = State(initialValue: extra.startAt != nil && extra.endAt != nil)
        _sleepStart = State(initialValue: extra.startAt ?? Date().addingTimeInterval(-3600))
        _sleepEnd = State(initialValue: extra.endAt ?? Date())
    }

    private var sleepMinutes: Int {
        Int(sleepEnd.timeIntervalSince(sleepStart) / 60)
    }

    private var lastDrink: POTSLogEntry? {
        previousEntries.first {
            !$0.isDeleted && $0.category == LogCategory.hydration.rawValue
        }
    }

    private var recentMedications: [POTSLogEntry] {
        var encountered = Set<String>()
        return Array(previousEntries.filter {
            $0.category == LogCategory.medications.rawValue && !$0.isDeleted &&
            encountered.insert($0.title.lowercased()).inserted
        }.prefix(5))
    }

    private var valid: Bool {
        switch category {
        case .hydration:
            guard let ml = Int(firstValue), (1...10000).contains(ml) else { return false }
            return secondValue.isEmpty || (Int(secondValue).map { (0...30000).contains($0) } ?? false)
        case .medications:
            return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                title.count <= 150 && medStatuses.contains(positionOrStatus)
        case .sleep:
            return sleepKinds.contains(title) &&
                (useTimeRange ? (1...2880).contains(sleepMinutes) :
                 (Int(firstValue).map { (1...2880).contains($0) } ?? false))
        case .posture:
            return positions.contains(positionOrStatus) &&
                (firstValue.isEmpty || (Int(firstValue).map { (1...400).contains($0) } ?? false)) &&
                (secondValue.isEmpty || (Int(secondValue).map { (0...1440).contains($0) } ?? false))
        default:
            return false
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heading
                    switch category {
                    case .hydration: hydrationFields
                    case .medications: medicationFields
                    case .sleep: sleepFields
                    case .posture: postureFields
                    default: EmptyView()
                    }
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            if category == .sleep && useTimeRange {
                                Text("This entry will be dated when your recorded rest ended.")
                                    .font(.caption).foregroundStyle(Color.potsSecondary)
                            } else {
                                DatePicker("Recorded at", selection: $recordedAt, in: ...Date(),
                                           displayedComponents: [.date, .hourAndMinute])
                            }
                            Text("Notes (optional)").font(.subheadline.weight(.semibold))
                            TextField("What would you like to remember?", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 25)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    saveRecord()
                } label: {
                    Label(editing == nil ? "Save entry" : "Save changes", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: lowEnergyMode ? 64 : 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.potsButtonFill)
                .disabled(!valid || saving || PersistenceController.shared.loadError != nil)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(.regularMaterial)
            }
            .background(Color.potsBackground.ignoresSafeArea())
            .navigationTitle(editing == nil ? "New \(category.title)" : "Edit \(category.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Couldn't save entry", isPresented: Binding(
                get: { errorText != nil },
                set: { if !$0 { errorText = nil } }
            )) {
                Button("OK") { errorText = nil }
            } message: {
                Text(errorText ?? "Please try again.")
            }
        }
    }

    private var heading: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Label(category.title, systemImage: category.symbol)
                    .font(.title3.bold())
                    .foregroundStyle(Color.potsTeal)
                Text("Only what you choose to record is saved. You can edit or delete it later.")
                    .font(.subheadline)
                    .foregroundStyle(Color.potsSecondary)
            }
        }
    }

    private var hydrationFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                Label("What did you drink?", systemImage: "drop.fill")
                    .font(.headline).foregroundStyle(Color.potsTeal)
                pickerGrid(fluidTypes, selected: $title)
                if let previous = lastDrink, previous.firstValue > 0 {
                    Button {
                        title = previous.title
                        firstValue = String(previous.firstValue)
                        secondValue = previous.secondValue > 0 ? String(previous.secondValue) : ""
                    } label: {
                        Label("Reuse last drink: \\(previous.title), \\(previous.firstValue) mL",
                              systemImage: "arrow.counterclockwise")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint("Fills the form only. Nothing is recorded until Save.")
                }
                Text("Amount").font(.subheadline.weight(.semibold))
                HStack {
                    TextField("Amount", text: $firstValue)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Fluid amount, milliliters")
                    Text("mL").foregroundStyle(Color.potsSecondary)
                }
                Text("Quick amounts").font(.caption.weight(.semibold))
                HStack(spacing: 7) {
                    ForEach([125, 250, 350, 500], id: \.self) { amount in
                        Button("\\(amount)") { firstValue = String(amount) }
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .foregroundStyle(firstValue == String(amount) ? Color.white : Color.potsTeal)
                            .background(firstValue == String(amount) ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                        in: RoundedRectangle(cornerRadius: 10))
                            .accessibilityLabel("\\(amount) milliliters")
                    }
                }
                Text("Sodium (optional)").font(.subheadline.weight(.semibold))
                HStack {
                    TextField("From the product label", text: $secondValue)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    Text("mg").font(.caption).foregroundStyle(Color.potsSecondary)
                }
                Text("Helpful context (optional)")
                    .font(.subheadline.weight(.semibold))
                tagGrid(["With food", "After activity", "Morning", "Before bed"])
                Text("These buttons enter amounts, not recommended targets. Sodium is recorded in mg, not grams of salt.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
        }
    }

    private var medicationFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                Label("Medication or supplement", systemImage: "pills.fill")
                    .font(.headline).foregroundStyle(Color.potsTeal)
                if !recentMedications.isEmpty {
                    Text("Previously recorded").font(.subheadline.weight(.semibold))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 8)], spacing: 8) {
                        ForEach(recentMedications, id: \.id) { item in
                            Button {
                                title = item.title
                                dose = PosiesEntryExtras.read(item.source).dose
                                // Never infer that a past dose was taken today.
                                if editing == nil { positionOrStatus = "" }
                            } label: {
                                Text(item.title)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(2).minimumScaleFactor(0.8)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityHint("Fills name and label. Choose today's status and Save to record.")
                        }
                    }
                }
                TextField("Name as written on your label", text: $title)
                    .textFieldStyle(.roundedBorder)
                TextField("Dose or label (optional)", text: $dose)
                    .textFieldStyle(.roundedBorder)
                Text("What happened?").font(.subheadline.weight(.semibold))
                pickerGrid(medStatuses, selected: $positionOrStatus)
                if positionOrStatus.isEmpty {
                    Text("Choose a status to save. Nothing is assumed taken.")
                        .font(.caption).foregroundStyle(Color.potsSecondary)
                }
                Text("Optional details").font(.subheadline.weight(.semibold))
                tagGrid(["With food", "With water", "After eating", "Effect noticed"])
                TextField("Timing, reason or other context", text: $contextText, axis: .vertical)
                    .lineLimit(2...4).textFieldStyle(.roundedBorder)
                Text("This is a personal record, not a dose recommendation or automatic medication adherence tracker.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
        }
    }

    private var sleepFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                Label("Sleep or rest", systemImage: "moon.stars.fill")
                    .font(.headline).foregroundStyle(Color.potsTeal)
                pickerGrid(sleepKinds, selected: $title)
                Toggle("Enter start and end times", isOn: $useTimeRange)
                    .tint(.potsTeal)
                if useTimeRange {
                    DatePicker("Started", selection: $sleepStart, in: ...Date(),
                               displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Ended", selection: $sleepEnd, in: ...Date(),
                               displayedComponents: [.date, .hourAndMinute])
                    Text((1...2880).contains(sleepMinutes)
                         ? "Duration: \\(sleepMinutes) minutes, including overnight rest."
                         : "End time must be after start time, within 48 hours.")
                        .font(.caption.weight(.medium))
                        .foregroundStyle((1...2880).contains(sleepMinutes) ? Color.potsTeal : Color.potsSecondary)
                } else {
                    HStack {
                        TextField("Duration", text: $firstValue)
                            .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        Text("min").foregroundStyle(Color.potsSecondary)
                    }
                    HStack(spacing: 7) {
                        ForEach([15, 30, 60, 90], id: \.self) { minutes in
                            Button("\\(minutes) min") { firstValue = String(minutes) }
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(Color.potsSurfaceMuted, in: RoundedRectangle(cornerRadius: 11))
                        }
                    }
                    .buttonStyle(.plain)
                }
                Text("How was it? (optional)").font(.subheadline.weight(.semibold))
                pickerGrid(["Not rated", "Restful", "Okay", "Interrupted", "Poor"], selected: $quality)
                Text("Afterward (optional)").font(.subheadline.weight(.semibold))
                pickerGrid(["Refreshed", "About the same", "Still tired", "Not sure"], selected: $recovery)
                TextField("Fatigue, brain fog, interruptions or context", text: $contextText, axis: .vertical)
                    .lineLimit(2...4).textFieldStyle(.roundedBorder)
                Text("Rest and sleep durations describe what you entered, not a sleep-quality score.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
        }
    }

    private var postureFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                Label("Position observation", systemImage: "figure.stand")
                    .font(.headline).foregroundStyle(Color.potsTeal)
                pickerGrid(positions, selected: $positionOrStatus)
                Text("Optional measurements").font(.subheadline.weight(.semibold))
                HStack {
                    TextField("Heart rate", text: $firstValue)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    Text("bpm").foregroundStyle(Color.potsSecondary)
                }
                HStack {
                    TextField("Time in position", text: $secondValue)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    Text("min").foregroundStyle(Color.potsSecondary)
                }
                Text("What did you notice? (optional)")
                    .font(.subheadline.weight(.semibold))
                tagGrid(["Lightheaded", "Palpitations", "Fatigued", "Uncomfortable"])
                TextField("Other symptoms or context", text: $contextText, axis: .vertical)
                    .lineLimit(2...5).textFieldStyle(.roundedBorder)
                Text("Record only a position you were already in. This is not a guided standing test or diagnosis; stop if you feel unsafe.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
        }
    }

    private func tagGrid(_ options: [String]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 116), spacing: 8)], spacing: 8) {
            ForEach(options, id: \.self) { tag in
                let selected = selectedTags.contains(tag)
                Button {
                    if selected { selectedTags.remove(tag) }
                    else { selectedTags.insert(tag) }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                        Text(tag).font(.caption.weight(selected ? .semibold : .regular))
                            .lineLimit(2).minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .foregroundStyle(selected ? Color.white : Color.primary)
                    .background(selected ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                in: RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
    }

    private func pickerGrid(_ options: [String], selected: Binding<String>) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 9)], spacing: 9) {
            ForEach(options, id: \.self) { choice in
                let active = selected.wrappedValue == choice
                Button {
                    selected.wrappedValue = choice
                } label: {
                    Text(choice)
                        .font(.subheadline.weight(active ? .semibold : .regular))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(active ? Color.white : Color.primary)
                        .background(active ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(active ? [.isSelected] : [])
            }
        }
    }

    private func saveRecord() {
        guard valid && !saving else { return }
        saving = true
        let item = editing ?? POTSLogEntry(context: context)
        if editing == nil { item.id = UUID() }
        item.category = category.rawValue
        item.title = category == .posture ? "Position observation" : title.trimmingCharacters(in: .whitespacesAndNewlines)
        item.recordedAt = category == .sleep && useTimeRange ? sleepEnd : recordedAt
        item.firstValue = category == .sleep && useTimeRange
            ? Int32(sleepMinutes) : (Int32(firstValue) ?? 0)
        item.secondValue = Int32(secondValue) ?? 0
        item.severity = -1
        item.posture = (category == .medications || category == .posture) ? positionOrStatus :
            (category == .sleep ? quality : "")
        item.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        var extras = editing.map { PosiesEntryExtras.read($0.source) } ?? PosiesEntryExtras()
        extras.dose = dose.trimmingCharacters(in: .whitespacesAndNewlines)
        extras.context = contextText.trimmingCharacters(in: .whitespacesAndNewlines)
        extras.quality = quality
        extras.tags = selectedTags.isEmpty ? nil : selectedTags.sorted()
        extras.recovery = recovery.isEmpty ? nil : recovery
        extras.startAt = category == .sleep && useTimeRange ? sleepStart : nil
        extras.endAt = category == .sleep && useTimeRange ? sleepEnd : nil
        item.source = extras.stored()
        if editing == nil { item.timezoneID = TimeZone.current.identifier }
        do {
            try POTSData.save(context)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            UIAccessibility.post(notification: .announcement, argument: "Entry saved")
            dismiss()
        } catch {
            context.rollback()
            saving = false
            errorText = error.localizedDescription
        }
    }
}
