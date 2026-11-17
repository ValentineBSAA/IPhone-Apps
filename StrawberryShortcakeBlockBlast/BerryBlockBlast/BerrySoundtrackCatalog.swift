import Foundation

/// Data is loaded from the supplied soundtrack catalog, not from fabricated track names.
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

enum BerryMusicMode: String, CaseIterable, Identifiable {
    case cozy = "Cozy Berry"
    case balanced = "Balanced Berry"
    case arcade = "Arcade Berry"

    var id: String { rawValue }
    var calmChance: Double {
        switch self {
        case .cozy: return 0.90
        case .balanced: return 0.70
        case .arcade: return 0.40
        }
    }
    var shortLabel: String {
        switch self {
        case .cozy: return "Cozy"
        case .balanced: return "Balanced"
        case .arcade: return "Arcade"
        }
    }
    var description: String {
        switch self {
        case .cozy: return "90% relaxing · 10% upbeat"
        case .balanced: return "70% relaxing · 30% upbeat"
        case .arcade: return "40% relaxing · 60% upbeat"
        }
    }
}

/// Pure playlist selection. The menu and results themes are never selected as
/// random gameplay songs. All sampled probabilities apply to genre, not titles.
enum BerryPlaylistPicker {
    static func gameplayIndices(_ tracks: [BerrySoundtrackTrack]) -> [Int] {
        tracks.indices.filter { ["gameplay", "high-score"].contains(tracks[$0].role) }
    }

    static func choose(tracks: [BerrySoundtrackTrack], lastIndex: Int?,
                       history: [Int], mode: BerryMusicMode, shuffle: Bool,
                       draw: Double = Double.random(in: 0..<1)) -> Int? {
        let eligible = gameplayIndices(tracks)
        guard !eligible.isEmpty else { return nil }
        if !shuffle {
            guard let current = lastIndex, let index = eligible.firstIndex(of: current) else {
                return eligible.first
            }
            return eligible[(index + 1) % eligible.count]
        }

        let preferCalm = draw < mode.calmChance
        let group = eligible.filter { tracks[$0].mood == (preferCalm ? "calm" : "upbeat") }
        // If no tracks exist in a mood group, fall back without breaking playback.
        let pool = group.isEmpty ? eligible : group
        let withoutLast = pool.filter { $0 != lastIndex }
        let viable = withoutLast.isEmpty ? pool : withoutLast
        let recent = Set(history.suffix(2))
        let withoutRecent = viable.filter { !recent.contains($0) }
        return (withoutRecent.isEmpty ? viable : withoutRecent).randomElement()
    }
}
