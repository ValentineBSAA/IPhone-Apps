import Foundation

/// Only Endless, Story and Cozy may opt into adaptive selection.
enum BerryDifficultyProfile: String, Codable {
    case endlessAdaptive
    case storyProgressive
    case cozyGentle
}

/// One hand slot per refill is reweighted at most; other two remain original.
/// Keeps Classic, Daily, Blitz and Nightmare score/rules untouched.
enum BerryDifficultyPolicy {
    static func preferredShapes(from pool: [[BerryPoint]],
                                profile: BerryDifficultyProfile?,
                                occupancy: Double, dryMoves: Int,
                                stage: Int, slot: Int,
                                isLegal: ([BerryPoint]) -> Bool) -> [[BerryPoint]] {
        guard let profile, slot == 0, !pool.isEmpty else { return [] }
        let legal = pool.filter(isLegal)
        guard !legal.isEmpty else { return [] }
        let selected: [[BerryPoint]]
        switch profile {
        case .endlessAdaptive:
            if occupancy >= 0.63 || (occupancy >= 0.51 && dryMoves >= 4) {
                selected = legal.filter { (2...4).contains($0.count) }
            } else if occupancy <= 0.22 && stage >= 2 {
                selected = legal.filter { (4...6).contains($0.count) }
            } else { return [] }
        case .storyProgressive:
            if stage <= 2 && occupancy >= 0.40 {
                selected = legal.filter { (1...3).contains($0.count) }
            } else if stage >= 5 && occupancy <= 0.45 {
                selected = legal.filter { (4...6).contains($0.count) }
            } else { return [] }
        case .cozyGentle:
            if occupancy >= 0.48 {
                selected = legal.filter { (1...2).contains($0.count) }
            } else { return [] }
        }
        return selected
    }
}
