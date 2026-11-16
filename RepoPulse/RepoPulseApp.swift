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

// MARK: - Native app entry point (existing bundle ID stays unchanged in project.yml)

@main
struct RepoPulseApp: App {
    @StateObject private var store = PulseStore()

    var body: some Scene {
        WindowGroup {
            PulseDashboard()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
