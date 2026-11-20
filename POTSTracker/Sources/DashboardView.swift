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
        .init(id: "hydration", name: "Hydration", file: "04_Hydration", symbol: "drop.fill", color: .cyan, build: 1),
        .init(id: "medications", name: "Medications", file: "05_Medications", symbol: "pills.fill", color: .green, build: 1),
        .init(id: "sleep", name: "Sleep & Rest", file: "06_Sleep", symbol: "moon.stars.fill", color: .purple, build: 1),
        .init(id: "calendar", name: "Calendar", file: "07_Calendar", symbol: "calendar", color: .orange, build: 1),
        .init(id: "reports", name: "Reports", file: "08_Reports", symbol: "chart.bar.fill", color: .mint, build: 1),
        .init(id: "journal", name: "Journal", file: "09_Journal", symbol: "book.closed.fill", color: .pink, build: 1),
        .init(id: "posture", name: "Posture", file: "10_Posture", symbol: "figure.stand", color: .teal, build: 1),
        .init(id: "reminders", name: "Reminders", file: "11_Reminders", symbol: "bell.fill", color: .blue, build: 1),
        .init(id: "settings", name: "Settings", file: "12_Settings", symbol: "gearshape.fill", color: .purple, build: 1) 
    ]

    var category: LogCategory? { LogCategory(rawValue: id) }
}

struct FeatureArtwork: View {
    let feature: TrackerFeature
    var width: CGFloat = 58

    var body: some View {
        Group {
            if feature.file.isEmpty {
                Image(systemName: feature.symbol)
                    .font(.system(size: width * 0.45, weight: .medium))
                    .foregroundStyle(Color.potsTeal)
                    .frame(width: width, height: width)
                    .background(Color.potsTeal.opacity(0.13), in: RoundedRectangle(cornerRadius: width * 0.22))
            } else {
                Image(feature.file)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: width)
            }
        }
        .accessibilityHidden(true)
    }
}

enum TrackerTab: Hashable {
    case home
    case log
    case history
    case more
}

/// Each bottom tab must open at its own root after entering from another tab.
/// Changing a NavigationStack identity discards old pushed destinations,
/// including a Journal that was visible before leaving Home or Log.
/// This is deliberately transient navigation state, never stored with records.
struct TabNavigationRevisions {
    private(set) var home = 0
    private(set) var log = 0
    private(set) var history = 0
    private(set) var more = 0

    mutating func resetDestination(_ tab: TrackerTab) {
        switch tab {
        case .home: home += 1
        case .log: log += 1
        case .history: history += 1
        case .more: more += 1
        }
    }

    func revision(for tab: TrackerTab) -> Int {
        switch tab {
        case .home: return home
        case .log: return log
        case .history: return history
        case .more: return more
        }
    }
}

/// A tab's tap always means that tab's root, never the last pushed feature
/// on its old NavigationStack. The destination is reset BEFORE selecting it,
/// so the stale Journal screen cannot briefly reappear and request Face ID.
struct DashboardView: View {
    @State private var selectedTab: TrackerTab = .home
    @State private var navigation = TabNavigationRevisions()

    private var tabSelection: Binding<TrackerTab> {
        Binding(
            get: { selectedTab },
            set: { destination in
                selectTab(destination)
            }
        )
    }

    private func selectTab(_ destination: TrackerTab) {
        guard selectedTab != destination else { return }
        navigation.resetDestination(destination)
        // Switching tabs ends any private Journal session.
        JournalAccess.shared.lock()
        selectedTab = destination
    }

    var body: some View {
        TabView(selection: tabSelection) {
            NavigationStack {
                HomeScreenView(
                    openLog: { selectTab(.log) },
                    openHistory: { selectTab(.history) }
                )
            }
            .id(navigation.home)
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(TrackerTab.home)

            NavigationStack {
                LogHubView()
            }
            .id(navigation.log)
            .tabItem { Label("Log", systemImage: "square.grid.2x2.fill") }
            .tag(TrackerTab.log)

            NavigationStack {
                HistoryScreenView()
            }
            .id(navigation.history)
            .tabItem { Label("History", systemImage: "calendar") }
            .tag(TrackerTab.history)

            NavigationStack {
                MoreHubView()
            }
            .id(navigation.more)
            .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
            .tag(TrackerTab.more)
        }
        .tint(.potsTeal)
        .toolbarBackground(Color.potsBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
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
            .background(Color.potsSurface,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.potsStroke.opacity(0.7)))
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(feature.name)
        .accessibilityHint(feature.build > 1 ? "Planned for Build \(feature.build)" : "Open \(feature.name)")
    }
}

struct FeelingDraft: Identifiable {
    let feeling: String
    var id: String { feeling }
}

struct HomeScreenView: View {
    let openLog: () -> Void
    let openHistory: () -> Void

    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var entries: FetchedResults<POTSLogEntry>

    @AppStorage("lowEnergyMode") private var lowEnergyMode = false
    @AppStorage("showEducationHints") private var showHints = true
    @AppStorage("homeModuleOrder") private var moduleOrder = HomeLayout.moduleDefault
    @AppStorage("homeHiddenModules") private var hiddenModules = ""
    @AppStorage("homePinnedFeatureIDs") private var pinnedIDs = HomeLayout.pinDefault
    @AppStorage("homeLayoutDensity") private var density = "compact"

    @State private var newLog: LogCategory?
    @State private var feelingDraft: FeelingDraft?
    @AppStorage("journalLockEnabled") private var journalLockEnabled = false
    @ObservedObject private var journalAccess = JournalAccess.shared
    @AppStorage("homeStatusDotsMigrationV1") private var migratedStatusDots = false

    private var allRecords: [RecordSnapshot] {
        let journalHidden = journalLockEnabled && !journalAccess.unlocked
        return RecordSnapshot.snapshots(of: Array(entries).filter {
            !journalHidden || $0.category != LogCategory.journal.rawValue
        })
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
                        .foregroundStyle(Color.potsSecondary)
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
                                .font(.subheadline).foregroundStyle(Color.potsSecondary)
                            Button("Go to Log", action: openLog).buttonStyle(.borderedProminent)
                        }
                    }
                }


            }
            .padding(.horizontal, 17)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("POTS & Posies")
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
        .sheet(item: $feelingDraft) { draft in
            EntryEditor(category: .checkIn, suggestedFeeling: draft.feeling.isEmpty ? nil : draft.feeling)
        }
        .onAppear {
            guard !migratedStatusDots else { return }
            if moduleOrder == "today,checkIn,favorites,recent" {
                moduleOrder = HomeLayout.moduleDefault
            }
            migratedStatusDots = true
        }
    }

    @ViewBuilder
    private func moduleView(_ module: HomeModule) -> some View {
        switch module {
        case .today: todayCard
        case .checkIn: checkInStrip
        case .favorites: favoriteGrid
        case .recent: statusDots
        }
    }

    private var todayCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: roomy ? 15 : 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Today")
                            .font(.title3.bold())
                        if todayEntries.contains(where: { $0.category == LogCategory.checkIn.rawValue }) {
                            Text("Check-in recorded")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        } else {
                            Text(todayEntries.isEmpty ? "Nothing logged yet" : "No check-in yet")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
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
                    .background(Color.potsButtonFill, in: RoundedRectangle(cornerRadius: 14))
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
        Button {
            feelingDraft = FeelingDraft(feeling: answer)
        } label: {
            Text(answer)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: roomy ? 51 : 37)
                .foregroundStyle(Color.primary)
                .background(Color.potsSurface, in: RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
        .disabled(PersistenceController.shared.loadError != nil)
        .accessibilityHint("Opens an unsaved note. No record is created until you choose Save.")
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

    private var statusDots: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Logged today")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("History", action: openHistory)
                    .font(.caption.weight(.semibold))
            }

            HStack(spacing: 9) {
                statusDot("Feeling", category: .checkIn)
                statusDot("Symptoms", category: .symptom)
                statusDot("Heart rate", category: .heartRate)
                statusDot("BP", category: .bloodPressure)
            }


        }
    }

    private func statusDot(_ title: String, category: LogCategory) -> some View {
        let logged = todayEntries.contains { $0.category == category.rawValue }
        return Button {
            if category == .checkIn {
                feelingDraft = FeelingDraft(feeling: "")
            } else {
                newLog = category
            }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(logged ? Color.potsTeal : Color.clear)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().strokeBorder(
                        logged ? Color.potsTeal : Color.potsTertiary.opacity(0.85),
                        lineWidth: 1.5
                    ))
                Text(title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: roomy ? 64 : 51)
            .background(Color.potsSurface,
                        in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .disabled(PersistenceController.shared.loadError != nil)
        .accessibilityLabel("\(title), \(logged ? "recorded today" : "not recorded today")")
        .accessibilityHint("Open an entry form")
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
                        .font(.subheadline).foregroundStyle(Color.potsSecondary)
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
                    .foregroundStyle(Color.potsSecondary)

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
                }

                section("Privacy & security")
                LazyVGrid(columns: columns, spacing: 11) {
                    NavigationLink {
                        JournalLockSettings()
                    } label: {
                        smallTool("Journal Lock", icon: "lock.shield.fill")
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        PrivacyText()
                    } label: {
                        smallTool("Privacy & safety", icon: "hand.raised.fill")
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 5) {
                    Text("POTS & Posies · \(InstalledBuild.shortLabel)")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(Color.potsSecondary)
                        .accessibilityLabel("Installed POTS & Posies, \(InstalledBuild.fullLabel)")
                    Text("Test build · Local backup and export aren't available yet")
                        .font(.caption2)
                        .foregroundStyle(Color.potsTertiary)
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
        .background(Color.potsSurface,
                    in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.potsStroke.opacity(0.7)))
        .accessibilityElement(children: .combine)
    }
}
