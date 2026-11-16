import SwiftUI
import Charts

// MARK: - Repo Pulse visual system

enum PulseStyle {
    static let bg = Color(red: 0.035, green: 0.050, blue: 0.081)
    static let surface = Color(red: 0.080, green: 0.105, blue: 0.161)
    static let elevated = Color(red: 0.110, green: 0.142, blue: 0.205)
    static let teal = Color(red: 0.31, green: 0.91, blue: 0.83)
    static let blue = Color(red: 0.24, green: 0.64, blue: 0.94)
    static let muted = Color(red: 0.61, green: 0.68, blue: 0.77)
    static let stroke = Color.white.opacity(0.075)
    static let accentGradient = LinearGradient(
        colors: [teal, blue], startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

struct PulseDashboard: View {
    @EnvironmentObject private var store: PulseStore
    @State private var showAdd = false
    @State private var showAbout = false
    @State private var selected: WatchedRepo?

    private var totalStars: Int {
        store.loaded.values.reduce(0) { $0 + $1.repository.stargazersCount }
    }

    private var totalIssues: Int {
        store.loaded.values.reduce(0) { $0 + $1.repository.openIssuesCount }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PulseStyle.bg.ignoresSafeArea()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        topBar
                        hero
                        HStack(spacing: 12) {
                            compactMetric("TOTAL STARS", totalStars.formatted(), "star.fill")
                            compactMetric("OPEN ISSUES", totalIssues.formatted(), "exclamationmark.circle")
                        }

                        if let message = store.errorText {
                            HStack(alignment: .top, spacing: 11) {
                                Image(systemName: "wifi.exclamationmark")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Some repositories couldn't sync")
                                        .font(.subheadline.weight(.bold))
                                    Text(message)
                                        .font(.caption)
                                        .foregroundStyle(PulseStyle.muted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(PulseStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                        }

                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("YOUR WATCHLIST")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .tracking(2.2)
                                    .foregroundStyle(PulseStyle.muted)
                                Text("Repositories")
                                    .font(.system(size: 23, weight: .bold, design: .rounded))
                            }
                            Spacer()
                            Text("\(store.watched.count) TRACKED")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.7)
                                .foregroundStyle(PulseStyle.teal)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 8)
                                .background(PulseStyle.teal.opacity(0.10), in: Capsule())
                        }
                        .padding(.top, 1)

                        if store.watched.isEmpty {
                            emptyWatchlist
                        } else {
                            ForEach(store.visible) { repo in
                                Button {
                                    selected = repo
                                } label: {
                                    PremiumRepoCard(
                                        repo: repo,
                                        stats: store.loaded[repo.id],
                                        loading: store.busy
                                    )
                                }
                                .buttonStyle(PulsePressStyle())
                                .accessibilityLabel("View \(repo.id) details")
                            }
                            pager
                        }

                        Text("Downloads count GitHub release assets from up to 100 recent releases per repository. They are not unique installs.")
                            .font(.system(size: 11))
                            .foregroundStyle(PulseStyle.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .refreshable { await store.refresh() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAdd) {
                PremiumAddRepoSheet().environmentObject(store)
            }
            .sheet(isPresented: $showAbout) {
                PulseAboutSheet().environmentObject(store)
            }
            .sheet(item: $selected) { repo in
                if let stats = store.loaded[repo.id] {
                    PremiumRepoDetails(stats: stats) {
                        store.remove(repo)
                        selected = nil
                    }
                } else {
                    ContentUnavailableView("No statistics yet", systemImage: "wifi.slash",
                        description: Text("Pull down on the dashboard to refresh."))
                        .presentationDetents([.medium])
                        .preferredColorScheme(.dark)
                }
            }
            .task {
                if store.refreshedAt == nil { await store.refresh() }
            }
        }
        .tint(PulseStyle.teal)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(PulseStyle.accentGradient.opacity(0.18))
                    .frame(width: 49, height: 49)
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(PulseStyle.teal.opacity(0.40), lineWidth: 1)
                    .frame(width: 49, height: 49)
                Image(systemName: "waveform.path.ecg.rectangle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(PulseStyle.teal)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("REPO PULSE")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .tracking(2.8)
                    .foregroundStyle(.white)
                Text("iPhone command center")
                    .font(.caption)
                    .foregroundStyle(PulseStyle.muted)
            }
            Spacer(minLength: 4)
            actionButton("arrow.clockwise", "Refresh repositories") {
                Task { await store.refresh() }
            }
            .disabled(store.busy)
            actionButton("plus", "Add repository") { showAdd = true }
            actionButton("gearshape", "About and settings") { showAbout = true }
        }
    }

    private func actionButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PulseStyle.teal)
                .frame(width: 34, height: 38)
                .background(PulseStyle.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(PulseStyle.stroke))
        }
        .accessibilityLabel(label)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(spacing: 7) {
                Circle()
                    .fill(store.busy ? Color.orange : PulseStyle.teal)
                    .frame(width: 6, height: 6)
                Text(store.busy ? "SYNCING REPOSITORIES" : "LIVE GITHUB OVERVIEW")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(PulseStyle.teal)
                Spacer()
                Image(systemName: "waveform.path")
                    .font(.title3)
                    .foregroundStyle(PulseStyle.teal.opacity(0.7))
            }
            VStack(alignment: .leading, spacing: 7) {
                Text("Your projects.\nOne clear pulse.")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .tracking(-0.65)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(store.refreshedAt.map {
                    "Last synced \($0.formatted(date: .omitted, time: .shortened))"
                } ?? "Connect to your public GitHub activity")
                    .font(.caption)
                    .foregroundStyle(PulseStyle.muted)
            }
            Rectangle()
                .fill(Color.white.opacity(0.11))
                .frame(height: 1)
            HStack(alignment: .top, spacing: 12) {
                heroMetric(
                    value: "\(store.watched.count)",
                    label: "WATCHING",
                    symbol: "square.stack.3d.up"
                )
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 1, height: 57)
                heroMetric(
                    value: store.totalDownloads.formatted(),
                    label: "RELEASE DOWNLOADS",
                    symbol: "arrow.down.to.line.compact"
                )
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.105, green: 0.178, blue: 0.245),
                    Color(red: 0.070, green: 0.097, blue: 0.158),
                    PulseStyle.surface
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [PulseStyle.teal.opacity(0.48), Color.white.opacity(0.05)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func heroMetric(value: String, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.caption)
                Text(label).lineLimit(1).minimumScaleFactor(0.8)
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(PulseStyle.muted)
            Text(value)
                .font(.system(size: 27, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactMetric(_ name: String, _ value: String, _ symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PulseStyle.teal)
                .frame(width: 34, height: 34)
                .background(PulseStyle.teal.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(name)
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(PulseStyle.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PulseStyle.surface, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(PulseStyle.stroke))
    }

    private var emptyWatchlist: some View {
        VStack(spacing: 13) {
            Image(systemName: "shippingbox")
                .font(.system(size: 34))
                .foregroundStyle(PulseStyle.teal)
            Text("Your watchlist starts here")
                .font(.headline)
            Text("Add a public GitHub repository to see releases, downloads and activity.")
                .font(.subheadline)
                .foregroundStyle(PulseStyle.muted)
                .multilineTextAlignment(.center)
            Button("Add a repository") { showAdd = true }
                .buttonStyle(.borderedProminent)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(PulseStyle.surface, in: RoundedRectangle(cornerRadius: 22))
    }

    private var pager: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    store.page = max(0, store.page - 1)
                }
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .disabled(store.page == 0)
            Spacer()
            Text("PAGE \(store.page + 1) OF \(store.pageCount)")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(PulseStyle.muted)
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    store.page = min(store.pageCount - 1, store.page + 1)
                }
            } label: {
                Label("Next", systemImage: "chevron.right")
                    .labelStyle(.titleAndIcon)
            }
            .disabled(store.page == store.pageCount - 1)
        }
        .font(.subheadline.weight(.semibold))
        .buttonStyle(.plain)
        .foregroundStyle(PulseStyle.teal)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

private struct PulsePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private struct PremiumRepoCard: View {
    let repo: WatchedRepo
    let stats: RepoStats?
    let loading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 19))
                    .foregroundStyle(PulseStyle.teal)
                    .frame(width: 41, height: 41)
                    .background(PulseStyle.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 4) {
                    Text(repo.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(.white)
                    Text(repo.owner)
                        .font(.caption)
                        .foregroundStyle(PulseStyle.muted)
                }
                Spacer(minLength: 3)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PulseStyle.teal)
                    .frame(width: 28, height: 28)
                    .background(PulseStyle.teal.opacity(0.08), in: Circle())
            }

            if let stats {
                HStack(spacing: 17) {
                    Label(stats.repository.stargazersCount.formatted(), systemImage: "star.fill")
                    Label(stats.repository.forksCount.formatted(), systemImage: "tuningfork")
                    Label(stats.repository.openIssuesCount.formatted(), systemImage: "exclamationmark.circle")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(PulseStyle.muted)

                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)

                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RELEASE DOWNLOADS")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.8)
                            .foregroundStyle(PulseStyle.muted)
                        Text(stats.totalDownloads.formatted())
                            .font(.system(size: 31, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(PulseStyle.teal)
                    }
                    Spacer()
                    PulseMiniBars(releases: stats.releases)
                }
                HStack {
                    Label("Latest release", systemImage: "tag")
                        .foregroundStyle(PulseStyle.muted)
                    Spacer()
                    Text(stats.latest?.tagName ?? "No releases")
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .font(.system(size: 12, weight: .semibold))
            } else {
                HStack(spacing: 9) {
                    if loading { ProgressView().tint(PulseStyle.teal) }
                    else { Image(systemName: "arrow.clockwise").foregroundStyle(PulseStyle.teal) }
                    Text(loading ? "Fetching GitHub activity…" : "Refresh to load repository activity")
                        .font(.caption)
                        .foregroundStyle(PulseStyle.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            }
        }
        .padding(19)
        .background(PulseStyle.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [PulseStyle.teal.opacity(0.28), PulseStyle.stroke],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

private struct PulseMiniBars: View {
    let releases: [GitHubRelease]

    var body: some View {
        let items = Array(releases.prefix(9).reversed())
        let maxDownloads = max(1, items.map(\.downloads).max() ?? 1)
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(items.indices, id: \.self) { index in
                Capsule()
                    .fill(index == items.count - 1 ? PulseStyle.teal : PulseStyle.teal.opacity(0.26 + Double(index) * 0.055))
                    .frame(width: 6, height: CGFloat(max(7, Int(Double(items[index].downloads) / Double(maxDownloads) * 37))))
            }
        }
        .frame(height: 41, alignment: .bottom)
        .accessibilityLabel("Mini chart of recent release downloads")
    }
}

private struct PremiumAddRepoSheet: View {
    @EnvironmentObject private var store: PulseStore
    @Environment(\.dismiss) private var dismiss
    @State private var entry = "ValentineBSAA/"
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PulseStyle.bg.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 18) {
                    Image(systemName: "plus.app")
                        .font(.system(size: 37, weight: .light))
                        .foregroundStyle(PulseStyle.teal)
                    Text("Add to your watchlist")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    Text("Track a public repository's releases, asset downloads, stars and issues.")
                        .font(.subheadline)
                        .foregroundStyle(PulseStyle.muted)
                    TextField("owner/repository", text: $entry)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .padding(15)
                        .background(PulseStyle.surface, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(PulseStyle.teal.opacity(0.3)))
                    if let error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                    Button {
                        if let issue = store.add(entry) {
                            error = issue
                        } else {
                            dismiss()
                            Task { await store.refresh() }
                        }
                    } label: {
                        Text("Start watching")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Add Repository")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .tint(PulseStyle.teal)
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
    }
}

private struct PremiumRepoDetails: View {
    let stats: RepoStats
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PulseStyle.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .font(.title)
                                .foregroundStyle(PulseStyle.teal)
                                .frame(width: 58, height: 58)
                                .background(PulseStyle.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 17))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stats.identity.name)
                                    .font(.system(size: 23, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text(stats.identity.owner)
                                    .font(.subheadline)
                                    .foregroundStyle(PulseStyle.muted)
                            }
                            Spacer()
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TOTAL RELEASE DOWNLOADS")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1)
                                .foregroundStyle(PulseStyle.muted)
                            Text(stats.totalDownloads.formatted())
                                .font(.system(size: 43, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(PulseStyle.teal)
                            Text("Latest: \(stats.latest?.tagName ?? "No releases")")
                                .font(.caption)
                                .foregroundStyle(PulseStyle.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(PulseStyle.surface, in: RoundedRectangle(cornerRadius: 21))
                        HStack(spacing: 10) {
                            detailMetric("STARS", stats.repository.stargazersCount, "star.fill")
                            detailMetric("FORKS", stats.repository.forksCount, "tuningfork")
                            detailMetric("ISSUES", stats.repository.openIssuesCount, "exclamationmark.circle")
                        }
                        if !stats.releases.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Release performance")
                                    .font(.headline)
                                Chart(Array(stats.releases.prefix(10).reversed()), id: \.tagName) { release in
                                    BarMark(
                                        x: .value("Version", release.tagName),
                                        y: .value("Downloads", release.downloads)
                                    )
                                    .foregroundStyle(PulseStyle.accentGradient)
                                    .cornerRadius(4)
                                }
                                .frame(height: 210)
                                Text("Latest 10 releases · combined GitHub asset downloads")
                                    .font(.caption2)
                                    .foregroundStyle(PulseStyle.muted)
                            }
                            .padding(18)
                            .background(PulseStyle.surface, in: RoundedRectangle(cornerRadius: 21))

                            Text("RECENT RELEASES")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(PulseStyle.muted)
                            ForEach(Array(stats.releases.prefix(5)), id: \.tagName) { release in
                                Link(destination: release.htmlUrl) {
                                    HStack(spacing: 12) {
                                        Image(systemName: release.prerelease ? "hammer.fill" : "shippingbox.fill")
                                            .foregroundStyle(PulseStyle.teal)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(release.tagName)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.white)
                                            Text(release.prerelease ? "Pre-release" : "Release")
                                                .font(.caption)
                                                .foregroundStyle(PulseStyle.muted)
                                        }
                                        Spacer()
                                        Text(release.downloads.formatted())
                                            .font(.subheadline.weight(.bold))
                                            .monospacedDigit()
                                            .foregroundStyle(PulseStyle.teal)
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption)
                                            .foregroundStyle(PulseStyle.muted)
                                    }
                                    .padding(15)
                                    .background(PulseStyle.surface, in: RoundedRectangle(cornerRadius: 15))
                                }
                            }
                        }
                        Link(destination: stats.repository.htmlUrl) {
                            Label("Open repository on GitHub", systemImage: "arrow.up.right.square")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        Button(role: .destructive) {
                            onRemove()
                            dismiss()
                        } label: {
                            Label("Remove from watchlist", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(20)
                    .padding(.bottom, 18)
                }
            }
            .navigationTitle("Repository")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(PulseStyle.teal)
        .preferredColorScheme(.dark)
    }

    private func detailMetric(_ title: String, _ value: Int, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: symbol)
                .foregroundStyle(PulseStyle.teal)
            Text(value.formatted())
                .font(.title3.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(PulseStyle.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(PulseStyle.surface, in: RoundedRectangle(cornerRadius: 15))
    }
}

private struct PulseAboutSheet: View {
    @EnvironmentObject private var store: PulseStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PulseStyle.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Image(systemName: "waveform.path.ecg.rectangle")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(PulseStyle.teal)
                        Text("Repo Pulse Pocket")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Native GitHub activity, designed for your iPhone.")
                            .foregroundStyle(PulseStyle.muted)
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Manual refresh and pull to refresh", systemImage: "arrow.clockwise")
                            Label("Four repositories per page", systemImage: "square.grid.2x2")
                            Label("Watchlist saved on your iPhone", systemImage: "iphone")
                            Label("Public GitHub REST API, no account required", systemImage: "lock.shield")
                        }
                        .font(.subheadline)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PulseStyle.surface, in: RoundedRectangle(cornerRadius: 20))
                        Text("Tracked counts are GitHub release asset downloads from the latest 100 releases per repository. API rate limits apply. Background alerts are not enabled.")
                            .font(.caption)
                            .foregroundStyle(PulseStyle.muted)
                        Button("Refresh now") {
                            dismiss()
                            Task { await store.refresh() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(23)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(PulseStyle.teal)
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
    }
}
