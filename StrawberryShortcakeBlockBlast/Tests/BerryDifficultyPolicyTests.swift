import XCTest
@testable import BerryBlockBlast

final class BerryDifficultyPolicyTests: XCTestCase {
    private let shapes: [[BerryPoint]] = (1...7).map { n in
        (0..<n).map { BerryPoint(row: 0, col: $0) }
    }

    func testOnlyOneHandSlotIsAdapted() {
        for profile in [BerryDifficultyProfile.endlessAdaptive,
                        .storyProgressive, .cozyGentle] {
            for slot in 1...2 {
                XCTAssertTrue(BerryDifficultyPolicy.preferredShapes(
                    from: shapes, profile: profile, occupancy: 0.70,
                    dryMoves: 6, stage: 6, slot: slot, isLegal: { _ in true }).isEmpty)
            }
        }
    }

    func testClassicDailyBlitzAndNightmareHaveNoAdaptivePolicy() {
        for slot in 0..<3 {
            XCTAssertTrue(BerryDifficultyPolicy.preferredShapes(
                from: shapes, profile: nil, occupancy: 0.91,
                dryMoves: 12, stage: 99, slot: slot, isLegal: { _ in true }).isEmpty)
        }
    }

    func testEndlessLateBoardDoesNotGuaranteeASingleton() {
        let choices = BerryDifficultyPolicy.preferredShapes(
            from: shapes, profile: .endlessAdaptive,
            occupancy: 0.75, dryMoves: 0, stage: 1, slot: 0,
            isLegal: { _ in true })
        XCTAssertFalse(choices.isEmpty)
        XCTAssertTrue(choices.allSatisfy { (2...4).contains($0.count) })
    }

    func testStoryChaptersGetDifferentButBoundedShapeBias() {
        let early = BerryDifficultyPolicy.preferredShapes(
            from: shapes, profile: .storyProgressive,
            occupancy: 0.45, dryMoves: 0, stage: 1, slot: 0,
            isLegal: { _ in true })
        let late = BerryDifficultyPolicy.preferredShapes(
            from: shapes, profile: .storyProgressive,
            occupancy: 0.12, dryMoves: 0, stage: 8, slot: 0,
            isLegal: { _ in true })
        XCTAssertTrue(early.allSatisfy { $0.count <= 3 })
        XCTAssertTrue(late.allSatisfy { (4...6).contains($0.count) })
    }

    func testNeverOffersAnIllegalPreferredShape() {
        let chosen = BerryDifficultyPolicy.preferredShapes(
            from: shapes, profile: .cozyGentle,
            occupancy: 0.80, dryMoves: 5, stage: 4, slot: 0,
            isLegal: { $0.count == 2 })
        XCTAssertEqual(chosen.map(\.count), [2])
    }

    func testLegacyEngineWithoutAdaptiveKeysStillDecodes() throws {
        let engine = BerryEngine(seed: 1389)
        let old = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(engine)) as? [String: Any])
        var legacy = old
        legacy.removeValue(forKey: "adaptiveProfile")
        legacy.removeValue(forKey: "adaptiveStage")
        let data = try JSONSerialization.data(withJSONObject: legacy)
        let reloaded = try JSONDecoder().decode(BerryEngine.self, from: data)
        XCTAssertEqual(reloaded.score, engine.score)
        XCTAssertEqual(reloaded.board, engine.board)
        XCTAssertEqual(reloaded.tray.count, engine.tray.count)
    }
}
