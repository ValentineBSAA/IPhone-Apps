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

    var body: some View {
        Image(feature.file)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: width)
            .accessibilityHidden(true)
    }
}

enum TrackerTab: Hashable {
    case home
    case log
    case history
    case more
}

/// One tab per real task. Features are pushed, not opened as a second full-screen sheet.
struct DashboardView: View {
    @State private var selectedTab: TrackerTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeScreenView(
                    openLog: { selectedTab = .log },
                    openHistory: { selectedTab = .history }
                )
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(TrackerTab.home)

            NavigationStack {
                LogHubView()
            }
            .tabItem { Label("Log", systemImage: "square.grid.2x2.fill") }
            .tag(TrackerTab.log)

            NavigationStack {
                HistoryScreenView()
            }
            .tabItem { Label("History", systemImage: "calendar") }
            .tag(TrackerTab.history)

            NavigationStack {
                MoreHubView()
            }
            .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
            .tag(TrackerTab.more)
        }
        .tint(.potsTeal)
    }
}

struct FeatureTile: View {
    let feature: TrackerFeature
    var roomy = false
    var horizontal = false

    var body: some View {
        NavigationLink {
            FeatureDetail(feature: feature)
        } label: {
            Group {
                if horizontal {
                    HStack(spacing: 10) {
                        FeatureArtwork(feature: feature, width: roomy ? 57 : 44)
                        Text(feature.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                } else {
                    VStack(spacing: 9) {
                        FeatureArtwork(feature: feature, width: roomy ? 72 : 61)
                        Text(feature.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .foregroundStyle(.primary)
            .padding(horizontal ? 12 : 14)
            .frame(maxWidth: .infinity, minHeight: horizontal ? (roomy ? 87 : 72) : (roomy ? 139 : 125))
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.potsTeal.opacity(0.07)))
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(feature.name)
        .accessibilityHint(feature.build > 1 ? "Planned for Build \(feature.build)" : "Open \(feature.name)")
    }
}

struct HomeScreenView: View {
    let openLog: () -> Void
    let openHistory: () -> Void

    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var entries: FetchedResults<POTSLogEntry>

    @AppStorage("lowEnergyMode") private var lowEnergyMode = false
    @AppStorage("showEducationHints") private var showHints = true
    @AppStorage("homeModuleOrder") private var moduleOrder = HomeLayout.moduleDefault
    @AppStorage("homeHiddenModules") private var hiddenModules = ""
    @AppStorage("homePinnedFeatureIDs") private var pinnedIDs = HomeLayout.pinDefault
    @AppStorage("homeLayoutDensity") private var density = "compact"

    @State private var newLog: LogCategory?
    @State private var editLog: POTSLogEntry?
    @State private var notice: String?

    private var todayEntries: [POTSLogEntry] {
        entries.filter { Calendar.current.isDateInToday($0.recordedAt) }
    }

    private var roomy: Bool { density == "comfortable" || lowEnergyMode }
    private var gap: CGFloat { roomy ? 18 : 13 }
    private var hidden: Set<String> { Set(HomeLayout.ids(from: hiddenModules)) }
    private var modules: [HomeModule] {
        HomeLayout.orderedModules(from: moduleOrder).filter { !hidden.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: gap) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text("Your day, at a glance")
                            .font(.title3.weight(.semibold))
                    }
                    Spacer()
                }
                .padding(.bottom, 2)

                if let error = PersistenceController.shared.loadError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(12)
                        .background(Color.red.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                }

                ForEach(modules) { module in
                    moduleView(module)
                }
                if modules.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Home is clear").font(.headline)
                            Text("You can open Log or restore sections in Customize Home.")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Button("Go to Log", action: openLog).buttonStyle(.borderedProminent)
                        }
                    }
                }

                if showHints {
                    Text("Unrecorded days are unknown, never counted as symptom-free.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 3)
                }
            }
            .padding(.horizontal, 17)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("POTS Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    HomeCustomizationView()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Customize Home")
            }
        }
        .sheet(item: $newLog) { category in
            EntryEditor(category: category)
        }
        .sheet(item: $editLog) { entry in
            EntryEditor(category: LogCategory(rawValue: entry.category) ?? .journal, editing: entry)
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

    @ViewBuilder
    private func moduleView(_ module: HomeModule) -> some View {
        switch module {
        case .today: todayCard
        case .checkIn: checkInStrip
        case .favorites: favoriteGrid
        case .recent: recentGrid
        }
    }

    private var todayCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: roomy ? 15 : 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Today")
                            .font(.title3.bold())
                        if let check = todayEntries.first(where: { $0.category == LogCategory.checkIn.rawValue }) {
                            Text("Last check-in: \(check.title)")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("No check-in yet")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text("\(todayEntries.count) \(todayEntries.count == 1 ? "entry" : "entries")")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.potsTeal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.potsTeal.opacity(0.10), in: Capsule())
                }

                Button(action: openLog) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log something")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 15)
                    .frame(minHeight: roomy ? 58 : 50)
                    .foregroundStyle(.white)
                    .background(Color.potsTeal, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    quickAction("Symptom", category: .symptom)
                    quickAction("Heart rate", category: .heartRate)
                    quickAction("BP", category: .bloodPressure)
                }
            }
        }
    }

    private func quickAction(_ title: String, category: LogCategory) -> some View {
        Button { newLog = category } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: roomy ? 53 : 41)
                .foregroundStyle(Color.potsTeal)
                .background(Color.potsTeal.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(PersistenceController.shared.loadError != nil)
    }

    private var checkInStrip: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("How are you feeling?")
                    .font(.headline)
                Spacer()
                Text("Optional").font(.caption2).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: roomy ? 112 : 97), spacing: 7)], spacing: 7) {
                ForEach(["Better", "Usual", "Worse", "Much worse", "Not sure"], id: \.self) { answer in
                    Button {
                        saveCheckIn(answer)
                    } label: {
                        Text(answer)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.77)
                            .frame(maxWidth: .infinity, minHeight: roomy ? 55 : 40)
                            .foregroundStyle(.primary)
                            .background(Color(uiColor: .secondarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(PersistenceController.shared.loadError != nil)
                    .accessibilityHint("Adds a new check-in for today")
                }
            }
        }
    }

    private var favoriteGrid: some View {
        let favorites = HomeLayout.pinned(from: pinnedIDs)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your shortcuts").font(.headline)
                Spacer()
                NavigationLink("Edit") { HomeCustomizationView() }
                    .font(.caption.weight(.semibold))
            }
            if favorites.isEmpty {
                Button {
                    openLog()
                } label: {
                    Label("Choose trackers in Log or customize Home", systemImage: "plus.circle")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                .buttonStyle(.bordered)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(favorites) { feature in
                        FeatureTile(feature: feature, roomy: roomy, horizontal: true)
                    }
                }
            }
        }
    }

    private var recentGrid: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Recent activity").font(.headline)
                Spacer()
                Button("See all", action: openHistory)
                    .font(.caption.weight(.semibold))
            }
            if entries.isEmpty {
                Text("Nothing recorded yet. This space stays quiet until you add an entry.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)], spacing: 9) {
                    ForEach(Array(entries.prefix(3)), id: \.objectID) { entry in
                        Button { editLog = entry } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.title)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text(EntryFormat.description(for: entry))
                                    .font(.caption)
                                    .lineLimit(2)
                                    .foregroundStyle(.secondary)
                                Text(entry.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: roomy ? 86 : 71, alignment: .topLeading)
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func saveCheckIn(_ answer: String) {
        let entry = POTSLogEntry(context: context)
        entry.id = UUID()
        entry.recordedAt = Date()
        entry.category = LogCategory.checkIn.rawValue
        entry.title = answer
        entry.severity = -1
        entry.firstValue = 0
        entry.secondValue = 0
        entry.posture = ""
        entry.notes = ""
        entry.timezoneID = TimeZone.current.identifier
        entry.source = "manual"
        do {
            try POTSData.save(context)
        } catch {
            context.rollback()
            notice = error.localizedDescription
        }
    }
}

struct LogHubView: View {
    @AppStorage("lowEnergyMode") private var lowEnergyMode = false
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Choose what to record")
                        .font(.title3.weight(.semibold))
                    Text("One entry at a time. Every category is optional.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                featureSection("Track now", ids: ["symptom", "heartRate", "bloodPressure", "journal"])
                featureSection("Daily support", ids: ["hydration", "medications", "sleep", "posture"])
                featureSection("Review & organize", ids: ["calendar", "reports", "reminders", "settings"])
            }
            .padding(18)
            .padding(.bottom, 20)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Log")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func featureSection(_ title: String, ids: [String]) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title).font(.headline)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ids.compactMap { id in TrackerFeature.all.first(where: { $0.id == id }) }) { feature in
                    FeatureTile(feature: feature, roomy: lowEnergyMode)
                }
            }
        }
    }
}

struct MoreHubView: View {
    @AppStorage("lowEnergyMode") private var lowEnergyMode = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                Text("Keep things comfortable")
                    .font(.title3.weight(.semibold))
                Text("Your preferences stay on this iPhone.")
                    .font(.subheadline).foregroundStyle(.secondary)

                NavigationLink {
                    HomeCustomizationView()
                } label: {
                    moreCard("Customize Home", subtitle: "Pin features, hide or reorder sections", icon: "slider.horizontal.3")
                }
                NavigationLink {
                    SettingsPanel()
                } label: {
                    moreCard("Comfort & settings", subtitle: "Larger controls and display preferences", icon: "gearshape.fill")
                }
                NavigationLink {
                    PrivacyText()
                } label: {
                    moreCard("Privacy & medical information", subtitle: "How your local records are handled", icon: "hand.raised.fill")
                }
                GlassCard {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Build 1 · First iPhone test").font(.headline)
                        Text("The advanced trackers, reports, reminders and backups are scheduled for later builds. They will remain free.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text("Do not store irreplaceable medical records until export and restore are available.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func moreCard(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.potsTeal)
                .frame(width: 44, height: 44)
                .background(Color.potsTeal.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 2)
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 19))
    }
}
