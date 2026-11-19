import SwiftUI
import CoreData

struct FeatureDetail: View {
    @Environment(\.dismiss) private var dismiss
    let feature: TrackerFeature

    var body: some View {
        NavigationStack {
            Group {
                if feature.id == "settings" {
                    SettingsPanel()
                } else if feature.id == "calendar" {
                    SevenDayHistory()
                } else if let kind = feature.category {
                    EntriesForCategory(category: kind)
                } else {
                    plannedFeature
                }
            }
            .navigationTitle(feature.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var plannedFeature: some View {
        ScrollView {
            VStack(spacing: 18) {
                FeatureArtwork(feature: feature, width: 100)
                Text("Planned for Build \(feature.build)")
                    .font(.title2.bold())
                Text("\(feature.name) is included in the roadmap, but logging here is not implemented yet. We won't show a fake tracker or pretend information has been saved.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("Current working tools: Symptoms, Heart Rate, Blood Pressure, Journal, and seven-day history.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color.potsBackground.ignoresSafeArea())
    }
}

struct EntriesForCategory: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var entries: FetchedResults<POTSLogEntry>

    let category: LogCategory
    @State private var adding = false
    @State private var editing: POTSLogEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 13) {
                Button {
                    adding = true
                } label: {
                    Label("New \(category.title) entry", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 54)
                }
                .buttonStyle(.borderedProminent)
                .disabled(PersistenceController.shared.loadError != nil)
                let filtered = entries.filter { $0.category == category.rawValue }
                Text("\(filtered.count) recorded \(filtered.count == 1 ? "entry" : "entries")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if filtered.isEmpty {
                    GlassCard {
                        Text("No records in this category yet. You can add one whenever you want.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(filtered, id: \.objectID) { entry in
                    EntryCard(entry: entry) { editing = entry }
                }
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .sheet(isPresented: $adding) {
            EntryEditor(category: category)
        }
        .sheet(item: $editing) { entry in
            EntryEditor(category: category, editing: entry)
        }
    }
}

struct SevenDayHistory: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var entries: FetchedResults<POTSLogEntry>

    @State private var editing: POTSLogEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Every day is optional. No entry is never treated as zero symptoms.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                ForEach(DateTracking.lastSevenDays().reversed(), id: \.self) { day in
                    let dayEntries = entries.filter { Calendar.current.isDate($0.recordedAt, inSameDayAs: day) }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                .font(.headline)
                            Spacer()
                            Text(dayEntries.isEmpty ? "Not recorded" : "\(dayEntries.count) entries")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if dayEntries.isEmpty {
                            GlassCard {
                                Text("No entries on this date")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            ForEach(dayEntries, id: \.objectID) { entry in
                                EntryCard(entry: entry) { editing = entry }
                            }
                        }
                    }
                }
                Text("Full monthly, yearly, and lifetime visualizations are scheduled for Build 3. Older records remain stored even when not shown on this seven-day screen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .sheet(item: $editing) { entry in
            EntryEditor(category: LogCategory(rawValue: entry.category) ?? .journal, editing: entry)
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
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Comfort & accessibility")
                            .font(.headline)
                        Toggle("Low Energy Mode: larger controls", isOn: $lowEnergyMode)
                        Toggle("Show introductory explanations", isOn: $showEducationHints)
                        Text("Use your iPhone's Display & Text Size settings to increase system text size or contrast.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Private local storage")
                            .font(.headline)
                        Label("No account required", systemImage: "checkmark.shield.fill")
                        Label("No Apple Watch support", systemImage: "iphone")
                        Label("No paid features", systemImage: "gift.fill")
                        Text("Data is saved on this device. Backup, PDF and CSV export are scheduled for Build 3. Do not delete the app until an export and restore workflow is available, because deleting the app may delete its local data.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    PrivacyText()
                } label: {
                    Label("Privacy and medical information", systemImage: "hand.raised.fill")
                        .font(.headline)
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
                Text("Important: deleting the app may remove its local records. Do not use the app as the only copy of critical medical information until export and restore have been tested.")
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
