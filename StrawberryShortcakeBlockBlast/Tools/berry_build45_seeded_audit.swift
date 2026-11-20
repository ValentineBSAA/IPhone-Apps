import Foundation

/// Synthetic deterministic first-fit board play. This is not human telemetry,
/// and no pricing or gameplay rules are changed by running this CI-only audit.
@main
struct BerryBuild45SeededAudit {
    struct Profile {
        let name: String
        let side: Int
        let hard: Bool
        let cozy: Bool
        let adaptive: BerryDifficultyProfile?
        let samples: Int
        let rescue: String
    }
    struct Counters: Equatable {
        var placements = 0
        var lineClears = 0
        var lineBerries = 0
        var stalls = 0
        var freeRecoveries = 0
        var legalTraySlots = 0
        var blockedTraySlots = 0
        var peakOccupied = 0
        var endScore = 0
    }
    static func check(_ truth: @autoclosure () -> Bool, _ message: String) {
        guard truth() else { fatalError("FAIR PLAY AUDIT: " + message) }
    }
    static func firstFit(_ e: BerryEngine) -> (slot: Int, row: Int, col: Int)? {
        let start = e.sectionOrigin
        for slot in e.tray.indices {
            guard let piece = e.tray[slot] else { continue }
            for row in start.row..<(start.row + e.visibleSide) {
                for col in start.col..<(start.col + e.visibleSide) {
                    if e.canPlace(piece, row: row, col: col) {
                        return (slot, row, col)
                    }
                }
            }
        }
        return nil
    }
    static func occupied(_ e: BerryEngine) -> Int {
        var count = 0
        for row in 0..<e.visibleSide {
            for col in 0..<e.visibleSide {
                if e.visibleCell(row: row, col: col) != nil { count += 1 }
            }
        }
        return count
    }
    static func simulate(_ profile: Profile, seed: Int) throws -> Counters {
        var e = BerryEngine(side: profile.side, hard: profile.hard,
                            cozy: profile.cozy, seed: UInt64(seed))
        e.configureDifficulty(profile.adaptive, stage: 5)
        check(e.tray.count == 3, "opening tray has incorrect length")
        var result = Counters()
        let maxSteps = profile.side == 24 ? 35 : 55
        for _ in 0..<maxSteps {
            if !e.hasMove() {
                let recovered: Bool
                if profile.rescue == "endless" {
                    recovered = e.beginNextEndlessSeasonIfStuck()
                } else if profile.rescue == "blitz" {
                    recovered = e.beginNextTimedBoardIfStuck()
                } else {
                    recovered = false
                }
                if recovered {
                    result.freeRecoveries += 1
                    continue
                }
                result.stalls += 1
                break
            }
            let viable = e.tray.compactMap { $0 }
                .filter { e.hasPlacement(for: $0) }.count
            result.legalTraySlots += viable
            result.blockedTraySlots += 3 - viable
            result.peakOccupied = max(result.peakOccupied, occupied(e))
            guard let move = firstFit(e) else {
                fatalError("hasMove() returned true without a legal first-fit placement")
            }
            let oldMoves = e.moves
            let oldScore = e.score
            guard let event = e.place(slot: move.slot, row: move.row,
                                      col: move.col) else {
                fatalError("a known legal piece was rejected")
            }
            check(e.moves == oldMoves + 1, "placement did not advance moves")
            check(e.score >= oldScore, "placement caused decreasing score")
            check(e.tray.count == 3, "tray lost three-slot shape")
            result.placements += 1
            result.lineClears += event.clearedLines
            let berries = event.clearedLines > 0
                ? event.clearedLines * 3 + (event.streak > 1 ? event.streak : 0)
                    + (event.boardClear ? 25 : 0) : 0
            check(berries >= 0, "negative estimated line reward")
            result.lineBerries += berries
        }
        result.endScore = e.score
        if seed == 1 || seed == profile.samples {
            let restored = try JSONDecoder().decode(BerryEngine.self,
                                                   from: JSONEncoder().encode(e))
            check(restored.board == e.board && restored.score == e.score
                  && restored.moves == e.moves && restored.tray == e.tray,
                  "engine state did not survive save round-trip")
        }
        return result
    }
    static func main() throws {
        let profiles = [
            Profile(name: "Berry Classic 8x8", side: 8, hard: false,
                    cozy: false, adaptive: nil, samples: 300, rescue: "none"),
            Profile(name: "Sweet Endless 8x8", side: 8, hard: false,
                    cozy: false, adaptive: .endlessAdaptive, samples: 300, rescue: "endless"),
            Profile(name: "Sweet Endless 12x12", side: 12, hard: false,
                    cozy: false, adaptive: .endlessAdaptive, samples: 100, rescue: "endless"),
            Profile(name: "Sweet Endless 24x24", side: 24, hard: true,
                    cozy: false, adaptive: .endlessAdaptive, samples: 30, rescue: "endless"),
            Profile(name: "Berry Story 8x8", side: 8, hard: false,
                    cozy: false, adaptive: .storyProgressive, samples: 300, rescue: "none"),
            Profile(name: "Daily Harvest 8x8", side: 8, hard: false,
                    cozy: false, adaptive: nil, samples: 300, rescue: "none"),
            Profile(name: "Cozy Cottage 8x8", side: 8, hard: false,
                    cozy: true, adaptive: .cozyGentle, samples: 300, rescue: "none"),
            Profile(name: "Berry Blitz 8x8", side: 8, hard: false,
                    cozy: false, adaptive: nil, samples: 300, rescue: "blitz"),
            Profile(name: "Strawberry Nightmare 12x12", side: 12, hard: true,
                    cozy: false, adaptive: nil, samples: 100, rescue: "none")
        ]
        var records: [[String: Any]] = []
        var sessionCount = 0
        var placementCount = 0
        for profile in profiles {
            var totals = Counters()
            for seed in 1...profile.samples {
                let actual = try simulate(profile, seed: seed)
                if seed == 1 {
                    let repeatRun = try simulate(profile, seed: seed)
                    check(actual == repeatRun,
                          "same seed returned different results: " + profile.name)
                }
                totals.placements += actual.placements
                totals.lineClears += actual.lineClears
                totals.lineBerries += actual.lineBerries
                totals.stalls += actual.stalls
                totals.freeRecoveries += actual.freeRecoveries
                totals.legalTraySlots += actual.legalTraySlots
                totals.blockedTraySlots += actual.blockedTraySlots
                totals.peakOccupied = max(totals.peakOccupied, actual.peakOccupied)
                totals.endScore += actual.endScore
            }
            sessionCount += profile.samples
            placementCount += totals.placements
            records.append([
                "profile": profile.name,
                "board_side": profile.side,
                "seeded_sessions": profile.samples,
                "placements": totals.placements,
                "line_clears": totals.lineClears,
                "simulated_line_berries": totals.lineBerries,
                "unrescued_stalls": totals.stalls,
                "free_recoveries": totals.freeRecoveries,
                "legal_tray_slots_observed": totals.legalTraySlots,
                "blocked_tray_slots_observed": totals.blockedTraySlots,
                "max_occupied_visible_cells": totals.peakOccupied,
                "total_end_scores": totals.endScore
            ])
            print("FAIR PLAY: \(profile.name) • \(profile.samples) seeds, \(totals.placements) moves, \(totals.stalls) stalls, \(totals.freeRecoveries) recoveries")
        }
        check(sessionCount == 2030, "wrong number of seeded trials")
        check(placementCount > 4000, "too few valid placements")
        let report: [String: Any] = [
            "build": "4.5", "sample_count": sessionCount,
            "total_placements": placementCount,
            "method": "synthetic deterministic first-fit play, not human gameplay",
            "limitations": "No real timers, shop actions, quests, human strategy or player wallet simulation; balance and prices unchanged.",
            "mode_profiles": records
        ]
        if let file = ProcessInfo.processInfo.environment["BERRY_FAIR_PLAY_JSON"] {
            let data = try JSONSerialization.data(withJSONObject: report,
                                                   options: [.prettyPrinted, .sortedKeys])
            try data.write(to: URL(fileURLWithPath: file), options: .atomic)
        }
        print("PASS: \(sessionCount) seeded sessions, \(placementCount) placements")
    }
}
