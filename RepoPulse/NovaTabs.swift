import SwiftUI
import UserNotifications
import UIKit

private struct NovaSectionTitle: View {
    let text: String
    let symbol: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(Nova.cyan)
            Text(text.uppercased()).tracking(1.25)
        }
        .font(.system(size: 11, weight: .heavy, design: .rounded))
    }
}

private struct NovaTabHeader: View {
    let eyebrow: String
    let heading: String
    let subtitle: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(eyebrow.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(Nova.cyan)
                Spacer()
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Nova.violet)
            }
            Text(heading)
                .font(.system(size: 31, weight: .heavy, design: .rounded))
                .tracking(-0.6)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Nova.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

struct NovaInsights: View {
    @EnvironmentObject private var store: PulseStore
    @EnvironmentObject private var engine: DeckPulseEngine
    @AppStorage("pulse.mobile.analytics") private var category = "deck"
    @AppStorage("pulse.mobile.asset") private var assetRaw = "primary"
    @AppStorage("pulse.mobile.release") private var modeRaw = "all"
    private var asset: PulseAsset { PulseAsset(rawValue: assetRaw) ?? .primary }
    private var mode: PulseReleaseMode { PulseReleaseMode(rawValue: modeRaw) ?? .all }
    private var members: [RepoStats] {
        store.watched.compactMap { store.loaded[$0.id] }
            .filter { engine.isOther($0.id) == (category == "other") }
    }
    private var ranked: [RepoStats] {
        members.filter { $0.measure(mode, asset: asset, fallback: false).count != nil }
            .sorted {
                ($0.measure(mode, asset: asset, fallback: false).count ?? 0) >
                ($1.measure(mode, asset: asset, fallback: false).count ?? 0)
            }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                NovaBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 19) {
                        NovaTabHeader(eyebrow: "REPO PULSE / ANALYTICS",
                                      heading: "The leaderboard.",
                                      subtitle: "Compare your projects without mixing stable releases, previews, or supporting files.",
                                      symbol: "chart.bar.xaxis")
                        Picker("Group", selection: $category) {
                            Text("Deck plugins").tag("deck")
                            Text("Other projects").tag("other")
                        }
                        .pickerStyle(.segmented)
                        NovaMetricPicker()
                        overview
                        NovaSectionTitle(text: "Leaderboard", symbol: "trophy.fill")
                        if ranked.isEmpty {
                            NovaEmpty(title: "No comparable releases",
                                      message: "Projects without verified counts are not given a fake rank.",
                                      icon: "chart.bar")
                        }
                        ForEach(ranked.indices, id: \.self) { position in
                            leaderRow(ranked[position], position: position)
                        }
                        NovaSectionTitle(text: "Momentum", symbol: "bolt.fill")
                        if members.isEmpty {
                            NovaEmpty(title: "No projects here",
                                      message: "Assign a watched project to this category under Settings.",
                                      icon: "square.stack")
                        }
                        ForEach(members) { item in
                            HStack(spacing: 12) {
                                NovaEmblem(name: item.identity.name, size: 40)
                                Text(item.identity.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                if let delta = engine.change(item.id, mode, asset) {
                                    Text(delta > 0 ? "+\(delta.formatted())" : delta.formatted())
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(delta > 0 ? Nova.cyan : Nova.muted)
                                } else {
                                    Text("NO TREND YET")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Nova.muted)
                                }
                            }
                            .padding(13)
                            .novaPanel()
                        }
                        Text("Ranking and momentum use live GitHub counts and saved snapshots. Beta-only repos remain unranked when Stable is selected.")
                            .font(.caption2)
                            .foregroundStyle(Nova.muted)
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 18)
                }
                .refreshable {
                    await store.refresh()
                    engine.ingest(store)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    private var overview: some View {
        HStack(spacing: 10) {
            summary("PROJECTS", "\(members.count)", "square.stack")
            summary("DOWNLOADS",
                    ranked.compactMap { $0.measure(mode, asset: asset).count }.reduce(0, +).formatted(),
                    "arrow.down.circle")
            summary("WITH DATA", "\(ranked.count)", "checkmark.circle")
        }
    }
    private func summary(_ label: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).foregroundStyle(Nova.violet)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Nova.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .novaPanel(radius: 16)
    }

    private func leaderRow(_ item: RepoStats, position: Int) -> some View {
        let count = item.measure(mode, asset: asset, fallback: false).count ?? 0
        let best = max(1, ranked.first?.measure(mode, asset: asset, fallback: false).count ?? 1)
        let delta = position == 0 ? nil :
            (ranked[position - 1].measure(mode, asset: asset, fallback: false).count ?? 0) - count + 1
        return VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 11) {
                Text(position == 0 ? "🥇" : position == 1 ? "🥈" : position == 2 ? "🥉" : "#\(position + 1)")
                    .font(.system(size: 23, weight: .heavy, design: .rounded))
                    .frame(width: 38, alignment: .center)
                NovaEmblem(name: item.identity.name, size: 43)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.identity.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(position == 0 ? "TOP PROJECT" : "\(delta ?? 0) to take the next spot")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Nova.muted)
                }
                Spacer(minLength: 2)
                Text(count.formatted())
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(position == 0 ? Nova.gold : Nova.cyan)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule().fill(position == 0 ? Nova.gold : Nova.cyan)
                        .frame(width: max(3, geometry.size.width * CGFloat(count) / CGFloat(best)))
                }
            }
            .frame(height: 5)
        }
        .padding(14)
        .novaPanel(position == 0 ? Nova.gold.opacity(0.65) : Nova.stroke, radius: 18)
    }
}

struct NovaTrophies: View {
    @EnvironmentObject private var store: PulseStore
    @EnvironmentObject private var engine: DeckPulseEngine
    var body: some View {
        NavigationStack {
            ZStack {
                NovaBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        NovaTabHeader(eyebrow: "REPO PULSE / ACHIEVEMENTS",
                                      heading: "Trophy cabinet.",
                                      subtitle: "35 milestones per project. Only verified primary-package downloads count.",
                                      symbol: "trophy.fill")
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Nova.gold)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(awards) TOTAL AWARDS")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                Text("From \(store.watched.count) tracked repositories")
                                    .font(.caption)
                                    .foregroundStyle(Nova.muted)
                            }
                            Spacer()
                        }
                        .padding(18)
                        .novaPanel(Nova.gold.opacity(0.5))
                        NovaSectionTitle(text: "By project", symbol: "square.stack.3d.up")
                        ForEach(store.watched) { repo in
                            trophyCard(repo)
                        }
                        NovaSectionTitle(text: "Milestone collection", symbol: "sparkles")
                        VStack(spacing: 0) {
                            ForEach(pulseTrophies.indices, id: \.self) { index in
                                let tier = pulseTrophies[index]
                                HStack(spacing: 11) {
                                    Text(tier.emoji)
                                        .font(.title3)
                                        .frame(width: 35)
                                    Text(tier.name)
                                        .font(.system(size: 13, weight: .semibold))
                                    Spacer()
                                    Text(tier.target.formatted())
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundStyle(Nova.muted)
                                }
                                .padding(.vertical, 10)
                                if index < pulseTrophies.count - 1 {
                                    Divider().overlay(Nova.stroke)
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                        .novaPanel()
                        Text("Milestones keep their high-water marks, so a later change in metric view doesn't revoke awards.")
                            .font(.caption2)
                            .foregroundStyle(Nova.muted)
                            .padding(.bottom, 22)
                    }
                    .padding(.horizontal, 18)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    private var awards: Int {
        store.watched.reduce(0) { tally, repo in
            let high = engine.trophyHigh[repo.id.lowercased()] ?? 0
            return tally + pulseTrophies.filter { high >= $0.target }.count
        }
    }
    private func trophyCard(_ repo: WatchedRepo) -> some View {
        let high = engine.trophyHigh[repo.id.lowercased()] ?? 0
        let earned = pulseTrophies.filter { high >= $0.target }
        let next = pulseTrophies.first { high < $0.target }
        return VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 12) {
                NovaEmblem(name: repo.name, size: 46)
                VStack(alignment: .leading, spacing: 4) {
                    Text(repo.name)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                    Text(earned.last.map { "\($0.emoji) \($0.name) unlocked" }
                         ?? "Next award: \(next?.name ?? "None")")
                        .font(.caption)
                        .foregroundStyle(Nova.muted)
                }
                Spacer(minLength: 2)
                Text("\(earned.count) / 35")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Nova.gold)
            }
            if let next {
                let previous = earned.last?.target ?? 0
                ProgressView(value: Double(max(0, high - previous)),
                             total: Double(max(1, next.target - previous)))
                    .tint(Nova.gold)
                HStack {
                    Text("NEXT: \(next.emoji) \(next.name)")
                    Spacer()
                    Text("\(max(0, next.target - high).formatted()) TO GO")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Nova.muted)
            } else {
                Label("All milestones complete", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(Nova.gold)
            }
        }
        .padding(15)
        .novaPanel(Nova.tint(repo.id).opacity(0.3))
    }
}

struct NovaActivity: View {
    @EnvironmentObject private var engine: DeckPulseEngine
    @State private var mode = "All"
    @State private var confirm = false
    private let tabs = ["All", "Unread", "Downloads", "Releases", "Stars", "Trophies"]
    private var events: [PulseEvent] {
        engine.inbox.filter { entry in
            switch mode {
            case "Unread": return !entry.read
            case "Downloads": return entry.type == "downloads"
            case "Releases": return entry.type == "release"
            case "Stars": return entry.type == "stars"
            case "Trophies": return entry.type == "trophy"
            default: return true
            }
        }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                NovaBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 19) {
                        NovaTabHeader(eyebrow: "REPO PULSE / ACTIVITY",
                                      heading: "Stay in the loop.",
                                      subtitle: "A persistent local inbox for real changes detected during GitHub checks.",
                                      symbol: "bell.badge.fill")
                        HStack(spacing: 12) {
                            Image(systemName: "bell.and.waves.left.and.right.fill")
                                .font(.system(size: 25))
                                .foregroundStyle(Nova.cyan)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(engine.unread) UNREAD")
                                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                                Text("\(engine.inbox.count) saved events")
                                    .font(.caption).foregroundStyle(Nova.muted)
                            }
                            Spacer()
                            Button("Read all") { engine.markAllRead() }
                                .font(.caption.weight(.semibold))
                                .disabled(engine.unread == 0)
                        }
                        .padding(17).novaPanel(Nova.cyan.opacity(0.4))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tabs, id: \.self) { item in
                                    Button { mode = item } label: {
                                        Text(item)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(mode == item ? Nova.bg : Nova.muted)
                                            .padding(.horizontal, 13)
                                            .padding(.vertical, 9)
                                            .background(mode == item ? Nova.cyan : Nova.surface,
                                                        in: Capsule())
                                    }
                                }
                            }
                        }
                        if events.isEmpty {
                            NovaEmpty(title: "No activity to show",
                                      message: "After a baseline refresh, new releases, download changes and achievements will appear here.",
                                      icon: "bell.slash")
                        }
                        ForEach(events) { item in
                            Button {
                                engine.markRead(item.id)
                            } label: { activityRow(item) }
                            .buttonStyle(.plain)
                        }
                        if !engine.inbox.isEmpty {
                            Button(role: .destructive) { confirm = true } label: {
                                Label("Clear all saved activity", systemImage: "trash")
                                    .font(.caption.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                        }
                        Text("Native iOS banners and sounds can be enabled in Settings. Live push alerts while the app is closed require a separately configured APNs service.")
                            .font(.caption2).foregroundStyle(Nova.muted)
                            .padding(.bottom, 22)
                    }
                    .padding(.horizontal, 18)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("Clear notification history?", isPresented: $confirm) {
                Button("Clear history", role: .destructive) { engine.clearInbox() }
            }
        }
    }
    private func activityRow(_ event: PulseEvent) -> some View {
        HStack(alignment: .top, spacing: 13) {
            let isTrophy = event.type == "trophy"
            Image(systemName: symbol(event.type))
                .font(.system(size: 18))
                .foregroundStyle(isTrophy ? Nova.gold : Nova.cyan)
                .frame(width: 44, height: 44)
                .background((isTrophy ? Nova.gold : Nova.cyan).opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.title)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 4)
                    if !event.read {
                        Circle().fill(Nova.cyan).frame(width: 7, height: 7)
                    }
                }
                Text(event.details)
                    .font(.system(size: 12))
                    .foregroundStyle(Nova.muted)
                    .multilineTextAlignment(.leading)
                Text(event.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Nova.muted)
            }
        }
        .padding(14)
        .novaPanel(event.read ? Nova.stroke : Nova.cyan.opacity(0.6), radius: 18)
    }
    private func symbol(_ category: String) -> String {
        switch category {
        case "downloads": return "arrow.down.circle.fill"
        case "release": return "shippingbox.fill"
        case "stars": return "star.fill"
        case "trophy": return "trophy.fill"
        default: return "bell.fill"
        }
    }
}

struct NovaSettings: View {
    @EnvironmentObject private var store: PulseStore
    @EnvironmentObject private var engine: DeckPulseEngine
    @AppStorage("pulse.mobile.notifications") private var notifications = false
    @AppStorage("pulse.mobile.sound") private var sound = true
    @AppStorage("pulse.mobile.analytics") private var category = "deck"
    private var version: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "?"
    }
    private var build: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "?"
    }
    var body: some View {
        NavigationStack {
            ZStack {
                NovaBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 19) {
                        NovaTabHeader(eyebrow: "REPO PULSE / PREFERENCES",
                                      heading: "Your control room.",
                                      subtitle: "One carefully designed midnight interface. No light or dark theme switching.",
                                      symbol: "gearshape.fill")
                        HStack(spacing: 12) {
                            Image("RepoPulseMark")
                                .resizable().scaledToFit().frame(width: 53, height: 53)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 5) {
                                Text("MIDNIGHT EDITION")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .tracking(1)
                                Text("Fixed deep navy · cyan · violet")
                                    .font(.caption).foregroundStyle(Nova.muted)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Nova.cyan)
                        }
                        .padding(15).novaPanel(Nova.violet.opacity(0.4))
                        NovaSectionTitle(text: "Native iPhone alerts", symbol: "bell.badge.fill")
                        VStack(spacing: 17) {
                            Toggle(isOn: $notifications) {
                                Label("Banners and alerts", systemImage: "bell.fill")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .onChange(of: notifications) { _, active in
                                if active { PulseNotifier.shared.requestPermission() }
                            }
                            Divider().overlay(Nova.stroke)
                            Toggle(isOn: $sound) {
                                Label("System notification sound", systemImage: "speaker.wave.2.fill")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .disabled(!notifications)
                            Button {
                                if !notifications {
                                    notifications = true
                                    PulseNotifier.shared.requestPermission()
                                }
                                let event = PulseEvent(
                                    id: UUID(), repo: "Repo Pulse", type: "test",
                                    title: "Repo Pulse · Notification test",
                                    details: "Your native iPhone notification system is connected.",
                                    delta: 0, createdAt: Date(), read: false)
                                PulseNotifier.shared.send(event)
                            } label: {
                                Label("Send test notification", systemImage: "paperplane.fill")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Nova.cyan)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label("Open iPhone notification settings", systemImage: "arrow.up.right.square")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Nova.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(17).novaPanel()
                        Text("Local alerts appear when Repo Pulse detects a real change while checking GitHub. iOS may suspend checks while the app is closed; instant background push requires a separate APNs service.")
                            .font(.caption2)
                            .foregroundStyle(Nova.muted)
                        NovaSectionTitle(text: "Download calculation", symbol: "slider.horizontal.3")
                        NovaMetricPicker()
                        NovaSectionTitle(text: "Project categories", symbol: "square.stack.3d.up")
                        VStack(alignment: .leading, spacing: 13) {
                            Text("Set which projects compete on the Deck plugin leaderboard.")
                                .font(.caption).foregroundStyle(Nova.muted)
                            ForEach(store.watched) { repo in
                                HStack(spacing: 10) {
                                    NovaEmblem(name: repo.name, size: 34)
                                    Text(repo.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .lineLimit(1)
                                    Spacer(minLength: 2)
                                    Button(engine.isOther(repo.id) ? "Other" : "Deck") {
                                        engine.toggleCategory(repo.id)
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(engine.isOther(repo.id) ? Nova.violet : Nova.cyan)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(Nova.raised, in: Capsule())
                                }
                            }
                        }
                        .padding(15).novaPanel()
                        NovaSectionTitle(text: "Build information", symbol: "info.circle")
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Repo Pulse for iPhone")
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Text("v\(version) · b\(build)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Nova.cyan)
                            }
                            HStack {
                                Text("Bundle")
                                Spacer()
                                Text("com.valentinebsaa.repopulse")
                                    .font(.system(size: 10, design: .monospaced))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .foregroundStyle(Nova.muted)
                            HStack {
                                Text("Watched")
                                Spacer()
                                Text("\(store.watched.count) repositories")
                            }
                            .foregroundStyle(Nova.muted)
                            HStack {
                                Text("Saved notifications")
                                Spacer()
                                Text("\(engine.inbox.count) events")
                            }
                            .foregroundStyle(Nova.muted)
                            Text("Counts use GitHub release assets from up to 100 recent releases per project. API rate limits apply.")
                                .font(.caption2).foregroundStyle(Nova.muted)
                        }
                        .font(.system(size: 12))
                        .padding(16).novaPanel()
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 18)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
