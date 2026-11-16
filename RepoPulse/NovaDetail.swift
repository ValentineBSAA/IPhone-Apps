import SwiftUI
import Charts

// A pushed navigation screen, not a second dark modal stacked on the Home tab.
struct NovaRepoDetail: View {
    @EnvironmentObject private var engine: DeckPulseEngine
    @EnvironmentObject private var store: PulseStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("pulse.mobile.asset") private var assetRaw = "primary"
    @AppStorage("pulse.mobile.release") private var modeRaw = "all"
    @State private var style = "area"
    @State private var confirmRemoval = false
    let stats: RepoStats

    private var asset: PulseAsset { PulseAsset(rawValue: assetRaw) ?? .primary }
    private var mode: PulseReleaseMode { PulseReleaseMode(rawValue: modeRaw) ?? .all }
    private var metric: PulseMeasurement { stats.measure(mode, asset: asset) }
    private var accent: Color { Nova.tint(stats.id) }
    private var observations: [PulseReading] {
        engine.samples(stats.id, mode, asset).filter { $0.value != nil }
            .sorted { $0.observedAt < $1.observedAt }
    }
    private var hasActualChange: Bool {
        observations.count >= 3 && Set(observations.compactMap(\.value)).count > 1
    }

    var body: some View {
        ZStack {
            NovaBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    identity
                    hero
                    HStack(spacing: 10) {
                        smallStat("STARS", stats.repository.stargazersCount, "star.fill")
                        smallStat("FORKS", stats.repository.forksCount, "tuningfork")
                        smallStat("ISSUES", stats.repository.openIssuesCount, "exclamationmark.circle")
                    }
                    title("DOWNLOAD ANALYTICS", symbol: "chart.xyaxis.line")
                    historyPanel
                    if stats.published.count > 1 {
                        releaseComparison
                    }
                    trophyPanel
                    HStack {
                        title("RELEASE HISTORY", symbol: "tag.fill")
                        Spacer()
                        Text("\(stats.published.count) scanned")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Nova.muted)
                    }
                    ForEach(Array(stats.published.prefix(30)), id: \.tagName) { release in
                        releaseRow(release)
                    }
                    Link(destination: stats.repository.htmlUrl) {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open repository on GitHub")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Nova.cyan)
                        .padding(16)
                        .novaPanel()
                    }
                    Button(role: .destructive) { confirmRemoval = true } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove from watchlist")
                        }
                        .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    Text("Asset counts are GitHub downloads, not unique devices. Trends use only saved successful checks.")
                        .font(.system(size: 11))
                        .foregroundStyle(Nova.muted)
                        .padding(.bottom, 22)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
            }
        }
        .navigationTitle(stats.identity.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .tint(Nova.cyan)
        .confirmationDialog("Stop watching \(stats.identity.name)?",
                            isPresented: $confirmRemoval) {
            Button("Remove repository", role: .destructive) {
                store.remove(stats.identity)
                dismiss()
            }
        }
    }

    private var identity: some View {
        HStack(spacing: 13) {
            NovaEmblem(name: stats.identity.name, size: 62)
            VStack(alignment: .leading, spacing: 5) {
                Text(stats.identity.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(stats.identity.owner)
                    .font(.subheadline)
                    .foregroundStyle(Nova.muted)
            }
            Spacer(minLength: 0)
            Circle().fill(accent).frame(width: 7, height: 7)
                .shadow(color: accent.opacity(0.8), radius: 6)
        }
        .padding(.vertical, 9)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("DOWNLOAD COUNTER")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(Nova.muted)
                Spacer()
                Text(asset.short.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.7)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(accent.opacity(0.10), in: Capsule())
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(metric.count.map { $0.formatted() } ?? "—")
                    .font(.system(size: 43, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(.white)
                if let change = engine.change(stats.id, mode, asset), change > 0 {
                    Text("+\(change.formatted())")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Nova.cyan)
                }
            }
            Rectangle().fill(accent.opacity(0.45)).frame(height: 1)
            HStack(spacing: 8) {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(accent)
                Text(metric.note)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 4)
                Text(mode == .all ? "ALL VERSIONS" : metric.tag)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Nova.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            if metric.fallback {
                Label("Showing available release type instead", systemImage: "info.circle")
                    .font(.caption2).foregroundStyle(Nova.gold)
            }
            NovaMetricPicker()
        }
        .padding(20)
        .novaPanel(accent.opacity(0.85), radius: 24)
    }

    private func smallStat(_ title: String, _ n: Int, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Nova.violet)
            Text(n.formatted())
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(title)
                .font(.system(size: 9, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(Nova.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .novaPanel(radius: 18)
    }

    private func title(_ name: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(accent)
            Text(name).tracking(1.2)
        }
        .font(.system(size: 11, weight: .heavy, design: .rounded))
        .foregroundStyle(.white)
    }

    private var historyPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("Observed growth")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                if hasActualChange {
                    Menu {
                        Picker("Trend chart", selection: $style) {
                            Text("Area").tag("area")
                            Text("Line").tag("line")
                            Text("Bars").tag("bars")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.xyaxis.line")
                            Text(style.capitalized)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Nova.cyan)
                    }
                }
            }
            if hasActualChange {
                Chart {
                    ForEach(observations, id: \.observedAt) { point in
                        if let count = point.value {
                            if style == "bars" {
                                BarMark(x: .value("Time", point.observedAt),
                                        y: .value("Downloads", count))
                                .foregroundStyle(accent.opacity(0.72))
                                .cornerRadius(4)
                            } else {
                                LineMark(x: .value("Time", point.observedAt),
                                         y: .value("Downloads", count))
                                .interpolationMethod(.monotone)
                                .foregroundStyle(accent)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                                if style == "area" {
                                    AreaMark(x: .value("Time", point.observedAt),
                                             y: .value("Downloads", count))
                                    .interpolationMethod(.monotone)
                                    .foregroundStyle(
                                        LinearGradient(colors: [accent.opacity(0.25), .clear],
                                                       startPoint: .top, endPoint: .bottom))
                                }
                            }
                        }
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Nova.muted.opacity(0.25))
                        AxisValueLabel()
                            .foregroundStyle(Nova.muted)
                    }
                }
                .frame(height: 165)
                HStack {
                    Text(observations.first?.observedAt.formatted(date: .abbreviated, time: .shortened) ?? "")
                    Spacer()
                    Text(observations.last?.observedAt.formatted(date: .abbreviated, time: .shortened) ?? "")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Nova.muted)
            } else {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: observations.count < 2 ? "clock.arrow.circlepath" : "equal.circle")
                        .font(.system(size: 29, weight: .light))
                        .foregroundStyle(Nova.violet)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(observations.count < 2 ? "Building history" : "No movement yet")
                            .font(.subheadline.weight(.bold))
                        Text(observations.count < 2
                             ? "A real trend appears after several comparable refreshes."
                             : "\(observations.count) saved checks. Downloads haven't changed between them.")
                            .font(.caption)
                            .foregroundStyle(Nova.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(17)
        .novaPanel()
    }

    private var releaseComparison: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Release performance")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Text("REAL ASSET COUNTS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(Nova.muted)
            }
            let selected = Array(stats.published.prefix(6))
            let ceiling = max(1, selected.compactMap { $0.count(asset, repo: stats.id) }.max() ?? 1)
            ForEach(selected, id: \.tagName) { release in
                let count = release.count(asset, repo: stats.id)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 9) {
                        Text(release.tagName)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                        Spacer(minLength: 2)
                        Text(count.map { $0.formatted() } ?? "Unknown")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(accent)
                    }
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.08))
                            Capsule().fill(Nova.gradient)
                                .frame(width: max(3, proxy.size.width * CGFloat(count ?? 0) / CGFloat(ceiling)))
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(17)
        .novaPanel()
    }

    private var trophyPanel: some View {
        let high = engine.trophyHigh[stats.id.lowercased()]
        let earned = pulseTrophies.filter { tier in high.map { $0 >= tier.target } ?? false }
        let next = pulseTrophies.first { tier in high.map { $0 < tier.target } ?? true }
        return HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Nova.gold)
                .frame(width: 42, height: 42)
                .background(Nova.gold.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 5) {
                Text(earned.last.map { "\($0.name) earned" } ?? "Next milestone")
                    .font(.system(size: 13, weight: .bold))
                Text(next.map { "\($0.name) · \($0.target.formatted()) packages" }
                     ?? "All 35 milestones completed")
                    .font(.system(size: 11))
                    .foregroundStyle(Nova.muted)
            }
            Spacer(minLength: 0)
            Text("\(earned.count)/35")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Nova.gold)
        }
        .padding(14)
        .novaPanel(Nova.gold.opacity(0.3))
    }

    private func releaseRow(_ release: GitHubRelease) -> some View {
        Link(destination: release.htmlUrl) {
            HStack(spacing: 13) {
                Image(systemName: release.preview ? "hammer.fill" : "shippingbox.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(release.preview ? Nova.violet : accent)
                    .frame(width: 39, height: 39)
                    .background((release.preview ? Nova.violet : accent).opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 4) {
                    Text(release.tagName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(release.preview ? "PREVIEW / BETA" : "STABLE RELEASE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Nova.muted)
                }
                Spacer(minLength: 3)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(release.count(asset, repo: stats.id).map { $0.formatted() } ?? "—")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(accent)
                    Text("downloads")
                        .font(.system(size: 9))
                        .foregroundStyle(Nova.muted)
                }
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Nova.muted)
            }
            .padding(13)
            .novaPanel(radius: 15)
        }
        .buttonStyle(.plain)
    }
}

// Lightweight Quick Glance sheet, not a second navigation hierarchy.
struct NovaQuickGlance: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var engine: DeckPulseEngine
    let stats: [RepoStats]
    let asset: PulseAsset
    let mode: PulseReleaseMode
    @State private var sortMode = "downloads"

    private var ordered: [RepoStats] {
        switch sortMode {
        case "growth":
            return stats.sorted {
                (engine.change($0.id, mode, asset) ?? -1) > (engine.change($1.id, mode, asset) ?? -1)
            }
        case "name":
            return stats.sorted { $0.identity.name < $1.identity.name }
        default:
            return stats.sorted {
                ($0.measure(mode, asset: asset).count ?? -1) > ($1.measure(mode, asset: asset).count ?? -1)
            }
        }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                NovaBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        Picker("Sort projects", selection: $sortMode) {
                            Text("Downloads").tag("downloads")
                            Text("Growth").tag("growth")
                            Text("Name").tag("name")
                        }
                        .pickerStyle(.segmented)
                        if ordered.isEmpty {
                            NovaEmpty(title: "No statistics", message: "Refresh GitHub from Home first.", icon: "chart.bar")
                        }
                        ForEach(ordered) { item in
                            HStack(spacing: 13) {
                                NovaEmblem(name: item.identity.name, size: 46)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.identity.name)
                                        .font(.subheadline.weight(.bold))
                                        .lineLimit(1)
                                    Text(item.published.first?.tagName ?? "No release")
                                        .font(.caption)
                                        .foregroundStyle(Nova.muted)
                                }
                                Spacer(minLength: 4)
                                Text(item.measure(mode, asset: asset).count.map { $0.formatted() } ?? "—")
                                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(Nova.tint(item.id))
                            }
                            .padding(14)
                            .novaPanel()
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Quick glance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
        .tint(Nova.cyan)
        .preferredColorScheme(.dark)
    }
}
