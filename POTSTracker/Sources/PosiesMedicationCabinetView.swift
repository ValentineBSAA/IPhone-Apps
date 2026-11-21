import SwiftUI
import CoreData

private struct PosiesMedicationDraft: Identifiable {
    let id: UUID
    let profile: PosiesMedicationProfile
    init(_ profile: PosiesMedicationProfile) {
        id = profile.id
        self.profile = profile
    }
}

/// A compact private cabinet: user-saved information first, a separate
/// offline lookup for generic/brand names, and no inferred medication intake.
struct PosiesMedicationCabinetView: View {
    @State private var profiles: [PosiesMedicationProfile] = []
    @State private var editing: PosiesMedicationDraft?
    @State private var deleting: UUID?
    @State private var errorText: String?
    @State private var showingCatalog = false
    @State private var pendingCatalogChoice: PosiesMedicationReference?
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var recordedEvents: FetchedResults<POTSLogEntry>

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    private func lastEvent(for name: String) -> POTSLogEntry? {
        recordedEvents.first {
            !$0.isDeleted && $0.category == LogCategory.medications.rawValue &&
            $0.title.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Keep your own medication labels in one place. Browse by generic or brand name, or add something yourself.")
                    .font(.subheadline)
                    .foregroundStyle(Color.potsSecondary)
                LazyVGrid(columns: columns, spacing: 12) {
                    Button {
                        showingCatalog = true
                    } label: {
                        Label("Browse medicine library", systemImage: "books.vertical.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.potsButtonFill)
                    .disabled(profiles.count >= PosiesMedicationLibrary.maximumProfiles)
                    Button {
                        editing = PosiesMedicationDraft(
                            PosiesMedicationProfile(name: "", schedule: "Not set"))
                    } label: {
                        Label("Add custom medication", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(.bordered)
                    .disabled(profiles.count >= PosiesMedicationLibrary.maximumProfiles)
                }
                HStack {
                    Text("Your saved medications").font(.title3.bold())
                    Spacer()
                    Text("\(profiles.count) saved").font(.caption).foregroundStyle(Color.potsSecondary)
                }
                if profiles.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Your cabinet is ready", systemImage: "heart.text.square")
                                .font(.headline).foregroundStyle(Color.potsTeal)
                            Text("Choose a name from the library or add your own. A preset never records that you took anything.")
                                .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        }
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(profiles) { profile in
                            profileTile(profile)
                        }
                    }
                }
                LazyVGrid(columns: columns, spacing: 12) {
                    NavigationLink {
                        ExpandedEntryEditor(category: .medications)
                    } label: {
                        Label("Record an event", systemImage: "square.and.pencil")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 64)
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(.bordered)
                    NavigationLink {
                        PosiesRemindersView()
                    } label: {
                        Label("My reminders", systemImage: "bell")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 64)
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(.bordered)
                }
                Text("Your cabinet stores what you enter from a label. It never chooses a dose or records an intake for you. Open Safety & label for official medication information.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Medications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { profiles = PosiesMedicationLibrary.load() }
        .sheet(isPresented: $showingCatalog, onDismiss: {
            if let choice = pendingCatalogChoice {
                pendingCatalogChoice = nil
                editing = PosiesMedicationDraft(choice.draftProfile)
            }
        }) {
            PosiesMedicationCatalogView { reference in
                pendingCatalogChoice = reference
                showingCatalog = false
            }
        }
        .sheet(item: $editing) { draft in
            PosiesMedicationProfileEditor(profile: draft.profile) { changed in
                var updated = profiles
                if let index = updated.firstIndex(where: { $0.id == changed.id }) {
                    updated[index] = changed
                } else {
                    updated.append(changed)
                }
                guard PosiesMedicationLibrary.save(updated) else {
                    errorText = "We couldn't save that profile. Your original entries are safe."
                    return false
                }
                profiles = updated
                PosiesCloudBackup.shared.noteRecordSaved()
                return true
            }
        }
        .confirmationDialog("Remove this saved profile?", isPresented: Binding(
            get: { deleting != nil },
            set: { if !$0 { deleting = nil } }
        ), titleVisibility: .visible) {
            Button("Remove saved profile", role: .destructive) {
                guard let removing = deleting else { return }
                let next = profiles.filter { $0.id != removing }
                if PosiesMedicationLibrary.save(next) {
                    profiles = next
                    PosiesCloudBackup.shared.noteRecordSaved()
                } else {
                    errorText = "We couldn't remove that profile. Please try again."
                }
                deleting = nil
            }
            Button("Keep it", role: .cancel) { deleting = nil }
        } message: {
            Text("This only removes the saved medication profile. Your previous medication event records stay.")
        }
        .alert("Unable to update cabinet", isPresented: Binding(
            get: { errorText != nil }, set: { if !$0 { errorText = nil } }
        )) {
            Button("OK") { errorText = nil }
        } message: {
            Text(errorText ?? "")
        }
    }

    private func profileTile(_ profile: PosiesMedicationProfile) -> some View {
        let reference = PosiesMedicationCatalog.find(profile.name)
        return GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    PosiesFeatureIcon(featureID: "medications", width: 39)
                    Text(profile.name)
                        .font(.headline).lineLimit(2).minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                }
                if !profile.displayStrength.isEmpty {
                    Text(profile.displayStrength)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.potsTeal)
                        .lineLimit(2)
                }
                if let dosageForm = profile.dosageForm {
                    Text(dosageForm).font(.caption).foregroundStyle(Color.potsSecondary)
                }
                if profile.schedule != "Not set" && !profile.schedule.isEmpty {
                    Label(profile.schedule, systemImage: "calendar")
                        .font(.caption).foregroundStyle(Color.potsSecondary)
                        .lineLimit(2)
                }
                if let supply = profile.displaySupply {
                    Text(supply).font(.caption).foregroundStyle(Color.potsSecondary)
                        .lineLimit(2)
                }
                if let reference {
                    NavigationLink {
                        PosiesMedicationReferenceDetail(reference: reference)
                    } label: {
                        Label("Safety & label", systemImage: "info.circle")
                            .font(.caption.weight(.semibold))
                    }
                }
                if let last = lastEvent(for: profile.name) {
                    Text("Last recorded: \(last.posture) · \(last.recordedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundStyle(Color.potsSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 4)
                HStack {
                    Button("Edit") { editing = PosiesMedicationDraft(profile) }
                    Spacer()
                    Button("Remove", role: .destructive) { deleting = profile.id }
                }
                .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Search is local. Categories are browsing aids, NOT indications and NOT
/// personalized recommendations for any person or diagnosis.
struct PosiesMedicationCatalogView: View {
    @Environment(\.dismiss) private var dismiss
    let onChoose: (PosiesMedicationReference) -> Void
    @State private var search = ""
    @State private var category = "All"

    private var matches: [PosiesMedicationReference] {
        PosiesMedicationCatalog.search(search, category: category)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 13) {
                    Text("Search by generic or brand name. This is a name reference, not a list of medicines recommended for you.")
                        .font(.subheadline).foregroundStyle(Color.potsSecondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["All"] + PosiesMedicationCatalog.categories, id: \.self) { option in
                                let selected = category == option
                                Button {
                                    category = PosiesChoiceBehavior.toggle(
                                        category, tapped: option, empty: "All")
                                } label: {
                                    Text(option)
                                        .font(.caption.weight(selected ? .semibold : .regular))
                                        .padding(.horizontal, 11).padding(.vertical, 10)
                                        .foregroundStyle(selected ? Color.white : Color.primary)
                                        .background(selected ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                                    in: RoundedRectangle(cornerRadius: 11))
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(selected ? [.isSelected] : [])
                            }
                        }
                    }
                    Text("\(matches.count) matching names · \(PosiesMedicationCatalog.all.count) in library")
                        .font(.caption).foregroundStyle(Color.potsSecondary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                        GridItem(.flexible(), spacing: 11)], spacing: 11) {
                        ForEach(matches) { reference in
                            NavigationLink {
                                PosiesMedicationReferenceDetail(reference: reference) {
                                    onChoose(reference)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(reference.name)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color.primary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                    if !reference.brands.isEmpty {
                                        Text(reference.brandSummary)
                                            .font(.caption)
                                            .foregroundStyle(Color.potsSecondary)
                                            .lineLimit(2)
                                    }
                                    Spacer(minLength: 4)
                                    Text(reference.category)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(Color.potsTeal)
                                        .lineLimit(2)
                                    Label("Details & cautions", systemImage: "info.circle")
                                        .font(.caption2)
                                        .foregroundStyle(Color.potsSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 112)
                                .padding(12)
                                .background(Color.potsSurfaceMuted,
                                            in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if matches.isEmpty {
                        GlassCard {
                            Text("No exact match here. Try a generic name or different spelling, or add a custom medication.")
                                .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.potsBackground.ignoresSafeArea())
            .navigationTitle("Medication library")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Generic or brand name")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct PosiesMedicationReferenceDetail: View {
    let reference: PosiesMedicationReference
    var onUse: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Text(reference.name).font(.title2.bold()).foregroundStyle(Color.potsTeal)
                        if !reference.brands.isEmpty {
                            Text("Brand names you may recognize: \(reference.brandSummary)")
                                .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        }
                        Text("Browsing category: \(reference.category)")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Important to know", systemImage: "exclamationmark.shield")
                            .font(.headline).foregroundStyle(Color.potsTeal)
                        Text(reference.caution).font(.subheadline)
                        Text("This is a brief educational note, not a complete warning, interaction check, diagnosis or prescribing instruction. Packaging and brand formulations can differ. Always read your exact product label.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }
                GlassCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("Check current official information").font(.headline)
                        Link(destination: reference.detailURL) {
                            Label(reference.hasDirectReference ?
                                  "Read MedlinePlus information for this medicine" :
                                  "Search MedlinePlus for this medicine",
                                  systemImage: "arrow.up.right.square")
                                .font(.subheadline)
                        }
                        Link(destination: reference.dailyMedSearchURL) {
                            Label("Find current labels for \(reference.name) on DailyMed",
                                  systemImage: "arrow.up.right.square")
                                .font(.subheadline)
                        }
                        Text("Reference names and brief cautions reviewed \(PosiesMedicationCatalog.reviewedOn). Official labels may change after this date.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }
                if reference.category == "Autonomic & circulation" {
                    Text("A medicine appearing in POTS-related discussions is not an FDA-approved POTS treatment recommendation. Only a clinician can decide what is appropriate for an individual.")
                        .font(.caption).foregroundStyle(Color.potsSecondary)
                }
                if let onUse {
                    Button {
                        onUse()
                    } label: {
                        Label("Use this name in my cabinet", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.potsButtonFill)
                    Text("This only opens a draft. Strength, instructions and schedule stay blank or not set until you enter them.")
                        .font(.caption).foregroundStyle(Color.potsSecondary)
                }
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Medicine details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PosiesMedicationProfileEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profile: PosiesMedicationProfile
    @State private var strengthText: String
    @State private var strengthUnit: String
    @State private var form: String
    @State private var schedule: String
    @State private var supplyText: String
    @State private var supplyUnit: String
    @State private var hasRefillDate: Bool
    @State private var showLabelDetails = false
    @State private var saveFailed = false
    /// A decimal pad has no Return/Done key on iPhone. Track the active editor
    /// so an explicit, accessible keyboard toolbar can dismiss every field.
    @FocusState private var focusedField: MedicationField?
    private enum MedicationField: Hashable {
        case name, strength, supply, instructions, notes, legacyLabel
    }
    let onSave: (PosiesMedicationProfile) -> Bool

    init(profile: PosiesMedicationProfile, onSave: @escaping (PosiesMedicationProfile) -> Bool) {
        _profile = State(initialValue: profile)
        _strengthText = State(initialValue: profile.strengthAmount ?? "")
        _strengthUnit = State(initialValue: profile.strengthUnit ?? "")
        _form = State(initialValue: profile.dosageForm ?? "")
        _schedule = State(initialValue: profile.schedule == "Not set" ? "" : profile.schedule)
        _supplyText = State(initialValue: profile.supplyAmount ??
                            profile.remainingSupply.map(String.init) ?? "")
        _supplyUnit = State(initialValue: profile.supplyUnit ??
                            (profile.remainingSupply == nil ? "" : "units"))
        _hasRefillDate = State(initialValue: profile.refillDate != nil)
        self.onSave = onSave
    }

    private var strengthIsValid: Bool {
        PosiesMedicationMeasurements.validPair(
            amount: strengthText, unit: strengthUnit,
            units: PosiesMedicationMeasurements.strengthUnits, max: 1000000)
    }
    private var supplyIsValid: Bool {
        // Keep legacy 0-count inventory editable without converting or deleting it.
        isOriginalLegacySupply || PosiesMedicationMeasurements.validPair(
            amount: supplyText, unit: supplyUnit,
            units: PosiesMedicationMeasurements.supplyUnits, max: 100000)
    }
    private var canSave: Bool {
        var candidate = profile
        candidate.strengthAmount = strengthText.isEmpty ? nil : strengthText
        candidate.strengthUnit = strengthUnit.isEmpty ? nil : strengthUnit
        candidate.dosageForm = form.isEmpty ? nil : form
        // Legacy supply is preserved below if no structured replacement is made.
        if !isOriginalLegacySupply {
            candidate.remainingSupply = nil
            candidate.supplyAmount = supplyText.isEmpty ? nil : supplyText
            candidate.supplyUnit = supplyUnit.isEmpty ? nil : supplyUnit
        }
        return strengthIsValid && supplyIsValid && candidate.safeToSave
    }
    private var isOriginalLegacySupply: Bool {
        profile.supplyAmount == nil && profile.remainingSupply != nil &&
        supplyText == profile.remainingSupply.map(String.init) &&
        supplyUnit == "units"
    }
    private var draftStrength: String {
        strengthIsValid && !strengthText.isEmpty ? "\(strengthText) \(strengthUnit)" :
            (profile.labelDose.isEmpty ? "Strength not entered" : profile.labelDose)
    }
    private var isLiquid: Bool { form == "Liquid" || form == "Drops" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 13) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 9) {
                            HStack(spacing: 12) {
                                PosiesFeatureIcon(featureID: "medications", width: 52)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(profile.name.isEmpty ? "New medication" : profile.name)
                                        .font(.headline).lineLimit(2)
                                    Text(draftStrength)
                                        .font(.subheadline).foregroundStyle(Color.potsSecondary)
                                }
                                Spacer(minLength: 0)
                            }
                            Text("A personal bottle card, not a prescription or a dose recommendation.")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Bottle label", systemImage: "pills.fill")
                                .font(.headline).foregroundStyle(Color.potsTeal)
                            TextField("Medication name (from your label)", text: $profile.name)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .name)
                                .submitLabel(.done)
                                .onSubmit { focusedField = nil }
                                .accessibilityLabel("Medication name")
                            Text("Strength shown on label (optional)")
                                .font(.subheadline.weight(.semibold))
                            HStack(spacing: 9) {
                                TextField("e.g. 400", text: $strengthText)
                                    .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .strength)
                                    .accessibilityLabel("Label strength amount")
                                selectionMenu("Unit", value: strengthUnit,
                                              options: PosiesMedicationMeasurements.strengthUnits) {
                                    strengthUnit = $0
                                }
                                .frame(maxWidth: 150)
                            }
                            if !strengthIsValid {
                                Text("Enter a positive label amount and select its matching unit, or clear both.")
                                    .font(.caption).foregroundStyle(Color.potsSecondary)
                            }
                            Text("These are label details, not instructions for how much to take.")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                            HStack(spacing: 9) {
                                selectionMenu("Medicine form", value: form,
                                              options: PosiesMedicationMeasurements.forms) {
                                    form = $0
                                }
                                selectionMenu("My schedule", value: schedule,
                                              options: PosiesMedicationMeasurements.schedules) {
                                    schedule = $0
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Bottle & refills", systemImage: "shippingbox")
                                .font(.headline).foregroundStyle(Color.potsTeal)
                            Text("Amount on hand (optional)")
                                .font(.subheadline.weight(.semibold))
                            HStack(spacing: 9) {
                                TextField("e.g. 30", text: $supplyText)
                                    .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .supply)
                                    .accessibilityLabel("Amount remaining in the bottle")
                                selectionMenu("Unit", value: supplyUnit,
                                              options: PosiesMedicationMeasurements.supplyUnits) {
                                    supplyUnit = $0
                                }
                                .frame(maxWidth: 150)
                            }
                            if !supplyIsValid {
                                Text("Enter a positive amount with a matching unit, or clear both.")
                                    .font(.caption).foregroundStyle(Color.potsSecondary)
                            }
                            if supplyUnit == "US fl oz" || isLiquid {
                                Text("US fl oz can describe bottle volume, but use mL and a proper dosing device for oral-liquid doses. This app doesn't calculate doses.")
                                    .font(.caption).foregroundStyle(Color.potsSecondary)
                            }
                            Toggle("Track a refill date", isOn: $hasRefillDate)
                                .tint(Color.potsTeal)
                            if hasRefillDate {
                                DatePicker("My refill date", selection: Binding(
                                    get: { profile.refillDate ?? Date() },
                                    set: { profile.refillDate = $0 }), displayedComponents: .date)
                            }
                            Text("Supply is updated only when you edit it. No automatic pill counting.")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                    }

                    GlassCard {
                        DisclosureGroup(isExpanded: $showLabelDetails) {
                            VStack(alignment: .leading, spacing: 12) {
                                TextField("Directions copied from my label (optional)",
                                          text: $profile.instructions, axis: .vertical)
                                    .lineLimit(2...5).textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .instructions)
                                TextField("My notes (optional)", text: $profile.notes, axis: .vertical)
                                    .lineLimit(2...5).textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .notes)
                                TextField("Older free-text label value (kept for compatibility)",
                                          text: $profile.labelDose)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .legacyLabel)
                                    .submitLabel(.done)
                                    .onSubmit { focusedField = nil }
                                if !profile.labelDose.isEmpty {
                                    Text("Older entries may contain a number without a unit. We keep it exactly as entered and never assume it means mg.")
                                        .font(.caption).foregroundStyle(Color.potsSecondary)
                                }
                            }
                            .padding(.top, 9)
                        } label: {
                            Label("Directions & personal notes (optional)", systemImage: "square.and.pencil")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(Color.potsTeal)
                    }
                    Text("Use the strength, form and instructions printed on your own package. Ask your pharmacist if the label is unclear. Nothing in this app changes treatment.")
                        .font(.caption).foregroundStyle(Color.potsSecondary)
                }
                .padding(18)
                .padding(.bottom, 20)
            }
            .background(Color.potsBackground.ignoresSafeArea())
            // Drag or swipe the form to reveal content behind the keyboard.
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Medication profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveProfile() }
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .font(.subheadline.weight(.semibold))
                    .accessibilityLabel("Done editing, dismiss keyboard")
                }
            }
            .alert("That profile wasn't saved", isPresented: $saveFailed) {
                Button("Keep editing", role: .cancel) {}
            } message: {
                Text("Please check the details and try again. Your existing cabinet was not changed.")
            }
        }
    }

    private func selectionMenu(_ title: String, value: String, options: [String],
                               onSelect: @escaping (String) -> Void) -> some View {
        Menu {
            Button("Not set") { onSelect("") }
            ForEach(options, id: \.self) { option in
                Button {
                    onSelect(value == option ? "" : option)
                } label: {
                    if value == option {
                        Label(option, systemImage: "checkmark")
                    } else {
                        Text(option)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.caption2).foregroundStyle(Color.potsSecondary)
                    Text(value.isEmpty ? "Choose" : value)
                        .font(.subheadline.weight(.semibold)).lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.down").font(.caption2)
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.potsSurfaceMuted, in: RoundedRectangle(cornerRadius: 10))
        }
        .accessibilityLabel("\(title), \(value.isEmpty ? "not set" : value)")
        .accessibilityHint("Opens a menu; choose the same option again to clear it.")
    }

    private func saveProfile() {
        guard canSave else { return }
        focusedField = nil
        profile.strengthAmount = strengthText.isEmpty ? nil : strengthText.trimmingCharacters(in: .whitespaces)
        profile.strengthUnit = strengthUnit.isEmpty ? nil : strengthUnit
        profile.dosageForm = form.isEmpty ? nil : form
        profile.schedule = schedule.isEmpty ? "Not set" : schedule
        if !isOriginalLegacySupply {
            profile.remainingSupply = nil
            profile.supplyAmount = supplyText.isEmpty ? nil : supplyText.trimmingCharacters(in: .whitespaces)
            profile.supplyUnit = supplyUnit.isEmpty ? nil : supplyUnit
        }
        profile.refillDate = hasRefillDate ? (profile.refillDate ?? Date()) : nil
        if onSave(profile) {
            dismiss()
        } else {
            saveFailed = true
        }
    }
}
