import SwiftUI
import CoreData
import UIKit

struct EntryEditor: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lowEnergyMode") private var lowEnergyMode = false

    let category: LogCategory
    let editing: POTSLogEntry?

    @State private var selectedFeeling: String
    @State private var title: String
    @State private var notes: String
    @State private var posture: String
    @State private var severity: Int
    @State private var firstValue: String
    @State private var secondValue: String
    @State private var recordedAt: Date
    @State private var saveError: String?
    @State private var saveInProgress = false
    @FocusState private var inputFocused: Bool

    private let symptoms = [
        "Dizziness", "Near-fainting", "Fainting", "Palpitations",
        "Fatigue", "Brain fog", "Nausea", "Headache",
        "Shakiness", "Heat intolerance", "Shortness of breath", "Other"
    ]
    private let positions = ["Not specified", "Lying down", "Sitting", "Standing"]

    init(category: LogCategory, editing: POTSLogEntry? = nil, suggestedFeeling: String? = nil, suggestedBPM: Int? = nil, suggestedNote: String? = nil) {
        self.category = category
        self.editing = editing
        _selectedFeeling = State(initialValue: editing.flatMap {
            CheckInFormat.feeling(title: $0.title, posture: $0.posture)
        } ?? suggestedFeeling ?? "")
        _title = State(initialValue: editing?.title ?? (
            category == .checkIn && suggestedFeeling != nil
            ? CheckInFormat.defaultTitle(for: suggestedFeeling!)
            : ""
        ))
        _notes = State(initialValue: editing?.notes ?? suggestedNote ?? "")
        _posture = State(initialValue: editing?.posture.isEmpty == false ? editing!.posture : "Not specified")
        _severity = State(initialValue: editing.map { Int($0.severity) } ?? -1)
        _firstValue = State(initialValue: editing == nil ? (suggestedBPM.map(String.init) ?? "") : "\(editing!.firstValue)")
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
            return CheckInFormat.feelings.contains(selectedFeeling)
                && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .hydration, .medications, .sleep, .posture:
            // These categories have their own dedicated typed editor.
            return false
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    Text("Add only what is useful. You can edit an entry later.")
                        .font(.footnote)
                        .foregroundStyle(Color.potsSecondary)
                    switch category {
                    case .symptom: symptomFields
                    case .heartRate: heartRateFields
                    case .bloodPressure: bloodPressureFields
                    case .journal: journalFields
                    case .checkIn: checkInFields
                    case .hydration, .medications, .sleep, .posture: EmptyView()
                    }
                    if category != .checkIn {
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
                    }
                    Text("This is a personal journal, not a medical diagnosis or emergency monitor.")
                        .font(.caption)
                        .foregroundStyle(Color.potsSecondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(18)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    inputFocused = false
                    saveEntry()
                } label: {
                    Label(editing == nil ? (category == .checkIn ? "Save check-in" : "Save entry") : "Save changes", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: lowEnergyMode ? 62 : 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.potsButtonFill)
                .disabled(!valid || saveInProgress || PersistenceController.shared.loadError != nil)
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(.regularMaterial)
            }
            .background(Color.potsBackground.ignoresSafeArea())
            .navigationTitle(editing == nil ? "New \(category.title)" : "Edit \(category.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { inputFocused = false }
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
                            title = PosiesChoiceBehavior.toggle(title, tapped: item == "Other" ? "" : item)
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(title == item ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity, minHeight: lowEnergyMode ? 56 : 43)
                        .background(title == item ? Color.potsButtonFill : Color.potsTeal.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(title == item ? [.isSelected] : [])
                        .accessibilityHint(title == item ? "Selected. Tap again to clear." : "Tap to select this symptom.")
                    }
                }
                TextField("Or type a symptom", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .focused($inputFocused)
                Text("Severity (optional)").font(.subheadline.weight(.semibold))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 55), spacing: 7)], spacing: 7) {
                    ForEach(0...10, id: \.self) { score in
                        let chosen = severity == score
                        Button {
                            severity = chosen ? -1 : score
                        } label: {
                            Text("\(score)")
                                .font(.subheadline.weight(chosen ? .bold : .medium))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .foregroundStyle(chosen ? Color.white : Color.primary)
                                .background(chosen ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                            in: RoundedRectangle(cornerRadius: 11))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Severity \(score) out of 10")
                        .accessibilityAddTraits(chosen ? [.isSelected] : [])
                        .accessibilityHint(chosen ? "Selected. Tap again to clear." : "Tap to record this rating.")
                    }
                }
                Text(severity < 0 ? "Not rated. You can leave this blank." :
                     "Tap the highlighted number again to remove your rating.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
                Text("Choose 0 only if you actually want to record zero.")
                    .font(.caption)
                    .foregroundStyle(Color.potsSecondary)
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
                        .focused($inputFocused)
                    Text("bpm")
                        .foregroundStyle(Color.potsSecondary)
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
                        .focused($inputFocused)
                    Text("/")
                    TextField("Diastolic", text: $secondValue)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                    Text("mmHg")
                        .font(.caption)
                        .foregroundStyle(Color.potsSecondary)
                }
                posturePicker
                Text("Enter measurements from an external blood-pressure monitor.")
                    .font(.caption)
                    .foregroundStyle(Color.potsSecondary)
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
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Text("How are you feeling?")
                        .font(.headline)
                    Spacer()
                    Text("Optional check-in")
                        .font(.caption)
                        .foregroundStyle(Color.potsSecondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 7)], spacing: 7) {
                    ForEach(CheckInFormat.feelings, id: \.self) { feeling in
                        Button {
                            let newFeeling = PosiesChoiceBehavior.toggle(selectedFeeling, tapped: feeling)
                            // Never save a feeling unless explicitly selected.
                            // Preserve titles written by the user.
                            if CheckInFormat.titleWasSuggested(title) || title.isEmpty {
                                title = newFeeling.isEmpty ? "" : CheckInFormat.defaultTitle(for: newFeeling)
                            }
                            selectedFeeling = newFeeling
                        } label: {
                            Text(feeling)
                                .font(.subheadline.weight(selectedFeeling == feeling ? .semibold : .medium))
                                .minimumScaleFactor(0.82)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, minHeight: lowEnergyMode ? 56 : 43)
                                .foregroundStyle(selectedFeeling == feeling ? Color.potsTeal : Color.primary)
                                .background(
                                    selectedFeeling == feeling ? Color.potsTeal.opacity(0.14) : Color.potsTeal.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
                                    selectedFeeling == feeling ? Color.potsTeal.opacity(0.45) : Color.clear
                                ))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedFeeling == feeling ? [.isSelected] : [])
                        .accessibilityHint(selectedFeeling == feeling ? "Selected. Tap again to clear." : "Tap to choose how you feel.")
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Title").font(.subheadline.weight(.semibold))
                    TextField("A short heading", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("What would you like to remember?")
                        .font(.subheadline.weight(.semibold))
                    TextField("Optional details, a trigger, or a question for later", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                }

                DatePicker("When?", selection: $recordedAt, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)

                Text("Nothing is recorded until you tap Save.")
                    .font(.caption)
                    .foregroundStyle(Color.potsSecondary)
            }
        }
    }

    private var posturePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position (optional)")
                .font(.subheadline.weight(.semibold))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                ForEach(positions.filter { $0 != "Not specified" }, id: \.self) { option in
                    let chosen = posture == option
                    Button {
                        posture = PosiesChoiceBehavior.toggle(posture, tapped: option, empty: "Not specified")
                    } label: {
                        Text(option)
                            .font(.subheadline.weight(chosen ? .semibold : .regular))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(chosen ? Color.white : Color.primary)
                            .background(chosen ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                        in: RoundedRectangle(cornerRadius: 11))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(chosen ? [.isSelected] : [])
                    .accessibilityHint(chosen ? "Selected. Tap again to clear." : "Tap to record this position.")
                }
            }
        }
    }

    private func saveEntry() {
        guard !saveInProgress else { return }
        guard valid else {
            saveError = "Enter a valid measurement or note."
            return
        }
        saveInProgress = true
        let entry = editing ?? POTSLogEntry(context: context)
        if editing == nil { entry.id = UUID() }
        entry.category = category.rawValue
        entry.title = category == .symptom || category == .checkIn ? title.trimmingCharacters(in: .whitespacesAndNewlines) : category.title
        entry.recordedAt = recordedAt
        entry.severity = category == .symptom ? Int16(severity) : -1
        entry.firstValue = Int32(firstValue) ?? 0
        entry.secondValue = Int32(secondValue) ?? 0
        entry.posture = category == .checkIn
            ? selectedFeeling
            : ((category == .heartRate || category == .bloodPressure) && posture != "Not specified" ? posture : "")
        entry.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if editing == nil {
            entry.timezoneID = TimeZone.current.identifier
            entry.source = "manual"
        }
        do {
            try POTSData.save(context)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            UIAccessibility.post(notification: .announcement, argument: "Entry saved")
            dismiss()
        } catch {
            context.rollback()
            saveInProgress = false
            saveError = error.localizedDescription
        }
    }
}
