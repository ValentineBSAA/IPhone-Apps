import Foundation

/// Independent cross-platform regression: no Xcode or macOS runner needed.
@main
struct BerryEngineCIRegression {
    static func check(_ ok: @autoclosure () -> Bool, _ message: String) {
        guard ok() else { fatalError("BERRY ENGINE REGRESSION: " + message) }
    }
    static func firstLegal(_ engine: BerryEngine) -> (Int, Int, Int)? {
        for slot in engine.tray.indices {
            guard let piece = engine.tray[slot] else { continue }
            for row in 0..<engine.side {
                for col in 0..<engine.side where engine.canPlace(piece, row: row, col: col) {
                    return (slot, row, col)
                }
            }
        }
        return nil
    }
    static func testPolicy() {
        let shapes = (1...7).map { n in
            (0..<n).map { BerryPoint(row: 0, col: $0) }
        }
        for slot in 0..<3 {
            check(BerryDifficultyPolicy.preferredShapes(
                from: shapes, profile: nil, occupancy: 0.9, dryMoves: 9,
                stage: 10, slot: slot, isLegal: { _ in true }).isEmpty,
                "nonadaptive Classic/Daily/Blitz/Nightmare altered")
        }
        for profile: BerryDifficultyProfile in [.endlessAdaptive, .storyProgressive, .cozyGentle] {
            for slot in 1..<3 {
                check(BerryDifficultyPolicy.preferredShapes(
                    from: shapes, profile: profile, occupancy: 0.8, dryMoves: 8,
                    stage: 8, slot: slot, isLegal: { _ in true }).isEmpty,
                    "more than one tray slot adapted")
            }
        }
        let dense = BerryDifficultyPolicy.preferredShapes(
            from: shapes, profile: .endlessAdaptive, occupancy: 0.7,
            dryMoves: 5, stage: 6, slot: 0, isLegal: { $0.count % 2 == 0 })
        check(dense.map(\.count) == [2, 4],
              "adaptation selected unplaceable or oversized pieces")
        check(BerryDifficultyPolicy.preferredShapes(
            from: shapes, profile: .cozyGentle, occupancy: 0.9,
            dryMoves: 6, stage: 6, slot: 0, isLegal: { _ in false }).isEmpty,
            "no legal move incorrectly guaranteed a rescue")
    }
    static func testOldSaves() throws {
        var engine = BerryEngine(seed: 1550)
        let originalBoard = engine.board
        let originalTray = engine.tray
        engine.configureDifficulty(.endlessAdaptive, stage: 4)
        check(engine.board == originalBoard && engine.tray == originalTray &&
              engine.moves == 0 && engine.score == 0,
              "changing profile regenerated existing save")
        let data = try JSONEncoder().encode(engine)
        var old = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        old.removeValue(forKey: "adaptiveProfile")
        old.removeValue(forKey: "adaptiveStage")
        let restored = try JSONDecoder().decode(BerryEngine.self,
            from: JSONSerialization.data(withJSONObject: old))
        check(restored.board == engine.board && restored.tray == engine.tray,
              "old saved board or tray could not round-trip")
        let new = try JSONDecoder().decode(BerryEngine.self, from: data)
        check(new.board == engine.board && new.tray == engine.tray,
              "new saved board or tray could not round-trip")
    }
    static func testGameplay() {
        let profiles: [BerryDifficultyProfile?] = [
            nil, .endlessAdaptive, .storyProgressive, .cozyGentle]
        var total = 0
        for profile in profiles {
            for seed in 1...60 {
                var e = BerryEngine(seed: UInt64(seed))
                e.configureDifficulty(profile, stage: 5)
                for _ in 0..<110 {
                    guard let (slot, row, col) = firstLegal(e) else { break }
                    let oldMoves = e.moves
                    let oldScore = e.score
                    check(e.place(slot: slot, row: row, col: col) != nil,
                          "legal placement rejected")
                    check(e.moves == oldMoves + 1 && e.score >= oldScore,
                          "placement corrupted score or moves")
                    check(e.tray.count == 3, "three-piece tray corrupted")
                    total += 1
                }
            }
        }
        check(total > 400, "simulation did not exercise enough placements")
        print("PASS 240 seeded games and \(total) legal placements")
    }
    static func main() throws {
        testPolicy()
        try testOldSaves()
        testGameplay()
        print("PASS mode policy, legacy saves, scoring and tray invariants")
    }
}
