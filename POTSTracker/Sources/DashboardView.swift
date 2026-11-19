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
                        FeatureArtwork(feature: feature, width: roomy ? 52 : 40)
                        Text(feature.name)
                            .font(.system(size: roomy ? 15 : 14, weight: .semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
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
            .padding(horizontal ? 10 : 12)
            .frame(maxWidth: .infinity, minHeight: horizontal ? (roomy ? 80 : 66) : (roomy ? 135 : 116))
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.potsTeal.opacity(0.06)))
            .contentShape(RoundedRectangle(cornerRadius: 18))
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
    @State private var editRoute: RecordEditRoute?
    @State private var notice: String?

    private var allRecords: [RecordSnapshot] {
        RecordSnapshot.snapshots(of: Array(entries))
    }
    private var todayEntries: [RecordSnapshot] {
        allRecords.filter { Calendar.current.isDateInToday($0.recordedAt) }
    }

    private var roomy: Bool { density == "comfortable" || lowEnergyMode }
    private var gap: CGFloat { roomy ? 16 : 11 }
    private var hidden: Set<String> { Set(HomeLayout.ids(from: hiddenModules)) }
    private var modules: [HomeModule] {
        HomeLayout.orderedModules(from: moduleOrder).filter { !hidden.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: gap) {
                HStack(alignment: .center) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 2)

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
            .padding(.top, 10)
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
        .sheet(item: $editRoute) { route in
            RecordEditDestination(objectID: route.objectID)
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
                            Text(todayEntries.isEmpty ? "Nothing logged yet" : "No check-in yet")
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
                        Text("Add an entry")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 15)
                    .frame(minHeight: roomy ? 58 : 47)
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
                .frame(maxWidth: .infinity, minHeight: roomy ? 52 : 38)
                .foregroundStyle(Color.potsTeal)
                .background(Color.potsTeal.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(PersistenceController.shared.loadError != nil)
    }

    private var checkInStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quick check-in").font(.subheadline.weight(.semibold))
                Spacer()
                if let latest = todayEntries.first(where: { $0.category == LogCategory.checkIn.rawValue }) {
                    Text("Last: \(latest.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Optional").font(.caption).foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 7) {
                HStack(spacing: 7) {
                    checkInButton("Better")
                    checkInButton("Usual")
                    checkInButton("Worse")
                }
                HStack(spacing: 7) {
                    checkInButton("Much worse")
                    checkInButton("Not sure")
                }
            }
        }
    }

    private func checkInButton(_ answer: String) -> some View {
        let selected = todayEntries.first(where: { $0.category == LogCategory.checkIn.rawValue })?.title == answer
        return Button {
            saveCheckIn(answer)
        } label: {
            Text(answer)
                .font(.system(size: 14, weight: selected ? .semibold : .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: roomy ? 51 : 37)
                .foregroundStyle(selected ? Color.potsTeal : Color.primary)
                .background(
                    selected ? Color.potsTeal.opacity(0.13) : Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 11)
                )
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(
                    selected ? Color.potsTeal.opacity(0.4) : Color.clear,
                    lineWidth: 1
                ))
        }
        .buttonStyle(.plain)
        .disabled(PersistenceController.shared.loadError != nil)
        .accessibilityHint("Records a new optional check-in")
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

    @ViewBuilder
    private var recentGrid: some View {
        if !allRecords.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Recent activity").font(.headline)
                Spacer()
                Button("See all", action: openHistory)
                    .font(.caption.weight(.semibold))
            }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)], spacing: 9) {
                    ForEach(Array(allRecords.prefix(3))) { entry in
                        Button { editRoute = RecordEditRoute(objectID: entry.id) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.title)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text(entry.detail)
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
                    Text("Choose a tracker. One entry at a time.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                featureSection("Track now", ids: ["symptom", "heartRate", "bloodPressure", "journal"])
                featureSection("Daily support", ids: ["hydration", "medications", "sleep", "posture"])
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
    private let columns = [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Make the app your own")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                section("Personalize")
                LazyVGrid(columns: columns, spacing: 11) {
                    NavigationLink {
                        HomeCustomizationView()
                    } label: {
                        smallTool("Customize Home", icon: "slider.horizontal.3")
                    }
                    .buttonStyle(.plain)

                    if let settings = TrackerFeature.all.first(where: { $0.id == "settings" }) {
                        FeatureTile(feature: settings, roomy: lowEnergyMode)
                    }
                }

                section("Review & tools")
                LazyVGrid(columns: columns, spacing: 11) {
                    ForEach(["calendar", "reports", "reminders"].compactMap({ id in
                        TrackerFeature.all.first(where: { $0.id == id })
                    })) { feature in
                        FeatureTile(feature: feature, roomy: lowEnergyMode)
                    }
                    NavigationLink {
                        PrivacyText()
                    } label: {
                        smallTool("Privacy & safety", icon: "hand.raised.fill")
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 5) {
                    Text("POTS Tracker · \(InstalledBuild.shortLabel)")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Installed POTS Tracker, \(InstalledBuild.fullLabel)")
                    Text("Test build · Local backup and export aren't available yet")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 5)
                .padding(.bottom, 10)
            }
            .padding(18)
            .padding(.bottom, 24)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String) -> some View {
        Text(title).font(.headline)
    }

    private func smallTool(_ title: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(Color.potsTeal)
                .frame(width: 57, height: 57)
                .background(Color.potsTeal.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: lowEnergyMode ? 135 : 116)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.potsTeal.opacity(0.06)))
        .accessibilityElement(children: .combine)
    }
}
