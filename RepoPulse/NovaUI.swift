import SwiftUI
import Charts

// Repo Pulse: cohesive native iPhone presentation, deliberately fixed dark theme.
enum Nova {
    static let bg = Color(red: 0.032, green: 0.047, blue: 0.078)
    static let surface = Color(red: 0.075, green: 0.106, blue: 0.161)
    static let raised = Color(red: 0.104, green: 0.143, blue: 0.213)
    static let cyan = Color(red: 0.31, green: 0.90, blue: 0.95)
    static let violet = Color(red: 0.62, green: 0.44, blue: 0.95)
    static let gold = Color(red: 1.0, green: 0.75, blue: 0.39)
    static let orange = Color(red: 1.0, green: 0.50, blue: 0.28)
    static let muted = Color(red: 0.61, green: 0.68, blue: 0.79)
    static let stroke = Color.white.opacity(0.10)
    static let gradient = LinearGradient(colors: [cyan, violet],
                                         startPoint: .leading, endPoint: .trailing)
    static func tint(_ name: String) -> Color {
        let v = name.lowercased()
        if v.contains("titledeck") { return gold }
        if v.contains("resonadeck") { return violet }
        if v.contains("xnfs") { return orange }
        return cyan
    }
    static func format(_ count: Int) -> String { count.formatted() }
}

struct NovaPanel: ViewModifier {
    var accent: Color = Nova.stroke
    var radius: CGFloat = 22
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(colors: [Nova.raised.opacity(0.70), Nova.surface],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(accent.opacity(0.44), lineWidth: 1))
    }
}
extension View {
    func novaPanel(_ accent: Color = Nova.stroke, radius: CGFloat = 22) -> some View {
        modifier(NovaPanel(accent: accent, radius: radius))
    }
}

struct NovaBackdrop: View {
    var body: some View {
        ZStack {
            Nova.bg
            RadialGradient(colors: [Nova.violet.opacity(0.17), .clear],
                           center: .topTrailing, startRadius: 8, endRadius: 380)
            RadialGradient(colors: [Nova.cyan.opacity(0.08), .clear],
                           center: .bottomLeading, startRadius: 5, endRadius: 400)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct NovaEmblem: View {
    let name: String
    var size: CGFloat = 51
    private var accent: Color { Nova.tint(name) }
    private var key: String { name.lowercased() }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(
                    LinearGradient(colors: [accent.opacity(0.30), accent.opacity(0.075)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .stroke(accent.opacity(0.26), lineWidth: 1)
            Group {
                if key.contains("game-theme-music") {
                    ZStack {
                        Circle().stroke(accent.opacity(0.8), lineWidth: size * 0.027)
                            .frame(width: size * 0.56, height: size * 0.56)
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.37, weight: .bold))
                    }
                } else if key.contains("titledeck") {
                    ZStack {
                        RoundedRectangle(cornerRadius: size * 0.06)
                            .stroke(accent.opacity(0.8), lineWidth: 1.5)
                            .frame(width: size * 0.52, height: size * 0.60)
                        Text("T")
                            .font(.system(size: size * 0.41, weight: .heavy, design: .rounded))
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: size * 0.15, weight: .heavy))
                            .offset(x: size * 0.10, y: size * 0.19)
                    }
                } else if key.contains("resonadeck") {
                    Image(systemName: "waveform")
                        .font(.system(size: size * 0.46, weight: .semibold))
                } else if key.contains("xnfs") {
                    Image(systemName: "steeringwheel")
                        .font(.system(size: size * 0.52, weight: .medium))
                } else {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: size * 0.41, weight: .medium))
                }
            }
            .foregroundStyle(accent)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct NovaAppView: View {
    @EnvironmentObject private var store: PulseStore
    @EnvironmentObject private var engine: DeckPulseEngine
    @Environment(\.scenePhase) private var phase
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            NovaDashboard(showAlerts: { tab = 3 })
                .tabItem { Label("Home", systemImage: "square.grid.2x2.fill") }.tag(0)
            NovaInsights()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }.tag(1)
            NovaTrophies()
                .tabItem { Label("Trophies", systemImage: "trophy.fill") }.tag(2)
            NovaActivity()
                .tabItem { Label("Alerts", systemImage: "bell.badge.fill") }.tag(3)
            NovaSettings()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(4)
        }
        .tint(Nova.cyan)
        .preferredColorScheme(.dark)
        .toolbarColorScheme(.dark, for: .tabBar)
        .background(Nova.bg.ignoresSafeArea())
        .task {
            if store.refreshedAt == nil { await refresh() }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(300)) }
                catch { break }
                if Task.isCancelled { break }
                if phase == .active { await refresh() }
            }
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .active,
                let previous = store.refreshedAt,
                Date().timeIntervalSince(previous) > 300 {
                Task { await refresh() }
            }
        }
    }
    private func refresh() async {
        guard !store.busy else { return }
        await store.refresh()
        engine.ingest(store)
    }
}

struct NovaTopbar: View {
    @EnvironmentObject private var store: PulseStore
    @EnvironmentObject private var engine: DeckPulseEngine
    let openAlerts: () -> Void
    var body: some View {
        HStack(spacing: 11) {
            Image("RepoPulseMark")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 45, height: 45)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text("REPO PULSE")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white)
                Text("YOUR PROJECT COMMAND CENTER")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(Nova.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 1)
            Button {
                Task { await store.refresh(); engine.ingest(store) }
            } label: {
                Image(systemName: store.busy ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(Nova.surface, in: Circle())
            }
            .disabled(store.busy)
            .accessibilityLabel("Refresh GitHub repositories")
            Button(action: openAlerts) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 38, height: 38)
                        .background(Nova.surface, in: Circle())
                    if engine.unread > 0 {
                        Circle().fill(Nova.gold).frame(width: 7, height: 7)
                            .offset(x: -6, y: 5)
                    }
                }
            }
            .accessibilityLabel("\(engine.unread) unread alerts")
        }
        .foregroundStyle(Nova.cyan)
    }
}

struct NovaMetricPicker: View {
    @AppStorage("pulse.mobile.asset") private var assetRaw = "primary"
    @AppStorage("pulse.mobile.release") private var modeRaw = "all"
    var body: some View {
        HStack(spacing: 10) {
            Menu {
                Picker("Release scope", selection: $modeRaw) {
                    ForEach(PulseReleaseMode.allCases) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
            } label: {
                pickerLabel((PulseReleaseMode(rawValue: modeRaw) ?? .all).label, "tag")
            }
            Menu {
                Picker("Asset scope", selection: $assetRaw) {
                    ForEach(PulseAsset.allCases) { asset in
                        Text(asset.label).tag(asset.rawValue)
                    }
                }
            } label: {
                pickerLabel((PulseAsset(rawValue: assetRaw) ?? .primary).label, "archivebox")
            }
        }
    }
    private func pickerLabel(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol).foregroundStyle(Nova.cyan)
            Text(title).lineLimit(1).minimumScaleFactor(0.75)
            Spacer(minLength: 1)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .frame(maxWidth: .infinity, minHeight: 46)
        .novaPanel(Nova.stroke, radius: 15)
    }
}

struct NovaDashboard: View {
    @EnvironmentObject private var store: PulseStore
    @EnvironmentObject private var engine: DeckPulseEngine
    @AppStorage("pulse.mobile.asset") private var assetRaw = "primary"
    @AppStorage("pulse.mobile.release") private var modeRaw = "all"
    @State private var addSheet = false
    @State private var quickSheet = false
    let showAlerts: () -> Void

    private var asset: PulseAsset { PulseAsset(rawValue: assetRaw) ?? .primary }
    private var mode: PulseReleaseMode { PulseReleaseMode(rawValue: modeRaw) ?? .all }
    private var known: [Int] {
        store.watched.compactMap { store.loaded[$0.id]?.measure(mode, asset: asset).count }
    }
    private var total: Int { known.reduce(0, +) }

    var body: some View {
        NavigationStack {
            ZStack {
                NovaBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 19) {
                        NovaTopbar(openAlerts: showAlerts)
                        hero
                        if let error = store.errorText { errorCard(error) }
                        HStack {
                            label("WATCHLIST", icon: "square.stack.3d.up")
                            Spacer()
                            Button { addSheet = true } label: {
                                Label("Add", systemImage: "plus.circle.fill")
                                    .font(.system(size: 13, weight: .bold))
                            }
                        }
                        NovaMetricPicker()
                        VStack(spacing: 11) {
                            ForEach(store.visible) { repo in
                                NavigationLink {
                                    if let stats = store.loaded[repo.id] {
                                        NovaRepoDetail(stats: stats)
                                    } else {
                                        NovaNotLoaded(repo: repo)
                                    }
                                } label: {
                                    NovaRepoRow(repo: repo, stats: store.loaded[repo.id],
                                                asset: asset, mode: mode, engine: engine)
                                }
                                .buttonStyle(.plain)
                            }
                            if store.watched.isEmpty {
                                NovaEmpty(title: "Start your watchlist",
                                          message: "Add a public GitHub project to see its releases and activity.",
                                          icon: "shippingbox")
                            }
                        }
                        if store.pageCount > 1 { pagination }
                        Button { quickSheet = true } label: {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("QUICK GLANCE")
                                    .tracking(1.2)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(Nova.cyan)
                            .padding(16)
                            .novaPanel(Nova.cyan.opacity(0.24), radius: 17)
                        }
                        NovaBriefing(stats: store.watched.compactMap { store.loaded[$0.id] },
                                     engine: engine, asset: asset, mode: mode)
                        Text("Totals reflect GitHub release assets, not unique installs. Growth appears only after real snapshots.")
                            .font(.system(size: 11))
                            .foregroundStyle(Nova.muted)
                            .padding(.bottom, 13)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
                .refreshable { await store.refresh(); engine.ingest(store) }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $addSheet) { NovaAddProject() }
            .sheet(isPresented: $quickSheet) {
                NovaQuickGlance(stats: store.watched.compactMap { store.loaded[$0.id] },
                                asset: asset, mode: mode)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Circle().fill(store.busy ? Nova.gold : Nova.cyan)
                    .frame(width: 7, height: 7)
                Text(store.busy ? "SYNCING GITHUB" : "GITHUB ACTIVITY")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.7)
                    .foregroundStyle(Nova.cyan)
                Spacer()
                Text("iOS  ·  1.4.0")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Nova.muted)
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(Nova.format(total))
                    .font(.system(size: 45, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(.white)
                Text("downloads")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Nova.muted)
            }
            VStack(alignment: .leading, spacing: 9) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Nova.gradient)
                    .frame(height: 3)
                HStack {
                    Label("\(store.watched.count) watched", systemImage: "square.stack")
                    Spacer()
                    Label("\(engine.unread) new alerts", systemImage: "bell")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Nova.muted)
            }
            HStack {
                Image(systemName: "clock")
                Text(store.refreshedAt.map { "Last synced \($0.formatted(date: .omitted, time: .shortened))" }
                     ?? "Waiting for first sync")
                Spacer()
                Text("BUILD 6")
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(Nova.muted)
        }
        .padding(20)
        .novaPanel(Nova.cyan.opacity(0.85), radius: 24)
    }
    private func label(_ value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(Nova.cyan)
            Text(value).tracking(1.6)
        }
        .font(.system(size: 11, weight: .heavy, design: .rounded))
        .foregroundStyle(.white)
    }
    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("Refresh incomplete", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Nova.gold)
            Text(message).font(.caption).foregroundStyle(Nova.muted)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .novaPanel(Nova.gold.opacity(0.5))
    }
    private var pagination: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { store.page = max(0, store.page - 1) }
            } label: { Label("Previous", systemImage: "chevron.left") }
            .disabled(store.page == 0)
            Spacer()
            Text("PAGE \(store.page + 1) / \(store.pageCount)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Nova.muted)
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { store.page = min(store.pageCount - 1, store.page + 1) }
            } label: { Label("Next", systemImage: "chevron.right") }
            .disabled(store.page == store.pageCount - 1)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Nova.cyan)
        .padding(.vertical, 8)
    }
}

struct NovaRepoRow: View {
    let repo: WatchedRepo
    let stats: RepoStats?
    let asset: PulseAsset
    let mode: PulseReleaseMode
    @ObservedObject var engine: DeckPulseEngine
    private var accent: Color { Nova.tint(repo.id) }
    private var measurement: PulseMeasurement? { stats?.measure(mode, asset: asset) }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center, spacing: 13) {
                NovaEmblem(name: repo.name, size: 52)
                VStack(alignment: .leading, spacing: 5) {
                    Text(repo.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(repo.owner)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Nova.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 2)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
            }
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(measurement?.count.map { Nova.format($0) } ?? "—")
                        .font(.system(size: 27, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(accent)
                    Text(asset.short.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Nova.muted)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 6) {
                    if let change = engine.change(repo.id, mode, asset) {
                        Label(change > 0 ? "+\(change.formatted())" : change.formatted(),
                              systemImage: change > 0 ? "arrow.up.right" : "equal")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(change > 0 ? Nova.cyan : Nova.muted)
                    } else {
                        Text("AWAITING TREND")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Nova.muted)
                    }
                    Text(stats?.published.first?.tagName ?? "No release loaded")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .lineLimit(1)
                        .foregroundStyle(Nova.muted)
                }
            }
        }
        .padding(16)
        .novaPanel(accent.opacity(0.57), radius: 20)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

struct NovaBriefing: View {
    let stats: [RepoStats]
    @ObservedObject var engine: DeckPulseEngine
    let asset: PulseAsset
    let mode: PulseReleaseMode
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("PROJECT BRIEFING", systemImage: "waveform.path.ecg")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(Nova.cyan)
            if stats.isEmpty {
                Text("Your next sync will build this briefing.")
                    .font(.caption).foregroundStyle(Nova.muted)
            } else {
                ForEach(stats.prefix(4)) { item in
                    HStack {
                        Circle().fill(Nova.tint(item.id)).frame(width: 6, height: 6)
                        Text(item.identity.name)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        Spacer()
                        Text(engine.change(item.id, mode, asset).map {
                            $0 > 0 ? "+\($0.formatted())" : $0.formatted()
                        } ?? "Not enough history")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Nova.muted)
                    }
                }
            }
        }
        .padding(16)
        .novaPanel()
    }
}

struct NovaNotLoaded: View {
    let repo: WatchedRepo
    var body: some View {
        ZStack {
            NovaBackdrop()
            NovaEmpty(title: repo.name,
                       message: "Statistics aren't available yet. Return to Home and refresh.",
                       icon: "wifi.exclamationmark")
                .padding(20)
        }
        .navigationTitle("Repository")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

struct NovaEmpty: View {
    let title: String
    let message: String
    let icon: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 29, weight: .light))
                .foregroundStyle(Nova.violet)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Nova.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .novaPanel()
    }
}

struct NovaAddProject: View {
    @EnvironmentObject private var store: PulseStore
    @EnvironmentObject private var engine: DeckPulseEngine
    @Environment(\.dismiss) private var dismiss
    @State private var entry = "ValentineBSAA/"
    @State private var warning: String?

    var body: some View {
        NavigationStack {
            ZStack {
                NovaBackdrop()
                VStack(alignment: .leading, spacing: 18) {
                    NovaEmpty(title: "Add a repository",
                              message: "Track a public GitHub project with the same download rules as Repo Pulse Decky.",
                              icon: "plus.square.on.square")
                    TextField("owner/repository", text: $entry)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(16)
                        .novaPanel(Nova.cyan.opacity(0.4))
                    if let warning {
                        Text(warning).foregroundStyle(Nova.gold).font(.caption)
                    }
                    Button {
                        if let issue = store.add(entry) { warning = issue }
                        else {
                            dismiss()
                            Task { await store.refresh(); engine.ingest(store) }
                        }
                    } label: {
                        Text("START WATCHING")
                            .font(.system(size: 13, weight: .heavy))
                            .frame(maxWidth: .infinity).padding(16)
                    }
                    .foregroundStyle(Nova.bg)
                    .background(Nova.cyan, in: RoundedRectangle(cornerRadius: 15))
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
        .tint(Nova.cyan)
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
    }
}
