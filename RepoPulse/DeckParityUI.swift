import SwiftUI
import Charts

// A native, touch-adapted counterpart to the actual Repo Pulse Decky 0.8.3.
// Dark premium palette is fixed. No light mode, CSS detection, or theme toggle.

private enum DeckLook {
    static let bg = Color(red: 0.035, green: 0.055, blue: 0.098)
    static let card = Color(red: 0.075, green: 0.115, blue: 0.175)
    static let raised = Color(red: 0.105, green: 0.165, blue: 0.245)
    static let cyan = Color(red: 0.32, green: 0.92, blue: 0.96)
    static let violet = Color(red: 0.66, green: 0.43, blue: 0.99)
    static let aqua = Color(red: 0.45, green: 0.93, blue: 0.80)
    static let gold = Color(red: 1.00, green: 0.78, blue: 0.42)
    static let dim = Color(red: 0.65, green: 0.74, blue: 0.83)
    static let line = Color.white.opacity(0.10)
    static let gradient = LinearGradient(colors: [cyan, violet],
                                         startPoint: .leading, endPoint: .trailing)
}

private struct DeckPanel: ViewModifier {
    var highlight = false
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [DeckLook.raised.opacity(highlight ? 0.98 : 0.65), DeckLook.card],
                    startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(highlight ? DeckLook.cyan.opacity(0.44) : DeckLook.line, lineWidth: 1))
    }
}
private extension View {
    func deckPanel(_ highlight: Bool = false) -> some View { modifier(DeckPanel(highlight: highlight)) }
}

private func compact(_ value: Int) -> String {
    if value >= 1_000_000_000_000 { return String(format: "%.1fT", Double(value)/1_000_000_000_000) }
    if value >= 1_000_000_000 { return String(format: "%.1fB", Double(value)/1_000_000_000) }
    if value >= 1_000_000 { return String(format: "%.1fM", Double(value)/1_000_000) }
    if value >= 1_000 { return String(format: "%.1fK", Double(value)/1_000) }
    return value.formatted()
}

private func kindColor(_ repo: String) -> Color {
    let lower = repo.lowercased()
    if lower.contains("titledeck") { return DeckLook.gold }
    if lower.contains("resonadeck") { return DeckLook.violet }
    if lower.contains("xnfs") { return .orange }
    return DeckLook.cyan
}

private struct DeckHeader: View {
    let title: String
    let subtitle: String
    let unread: Int
    let refresh: () -> Void
    let onInbox: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            Image("DeckCube")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DeckLook.gradient)
                .frame(width: 47, height: 47)
                .background(DeckLook.raised, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(DeckLook.cyan.opacity(0.28)))
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(1.8)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(DeckLook.dim)
                    .lineLimit(1)
            }
            Spacer(minLength: 2)
            Button(action: refresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 35, height: 39)
            }
            .accessibilityLabel("Refresh GitHub")
            Button(action: onInbox) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 17))
                        .frame(width: 37, height: 39)
                    if unread > 0 {
                        Circle().fill(DeckLook.gold).frame(width: 8, height: 8)
                            .offset(x: -5, y: 3)
                    }
                }
            }
            .accessibilityLabel("Notification inbox, \(unread) unread")
        }
        .foregroundStyle(.white)
        .tint(DeckLook.cyan)
    }
}

struct DeckPulseHome: View {
    @EnvironmentObject private var store: PulseStore
    @EnvironmentObject private var deck: DeckPulseEngine
    @AppStorage("pulse.mobile.asset") private var assetRaw = "primary"
    @AppStorage("pulse.mobile.release") private var releaseRaw = "all"
    @AppStorage("pulse.mobile.analytics") private var analytics = "deck"
    @AppStorage("pulse.mobile.ribbon") private var showRibbon = true
    @State private var tab = 0
    @State private var selectedRepo: WatchedRepo?
    @State private var addRepo = false
    @State private var glance = false

    private var asset: PulseAsset { PulseAsset(rawValue: assetRaw) ?? .primary }
    private var mode: PulseReleaseMode { PulseReleaseMode(rawValue: releaseRaw) ?? .all }

    private var pageStats: [RepoStats] {
        store.visible.compactMap { store.loaded[$0.id] }
    }
    private var displayedTotal: Int {
        store.watched.compactMap { store.loaded[$0.id]?.measure(mode, asset: asset).count }.reduce(0,+)
    }

    var body: some View {
        TabView(selection: $tab) {
            homePage.tabItem { Label("Home", systemImage:"square.grid.2x2.fill") }.tag(0)
            analyticsPage.tabItem { Label("Insights", systemImage:"chart.xyaxis.line") }.tag(1)
            trophiesPage.tabItem { Label("Trophies", systemImage:"trophy.fill") }.tag(2)
            activityPage.tabItem { Label("Alerts", systemImage:"bell.badge.fill") }.tag(3)
            settingsPage.tabItem { Label("Settings", systemImage:"gearshape.fill") }.tag(4)
        }
        .background(DeckLook.bg.ignoresSafeArea())
        .tint(DeckLook.cyan)
        .preferredColorScheme(.dark)
        .toolbarColorScheme(.dark, for: .tabBar)
        .sheet(item: $selectedRepo) { repo in
            if let stats = store.loaded[repo.id] {
                DeckRepoDetails(stats: stats, asset: asset, mode: mode)
                    .environmentObject(deck)
            } else {
                ContentUnavailableView("Not synced yet", systemImage:"wifi.exclamationmark",
                                       description: Text("Refresh GitHub and try again."))
                    .preferredColorScheme(.dark)
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $addRepo) { DeckAddRepo(onAdded: reload) .environmentObject(store) }
        .sheet(isPresented: $glance) {
            NavigationStack {
                DeckQuickGlance(stats: store.watched.compactMap { store.loaded[$0.id] },
                                asset: asset, mode: mode, onSelect: { repo in
                    glance = false
                    selectedRepo = repo
                })
                .environmentObject(deck)
            }
            .preferredColorScheme(.dark)
        }
        .task {
            // Foreground-only polling. iOS can suspend the process in background.
            if store.refreshedAt == nil { await reload() }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 900_000_000_000)
                if Task.isCancelled { break }
                await reload()
            }
        }
    }

    private func reload() {
        Task { await store.refresh(); deck.ingest(store) }
    }
    private func reloadAsync() async {
        await store.refresh()
        deck.ingest(store)
    }
    private func header(_ title: String, _ sub: String) -> some View {
        DeckHeader(title: title, subtitle: sub, unread: deck.unread, refresh: reload,
                   onInbox: { tab = 3 })
    }
    private func section(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(DeckLook.cyan)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.7)
            Spacer()
        }
    }
    private func errorBanner() -> some View {
        Group {
            if let error = store.errorText {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(DeckLook.gold)
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .deckPanel()
            }
        }
    }
    private var homePage: some View {
        NavigationStack {
            pageScroll {
                header("Repo Pulse", "Steam Deck analytics, now native on iPhone")
                HStack {
                    Label("DECK EDITION · 0.8.3 DNA", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(DeckLook.cyan)
                    Spacer()
                    Text("v\(Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? "?") · b\(Bundle.main.object(forInfoDictionaryKey:"CFBundleVersion") as? String ?? "?")")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(DeckLook.dim)
                }
                .padding(12)
                .background(DeckLook.cyan.opacity(0.07), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(DeckLook.cyan.opacity(0.24)))
                HStack(alignment:.bottom,spacing:15) {
                    VStack(alignment:.leading,spacing:5) {
                        Text("MY GITHUB")
                            .font(.system(size:10,weight:.heavy)).tracking(2)
                            .foregroundStyle(DeckLook.dim)
                        Text(compact(displayedTotal))
                            .font(.system(size:42,weight:.black,design:.rounded))
                            .monospacedDigit()
                            .foregroundStyle(DeckLook.cyan)
                            .lineLimit(1).minimumScaleFactor(0.5)
                        Text("\(asset.label) · \(mode.label)")
                            .font(.caption2).foregroundStyle(DeckLook.dim)
                    }
                    Spacer()
                    Image(systemName:"waveform.path.ecg")
                        .font(.system(size:55,weight:.ultraLight))
                        .foregroundStyle(DeckLook.violet)
                }
                .padding(21)
                .frame(maxWidth:.infinity,alignment:.leading)
                .deckPanel(true)
                if showRibbon {
                    HStack(spacing:8) {
                        ribbonValue("\(store.watched.count)", "WATCHED", "square.stack.3d.up")
                        ribbonValue(compact(displayedTotal), "DOWNLOADS", "arrow.down.circle")
                        ribbonValue("\(deck.unread)", "UNREAD", "bell.badge")
                    }
                }
                errorBanner()
                selectionControls
                HStack {
                    section("Your repositories", icon: "square.grid.2x2")
                    Button { addRepo = true } label: {
                        Label("Add",systemImage:"plus.circle.fill")
                            .font(.subheadline.weight(.bold))
                    }
                    .tint(DeckLook.cyan)
                }
                if store.watched.isEmpty {
                    Text("Add a public GitHub repository to begin.")
                        .foregroundStyle(DeckLook.dim)
                } else {
                    LazyVGrid(columns:[GridItem(.flexible(),spacing:11),GridItem(.flexible(),spacing:11)],spacing:11) {
                        ForEach(store.visible) { repo in
                            Button { selectedRepo = repo } label: {
                                DeckRepoTile(repo:repo,stats:store.loaded[repo.id],
                                             asset:asset,mode:mode,
                                             other:deck.isOther(repo.id),
                                             unread:deck.unreadFor(repo.id),
                                             busy:store.busy)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack(spacing:16) {
                        Button { withAnimation(.easeInOut(duration:0.2)) { store.page = max(0,store.page-1) } } label: {
                            Label("Back",systemImage:"chevron.left")
                        }
                        .disabled(store.page == 0)
                        Spacer()
                        Text("\(store.page+1) / \(store.pageCount)")
                            .font(.subheadline.weight(.bold))
                            .monospacedDigit().foregroundStyle(DeckLook.dim)
                        Spacer()
                        Button { withAnimation(.easeInOut(duration:0.2)) { store.page = min(store.pageCount-1,store.page+1) } } label: {
                            Label("Next",systemImage:"chevron.right")
                        }
                        .disabled(store.page == store.pageCount-1)
                    }
                    .font(.subheadline.weight(.semibold))
                    .tint(DeckLook.cyan)
                    .padding(.vertical,5)
                }
                Button { glance = true } label: {
                    Label("QUICK GLANCE", systemImage:"bolt.horizontal.circle.fill")
                        .font(.system(size:12,weight:.heavy,design:.rounded))
                        .tracking(1.8)
                        .frame(maxWidth:.infinity).padding(16)
                }
                .buttonStyle(.plain)
                .foregroundStyle(DeckLook.cyan)
                .deckPanel()
                DeckBriefing(stats:store.watched.compactMap{store.loaded[$0.id]},
                             engine:deck,asset:asset,mode:mode)
                Text("GitHub asset downloads are not unique installs. Charts and growth use saved observations, not invented history.")
                    .font(.caption2).foregroundStyle(DeckLook.dim)
            }
            .refreshable { await reloadAsync() }
        }
    }
    private func ribbonValue(_ value:String,_ title:String,_ symbol:String)->some View {
        VStack(alignment:.leading,spacing:7) {
            Image(systemName:symbol).font(.caption).foregroundStyle(DeckLook.violet)
            Text(value).font(.system(size:19,weight:.bold,design:.rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
            Text(title).font(.system(size:9,weight:.heavy)).foregroundStyle(DeckLook.dim)
        }
        .frame(maxWidth:.infinity,alignment:.leading)
        .padding(13).deckPanel()
    }
    private var selectionControls: some View {
        VStack(alignment:.leading,spacing:10) {
            section("Download view", icon:"slider.horizontal.3")
            HStack(spacing:9) {
                Menu {
                    Picker("Release view",selection:$releaseRaw) {
                        ForEach(PulseReleaseMode.allCases) { value in
                            Text(value.label).tag(value.rawValue)
                        }
                    }
                } label: {
                    controlLabel(mode.label,"tag.fill")
                }
                Menu {
                    Picker("Assets",selection:$assetRaw) {
                        ForEach(PulseAsset.allCases) { value in
                            Text(value.label).tag(value.rawValue)
                        }
                    }
                } label: { controlLabel(asset.label,"archivebox.fill") }
            }
        }
    }
    private func controlLabel(_ label:String,_ icon:String) -> some View {
        HStack(spacing:6) {
            Image(systemName:icon)
            Text(label).lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength:0)
            Image(systemName:"chevron.down").font(.system(size:10))
        }
        .font(.system(size:12,weight:.bold))
        .foregroundStyle(DeckLook.cyan)
        .padding(.horizontal,11).padding(.vertical,13)
        .frame(maxWidth:.infinity)
        .deckPanel()
    }

    private var analyticsPage: some View {
        NavigationStack {
            pageScroll {
                header("Pulse Insights","Rankings, momentum and real growth")
                section("Analytics category",icon:"square.stack")
                Picker("Category",selection:$analytics) {
                    Text("🎮 Deck plugins").tag("deck")
                    Text("📁 Other projects").tag("other")
                }
                .pickerStyle(.segmented)
                selectionControls
                let group = store.watched.compactMap { store.loaded[$0.id] }
                    .filter { deck.isOther($0.id) == (analytics == "other") }
                let ranked = group.compactMap { stats -> (RepoStats,Int)? in
                    guard let count = stats.measure(mode,asset:asset,fallback:false).count else { return nil }
                    return (stats,count)
                }.sorted { $0.1 > $1.1 }
                HStack {
                    section("Leaderboard",icon:"trophy.fill")
                    Text("\(ranked.count) RANKED").font(.caption2.weight(.bold))
                        .foregroundStyle(DeckLook.dim)
                }
                if ranked.isEmpty {
                    blankCard("No rankings for this view","A beta-only project is unranked in strict Stable mode.")
                } else {
                    ForEach(ranked.indices,id:\.self) { index in
                        let entry = ranked[index]
                        HStack(spacing:13) {
                            Text(index == 0 ? "🥇" : index == 1 ? "🥈" : index == 2 ? "🥉" : "#\(index+1)")
                                .font(.system(size:25,weight:.bold,design:.rounded))
                                .frame(width:41)
                            VStack(alignment:.leading,spacing:5) {
                                Text(entry.0.identity.name).font(.headline).lineLimit(1)
                                Text(index == 0 ? "Leading this category" :
                                     "\((ranked[index-1].1 - entry.1 + 1).formatted()) to pass next")
                                    .font(.caption2).foregroundStyle(DeckLook.dim)
                            }
                            Spacer(minLength:5)
                            Text(compact(entry.1))
                                .font(.title3.bold()).monospacedDigit()
                                .foregroundStyle(index==0 ? DeckLook.gold : DeckLook.cyan)
                        }
                        .padding(14).deckPanel(index==0)
                    }
                }
                section("Momentum board",icon:"bolt.fill")
                let changes = group.map { (stats:$0, gain:deck.change($0.id,mode,asset)) }
                    .sorted { ($0.gain ?? Int.min) > ($1.gain ?? Int.min) }
                ForEach(changes.indices,id:\.self) { index in
                    let entry = changes[index]
                    HStack {
                        Image(systemName:"chart.line.uptrend.xyaxis")
                            .foregroundStyle(DeckLook.violet)
                        Text(entry.stats.identity.name)
                            .font(.subheadline.weight(.semibold)).lineLimit(1)
                        Spacer()
                        Text(entry.gain.map { $0 > 0 ? "+\($0.formatted())" : $0.formatted() } ?? "No comparison")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(entry.gain == nil ? DeckLook.dim : DeckLook.cyan)
                    }
                    .padding(14).deckPanel()
                }
                Text("Momentum compares two saved successful checks of the same release and asset view. No history is fabricated.")
                    .font(.caption2).foregroundStyle(DeckLook.dim)
            }
            .refreshable { await reloadAsync() }
        }
    }

    private var trophiesPage: some View {
        NavigationStack {
            pageScroll {
                header("Trophy Cabinet","35 Decky milestones per project")
                Text("Awards always use the verified all-release primary-package high-water mark, independent of selected charts.")
                    .font(.caption).foregroundStyle(DeckLook.dim)
                ForEach(store.watched) { repo in
                    let high = deck.trophyHigh[repo.id.lowercased()]
                    DeckTrophySummary(repo:repo,high:high)
                }
                section("All 35 milestone tiers",icon:"trophy.fill")
                ForEach(pulseTrophies.indices,id:\.self) { i in
                    let tier = pulseTrophies[i]
                    HStack {
                        Text(tier.emoji).font(.title3)
                        Text(tier.name).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(tier.target.formatted())
                            .font(.caption.weight(.medium)).monospacedDigit()
                            .foregroundStyle(DeckLook.dim)
                    }
                    .padding(.vertical,5)
                }
            }
        }
    }

    @AppStorage("pulse.mobile.inboxFilter") private var inboxFilter = "all"
    @State private var confirmClear = false
    private var activityPage: some View {
        NavigationStack {
            pageScroll {
                header("Notification Center","Native iPhone banners, sounds and history")
                HStack {
                    Text("\(deck.unread) unread")
                        .font(.subheadline.weight(.bold)).foregroundStyle(DeckLook.cyan)
                    Spacer()
                    Menu {
                        ForEach(["all","unread","downloads","release","stars","trophy"],id:\.self) { item in
                            Button(item.capitalized) { inboxFilter = item }
                        }
                    } label: {
                        Label(inboxFilter.capitalized,systemImage:"line.3.horizontal.decrease.circle")
                    }
                    Button("Read all") { deck.markAllRead() }
                        .disabled(deck.unread == 0)
                }
                .font(.subheadline).tint(DeckLook.cyan)
                let filtered = deck.inbox.filter { item in
                    inboxFilter=="all" || (inboxFilter=="unread" && !item.read) || item.type==inboxFilter
                }
                if filtered.isEmpty {
                    blankCard("Inbox is clear","After an initial baseline, fresh GitHub changes appear here. Notifications aren't retroactively invented.")
                } else {
                    ForEach(filtered) { event in
                        Button { deck.markRead(event.id) } label: {
                            HStack(alignment:.top,spacing:12) {
                                Image(systemName: eventIcon(event.type))
                                    .font(.title3)
                                    .foregroundStyle(event.type=="trophy" ? DeckLook.gold : DeckLook.cyan)
                                    .frame(width:34)
                                VStack(alignment:.leading,spacing:5) {
                                    HStack {
                                        Text(event.title).font(.subheadline.weight(.bold))
                                        Spacer(minLength:3)
                                        if !event.read { Circle().fill(DeckLook.cyan).frame(width:7,height:7) }
                                    }
                                    Text(event.details).font(.caption).foregroundStyle(DeckLook.dim)
                                    Text(event.createdAt.formatted(date:.abbreviated,time:.shortened))
                                        .font(.caption2).foregroundStyle(DeckLook.dim)
                                }
                            }
                            .padding(15)
                            .deckPanel(!event.read)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button(role:.destructive) { confirmClear = true } label: {
                    Label("Clear notification history",systemImage:"trash")
                }
                .font(.caption)
                .confirmationDialog("Clear all Repo Pulse notifications?",isPresented:$confirmClear) {
                    Button("Clear all",role:.destructive) { deck.clearInbox() }
                }
            }
        }
    }
    private func eventIcon(_ type:String)->String {
        switch type {
        case "downloads": return "arrow.down.circle.fill"
        case "release": return "shippingbox.fill"
        case "stars": return "star.fill"
        case "trophy": return "trophy.fill"
        default: return "bell.fill"
        }
    }

    @AppStorage("pulse.mobile.notifications") private var notifications = false
    @AppStorage("pulse.mobile.sound") private var sound = true
    private var settingsPage: some View {
        NavigationStack {
            pageScroll {
                header("Settings","One premium appearance. No theme switching.")
                HStack {
                    Image(systemName:"moon.stars.fill")
                        .font(.title2).foregroundStyle(DeckLook.violet)
                    VStack(alignment:.leading,spacing:4) {
                        Text("Midnight Neon").font(.headline)
                        Text("Permanent dark theme · cyan, blue and violet")
                            .font(.caption2).foregroundStyle(DeckLook.dim)
                    }
                    Spacer()
                    Image(systemName:"checkmark.circle.fill").foregroundStyle(DeckLook.cyan)
                }
                .padding(16).deckPanel(true)
                section("iPhone alerts",icon:"bell.badge.fill")
                Toggle(isOn:$notifications) {
                    Label("Native banners & notifications",systemImage:"bell.fill")
                }
                .onChange(of:notifications) { _, enabled in
                    if enabled { PulseNotifier.shared.requestPermission() }
                }
                Toggle(isOn:$sound) { Label("Notification sounds",systemImage:"speaker.wave.2.fill") }
                    .disabled(!notifications)
                Button {
                    if !notifications {
                        notifications = true
                        PulseNotifier.shared.requestPermission()
                    }
                    let test=PulseEvent(id:UUID(),repo:"Repo Pulse",type:"test",
                        title:"Repo Pulse · Test alert",
                        details:"Native iPhone banner and \(sound ? "sound" : "silent delivery") test.",
                        delta:0,createdAt:Date(),read:false)
                    PulseNotifier.shared.send(test)
                } label: {
                    Label("Send test iPhone notification",systemImage:"paperplane.fill")
                }
                .tint(DeckLook.cyan)
                Text("While open, Repo Pulse checks GitHub about every 15 minutes. New activity schedules local iPhone banners and sounds with permission. iOS suspends closed apps; always-on alerts require a separate APNs push backend.")
                    .font(.caption2).foregroundStyle(DeckLook.dim)
                section("Dashboard",icon:"slider.horizontal.3")
                Toggle("Show status ribbon",isOn:$showRibbon)
                selectionControls
                section("Project categories",icon:"square.stack")
                Text("The Home grid always shows every watched project. Analytics ranks Deck plugins separately from Other projects.")
                    .font(.caption2).foregroundStyle(DeckLook.dim)
                ForEach(store.watched) { repo in
                    HStack {
                        Text(repo.name).font(.subheadline.weight(.medium)).lineLimit(1)
                        Spacer()
                        Button(deck.isOther(repo.id) ? "Other" : "Deck") {
                            deck.toggleCategory(repo.id)
                        }
                        .buttonStyle(.bordered)
                        .tint(DeckLook.cyan)
                    }
                }
                section("Build & diagnostics",icon:"info.circle")
                VStack(alignment:.leading,spacing:9) {
                    Text("REPO PULSE • DECK PARITY")
                        .font(.subheadline.weight(.heavy)).foregroundStyle(DeckLook.cyan)
                    Text("Version \(Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? "?") · Build \(Bundle.main.object(forInfoDictionaryKey:"CFBundleVersion") as? String ?? "?")")
                    Text("Bundle: com.valentinebsaa.repopulse")
                    Text("Watching: \(store.watched.count) · Local saved alerts: \(deck.inbox.count)")
                    Text(store.refreshedAt.map { "Last refresh: \($0.formatted(date:.abbreviated,time:.shortened))" } ?? "Not synced")
                    Text("Asset downloads, not unique installs · GitHub public API · max 100 recent releases")
                        .foregroundStyle(DeckLook.dim)
                }
                .font(.caption).padding(16).frame(maxWidth:.infinity,alignment:.leading).deckPanel()
            }
        }
    }

    private func blankCard(_ title:String,_ message:String)->some View {
        VStack(spacing:9) {
            Image(systemName:"tray").font(.title).foregroundStyle(DeckLook.violet)
            Text(title).font(.headline)
            Text(message).font(.caption).foregroundStyle(DeckLook.dim).multilineTextAlignment(.center)
        }
        .padding(23).frame(maxWidth:.infinity).deckPanel()
    }
    private func pageScroll<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ZStack {
            DeckLook.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment:.leading,spacing:17) {
                    content()
                }
                .padding(.horizontal,17)
                .padding(.top,13)
                .padding(.bottom,28)
            }
        }
        .toolbar(.hidden,for:.navigationBar)
    }
}

private struct DeckRepoTile: View {
    let repo: WatchedRepo
    let stats: RepoStats?
    let asset: PulseAsset
    let mode: PulseReleaseMode
    let other: Bool
    let unread: Int
    let busy: Bool

    var body: some View {
        let measured = stats?.measure(mode,asset:asset)
        VStack(alignment:.leading,spacing:9) {
            HStack {
                Image("DeckCube")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(kindColor(repo.id))
                    .frame(width:42,height:42)
                    .background(kindColor(repo.id).opacity(0.12),in:RoundedRectangle(cornerRadius:12))
                Spacer()
                if unread > 0 {
                    Text("🔔 \(unread)").font(.system(size:10,weight:.heavy))
                        .foregroundStyle(DeckLook.gold)
                }
            }
            Text(repo.name)
                .font(.system(size:13,weight:.heavy,design:.rounded))
                .lineLimit(2).minimumScaleFactor(0.77)
                .frame(maxWidth:.infinity,alignment:.leading)
            Text(other ? "📁 Other project" : "🎮 Deck plugin")
                .font(.system(size:10,weight:.medium)).foregroundStyle(DeckLook.dim)
                .lineLimit(1).minimumScaleFactor(0.75)
            Spacer(minLength:0)
            Text(measured?.count.map(compact) ?? (busy ? "…" : "—"))
                .font(.system(size:25,weight:.black,design:.rounded))
                .monospacedDigit().foregroundStyle(kindColor(repo.id))
            HStack(spacing:3) {
                Text(measured?.note ?? "Awaiting sync")
                    .lineLimit(1).minimumScaleFactor(0.7)
                if measured?.fallback == true {
                    Image(systemName:"exclamationmark.circle").foregroundStyle(DeckLook.gold)
                }
            }
            .font(.system(size:10,weight:.semibold)).foregroundStyle(DeckLook.dim)
            if let tag = measured?.tag,tag != "all",!tag.isEmpty {
                Text(tag).font(.system(size:10,weight:.medium,design:.monospaced))
                    .lineLimit(1).foregroundStyle(DeckLook.dim)
            }
        }
        .padding(14)
        .frame(maxWidth:.infinity,alignment:.leading)
        .frame(height:199)
        .deckPanel()
        .overlay(RoundedRectangle(cornerRadius:20)
            .stroke(kindColor(repo.id).opacity(0.21),lineWidth:1))
    }
}

private struct DeckBriefing: View {
    let stats: [RepoStats]
    @ObservedObject var engine: DeckPulseEngine
    let asset: PulseAsset
    let mode: PulseReleaseMode
    var body: some View {
        VStack(alignment:.leading,spacing:14) {
            HStack {
                Image(systemName:"waveform.path.ecg").foregroundStyle(DeckLook.cyan)
                Text("DECK PULSE BRIEFING")
                    .font(.system(size:12,weight:.heavy,design:.rounded)).tracking(1.3)
                Spacer()
            }
            if stats.isEmpty {
                Text("Refreshing public project activity…")
                    .font(.caption).foregroundStyle(DeckLook.dim)
            }
            ForEach(stats.prefix(4)) { item in
                HStack(spacing:10) {
                    Circle().fill(kindColor(item.id)).frame(width:7,height:7)
                    Text(item.identity.name)
                        .font(.caption.weight(.semibold)).lineLimit(1)
                    Spacer()
                    Text(engine.change(item.id,mode,asset).map {
                        $0 > 0 ? "+\($0.formatted())" : $0.formatted()
                    } ?? "No comparison")
                        .font(.caption2.weight(.bold)).foregroundStyle(DeckLook.cyan)
                }
            }
            if let next = stats.compactMap({ item -> (String,PulseTrophy,Int)? in
                guard let high=engine.trophyHigh[item.id.lowercased()],
                      let tier=pulseTrophies.first(where:{$0.target>high}) else {return nil}
                return (item.identity.name,tier,tier.target-high)
            }).min(by:{$0.2<$1.2}) {
                Text("🏆 Next: \(next.0) · \(next.1.name), \(next.2.formatted()) primary-package downloads away")
                    .font(.caption2).foregroundStyle(DeckLook.gold)
            }
        }
        .padding(17).deckPanel(true)
    }
}

private struct DeckQuickGlance: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var engine: DeckPulseEngine
    let stats: [RepoStats]
    let asset: PulseAsset
    let mode: PulseReleaseMode
    let onSelect: (WatchedRepo) -> Void
    @State private var sort = "downloads"
    var body: some View {
        ZStack {
            DeckLook.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment:.leading,spacing:15) {
                    HStack {
                        Text("QUICK GLANCE").font(.title2.bold())
                        Spacer()
                        Button("Close") { dismiss() }
                    }
                    Picker("Sort",selection:$sort) {
                        Text("Most downloads").tag("downloads")
                        Text("Most growth").tag("growth")
                        Text("Watchlist").tag("custom")
                    }.pickerStyle(.segmented)
                    let sorted = sort=="custom" ? stats : stats.sorted { a,b in
                        if sort=="growth" { return (engine.change(a.id,mode,asset) ?? -1) > (engine.change(b.id,mode,asset) ?? -1) }
                        return (a.measure(mode,asset:asset).count ?? -1) > (b.measure(mode,asset:asset).count ?? -1)
                    }
                    ForEach(sorted) { item in
                        Button { onSelect(item.identity) } label: {
                            HStack(spacing:13) {
                                Image(systemName:"waveform.path.ecg.rectangle")
                                    .foregroundStyle(kindColor(item.id))
                                    .font(.title)
                                VStack(alignment:.leading,spacing:6) {
                                    Text(item.identity.name).font(.headline)
                                    Text(item.measure(mode,asset:asset).note)
                                        .font(.caption2).foregroundStyle(DeckLook.dim)
                                    Text(item.published.first?.tagName ?? "No release")
                                        .font(.caption2).foregroundStyle(DeckLook.dim)
                                }
                                Spacer()
                                VStack(alignment:.trailing,spacing:6) {
                                    Text(item.measure(mode,asset:asset).count.map(compact) ?? "—")
                                        .font(.title2.bold()).foregroundStyle(DeckLook.cyan)
                                    Text(engine.change(item.id,mode,asset).map { "+\($0.formatted())" } ?? "No growth data")
                                        .font(.caption2).foregroundStyle(DeckLook.dim)
                                }
                            }
                            .padding(16).deckPanel()
                        }.buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct DeckTrophySummary: View {
    let repo: WatchedRepo
    let high: Int?
    var body: some View {
        let earned = pulseTrophies.filter { tier in high.map { value in value >= tier.target } ?? false }
        let upcoming = pulseTrophies.first { tier in high.map { value in value < tier.target } ?? true }
        VStack(alignment:.leading,spacing:10) {
            HStack {
                Text(repo.name).font(.headline).lineLimit(1)
                Spacer()
                Text("\(earned.count)/35").font(.subheadline.bold()).foregroundStyle(DeckLook.gold)
            }
            if let last = earned.last {
                Text("\(last.emoji) \(last.name) unlocked")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(DeckLook.gold)
            }
            if let upcoming {
                Text("Next: \(upcoming.emoji) \(upcoming.name) · \(max(0,upcoming.target-(high ?? 0)).formatted()) to go")
                    .font(.caption).foregroundStyle(DeckLook.dim)
                ProgressView(value:Double(high ?? 0),total:Double(upcoming.target))
                    .tint(DeckLook.gold)
            } else {
                Text("Every milestone earned").foregroundStyle(DeckLook.gold).font(.caption)
            }
        }
        .padding(16).deckPanel()
    }
}

private struct DeckAddRepo: View {
    @EnvironmentObject private var store: PulseStore
    @Environment(\.dismiss) private var dismiss
    let onAdded: () -> Void
    @State private var text = "ValentineBSAA/"
    @State private var error: String?
    var body: some View {
        NavigationStack {
            ZStack {
                DeckLook.bg.ignoresSafeArea()
                VStack(alignment:.leading,spacing:16) {
                    Text("WATCH ANOTHER PROJECT")
                        .font(.system(size:12,weight:.heavy)).tracking(1.2)
                        .foregroundStyle(DeckLook.cyan)
                    TextField("owner/repository",text:$text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(15).deckPanel()
                    if let error {
                        Text(error).font(.caption).foregroundStyle(DeckLook.gold)
                    }
                    Button("Add to watchlist") {
                        if let warning=store.add(text) {error=warning}
                        else { dismiss(); onAdded() }
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }.padding(20)
            }
            .navigationTitle("Add repository")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .tint(DeckLook.cyan)
        .preferredColorScheme(.dark)
    }
}

private struct DeckRepoDetails: View {
    @EnvironmentObject private var engine: DeckPulseEngine
    @Environment(\.dismiss) private var dismiss
    let stats: RepoStats
    let asset: PulseAsset
    let mode: PulseReleaseMode
    @State private var chartStyle = "area"

    var body: some View {
        let metric = stats.measure(mode,asset:asset)
        let samples = engine.samples(stats.id,mode,asset).filter { $0.value != nil }
        return NavigationStack {
            ZStack {
                DeckLook.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment:.leading,spacing:18) {
                        HStack(spacing:11) {
                            Image("DeckCube").resizable().scaledToFit().frame(width:52,height:52)
                                .foregroundStyle(kindColor(stats.id))
                            VStack(alignment:.leading,spacing:5) {
                                Text(stats.identity.name).font(.title2.bold()).lineLimit(1).minimumScaleFactor(0.7)
                                Text(stats.identity.owner).font(.caption).foregroundStyle(DeckLook.dim)
                            }
                            Spacer()
                        }
                        VStack(alignment:.leading,spacing:9) {
                            Text("\(mode.label.uppercased()) · \(asset.label.uppercased())")
                                .font(.system(size:10,weight:.heavy)).tracking(1)
                                .foregroundStyle(DeckLook.dim)
                            Text(metric.count.map{ $0.formatted() } ?? "Not available")
                                .font(.system(size:37,weight:.black,design:.rounded))
                                .foregroundStyle(DeckLook.cyan).monospacedDigit()
                            Text(metric.fallback ? "\(metric.note) · \(metric.tag)" : metric.tag)
                                .font(.caption).foregroundStyle(metric.fallback ? DeckLook.gold : DeckLook.dim)
                        }
                        .padding(19).frame(maxWidth:.infinity,alignment:.leading).deckPanel(true)
                        HStack(spacing:10) {
                            detailStat("STARS",stats.repository.stargazersCount,"star.fill")
                            detailStat("FORKS",stats.repository.forksCount,"tuningfork")
                            detailStat("ISSUES",stats.repository.openIssuesCount,"exclamationmark.circle")
                        }
                        VStack(alignment:.leading,spacing:12) {
                            HStack {
                                Text("DOWNLOAD HISTORY")
                                    .font(.system(size:12,weight:.heavy)).tracking(1.2)
                                Spacer()
                                Menu {
                                    Picker("Chart style",selection:$chartStyle) {
                                        Text("Glowing Area").tag("area")
                                        Text("Smooth Line").tag("line")
                                        Text("Daily Bars").tag("bars")
                                        Text("Mixed").tag("mixed")
                                    }
                                } label: {
                                    Label(chartStyle.capitalized,systemImage:"chart.xyaxis.line")
                                        .font(.caption)
                                }
                            }
                            if samples.count < 2 {
                                Text("No history yet. Two comparable saved checks build the first real trend.")
                                    .font(.caption).foregroundStyle(DeckLook.dim)
                                    .frame(maxWidth:.infinity,minHeight:135)
                            } else {
                                Chart {
                                    ForEach(samples.indices,id:\.self) { index in
                                        let point=samples[index]
                                        if let count=point.value {
                                            if chartStyle=="bars" || chartStyle=="mixed" {
                                                BarMark(
                                                    x:.value("Observed",point.observedAt),
                                                    y:.value("Downloads",count)
                                                )
                                                .foregroundStyle(DeckLook.violet.opacity(0.55))
                                            }
                                            if chartStyle != "bars" {
                                                LineMark(
                                                    x:.value("Observed",point.observedAt),
                                                    y:.value("Downloads",count)
                                                )
                                                .foregroundStyle(DeckLook.cyan)
                                                .interpolationMethod(.catmullRom)
                                                if chartStyle=="area" {
                                                    AreaMark(
                                                        x:.value("Observed",point.observedAt),
                                                        y:.value("Downloads",count)
                                                    ).foregroundStyle(DeckLook.cyan.opacity(0.13))
                                                }
                                            }
                                        }
                                    }
                                }
                                .chartXAxis { AxisMarks(values:.automatic(desiredCount:3)) }
                                .frame(height:215)
                            }
                            Text("\(samples.count) real observations · no simulated history")
                                .font(.caption2).foregroundStyle(DeckLook.dim)
                        }
                        .padding(17).deckPanel()
                        HStack {
                            Text("RELEASE VERSIONS").font(.system(size:12,weight:.heavy)).tracking(1.3)
                            Spacer()
                            Text("\(stats.releases.count) scanned").font(.caption2).foregroundStyle(DeckLook.dim)
                        }
                        ForEach(Array(stats.published.prefix(50)),id:\.tagName) { release in
                            Link(destination:release.htmlUrl) {
                                HStack(spacing:10) {
                                    Image(systemName:release.preview ? "hammer.fill" : "shippingbox.fill")
                                        .foregroundStyle(release.preview ? DeckLook.violet : DeckLook.aqua)
                                    VStack(alignment:.leading,spacing:5) {
                                        Text(release.tagName)
                                            .font(.subheadline.weight(.bold)).foregroundStyle(.white)
                                        Text(release.preview ? "PREVIEW / BETA" : "STABLE")
                                            .font(.system(size:9,weight:.heavy)).foregroundStyle(DeckLook.dim)
                                    }
                                    Spacer()
                                    Text(release.count(asset,repo:stats.id).map { $0.formatted() } ?? "Unknown")
                                        .font(.subheadline.bold()).foregroundStyle(DeckLook.cyan)
                                        .monospacedDigit()
                                    Image(systemName:"arrow.up.right").font(.caption).foregroundStyle(DeckLook.dim)
                                }.padding(14).deckPanel()
                            }
                        }
                        Link(destination:stats.repository.htmlUrl) {
                            Label("Open GitHub repository",systemImage:"arrow.up.right.square")
                                .frame(maxWidth:.infinity)
                        }.buttonStyle(.borderedProminent)
                        Text("Primary packages apply the conservative Decky 0.8.3 ZIP rules. Unknown multi-package releases show unavailable counts rather than an invented zero.")
                            .font(.caption2).foregroundStyle(DeckLook.dim)
                    }.padding(18)
                }
            }
            .navigationTitle("Repository")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(DeckLook.cyan).preferredColorScheme(.dark)
    }
    private func detailStat(_ title:String,_ n:Int,_ icon:String)->some View {
        VStack(alignment:.leading,spacing:8) {
            Image(systemName:icon).foregroundStyle(DeckLook.violet)
            Text(compact(n)).font(.title3.bold()).monospacedDigit()
            Text(title).font(.system(size:9,weight:.semibold)).foregroundStyle(DeckLook.dim)
        }
        .frame(maxWidth:.infinity,alignment:.leading)
        .padding(12).deckPanel()
    }
}
