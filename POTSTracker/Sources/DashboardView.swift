import SwiftUI
import CoreData

struct TrackerFeature: Identifiable {
    let id: String
    let name: String
    let file: String
    let symbol: String
    let color: Color
    let build: Int

    static let all: [TrackerFeature] = [
        .init(id: "heartRate", name: "Heart Rate", file: "01_Heart_Rate", symbol: "heart.fill", color: .pink, build: 1),
        .init(id: "bloodPressure", name: "Blood Pressure", file: "02_Blood_Pressure", symbol: "waveform.path.ecg", color: .blue, build: 1),
        .init(id: "symptom", name: "Symptoms", file: "03_Symptoms", symbol: "list.clipboard.fill", color: .orange, build: 1),
        .init(id: "hydration", name: "Hydration", file: "04_Hydration", symbol: "drop.fill", color: .cyan, build: 2),
        .init(id: "medications", name: "Medications", file: "05_Medications", symbol: "pills.fill", color: .green, build: 2),
        .init(id: "sleep", name: "Sleep & Rest", file: "06_Sleep", symbol: "moon.stars.fill", color: .purple, build: 2),
        .init(id: "calendar", name: "Calendar", file: "07_Calendar", symbol: "calendar", color: .orange, build: 1),
        .init(id: "reports", name: "Reports", file: "08_Reports", symbol: "chart.bar.fill", color: .mint, build: 3),
        .init(id: "journal", name: "Journal", file: "09_Journal", symbol: "book.closed.fill", color: .pink, build: 1),
        .init(id: "posture", name: "Posture", file: "10_Posture", symbol: "figure.stand", color: .teal, build: 2),
        .init(id: "reminders", name: "Reminders", file: "11_Reminders", symbol: "bell.fill", color: .blue, build: 2),
        .init(id: "settings", name: "Settings", file: "12_Settings", symbol: "gearshape.fill", color: .purple, build: 1)
    ]

    var category: LogCategory? { LogCategory(rawValue: id) }
}

struct FeatureArtwork: View {
    let feature: TrackerFeature
    var width: CGFloat = 58

    private var image: UIImage? {
        let url = Bundle.main.url(forResource: feature.file, withExtension: "png", subdirectory: "Icons")
            ?? Bundle.main.url(forResource: feature.file, withExtension: "png")
        return url.flatMap { UIImage(contentsOfFile: $0.path) }
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: feature.symbol)
                    .font(.system(size: width * 0.42, weight: .semibold))
                    .foregroundStyle(feature.color)
                    .frame(width: width, height: width)
                    .background(feature.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 17))
                    .accessibilityHidden(true)
            }
        }
        .frame(width: width, height: width)
        .accessibilityHidden(true)
    }
}

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var entries: FetchedResults<POTSLogEntry>

    @AppStorage("lowEnergyMode") private var lowEnergyMode = false
    @AppStorage("showEducationHints") private var showEducationHints = true
    @State private var selectedFeature: TrackerFeature?
    @State private var newLog: LogCategory?
    @State private var editLog: POTSLogEntry?
    @State private var notice: String?
    @State private var showPrivacyInformation = false

    private var todayEntries: [POTSLogEntry] {
        entries.filter { Calendar.current.isDateInToday($0.recordedAt) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heading
                    if let error = PersistenceController.shared.loadError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(.red)
                            .padding()
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    }
                    todayCard
                    quickCheckIn
                    weekCard
                    categoryGrid
                    recentEntries
                    Button("Privacy and medical information") { showPrivacyInformation = true }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
            }
            .background(Color.potsBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("POTS Tracker")
                        .font(.headline.weight(.semibold))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if let settings = TrackerFeature.all.first(where: { $0.id == "settings" }) {
                            selectedFeature = settings
                        }
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(item: $newLog) { category in
                EntryEditor(category: category)
            }
            .sheet(item: $editLog) { entry in
                EntryEditor(category: LogCategory(rawValue: entry.category) ?? .journal, editing: entry)
            }
            .sheet(item: $selectedFeature) { feature in
                FeatureDetail(feature: feature)
            }
            .sheet(isPresented: $showPrivacyInformation) {
                PrivacyView()
            }
            .alert("Could not save", isPresented: Binding(
                get: { notice != nil },
                set: { if !$0 { notice = nil } }
            )) {
                Button("OK") { notice = nil }
            } message: {
                Text(notice ?? "Please try again.")
            }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your daily companion")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Color.primary)
                .minimumScaleFactor(0.8)
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if showEducationHints {
                Text("Log only what feels helpful. Every day is optional.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
    }

    private var todayCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Today", systemImage: "sun.max.fill")
                        .font(.headline)
                    Spacer()
                    Text("\(todayEntries.count) \(todayEntries.count == 1 ? "entry" : "entries")")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                if let checkIn = todayEntries.first(where: { $0.category == LogCategory.checkIn.rawValue }) {
                    Text("Last check-in: \(checkIn.title)")
                        .font(.subheadline.weight(.medium))
                } else {
                    Text("No check-in recorded today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Button {
                    newLog = .symptom
                } label: {
                    Label("Log a symptom", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: lowEnergyMode ? 60 : 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(PersistenceController.shared.loadError != nil)
                HStack(spacing: 10) {
                    quickButton("Heart rate", icon: "heart.fill", category: .heartRate)
                    quickButton("Blood pressure", icon: "waveform.path.ecg", category: .bloodPressure)
                }
            }
        }
    }

    private func quickButton(_ title: String, icon: String, category: LogCategory) -> some View {
        Button {
            newLog = category
        } label: {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: lowEnergyMode ? 55 : 42)
        }
        .buttonStyle(.bordered)
        .disabled(PersistenceController.shared.loadError != nil)
    }

    private var quickCheckIn: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("How are you feeling?")
                        .font(.headline)
                    Spacer()
                    if lowEnergyMode {
                        Text("Easy mode")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                Text("Optional one-tap check-in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: lowEnergyMode ? 124 : 96), spacing: 8)], spacing: 8) {
                    ForEach(["Better", "Usual", "Worse", "Much worse", "Not sure"], id: \.self) { title in
                        Button(title) { saveCheckIn(title) }
                            .font(.subheadline.weight(.medium))
                            .padding(.vertical, lowEnergyMode ? 15 : 11)
                            .frame(maxWidth: .infinity)
                            .background(Color.potsTeal.opacity(0.11), in: RoundedRectangle(cornerRadius: 13))
                            .buttonStyle(.plain)
                            .disabled(PersistenceController.shared.loadError != nil)
                    }
                }
                Toggle("Larger, simpler controls", isOn: $lowEnergyMode)
                    .font(.footnote)
                    .tint(.potsTeal)
                    .padding(.top, 3)
            }
        }
    }

    private var weekCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Last 7 days", systemImage: "calendar")
                        .font(.headline)
                    Spacer()
                    Text("Entries, not health scores")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 5) {
                    ForEach(DateTracking.lastSevenDays(), id: \.self) { date in
                        let count = DateTracking.count(on: date, among: Array(entries))
                        VStack(spacing: 7) {
                            Text(date.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(count == 0 ? "–" : "\(count)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(count == 0 ? Color.secondary : Color.potsTeal)
                                .frame(maxWidth: .infinity, minHeight: 43)
                                .background(count == 0 ? Color.secondary.opacity(0.08) : Color.potsTeal.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
                            Text(date.formatted(.dateTime.day()))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(date.formatted(date: .complete, time: .omitted)): \(count == 0 ? "not recorded" : "\(count) entries")")
                    }
                }
                Text("A blank day means nothing was recorded, not that symptoms were absent.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explore your tracking")
                .font(.title3.bold())
                .padding(.horizontal, 2)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(TrackerFeature.all) { feature in
                    Button {
                        selectedFeature = feature
                    } label: {
                        VStack(spacing: 10) {
                            FeatureArtwork(feature: feature, width: lowEnergyMode ? 78 : 66)
                            Text(feature.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(minHeight: 36)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 21))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(feature.name)
                    .accessibilityHint(feature.build > 1 ? "Planned for Build \(feature.build)" : "Open \(feature.name)")
                }
            }
        }
    }

    private var recentEntries: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent entries")
                .font(.title3.bold())
            if entries.isEmpty {
                GlassCard {
                    Text("Nothing recorded yet. Add your first entry whenever you're ready.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(Array(entries.prefix(8)), id: \.objectID) { entry in
                    EntryCard(entry: entry) {
                        editLog = entry
                    }
                }
            }
        }
    }

    private func saveCheckIn(_ title: String) {
        let item = POTSLogEntry(context: context)
        item.id = UUID()
        item.category = LogCategory.checkIn.rawValue
        item.title = title
        item.recordedAt = Date()
        item.severity = -1
        item.firstValue = 0
        item.secondValue = 0
        item.posture = ""
        item.notes = ""
        item.timezoneID = TimeZone.current.identifier
        item.source = "manual"
        do {
            try POTSData.save(context)
        } catch {
            context.rollback()
            notice = error.localizedDescription
        }
    }
}
