import XCTest
import Foundation
@testable import BerryBlockBlast

final class BerryBuild45FairPlayTests: XCTestCase {
    func testSeededQAModeMatchesExistingClassicDealing() {
        for seed in [1, 9, 20261119] {
            let original = BerryEngine(seed: UInt64(seed))
            let audited = BerryEngine(side: 8, seed: UInt64(seed))
            XCTAssertEqual(audited.board, original.board)
            XCTAssertEqual(audited.tray.map { $0?.points }, original.tray.map { $0?.points })
            XCTAssertEqual(audited.tray.map { $0?.tint }, original.tray.map { $0?.tint })
            XCTAssertEqual(audited.moves, 0)
            XCTAssertEqual(audited.score, 0)
        }
    }
    func testSeededSizesArePlayableAndPersist() throws {
        for side in [8, 12, 24] {
            let e = BerryEngine(side: side, hard: side == 24, seed: 410045)
            XCTAssertEqual(e.side, side)
            XCTAssertEqual(e.tray.count, 3)
            XCTAssertTrue(e.hasMove())
            let restored = try JSONDecoder().decode(BerryEngine.self,
                                                    from: JSONEncoder().encode(e))
            XCTAssertEqual(restored.board, e.board)
            XCTAssertEqual(restored.tray, e.tray)
            XCTAssertEqual(restored.moves, e.moves)
        }
    }
    func testSeededCozyRemainsGentle() {
        let e = BerryEngine(side: 8, cozy: true, seed: 45)
        XCTAssertTrue(e.hasMove())
        XCTAssertTrue(e.tray.compactMap { $0 }.allSatisfy { $0.points.count <= 4 })
    }
    func testInvalidPlacementCannotChangeSave() throws {
        var e = BerryEngine(side: 8, seed: 451)
        let prior = try JSONEncoder().encode(e)
        XCTAssertNil(e.place(slot: 0, row: -1, col: -1))
        XCTAssertNil(e.place(slot: 8, row: 0, col: 0))
        XCTAssertEqual(try JSONEncoder().encode(e), prior)
    }
    func testExistingBerryPricesUnchanged() {
        XCTAssertEqual(BerryEconomy.undoPrice, 40)
        XCTAssertEqual(BerryEconomy.shufflePrice, 50)
        XCTAssertEqual(BerryEconomy.hintPrice, 35)
        XCTAssertEqual(BerryEconomy.cottagePrices, [60, 90, 130, 180, 240, 300])
        XCTAssertEqual(BerryGameSession.goldenStrawberryCost, 250)
    }
    func testUntouchedModesNeverAcquireAdaptiveSelection() {
        let shapes = (1...6).map { n in (0..<n).map { BerryPoint(row: 0, col: $0) } }
        for slot in 0..<3 {
            XCTAssertTrue(BerryDifficultyPolicy.preferredShapes(
                from: shapes, profile: nil, occupancy: 0.8,
                dryMoves: 8, stage: 6, slot: slot,
                isLegal: { _ in true }).isEmpty)
        }
    }
}
