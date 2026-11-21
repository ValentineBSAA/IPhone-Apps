import SwiftUI

private struct PosiesMedicationDraft: Identifiable {
    let id: UUID
    var profile: PosiesMedicationProfile
    init(_ profile: PosiesMedicationProfile) {
        id = profile.id
        self.profile = profile
    }
}

/// The cabinet stores the user's own label details, not a medical drug
/// database and never an inferred dose or an automatically recorded intake.
struct PosiesMedicationCabinetView: View {
    @State private var profiles: [PosiesMedicationProfile] = []
    @State private var editing: PosiesMedicationDraft?
    @State private var deleting: UUID?
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("My medication cabinet", systemImage: "pills.fill")
                            .font(.title3.bold()).foregroundStyle(Color.potsTeal)
                        Text("Save the information from your own medication labels once, so you don't have to keep typing it.")
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        Text("Profiles are reference notes. They don't mean a medication was taken, and this app doesn't recommend doses.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                        Button {
                            editing = PosiesMedicationDraft(PosiesMedicationProfile(name: ""))
                        } label: {
                            Label("Add medication", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent).tint(Color.potsButtonFill)
                        .disabled(profiles.count >= PosiesMedicationLibrary.maximumProfiles)
                    }
                }
                if profiles.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Your cabinet starts here").font(.headline)
                            Text("Add a name and any label details you find helpful. You can leave most fields blank.")
                                .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        }
                    }
                } else {
                    ForEach(profiles) { profile in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(profile.name).font(.headline)
                                if !profile.labelDose.isEmpty {
                                    Text(profile.labelDose).font(.subheadline).foregroundStyle(Color.potsSecondary)
                                }
                                Label(profile.schedule, systemImage: "calendar.badge.clock")
                                    .font(.caption).foregroundStyle(Color.potsTeal)
                                if let refill = profile.refillDate {
                                    Label("Refill date you entered: \(refill.formatted(date: .abbreviated, time: .omitted))",
                                          systemImage: "calendar")
                                        .font(.caption).foregroundStyle(Color.potsSecondary)
                                }
                                if let supply = profile.remainingSupply {
                                    Text("Supply on hand (as entered): \(supply)")
                                        .font(.caption).foregroundStyle(Color.potsSecondary)
                                }
                                if !profile.instructions.isEmpty {
                                    Text(profile.instructions).font(.caption).foregroundStyle(Color.potsSecondary)
                                }
                                HStack(spacing: 18) {
                                    Button("Edit") { editing = PosiesMedicationDraft(profile) }
                                    Spacer()
                                    Button("Remove", role: .destructive) { deleting = profile.id }
                                }
                                .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }
                NavigationLink {
                    PosiesRemindersView()
                } label: {
                    Label("Set an optional medication or refill reminder", systemImage: "bell")
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)
                Text("Reminders are scheduled separately and only with your permission. No medication names or doses need to appear on the Lock Screen.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Medication cabinet")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { profiles = PosiesMedicationLibrary.load() }
        .sheet(item: $editing) { item in
            PosiesMedicationProfileEditor(profile: item.profile) { changed in
                var copy = profiles
                if let existing = copy.firstIndex(where: { $0.id == changed.id }) {
                    copy[existing] = changed
                } else {
                    copy.append(changed)
                }
                if PosiesMedicationLibrary.save(copy) {
                    profiles = copy
                    PosiesCloudBackup.shared.noteRecordSaved()
                } else {
                    errorText = "We couldn't save that medication profile. Please check the details and try again."
                }
            }
        }
        .confirmationDialog("Remove this medication profile?", isPresented: Binding(
            get: { deleting != nil },
            set: { if !$0 { deleting = nil } }
        ), titleVisibility: .visible) {
            Button("Remove profile", role: .destructive) {
                guard let deleting else { return }
                let updated = profiles.filter { $0.id != deleting }
                if PosiesMedicationLibrary.save(updated) {
                    profiles = updated
                    PosiesCloudBackup.shared.noteRecordSaved()
                } else {
                    errorText = "We couldn't remove this profile."
                }
                self.deleting = nil
            }
            Button("Keep profile", role: .cancel) { deleting = nil }
        } message: {
            Text("Saved medication log entries will not be deleted.")
        }
        .alert("Couldn't save", isPresented: Binding(
            get: { errorText != nil }, set: { if !$0 { errorText = nil } }
        )) {
            Button("OK") { errorText = nil }
        } message: {
            Text(errorText ?? "")
        }
    }
}

private struct PosiesMedicationProfileEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profile: PosiesMedicationProfile
    @State private var supplyText: String
    @State private var hasRefillDate: Bool
    let onSave: (PosiesMedicationProfile) -> Void

    private let schedules = ["Daily", "Several times daily", "As needed", "Other"]
    init(profile: PosiesMedicationProfile, onSave: @escaping (PosiesMedicationProfile) -> Void) {
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
                                            profile.schedule, tapped: option, defaultValue: "As needed")
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
                        onSave(profile)
                        dismiss()
                    }
                    .disabled(!profile.safeToSave || (!supplyText.isEmpty && Int(supplyText) == nil))
                }
            }
        }
    }
}
