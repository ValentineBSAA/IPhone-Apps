import SwiftUI
import Charts
import Foundation

// MARK: - GitHub models

struct WatchedRepo: Identifiable, Codable, Hashable {
    let owner: String
    let name: String
    var id: String { "\(owner)/\(name)" }

    init?(text: String) {
        let parts = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        let allowed = #"^[A-Za-z0-9_.-]+$"#
        guard parts.allSatisfy({
            String($0).range(of: allowed, options: .regularExpression) != nil
        }) else { return nil }
        owner = String(parts[0])
        name = String(parts[1])
    }
}

struct GitHubRepo: Decodable {
    let fullName: String
    let stargazersCount: Int
    let forksCount: Int
    let openIssuesCount: Int
    let htmlUrl: URL
}

struct ReleaseAsset: Decodable {
    let name: String
    let downloadCount: Int
}

struct GitHubRelease: Decodable {
    let tagName: String
    let prerelease: Bool
    let assets: [ReleaseAsset]
    let htmlUrl: URL
    var downloads: Int { assets.reduce(0) { $0 + $1.downloadCount } }
}

struct RepoStats: Identifiable {
    let identity: WatchedRepo
    let repository: GitHubRepo
    let releases: [GitHubRelease]
    var id: String { identity.id }
    var totalDownloads: Int { releases.reduce(0) { $0 + $1.downloads } }
    var latest: GitHubRelease? { releases.first }
}

// MARK: - GitHub public REST API

enum GitHubError: LocalizedError {
    case badResponse
    case status(Int)
    case rateLimit

    var errorDescription: String? {
        switch self {
        case .badResponse: return "Unexpected GitHub response."
        case .status(let code): return "GitHub HTTP \(code). Check the repository or retry."
        case .rateLimit: return "GitHub API rate limit reached. Try again later."
        }
    }
}

final class GitHubAPI {
    private let decoder: JSONDecoder = {
        let value = JSONDecoder()
        value.keyDecodingStrategy = .convertFromSnakeCase
        return value
    }()

    func load(_ repo: WatchedRepo) async throws -> RepoStats {
        async let info: GitHubRepo = get("repos/\(repo.owner)/\(repo.name)")
        async let releases: [GitHubRelease] =
            get("repos/\(repo.owner)/\(repo.name)/releases?per_page=100")
        return try await RepoStats(identity: repo, repository: info, releases: releases)
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: "https://api.github.com/\(path)") else {
            throw GitHubError.badResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("RepoPulse-iOS", forHTTPHeaderField: "User-Agent")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GitHubError.badResponse
        }
        if http.statusCode == 429 ||
            (http.statusCode == 403 && http.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0") {
            throw GitHubError.rateLimit
        }
        guard (200..<300).contains(http.statusCode) else {
            throw GitHubError.status(http.statusCode)
        }
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Observable app state

@MainActor
final class PulseStore: ObservableObject {
    @Published var watched: [WatchedRepo]
    @Published var loaded: [String: RepoStats] = [:]
    @Published var page = 0
    @Published var busy = false
    @Published var errorText: String?
    @Published var refreshedAt: Date?

    private let client = GitHubAPI()
    private let key = "pulse.watched"

    init() {
        let defaults = [
            "ValentineBSAA/Game-Theme-Music",
            "ValentineBSAA/TitleDeck",
            "ValentineBSAA/ResonaDeck",
            "ValentineBSAA/XNFS-Playlist-Builder-"
        ]
        watched = (UserDefaults.standard.stringArray(forKey: key) ?? defaults)
            .compactMap(WatchedRepo.init(text:))
    }

    var pageCount: Int { max(1, (watched.count + 3) / 4) }
    var visible: [WatchedRepo] { Array(watched.dropFirst(page * 4).prefix(4)) }
    var totalDownloads: Int { loaded.values.reduce(0) { $0 + $1.totalDownloads } }

    func add(_ input: String) -> String? {
        guard let repo = WatchedRepo(text: input) else {
            return "Use the format owner/repository."
        }
        guard !watched.contains(where: { $0.id.lowercased() == repo.id.lowercased() }) else {
            return "Already watching this repository."
        }
        watched.append(repo)
        page = (watched.count - 1) / 4
        persist()
        return nil
    }

    func remove(_ repo: WatchedRepo) {
        watched.removeAll { $0.id == repo.id }
        loaded[repo.id] = nil
        page = min(page, pageCount - 1)
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(watched.map(\.id), forKey: key)
    }

    func refresh() async {
        guard !busy else { return }
        busy = true
        errorText = nil
        defer { busy = false }
        var failures: [String] = []
        for repo in watched {
            do {
                loaded[repo.id] = try await client.load(repo)
            } catch {
                failures.append("\(repo.name): \(error.localizedDescription)")
            }
        }
        refreshedAt = Date()
        if !failures.isEmpty {
            errorText = failures.joined(separator: "\n")
        }
    }
}

// MARK: - App and interface

private enum Palette {
    static let bg = Color(red: 0.045, green: 0.055, blue: 0.083)
    static let panel = Color(red: 0.09, green: 0.11, blue: 0.17)
    static let teal = Color(red: 0.32, green: 0.88, blue: 0.82)
    static let muted = Color(red: 0.65, green: 0.69, blue: 0.77)
}

@main
struct RepoPulseApp: App {
    @StateObject private var store = PulseStore()

    var body: some Scene {
        WindowGroup {
            Dashboard()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

struct Dashboard: View {
    @EnvironmentObject private var store: PulseStore
    @State private var showAdd = false
    @State private var selected: WatchedRepo?

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 9) {
                            Image(systemName: "waveform.path.ecg.rectangle")
                                .foregroundStyle(Palette.teal)
                            Text("REPO PULSE")
                                .font(.caption.bold())
                                .tracking(3)
                                .foregroundStyle(Palette.teal)
                        }
                        Text("Your code, at a glance.")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text(store.busy ? "Refreshing..." :
                             store.refreshedAt.map { "Updated \($0.formatted(date: .omitted, time: .shortened))" } ?? "Public GitHub activity")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)

                        HStack(spacing: 12) {
                            summary("WATCHING", "\(store.watched.count)", "square.stack")
                            summary("TRACKED DOWNLOADS", store.totalDownloads.formatted(), "arrow.down.circle")
                        }

                        if let message = store.errorText {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(12)
                                .background(Palette.panel, in: RoundedRectangle(cornerRadius: 12))
                        }

                        Text("REPOSITORIES")
                            .font(.caption.bold())
                            .tracking(2)
                            .foregroundStyle(Palette.muted)

                        ForEach(store.visible) { repo in
                            Button {
                                selected = repo
                            } label: {
                                RepoCard(repo: repo, stats: store.loaded[repo.id])
                            }
                            .buttonStyle(.plain)
                        }

                        if store.watched.isEmpty {
                            ContentUnavailableView("Nothing watched yet",
                                systemImage: "tray",
                                description: Text("Add a public GitHub repository."))
                        }

                        HStack {
                            Button("Previous") { store.page = max(0, store.page - 1) }
                                .disabled(store.page == 0)
                            Spacer()
                            Text("\(store.page + 1) / \(store.pageCount)")
                                .foregroundStyle(Palette.muted)
                            Spacer()
                            Button("Next") { store.page = min(store.pageCount - 1, store.page + 1) }
                                .disabled(store.page == store.pageCount - 1)
                        }
                        .font(.subheadline.weight(.semibold))

                        Text("Counts include asset downloads from up to 100 recent GitHub releases per repository. Not unique installs.")
                            .font(.caption2)
                            .foregroundStyle(Palette.muted)
                    }
                    .padding(20)
                }
                .refreshable { await store.refresh() }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task { await store.refresh() }
                    } label: { Image(systemName: "arrow.clockwise") }
                    .disabled(store.busy)
                    .accessibilityLabel("Refresh")
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add repository")
                }
            }
            .sheet(isPresented: $showAdd) { AddRepoSheet().environmentObject(store) }
            .sheet(item: $selected) { repo in
                if let stats = store.loaded[repo.id] {
                    RepoDetails(stats: stats) {
                        store.remove(repo)
                        selected = nil
                    }
                } else {
                    Text("No data available. Refresh and try again.")
                        .padding()
                        .presentationDetents([.medium])
                }
            }
            .task {
                if store.refreshedAt == nil { await store.refresh() }
            }
        }
        .tint(Palette.teal)
    }

    private func summary(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon).foregroundStyle(Palette.teal)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct RepoCard: View {
    let repo: WatchedRepo
    let stats: RepoStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(repo.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(repo.owner)
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Palette.teal)
            }

            if let stats {
                HStack(spacing: 16) {
                    Label(stats.repository.stargazersCount.formatted(), systemImage: "star.fill")
                    Label(stats.repository.forksCount.formatted(), systemImage: "tuningfork")
                    Label(stats.repository.openIssuesCount.formatted(), systemImage: "exclamationmark.circle")
                }
                .font(.caption)
                .foregroundStyle(Palette.muted)
                Divider().overlay(.white.opacity(0.1))
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("RELEASE DOWNLOADS")
                            .font(.system(size: 10))
                            .foregroundStyle(Palette.muted)
                        Text(stats.totalDownloads.formatted())
                            .font(.title2.bold())
                            .foregroundStyle(Palette.teal)
                    }
                    Spacer()
                    Text(stats.latest?.tagName ?? "No releases")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            } else {
                Text("No statistics loaded")
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
            }
        }
        .padding(18)
        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21)
            .stroke(Palette.teal.opacity(0.13), lineWidth: 1))
    }
}

private struct AddRepoSheet: View {
    @EnvironmentObject private var store: PulseStore
    @Environment(\.dismiss) private var dismiss
    @State private var entry = "ValentineBSAA/"
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("owner/repository", text: $entry)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                } header: {
                    Text("Public GitHub repository")
                } footer: {
                    Text("Only public repositories are supported in this prototype.")
                }
                if let error { Text(error).foregroundStyle(.orange) }
            }
            .navigationTitle("Add Repository")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        if let issue = store.add(entry) { error = issue }
                        else {
                            dismiss()
                            Task { await store.refresh() }
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct RepoDetails: View {
    let stats: RepoStats
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(stats.repository.fullName)
                        .font(.title2.bold())

                    Text("Tracked release-asset downloads")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                    Text(stats.totalDownloads.formatted())
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.teal)

                    if let latest = stats.latest {
                        Text("Latest: \(latest.tagName) · \(latest.downloads.formatted()) downloads")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }

                    if !stats.releases.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent releases").font(.headline)
                            Chart(Array(stats.releases.prefix(10).reversed()), id: \.tagName) { release in
                                BarMark(
                                    x: .value("Release", release.tagName),
                                    y: .value("Downloads", release.downloads)
                                )
                                .foregroundStyle(Palette.teal.gradient)
                            }
                            .frame(height: 215)
                            Text("Up to 10 latest releases. Cumulative asset downloads per release.")
                                .font(.caption2)
                                .foregroundStyle(Palette.muted)
                        }
                        .padding()
                        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 18))
                    }

                    Link(destination: stats.repository.htmlUrl) {
                        Label("Open on GitHub", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        onRemove()
                        dismiss()
                    } label: {
                        Label("Stop watching", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .background(Palette.bg)
            .navigationTitle("Repository")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Palette.teal)
        .preferredColorScheme(.dark)
    }
}
