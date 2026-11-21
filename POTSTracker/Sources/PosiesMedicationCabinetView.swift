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
                Text("This library helps you find a name, not choose treatment. Your dose, schedule and actual medication events stay under your control. Lock-screen reminders remain discreet.")
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
                Text(profile.name)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if !profile.labelDose.isEmpty {
                    Text(profile.labelDose).font(.subheadline).foregroundStyle(Color.potsSecondary)
                        .lineLimit(2)
                }
                if profile.schedule != "Not set" && !profile.schedule.isEmpty {
                    Label(profile.schedule, systemImage: "calendar")
                        .font(.caption).foregroundStyle(Color.potsTeal)
                        .lineLimit(2)
                }
                if let reference {
                    Text(reference.category)
                        .font(.caption2.weight(.semibold)).foregroundStyle(Color.potsTeal)
                        .lineLimit(2)
                    Text(reference.caution)
                        .font(.caption)
                        .foregroundStyle(Color.potsSecondary)
                        .lineLimit(3)
                    NavigationLink {
                        PosiesMedicationReferenceDetail(reference: reference)
                    } label: {
                        Label("Safety details", systemImage: "info.circle")
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
                        Link {
                            Label(reference.hasDirectReference ?
                                  "Read MedlinePlus information for this medicine" :
                                  "Search MedlinePlus for this medicine",
                                  systemImage: "arrow.up.right.square")
                                .font(.subheadline)
                        } destination: {
                            reference.detailURL
                        }
                        Link {
                            Label("Search FDA-submitted labeling on DailyMed",
                                  systemImage: "arrow.up.right.square")
                                .font(.subheadline)
                        } destination: {
                            URL(string: "https://dailymed.nlm.nih.gov/dailymed/")!
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
    @State private var supplyText: String
    @State private var hasRefillDate: Bool
    let onSave: (PosiesMedicationProfile) -> Bool
    @State private var saveFailed = false

    private let schedules = ["Daily", "Several times daily", "As needed", "Other"]
    init(profile: PosiesMedicationProfile, onSave: @escaping (PosiesMedicationProfile) -> Bool) {
        _profile = State(initialValue: profile)
        _supplyText = State(initialValue: profile.remainingSupply.map(String.init) ?? "")
        _hasRefillDate = State(initialValue: profile.refillDate != nil)
        self.onSave = onSave
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("From your medication label").font(.headline)
                            TextField("Medication name", text: $profile.name)
                                .textFieldStyle(.roundedBorder)
                            TextField("Dose or strength on label (optional)", text: $profile.labelDose)
                                .textFieldStyle(.roundedBorder)
                            TextField("Instructions from your label (optional)", text: $profile.instructions, axis: .vertical)
                                .lineLimit(2...5).textFieldStyle(.roundedBorder)
                            Text("How is it scheduled?").font(.subheadline.weight(.semibold))
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 8)], spacing: 8) {
                                ForEach(schedules, id: \.self) { option in
                                    let active = profile.schedule == option
                                    Button {
                                        profile.schedule = PosiesChoiceBehavior.preference(
                                            profile.schedule, tapped: option, defaultValue: "Not set")
                                    } label: {
                                        Text(option)
                                            .font(.subheadline.weight(active ? .semibold : .regular))
                                            .frame(maxWidth: .infinity, minHeight: 45)
                                            .foregroundStyle(active ? Color.white : Color.primary)
                                            .background(active ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                                        in: RoundedRectangle(cornerRadius: 11))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityAddTraits(active ? [.isSelected] : [])
                                }
                            }
                        }
                    }
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Refills & notes (optional)").font(.headline)
                            Toggle("Save a refill date", isOn: $hasRefillDate)
                                .tint(Color.potsTeal)
                            if hasRefillDate {
                                DatePicker("Date from your plan", selection: Binding(
                                    get: { profile.refillDate ?? Date() },
                                    set: { profile.refillDate = $0 }), displayedComponents: .date)
                            }
                            TextField("Remaining tablets / units (optional)", text: $supplyText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            TextField("Notes", text: $profile.notes, axis: .vertical)
                                .lineLimit(2...5).textFieldStyle(.roundedBorder)
                            Text("Supply is only updated when you edit it. This app won't assume you took a dose.")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                    }
                    Text("Always use instructions from your clinician or pharmacy. No interaction checker or dosing advice is provided.")
                        .font(.caption).foregroundStyle(Color.potsSecondary)
                }
                .padding(18)
            }
            .background(Color.potsBackground.ignoresSafeArea())
            .navigationTitle("Medication profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        profile.refillDate = hasRefillDate ? (profile.refillDate ?? Date()) : nil
                        profile.remainingSupply = supplyText.isEmpty ? nil : Int(supplyText)
                        if onSave(profile) {
                            dismiss()
                        } else {
                            saveFailed = true
                        }
                    }
                    .disabled(!profile.safeToSave || (!supplyText.isEmpty && Int(supplyText) == nil))
                }
            }
            .alert("That profile wasn't saved", isPresented: $saveFailed) {
                Button("Keep editing", role: .cancel) {}
            } message: {
                Text("Please check the details and try again. Nothing in your cabinet was changed.")
            }
        }
    }
}
