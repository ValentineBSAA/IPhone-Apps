import Foundation

struct BerrySoundtrackCatalog: Decodable {
    let version: Int
    let tracks: [BerrySoundtrackTrack]
}

struct BerrySoundtrackTrack: Codable, Identifiable, Equatable {
    let id: Int
    let file: String
    let title: String
    let mood: String
    let role: String
    let sha256: String
    let bytes: Int
    let durationSeconds: Double
}

struct BerryEffectsCatalog: Decodable {
    let version: Int
    let effects: [BerryEffectTrack]
}

struct BerryEffectTrack: Decodable, Identifiable {
    let id: Int
    let file: String
    let title: String
    let eventKey: String
    let sha256: String
    let bytes: Int
    let durationSeconds: Double
}

enum BerryMusicMode: String, CaseIterable, Identifiable {
    case cozy = "Cozy Berry", balanced = "Balanced Berry", arcade = "Arcade Berry"
    var id: String { rawValue }
    var calmChance: Double {
        switch self { case .cozy: 0.90; case .balanced: 0.70; case .arcade: 0.40 }
    }
    var shortLabel: String {
        switch self { case .cozy: "Cozy"; case .balanced: "Balanced"; case .arcade: "Arcade" }
    }
    var description: String {
        switch self {
        case .cozy: "90% relaxing · 10% upbeat"
        case .balanced: "70% relaxing · 30% upbeat"
        case .arcade: "40% relaxing · 60% upbeat"
        }
    }
}

enum BerryPlaylistKind { case menu, gameplay, results, blitz }

enum BerryPlaylistPicker {
    static func indices(_ tracks: [BerrySoundtrackTrack], for kind: BerryPlaylistKind) -> [Int] {
        let role: String
        switch kind {
        case .menu: role = "menu"
        case .gameplay: role = "gameplay"
        case .results: role = "results"
        case .blitz: role = "blitz"
        }
        return tracks.indices.filter { tracks[$0].role == role ||
            (kind == .gameplay && tracks[$0].role == "high-score") }
    }

    static func gameplayIndices(_ tracks: [BerrySoundtrackTrack]) -> [Int] {
        indices(tracks, for: .gameplay)
    }

    static func choose(tracks: [BerrySoundtrackTrack], lastIndex: Int?, history: [Int],
                       mode: BerryMusicMode, shuffle: Bool, draw: Double = Double.random(in: 0..<1),
                       playlist: BerryPlaylistKind = .gameplay) -> Int? {
        let eligible = indices(tracks, for: playlist)
        guard !eligible.isEmpty else { return nil }
        if !shuffle {
            guard let lastIndex, let n = eligible.firstIndex(of: lastIndex) else { return eligible.first }
            return eligible[(n + 1) % eligible.count]
        }
        let filtered: [Int]
        if playlist == .gameplay {
            let mood = draw < mode.calmChance ? "calm" : "upbeat"
            let group = eligible.filter { tracks[$0].mood == mood }
            filtered = group.isEmpty ? eligible : group
        } else { filtered = eligible }
        let noLast = filtered.filter { $0 != lastIndex }
        let firstPool = noLast.isEmpty ? filtered : noLast
        let recent = Set(history.suffix(2))
        let noRecent = firstPool.filter { !recent.contains($0) }
        return (noRecent.isEmpty ? firstPool : noRecent).randomElement()
    }
}
