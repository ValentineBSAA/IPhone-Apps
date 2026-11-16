import SwiftUI
import UserNotifications
import Foundation

// Decky 0.8.3 parity: selectable release/asset metrics, real snapshots,
// category separation, primary-package filtering and durable events.

enum PulseAsset: String, CaseIterable, Identifiable {
    case primary, zip, all
    var id: String { rawValue }
    var label: String {
        switch self {
        case .primary: return "Primary packages"
        case .zip: return "All ZIPs"
        case .all: return "All files"
        }
    }
    var short: String {
        switch self {
        case .primary: return "Packages"
        case .zip: return "ZIPs"
        case .all: return "All files"
        }
    }
}

enum PulseReleaseMode: String, CaseIterable, Identifiable {
    case all, latest, stable, preview
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return "All releases"
        case .latest: return "Newest release"
        case .stable: return "Latest stable"
        case .preview: return "Latest preview"
        }
    }
}

struct PulseMeasurement {
    let count: Int?
    let tag: String
    let note: String
    let fallback: Bool
}

extension GitHubRelease {
    var preview: Bool {
        prerelease || tagName.range(of: #"(?i)(?:^|[-._ ])(?:alpha|beta|preview|rc)(?:[-._ 0-9]|$)"#,
                                     options: .regularExpression) != nil
    }
    var date: Date? {
        guard let publishedAt else { return nil }
        return ISO8601DateFormatter().date(from: publishedAt)
    }
    var zipDownloads: Int {
        assets.filter { $0.name.lowercased().hasSuffix(".zip") }
            .reduce(0) { $0 + max(0, $1.downloadCount) }
    }
    // Mirrors Decky v0.8.3 primary_package_count. Unknown multi-ZIP bundles
    // return nil rather than falsely being displayed as zero downloads.
    func primaryDownloads(repo: String) -> Int? {
        let support = #"(?:^|[._\-\s])(?:screenshots?|screen[._\-]?shots?|gallery|images?|docs?|documentation|source|src|repository[._\-]?source|developer|dev|debug|symbols?|tests?|testing|samples?|examples?|backups?|logs?|readme|changelog|license|checksums?|hashes?)(?:[._\-\s]|$)"#
        var eligible = assets.filter {
            $0.name.lowercased().hasSuffix(".zip")
                && $0.name.range(of: support, options: .regularExpression) == nil
        }
        if eligible.isEmpty { return 0 }
        let publicPackages = eligible.filter {
            $0.name.range(of: #"(?:^|[-_. ])public(?:[-_. ]|\.zip$)"#, options: [.regularExpression, .caseInsensitive]) != nil
        }
        if !publicPackages.isEmpty { eligible = publicPackages }
        let normalizedRepo = repo.components(separatedBy: "/").last.map {
            $0.lowercased().filter { $0.isLetter || $0.isNumber }
        } ?? ""
        let matched = eligible.filter {
            $0.name.lowercased().filter { $0.isLetter || $0.isNumber }.hasPrefix(normalizedRepo)
        }
        if !matched.isEmpty { eligible = matched }
        else if eligible.count != 1 { return nil }
        return eligible.reduce(0) { $0 + max(0, $1.downloadCount) }
    }
    func count(_ asset: PulseAsset, repo: String) -> Int? {
        switch asset {
        case .all: return downloads
        case .zip: return zipDownloads
        case .primary: return primaryDownloads(repo: repo)
        }
    }
}

extension RepoStats {
    var published: [GitHubRelease] {
        releases.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }
    func measure(_ mode: PulseReleaseMode, asset: PulseAsset,
                 fallback: Bool = true) -> PulseMeasurement {
        let items = published
        if mode == .all {
            let counts = items.map { $0.count(asset, repo: identity.id) }
            if counts.contains(where: { $0 == nil }) {
                return PulseMeasurement(count: nil, tag: "all", note: "Package total unavailable", fallback: false)
            }
            return PulseMeasurement(count: counts.compactMap { $0 }.reduce(0,+),
                                    tag: "all", note: "All releases", fallback: false)
        }
        var selected: GitHubRelease? = nil
        var label = mode.label
        var fallbackUsed = false
        switch mode {
        case .all: break
        case .latest: selected = items.first
        case .stable: selected = items.first { !$0.preview }
        case .preview: selected = items.first { $0.preview }
        }
        if selected == nil && fallback {
            if mode == .stable { selected = items.first { $0.preview }; label = "Beta only"; fallbackUsed = true }
            if mode == .preview { selected = items.first { !$0.preview }; label = "Stable only"; fallbackUsed = true }
        }
        guard let release = selected else {
            return PulseMeasurement(count: nil, tag: "", note: "No \(mode.label.lowercased())", fallback: false)
        }
        return PulseMeasurement(count: release.count(asset, repo: identity.id),
                                tag: release.tagName, note: label, fallback: fallbackUsed)
    }
}

struct PulseReading: Codable {
    let value: Int?
    let tag: String
    let observedAt: Date
}
struct PulseEvent: Identifiable, Codable {
    let id: UUID
    let repo: String
    let type: String
    let title: String
    let details: String
    let delta: Int
    let createdAt: Date
    var read: Bool
}
struct PulseTrophy {
    let target: Int
    let name: String
    let emoji: String
}
let pulseTrophies: [PulseTrophy] = [
    .init(target:10,name:"Bronze",emoji:"🥉"),
    .init(target:25,name:"Silver",emoji:"🥈"),
    .init(target:50,name:"Gold",emoji:"🥇"),
    .init(target:100,name:"Platinum",emoji:"🏆"),
    .init(target:250,name:"Diamond",emoji:"💎"),
    .init(target:500,name:"Master",emoji:"🔥"),
    .init(target:750,name:"Grandmaster",emoji:"⚡"),
    .init(target:1000,name:"Legend",emoji:"👑"),
    .init(target:1500,name:"Mythic",emoji:"🦅"),
    .init(target:2500,name:"Star",emoji:"🌟"),
    .init(target:5000,name:"Galaxy",emoji:"🌌"),
    .init(target:7500,name:"Supernova",emoji:"☄️"),
    .init(target:10000,name:"Hall of Fame",emoji:"🏛️"),
    .init(target:25000,name:"Monument",emoji:"🗿"),
    .init(target:50000,name:"Constellation",emoji:"✨"),
    .init(target:75000,name:"Celestial",emoji:"🌠"),
    .init(target:100000,name:"Titan",emoji:"🪐"),
    .init(target:250000,name:"Eternal",emoji:"♾️"),
    .init(target:500000,name:"Immortal",emoji:"🦋"),
    .init(target:750000,name:"Ascendant",emoji:"🔱"),
    .init(target:1000000,name:"Million Club",emoji:"💠"),
    .init(target:2500000,name:"Nebula",emoji:"🌈"),
    .init(target:5000000,name:"Cosmic",emoji:"🌍"),
    .init(target:10000000,name:"Cosmic Royalty",emoji:"🛸"),
    .init(target:25000000,name:"Universe",emoji:"🌐"),
    .init(target:50000000,name:"Infinite Star",emoji:"💫"),
    .init(target:100000000,name:"Centurion",emoji:"🏅"),
    .init(target:250000000,name:"Galactic Crown",emoji:"👑"),
    .init(target:500000000,name:"Transcendent",emoji:"🌌"),
    .init(target:1000000000,name:"Billion Club",emoji:"🏆"),
    .init(target:2500000000,name:"Deep Space",emoji:"🚀"),
    .init(target:5000000000,name:"Beyond",emoji:"🌟"),
    .init(target:10000000000,name:"Decabillion",emoji:"💎"),
    .init(target:100000000000,name:"Hundred Billion",emoji:"🪐"),
    .init(target:1000000000000,name:"Trillion Club",emoji:"🌌")
]

final class PulseNotifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PulseNotifier()
    func configure() {
        UserDefaults.standard.register(defaults: [
            "pulse.mobile.sound": true,
            "pulse.mobile.notifications": false
        ])
        UNUserNotificationCenter.current().delegate = self
    }
    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    func send(_ event: PulseEvent) {
        guard UserDefaults.standard.bool(forKey: "pulse.mobile.notifications") else { return }
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.details
        if UserDefaults.standard.bool(forKey: "pulse.mobile.sound") { content.sound = .default }
        let request = UNNotificationRequest(
            identifier: "repopulse.\(event.id.uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request) { _ in }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        if UserDefaults.standard.bool(forKey: "pulse.mobile.notifications") {
            if UserDefaults.standard.bool(forKey: "pulse.mobile.sound") {
                completionHandler([.banner, .list, .sound])
            } else {
                completionHandler([.banner, .list])
            }
        } else { completionHandler([]) }
    }
}

@MainActor
final class DeckPulseEngine: ObservableObject {
    @Published var readings: [String: PulseReading] = [:]
    @Published var history: [String: [PulseReading]] = [:]
    @Published var inbox: [PulseEvent] = []
    @Published var trophyHigh: [String: Int] = [:]
    @Published var otherRepos: [String] = []
    @Published var active = false

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        readings = restore("pulse.mobile.readings", fallback: [:])
        history = restore("pulse.mobile.history", fallback: [:])
        inbox = restore("pulse.mobile.inbox", fallback: [])
        trophyHigh = restore("pulse.mobile.trophyHigh", fallback: [:])
        otherRepos = restore("pulse.mobile.otherRepos", fallback: ["ValentineBSAA/XNFS-Playlist-Builder-"])
    }
    private func restore<T: Decodable>(_ key: String, fallback: T) -> T {
        guard let data = defaults.data(forKey: key),
              let result = try? decoder.decode(T.self, from: data) else { return fallback }
        return result
    }
    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? encoder.encode(value) { defaults.set(data, forKey: key) }
    }

    var unread: Int { inbox.filter { !$0.read }.count }
    func unreadFor(_ repo: String) -> Int { inbox.filter { $0.repo == repo && !$0.read }.count }
    func isOther(_ repo: String) -> Bool {
        otherRepos.contains(where: { $0.caseInsensitiveCompare(repo) == .orderedSame })
    }
    func toggleCategory(_ repo: String) {
        if isOther(repo) { otherRepos.removeAll { $0.caseInsensitiveCompare(repo) == .orderedSame } }
        else { otherRepos.append(repo) }
        save(otherRepos, key: "pulse.mobile.otherRepos")
    }
    func markAllRead() {
        for i in inbox.indices { inbox[i].read = true }
        save(inbox, key: "pulse.mobile.inbox")
    }
    func markRead(_ id: UUID) {
        if let index = inbox.firstIndex(where: { $0.id == id }) {
            inbox[index].read = true
            save(inbox, key: "pulse.mobile.inbox")
        }
    }
    func clearInbox() { inbox.removeAll(); save(inbox, key: "pulse.mobile.inbox") }

    func readingKey(_ repo: String, _ mode: PulseReleaseMode, _ asset: PulseAsset) -> String {
        "\(repo.lowercased())|\(mode.rawValue)|\(asset.rawValue)"
    }
    func samples(_ repo: String, _ mode: PulseReleaseMode, _ asset: PulseAsset) -> [PulseReading] {
        history[readingKey(repo, mode, asset)] ?? []
    }
    func change(_ repo: String, _ mode: PulseReleaseMode, _ asset: PulseAsset) -> Int? {
        let points = samples(repo, mode, asset).suffix(2)
        guard points.count == 2,
              let first = points.first,
              let last = points.last,
              first.tag == last.tag, let old = first.value, let new = last.value else { return nil }
        return new - old
    }

    func ingest(_ store: PulseStore) {
        guard !active else { return }
        active = true
        defer { active = false }
        let asset = PulseAsset(rawValue: defaults.string(forKey: "pulse.mobile.asset") ?? "") ?? .primary
        let mode = PulseReleaseMode(rawValue: defaults.string(forKey: "pulse.mobile.release") ?? "") ?? .all
        let now = Date()
        var emitted: [PulseEvent] = []
        for repo in store.watched {
            guard let stats = store.loaded[repo.id] else { continue }
            for m in PulseReleaseMode.allCases {
                for f in PulseAsset.allCases {
                    let key = readingKey(repo.id, m, f)
                    let measure = stats.measure(m, asset: f)
                    let fresh = PulseReading(value: measure.count, tag: measure.tag, observedAt: now)
                    if let previous = readings[key], key == readingKey(repo.id, mode, asset),
                       let a = previous.value, let b = fresh.value, previous.tag == fresh.tag, b > a {
                        emitted.append(PulseEvent(
                            id: UUID(), repo: repo.id, type: "downloads",
                            title: "Repo Pulse · \(repo.name)",
                            details: "+\((b - a).formatted()) \(f.short) downloads · \(m.label)",
                            delta: b - a, createdAt: now, read: false))
                    }
                    if let previous = readings[key], previous.value == fresh.value,
                       now.timeIntervalSince(previous.observedAt) < 60 { continue }
                    readings[key] = fresh
                    var recent = history[key] ?? []
                    recent.append(fresh)
                    if recent.count > 90 { recent = Array(recent.suffix(90)) }
                    history[key] = recent
                }
            }
            let repoKey = repo.id.lowercased()
            let starKey = "\(repoKey)|stars"
            let stars = stats.repository.stargazersCount
            if let lastStars = readings[starKey]?.value, stars > lastStars {
                emitted.append(PulseEvent(id:UUID(), repo:repo.id, type:"stars",
                    title:"Repo Pulse · New star", details:"\(repo.name) gained \(stars - lastStars) star(s)",
                    delta:stars-lastStars,createdAt:now,read:false))
            }
            readings[starKey] = PulseReading(value: stars, tag:"stars", observedAt:now)
            let releaseKey = "\(repoKey)|published"
            let recent = stats.published.first?.tagName ?? ""
            if let previous = readings[releaseKey], !previous.tag.isEmpty,
                recent != previous.tag, !recent.isEmpty {
                emitted.append(PulseEvent(id:UUID(), repo:repo.id, type:"release",
                    title:"Repo Pulse · New release",
                    details:"\(repo.name): \(recent)", delta:0, createdAt:now, read:false))
            }
            readings[releaseKey] = PulseReading(value:nil,tag:recent,observedAt:now)
            // Trophy high-water mark is independent of the selected download view.
            if let packages = stats.measure(.all, asset:.primary, fallback:false).count {
                let previous = trophyHigh[repoKey]
                let high = max(previous ?? 0, packages)
                trophyHigh[repoKey] = high
                if let previous {
                    let awarded = pulseTrophies.filter { $0.target > previous && $0.target <= high }
                    if let award = awarded.last {
                        emitted.append(PulseEvent(id:UUID(), repo:repo.id, type:"trophy",
                            title:"\(award.emoji) \(award.name) unlocked!",
                            details:"\(repo.name) passed \(award.target.formatted()) primary-package downloads",
                            delta:0, createdAt:now, read:false))
                    }
                }
            }
        }
        if !emitted.isEmpty {
            inbox.insert(contentsOf: emitted, at: 0)
            if inbox.count > 200 { inbox = Array(inbox.prefix(200)) }
            for alert in emitted { PulseNotifier.shared.send(alert) }
        }
        save(readings, key: "pulse.mobile.readings")
        save(history, key: "pulse.mobile.history")
        save(inbox, key: "pulse.mobile.inbox")
        save(trophyHigh, key: "pulse.mobile.trophyHigh")
    }
}
