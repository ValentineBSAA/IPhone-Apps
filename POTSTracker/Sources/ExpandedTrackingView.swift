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
            (category == .medications ? "Taken" : category == .posture ? "Sitting" : ""))
        _dose = State(initialValue: extra.dose)
        _contextText = State(initialValue: extra.context)
        _quality = State(initialValue: extra.quality)
        _notes = State(initialValue: editing?.notes ?? "")
        _recordedAt = State(initialValue: editing?.recordedAt ?? Date())
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
            return sleepKinds.contains(title) && (Int(firstValue).map { (1...2880).contains($0) } ?? false)
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
                            DatePicker("Recorded at", selection: $recordedAt, in: ...Date(),
                                       displayedComponents: [.date, .hourAndMinute])
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
            VStack(alignment: .leading, spacing: 14) {
                Text("Drink type").font(.headline)
                pickerGrid(fluidTypes, selected: $title)
                HStack {
                    TextField("Amount", text: $firstValue)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    Text("mL").foregroundStyle(Color.potsSecondary)
                }
                HStack {
                    TextField("Sodium (optional)", text: $secondValue)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    Text("mg sodium").font(.caption).foregroundStyle(Color.potsSecondary)
                }
                Text("1 US fluid ounce ≈ 29.57 mL. Sodium mg is not the same as grams of salt. No daily target is prescribed.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
        }
    }

    private var medicationFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                Text("Medication or supplement").font(.headline)
                TextField("Enter the name from your care plan", text: $title)
                    .textFieldStyle(.roundedBorder)
                Text("What happened?").font(.subheadline.weight(.semibold))
                pickerGrid(medStatuses, selected: $positionOrStatus)
                TextField("Dose / label (optional, as written)", text: $dose)
                    .textFieldStyle(.roundedBorder)
                TextField("Timing, effects or context (optional)", text: $contextText, axis: .vertical)
                    .lineLimit(2...4).textFieldStyle(.roundedBorder)
                Text("A reminder never marks a dose as taken. Record only what actually happened. This app does not recommend doses.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
        }
    }

    private var sleepFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                Text("Type of rest").font(.headline)
                pickerGrid(sleepKinds, selected: $title)
                HStack {
                    TextField("Duration in minutes", text: $firstValue)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    Text("min").foregroundStyle(Color.potsSecondary)
                }
                Text("How was it? (optional)").font(.subheadline.weight(.semibold))
                pickerGrid(["Not rated", "Restful", "Okay", "Interrupted", "Poor"], selected: $quality)
                TextField("Fatigue, brain fog or context (optional)", text: $contextText, axis: .vertical)
                    .lineLimit(2...4).textFieldStyle(.roundedBorder)
            }
        }
    }

    private var postureFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                Text("Position at the time").font(.headline)
                pickerGrid(positions, selected: $positionOrStatus)
                HStack {
                    TextField("Heart rate (optional)", text: $firstValue)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    Text("bpm").foregroundStyle(Color.potsSecondary)
                }
                HStack {
                    TextField("Minutes in position (optional)", text: $secondValue)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    Text("min").foregroundStyle(Color.potsSecondary)
                }
                TextField("Symptoms or conditions (optional)", text: $contextText, axis: .vertical)
                    .lineLimit(2...5).textFieldStyle(.roundedBorder)
                Text("This is an observation only, not a standing test or diagnosis. Never continue a position if you feel faint or unsafe.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
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
        item.recordedAt = recordedAt
        item.firstValue = Int32(firstValue) ?? 0
        item.secondValue = Int32(secondValue) ?? 0
        item.severity = -1
        item.posture = (category == .medications || category == .posture) ? positionOrStatus :
            (category == .sleep ? quality : "")
        item.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        var extras = PosiesEntryExtras()
        extras.dose = dose.trimmingCharacters(in: .whitespacesAndNewlines)
        extras.context = contextText.trimmingCharacters(in: .whitespacesAndNewlines)
        extras.quality = quality
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
