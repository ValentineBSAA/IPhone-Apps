import SwiftUI
import CoreData

/// A pushed destination inside the selected tab, never a second full-screen sheet.
struct FeatureDetail: View {
    let feature: TrackerFeature

    var body: some View {
        Group {
            if feature.id == "settings" {
                SettingsPanel()
            } else if feature.id == "calendar" {
                HistoryScreenView()
            } else if let category = feature.category {
                EntriesForCategory(category: category, feature: feature)
            } else {
                plannedFeature
            }
        }
        .navigationTitle(feature.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var plannedFeature: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    FeatureArtwork(feature: feature, width: 72)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(feature.name)
                            .font(.title3.bold())
                        Text("Coming in Build \(feature.build)")
                            .font(.subheadline)
                            .foregroundStyle(Color.potsTeal)
                    }
                    Spacer()
                }
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("A dedicated space is on the way")
                            .font(.headline)
                        Text("This tracker will be added with real local saving and history. It isn't active in this test build.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("For now, use the available Symptom, Heart Rate, Blood Pressure and Journal tools.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
    }
}

struct EntriesForCategory: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var entries: FetchedResults<POTSLogEntry>

    let category: LogCategory
    let feature: TrackerFeature
    @State private var adding = false
    @State private var editing: POTSLogEntry?

    private var filtered: [POTSLogEntry] {
        entries.filter { $0.category == category.rawValue }
    }
    private var thisWeek: Int {
        let start = DateTracking.lastSevenDays().first ?? Date()
        return filtered.filter { $0.recordedAt >= start && $0.recordedAt <= Date() }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    FeatureArtwork(feature: feature, width: 73)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(category.title)
                            .font(.title3.bold())
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 2)

                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(filtered.count)")
                                .font(.title2.bold().monospacedDigit())
                            Text("Total entries").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Rectangle().fill(Color.potsTeal.opacity(0.10))
                            .frame(width: 1, height: 41)
                        Spacer()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(thisWeek)")
                                .font(.title2.bold().monospacedDigit())
                            Text("Last 7 days").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                Button { adding = true } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add \(category == .journal ? "note" : "measurement")")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .padding(.horizontal, 17)
                    .frame(minHeight: 54)
                }
                .buttonStyle(.borderedProminent)
                .disabled(PersistenceController.shared.loadError != nil)

                HStack {
                    Text("Your entries").font(.headline)
                    Spacer()
                    Text(filtered.isEmpty ? "Nothing recorded" : "Newest first")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if filtered.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Ready when you are")
                                .font(.subheadline.weight(.semibold))
                            Text(emptyMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 9) {
                        ForEach(filtered, id: \.objectID) { entry in
                            EntryCard(entry: entry) { editing = entry }
                        }
                    }
                }
            }
            .padding(18)
            .padding(.bottom, 16)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .sheet(isPresented: $adding) { EntryEditor(category: category) }
        .sheet(item: $editing) { entry in
            EntryEditor(category: category, editing: entry)
        }
    }

    private var subtitle: String {
        switch category {
        case .heartRate: return "Record a reading from your monitor"
        case .bloodPressure: return "Manual systolic and diastolic readings"
        case .symptom: return "Track an episode when it happens"
        case .journal: return "Keep thoughts and questions together"
        case .checkIn: return "Record how today feels"
        }
    }

    private var emptyMessage: String {
        switch category {
        case .heartRate: return "Add a manual BPM reading whenever you wish."
        case .bloodPressure: return "Add numbers from your blood-pressure monitor."
        case .symptom: return "Log a symptom without needing to complete a long form."
        case .journal: return "A short note is enough. You can return to it later."
        case .checkIn: return "Daily check-ins are optional."
        }
    }
}

struct SettingsPanel: View {
    @AppStorage("lowEnergyMode") private var lowEnergyMode = false
    @AppStorage("showEducationHints") private var showEducationHints = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Comfort & accessibility")
                            .font(.headline)
                        Toggle("Larger, simpler controls", isOn: $lowEnergyMode)
                            .tint(.potsTeal)
                        Toggle("Show helpful explanations", isOn: $showEducationHints)
                            .tint(.potsTeal)
                        Text("Use the iPhone's Display & Text Size settings for larger fonts and additional contrast.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    HomeCustomizationView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundStyle(Color.potsTeal)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Customize Home")
                                .font(.subheadline.bold())
                            Text("Hide, pin and reorder your cards")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your privacy")
                            .font(.headline)
                        Text("Stored on this iPhone. No account, advertising, analytics or Apple Watch connection.")
                            .font(.subheadline)
                        Text("Backup and export are not available in Build 1. Do not use this version for irreplaceable medical records.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    PrivacyText()
                } label: {
                    Label("Privacy & medical guidance", systemImage: "hand.raised.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
    }
}

struct PrivacyText: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                Text("Your records belong to you")
                    .font(.title2.bold())
                Text("POTS Tracker currently stores information locally on the iPhone. It has no analytics service, cloud account, advertising or automatic uploads. Reports and backup exports are planned but not available in Build 1.")
                Text("Important: deleting the app may remove its local records. Do not use this app as the only copy of critical medical information until export and restore have been tested.")
                Divider()
                Text("About your health")
                    .font(.title2.bold())
                Text("This is a symptom and measurement journal, not a diagnostic tool or a device for emergency monitoring. A phone by itself does not measure blood pressure, and heart rate readings alone cannot establish POTS.")
                Text("Do not change your medicines, fluid intake or sodium intake based on an app chart. Discuss treatment with your healthcare professional.")
                Text("If you have severe chest pain, serious breathing trouble, become unresponsive, or have a serious injury after fainting, seek emergency medical help rather than relying on this app.")
            }
            .font(.body)
            .padding(20)
        }
        .navigationTitle("Important information")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.potsBackground.ignoresSafeArea())
    }
}

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PrivacyText()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}