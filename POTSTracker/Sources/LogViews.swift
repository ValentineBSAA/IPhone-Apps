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
    @State private var showGuidance = false
    @State private var vitalContext: PosiesVitalsContext
    @State private var secondReading: Bool
    @State private var secondSystolic: String
    @State private var secondDiastolic: String
    @State private var monitorPulse: String
    @State private var flareEnabled: Bool
    @State private var flareStart: Date
    @State private var flareHasEnd: Bool
    @State private var flareEnd: Date
    @State private var flarePulse: String
    @State private var flareTop: String
    @State private var flareBottom: String
    @State private var flareTriggers: Set<String>
    @State private var flareHelped: String
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
        let savedVitals = editing.map { PosiesVitalsContext.read($0.source) } ?? PosiesVitalsContext()
        _vitalContext = State(initialValue: savedVitals)
        _secondReading = State(initialValue: savedVitals.hasSecondReading)
        _secondSystolic = State(initialValue: savedVitals.secondSystolic.map(String.init) ?? "")
        _secondDiastolic = State(initialValue: savedVitals.secondDiastolic.map(String.init) ?? "")
        _monitorPulse = State(initialValue: savedVitals.monitorPulse.map(String.init) ?? "")
        let flare = editing.flatMap { PosiesFlareContext.read($0.source) }
        _flareEnabled = State(initialValue: flare != nil)
        _flareStart = State(initialValue: flare?.startedAt ?? editing?.recordedAt ?? Date())
        _flareHasEnd = State(initialValue: flare?.endedAt != nil)
        _flareEnd = State(initialValue: flare?.endedAt ?? Date())
        _flarePulse = State(initialValue: flare?.pulse.map(String.init) ?? "")
        _flareTop = State(initialValue: flare?.systolic.map(String.init) ?? "")
        _flareBottom = State(initialValue: flare?.diastolic.map(String.init) ?? "")
        _flareTriggers = State(initialValue: Set(flare?.triggers ?? []))
        _flareHelped = State(initialValue: flare?.whatHelped ?? "")
    }

    private var flareContext: PosiesFlareContext {
        var value = PosiesFlareContext()
        value.startedAt = flareStart
        value.endedAt = flareHasEnd ? flareEnd : nil
        value.pulse = flarePulse.isEmpty ? nil : Int(flarePulse)
        value.systolic = flareTop.isEmpty ? nil : Int(flareTop)
        value.diastolic = flareBottom.isEmpty ? nil : Int(flareBottom)
        value.triggers = flareTriggers.sorted()
        value.whatHelped = flareHelped.trimmingCharacters(in: .whitespacesAndNewlines)
        return value
    }
    private var flareInputsValid: Bool {
        (!flareHasEnd || flareEnd >= flareStart) &&
        (flarePulse.isEmpty || (Int(flarePulse).map { (1...400).contains($0) } ?? false)) &&
        (flareTop.isEmpty == flareBottom.isEmpty) &&
        (flareTop.isEmpty || (Int(flareTop).map { (1...400).contains($0) } ?? false)) &&
        (flareBottom.isEmpty || (Int(flareBottom).map { (1...400).contains($0) } ?? false)) &&
        flareHelped.count <= 2000
    }

    private var valid: Bool {
        switch category {
        case .symptom:
            return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                (!flareEnabled || flareInputsValid)
        case .heartRate:
            guard let bpm = Int(firstValue) else { return false }
            return (1...400).contains(bpm)
        case .bloodPressure:
            guard let systolic = Int(firstValue), let diastolic = Int(secondValue),
                  (1...400).contains(systolic), (1...400).contains(diastolic) else { return false }
            if !monitorPulse.isEmpty {
                guard let pulse = Int(monitorPulse), (1...400).contains(pulse) else { return false }
            }
            if secondReading {
                guard let secondTop = Int(secondSystolic), let secondBottom = Int(secondDiastolic),
                      (1...400).contains(secondTop), (1...400).contains(secondBottom) else { return false }
            }
            return true
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
                    HStack(spacing: 10) {
                        PosiesFeatureIcon(featureID: category.rawValue, width: 42)
                        Text("Record what feels useful; edit it later.")
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        Spacer(minLength: 0)
                    }.padding(10)
                        .background(Color.potsSurface, in: RoundedRectangle(cornerRadius: 15))
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
                PosiesFeatureSectionTitle(featureID: "symptom", title: "What happened?")
                PosiesChoiceMenu(title: "Choose a symptom",
                                 options: symptoms.filter { $0 != "Other" },
                                 selected: $title)
                Text("Quick choices").font(.caption.weight(.semibold))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 8)], spacing: 8) {
                    ForEach(["Dizziness", "Palpitations", "Fatigue", "Brain fog"], id: \.self) { item in
                        let active = title == item
                        Button(item) { title = PosiesChoiceBehavior.toggle(title, tapped: item) }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(active ? Color.white : Color.primary)
                            .frame(maxWidth: .infinity, minHeight: lowEnergyMode ? 56 : 43)
                            .background(active ? Color.potsButtonFill : Color.potsTeal.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 13))
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(active ? [.isSelected] : [])
                            .accessibilityHint(active ? "Selected. Tap again to clear." : "Tap to select.")
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
                            severity = PosiesChoiceBehavior.toggleRating(severity, tapped: score)
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
                Toggle("Add flare-up details (optional)", isOn: $flareEnabled)
                    .tint(.potsTeal)
                if flareEnabled {
                    VStack(alignment: .leading, spacing: 11) {
                        Label("One place for your observations", systemImage: "heart.text.square")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Color.potsTeal)
                        Text("Only include measurements you already have. No standing test or activity is required.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                        DatePicker("When it started", selection: $flareStart, in: ...Date(),
                                   displayedComponents: [.date, .hourAndMinute])
                        Toggle("Add an end time", isOn: $flareHasEnd).tint(.potsTeal)
                        if flareHasEnd {
                            DatePicker("When it eased", selection: $flareEnd, in: flareStart...Date(),
                                       displayedComponents: [.date, .hourAndMinute])
                        }
                        Text("What might have contributed? (optional)")
                            .font(.subheadline.weight(.semibold))
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                            ForEach(["Heat", "Activity", "Standing", "After food", "Stress", "Not sure"], id: \.self) { tag in
                                let chosen = flareTriggers.contains(tag)
                                Button {
                                    flareTriggers = PosiesChoiceBehavior.toggleInSet(flareTriggers, tapped: tag)
                                } label: {
                                    Text(tag).font(.caption.weight(chosen ? .semibold : .regular))
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .foregroundStyle(chosen ? Color.white : Color.primary)
                                        .background(chosen ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                                    in: RoundedRectangle(cornerRadius: 11))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text("Measurements you already recorded (optional)")
                            .font(.subheadline.weight(.semibold))
                        HStack {
                            TextField("Pulse", text: $flarePulse).keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            Text("bpm").font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                        HStack {
                            TextField("BP top", text: $flareTop).keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            Text("/")
                            TextField("BP bottom", text: $flareBottom).keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        TextField("What helped or changed afterward? (optional)", text: $flareHelped, axis: .vertical)
                            .lineLimit(2...5).textFieldStyle(.roundedBorder)
                        Text("Possible triggers are only your observations. The app doesn't infer causes or a diagnosis.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                    .padding(12)
                    .background(Color.potsSurfaceMuted, in: RoundedRectangle(cornerRadius: 15))
                }
            }
        }
    }

    private var heartRateFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                PosiesFeatureSectionTitle(featureID: "heartRate", title: "Record a heart-rate reading")
                Text("Enter the number shown on your own monitor, or a manually counted pulse.")
                    .font(.subheadline).foregroundStyle(Color.potsSecondary)
                measurementGuide
                HStack {
                    TextField("Heart rate", text: $firstValue)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                    Text("bpm").foregroundStyle(Color.potsSecondary)
                }
                Text("How did you measure? (optional)")
                    .font(.subheadline.weight(.semibold))
                PosiesChoiceMenu(title: "Reading source",
                                 options: ["Finger monitor", "Cuff monitor", "Manual pulse", "Other"],
                                 selected: $vitalContext.source)
                Text("When was it taken? (optional)")
                    .font(.subheadline.weight(.semibold))
                PosiesChoiceMenu(title: "Reading context",
                                 options: ["Resting", "After activity", "During symptoms", "Other"],
                                 selected: $vitalContext.timing)
                posturePicker
                Text("A reading is one observation, not a diagnosis. No camera pulse value is ever auto-saved.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
        }
    }

    private var bloodPressureFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                PosiesFeatureSectionTitle(featureID: "bloodPressure", title: "Record blood pressure")
                Text("Use the numbers from your own blood-pressure monitor.")
                    .font(.subheadline).foregroundStyle(Color.potsSecondary)
                measurementGuide
                Text("First reading").font(.subheadline.weight(.semibold))
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Systolic · top").font(.caption).foregroundStyle(Color.potsSecondary)
                        TextField("Top number", text: $firstValue).keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder).focused($inputFocused)
                    }
                    Text("/").padding(.top, 18)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Diastolic · bottom").font(.caption).foregroundStyle(Color.potsSecondary)
                        TextField("Bottom number", text: $secondValue).keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder).focused($inputFocused)
                    }
                    Text("mmHg").font(.caption).foregroundStyle(Color.potsSecondary).padding(.top, 18)
                }
                Toggle("Record a second reading", isOn: $secondReading)
                    .tint(.potsTeal)
                if secondReading {
                    Text("For standard seated home measurements, a second reading is often taken about a minute after the first.")
                        .font(.caption).foregroundStyle(Color.potsSecondary)
                    HStack(spacing: 9) {
                        TextField("Second top", text: $secondSystolic)
                            .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        Text("/")
                        TextField("Second bottom", text: $secondDiastolic)
                            .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        Text("mmHg").font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                    if let top = Int(firstValue), let bottom = Int(secondValue),
                       let nextTop = Int(secondSystolic), let nextBottom = Int(secondDiastolic),
                       [top, bottom, nextTop, nextBottom].allSatisfy({ (1...400).contains($0) }) {
                        Text("Two-reading average: \((top + nextTop + 1) / 2)/\((bottom + nextBottom + 1) / 2) mmHg")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.potsTeal)
                        Text("Both original readings are kept. The average is a calculation, not a health rating.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }
                Text("Pulse from your monitor (optional)")
                    .font(.subheadline.weight(.semibold))
                HStack {
                    TextField("Pulse, if shown", text: $monitorPulse)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    Text("bpm").foregroundStyle(Color.potsSecondary)
                }
                Text("Monitor type (optional)").font(.subheadline.weight(.semibold))
                choiceGrid(["Upper-arm cuff", "Wrist cuff", "Other monitor"], selected: $vitalContext.source)
                Text("When was it taken? (optional)")
                    .font(.subheadline.weight(.semibold))
                PosiesChoiceMenu(title: "Reading context",
                                 options: ["Resting", "After activity", "During symptoms", "Other"],
                                 selected: $vitalContext.timing)
                posturePicker
                Text("This app records measurements without diagnosing or recommending a change in medication.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
        }
    }

    private var measurementGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { showGuidance.toggle() }
            } label: {
                HStack {
                    Image(systemName: "book.closed.fill")
                    Text(showGuidance ? "Hide measuring tips" : "Help me measure")
                    Spacer()
                    Image(systemName: showGuidance ? "chevron.up" : "chevron.down")
                }
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
                .foregroundStyle(Color.potsTeal)
            }
            .buttonStyle(.plain)
            if showGuidance {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(Array((category == .bloodPressure
                          ? PosiesGentleGuidance.pressureSteps
                          : PosiesGentleGuidance.pulseSteps).enumerated()), id: \.offset) { index, line in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).").foregroundStyle(Color.potsTeal)
                            Text(line).foregroundStyle(Color.potsSecondary)
                        }
                        .font(.caption)
                    }
                    Text("If your clinician gave different instructions, follow those instead.")
                        .font(.caption.weight(.semibold))
                }
                .padding(12)
                .background(Color.potsSurfaceMuted, in: RoundedRectangle(cornerRadius: 13))
            }
        }
    }

    private func choiceGrid(_ choices: [String], selected: Binding<String>) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], spacing: 8) {
            ForEach(choices, id: \.self) { option in
                let chosen = selected.wrappedValue == option
                Button {
                    selected.wrappedValue = PosiesChoiceBehavior.toggle(selected.wrappedValue, tapped: option)
                } label: {
                    Text(option)
                        .font(.caption.weight(chosen ? .semibold : .regular))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(chosen ? Color.white : Color.primary)
                        .background(chosen ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                    in: RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(chosen ? [.isSelected] : [])
                .accessibilityHint(chosen ? "Selected. Tap again to clear." : "Tap to choose.")
            }
        }
    }

    private var journalFields: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                PosiesFeatureSectionTitle(featureID: "journal", title: "Today's thoughts")
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
                    PosiesFeatureSectionTitle(featureID: "checkIn", title: "How are you feeling?")
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
        if editing == nil { entry.timezoneID = TimeZone.current.identifier }
        if category == .bloodPressure || category == .heartRate {
            var extra = vitalContext
            extra.secondSystolic = category == .bloodPressure && secondReading ? Int(secondSystolic) : nil
            extra.secondDiastolic = category == .bloodPressure && secondReading ? Int(secondDiastolic) : nil
            extra.monitorPulse = category == .bloodPressure ? Int(monitorPulse) : nil
            entry.source = extra.stored()
        } else if category == .symptom {
            entry.source = flareEnabled ? flareContext.stored() : "manual"
        } else if editing == nil {
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
