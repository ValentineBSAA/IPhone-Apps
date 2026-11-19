import SwiftUI
import CoreData

struct EntryEditor: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lowEnergyMode") private var lowEnergyMode = false

    let category: LogCategory
    let editing: POTSLogEntry?

    @State private var title: String
    @State private var notes: String
    @State private var posture: String
    @State private var severity: Int
    @State private var firstValue: String
    @State private var secondValue: String
    @State private var recordedAt: Date
    @State private var saveError: String?

    private let symptoms = [
        "Dizziness", "Near-fainting", "Fainting", "Palpitations",
        "Fatigue", "Brain fog", "Nausea", "Headache",
        "Shakiness", "Heat intolerance", "Shortness of breath", "Other"
    ]
    private let positions = ["Not specified", "Lying down", "Sitting", "Standing"]

    init(category: LogCategory, editing: POTSLogEntry? = nil) {
        self.category = category
        self.editing = editing
        _title = State(initialValue: editing?.title ?? "")
        _notes = State(initialValue: editing?.notes ?? "")
        _posture = State(initialValue: editing?.posture.isEmpty == false ? editing!.posture : "Not specified")
        _severity = State(initialValue: editing.map { Int($0.severity) } ?? -1)
        _firstValue = State(initialValue: editing == nil ? "" : "\(editing!.firstValue)")
        _secondValue = State(initialValue: editing == nil ? "" : "\(editing!.secondValue)")
        _recordedAt = State(initialValue: editing?.recordedAt ?? Date())
    }

    private var valid: Bool {
        switch category {
        case .symptom:
            return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .heartRate:
            guard let bpm = Int(firstValue) else { return false }
            return (1...400).contains(bpm)
        case .bloodPressure:
            guard let systolic = Int(firstValue), let diastolic = Int(secondValue) else { return false }
            return (1...400).contains(systolic) && (1...400).contains(diastolic)
        case .journal:
            return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .checkIn:
            return !title.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    Text("Everything here is entered manually. An iPhone cannot measure blood pressure by itself.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    switch category {
                    case .symptom: symptomFields
                    case .heartRate: heartRateFields
                    case .bloodPressure: bloodPressureFields
                    case .journal: journalFields
                    case .checkIn: checkInFields
                    }
                    GlassCard {
                        VStack(alignment: .leading, spacing: 13) {
                            DatePicker("Recorded at", selection: $recordedAt, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                            if category != .journal {
                                Text("Additional notes (optional)")
                                    .font(.subheadline.weight(.semibold))
                                TextField("What were you doing? How did you feel?", text: $notes, axis: .vertical)
                                    .lineLimit(3...7)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    Button {
                        saveEntry()
                    } label: {
                        Label(editing == nil ? "Save entry" : "Save changes", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: lowEnergyMode ? 62 : 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!valid || PersistenceController.shared.loadError != nil)
                    Text("This is a personal journal, not a medical diagnosis or emergency monitor.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(18)
            }
            .background(Color.potsBackground.ignoresSafeArea())
            .navigationTitle(editing == nil ? "New \(category.title)" : "Edit \(category.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Entry wasn't saved", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
    }

    private var symptomFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("What happened?")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 8)], spacing: 8) {
                    ForEach(symptoms, id: \.self) { item in
                        Button(item) {
                            title = item == "Other" ? "" : item
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(title == item ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity, minHeight: lowEnergyMode ? 56 : 43)
                        .background(title == item ? Color.potsTeal : Color.potsTeal.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                        .buttonStyle(.plain)
                    }
                }
                TextField("Or type a symptom", text: $title)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Text("Severity")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Picker("Severity", selection: $severity) {
                        Text("Not rated").tag(-1)
                        ForEach(0...10, id: \.self) { score in
                            Text("\(score) / 10").tag(score)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Text("Severity is optional. Choose 0 only if you actually want to record zero.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var heartRateFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                Text("Manual heart rate")
                    .font(.headline)
                HStack {
                    TextField("Beats per minute", text: $firstValue)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Text("bpm")
                        .foregroundStyle(.secondary)
                }
                posturePicker
            }
        }
    }

    private var bloodPressureFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                Text("Manual blood pressure")
                    .font(.headline)
                HStack {
                    TextField("Systolic", text: $firstValue)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Text("/")
                    TextField("Diastolic", text: $secondValue)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Text("mmHg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                posturePicker
                Text("Enter measurements from an external blood-pressure monitor.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var journalFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's thoughts")
                    .font(.headline)
                TextField("Write a note, experience, or question for your clinician", text: $notes, axis: .vertical)
                    .lineLimit(5...12)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var checkInFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("How are you feeling?")
                    .font(.headline)
                ForEach(["Better", "Usual", "Worse", "Much worse", "Not sure"], id: \.self) { feeling in
                    Button(feeling) { title = feeling }
                        .buttonStyle(.bordered)
                        .tint(title == feeling ? Color.potsTeal : Color.gray)
                }
            }
        }
    }

    private var posturePicker: some View {
        HStack {
            Text("Position")
                .font(.subheadline.weight(.medium))
            Spacer()
            Picker("Position", selection: $posture) {
                ForEach(positions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func saveEntry() {
        guard valid else {
            saveError = "Enter a valid measurement or note."
            return
        }
        let entry = editing ?? POTSLogEntry(context: context)
        if editing == nil { entry.id = UUID() }
        entry.category = category.rawValue
        entry.title = category == .symptom || category == .checkIn ? title.trimmingCharacters(in: .whitespacesAndNewlines) : category.title
        entry.recordedAt = recordedAt
        entry.severity = category == .symptom ? Int16(severity) : -1
        entry.firstValue = Int32(firstValue) ?? 0
        entry.secondValue = Int32(secondValue) ?? 0
        entry.posture = (category == .heartRate || category == .bloodPressure) && posture != "Not specified" ? posture : ""
        entry.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if editing == nil {
            entry.timezoneID = TimeZone.current.identifier
            entry.source = "manual"
        }
        do {
            try POTSData.save(context)
            dismiss()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}

struct EntryCard: View {
    @Environment(\.managedObjectContext) private var context
    let entry: POTSLogEntry
    let onEdit: () -> Void

    @State private var confirmDelete = false
    @State private var deletionError: String?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: LogCategory(rawValue: entry.category)?.symbol ?? "square.and.pencil")
                        .foregroundStyle(Color.potsTeal)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.subheadline.weight(.semibold))
                        Text(EntryFormat.description(for: entry))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    Spacer(minLength: 0)
                    Text(entry.recordedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                if !entry.notes.isEmpty && entry.category != LogCategory.journal.rawValue {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                HStack {
                    Spacer()
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive) { confirmDelete = true }
                }
                .font(.caption.weight(.medium))
                .buttonStyle(.borderless)
            }
        }
        .confirmationDialog("Delete this record permanently?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete record", role: .destructive) {
                context.delete(entry)
                do {
                    try POTSData.save(context)
                } catch {
                    context.rollback()
                    deletionError = error.localizedDescription
                }
            }
        }
        .alert("Deletion failed", isPresented: Binding(
            get: { deletionError != nil },
            set: { if !$0 { deletionError = nil } }
        )) {
            Button("OK") { deletionError = nil }
        } message: {
            Text(deletionError ?? "Please try again.")
        }
    }
}
