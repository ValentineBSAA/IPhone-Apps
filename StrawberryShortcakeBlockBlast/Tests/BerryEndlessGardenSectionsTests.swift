import XCTest
@testable import BerryBlockBlast

/// Prevent the historic 24x24 "stuck behind an off-screen square" regression.
/// These tests exercise the engine, not a mock SwiftUI screenshot.
final class BerryEndlessGardenSectionsTests: XCTestCase {
    private var one: BerryPiece {
        BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 1)
    }

    func test24By24HasFourVisible12By12SectionsWithoutCrossSectionPlacements() {
        let engine = BerryEngine(side: 24, hard: true)
        XCTAssertEqual(engine.side, 24)
        XCTAssertEqual(engine.visibleSide, 12)
        XCTAssertEqual(engine.activeGardenSection, 0)
        XCTAssertEqual(engine.sectionOrigin.row, 0)
        XCTAssertEqual(engine.sectionOrigin.col, 0)
        XCTAssertTrue(engine.canPlace(one, row: 0, col: 0))
        XCTAssertFalse(engine.canPlace(one, row: 0, col: 12))
        XCTAssertFalse(engine.canPlace(one, row: 12, col: 0))
    }

    func testBlockedFirstPatchAutomaticallyMovesToNextPatchWithoutSpending() {
        var board = Array(repeating: Array<Int?>(repeating: nil, count: 24), count: 24)
        for row in 0..<12 {
            for col in 0..<12 { board[row][col] = 2 }
        }
        board[11][11] = nil
        let double = BerryPiece(points: [
            BerryPoint(row: 0, col: 0), BerryPoint(row: 0, col: 1)
        ], tint: 4)
        var engine = BerryEngine(board: board, tray: [double, nil, nil], score: 231)
        XCTAssertFalse(engine.hasMove())
        XCTAssertTrue(engine.beginNextEndlessSeasonIfStuck())
        XCTAssertTrue(engine.hasMove())
        XCTAssertEqual(engine.activeGardenSection, 1)
        XCTAssertEqual(engine.sectionOrigin.row, 0)
        XCTAssertEqual(engine.sectionOrigin.col, 12)
        XCTAssertEqual(engine.board[0][0], 2)
        XCTAssertEqual(engine.score, 231)
        XCTAssertEqual(engine.seasons, 0)
    }

    func testSinglePatchRowClearsAt12CellsNot24() {
        var board = Array(repeating: Array<Int?>(repeating: nil, count: 24), count: 24)
        for col in 0..<11 { board[0][col] = 2 }
        board[0][12] = 3
        var engine = BerryEngine(board: board, tray: [one, nil, nil], score: 5)
        let placement = engine.place(slot: 0, row: 0, col: 11)
        XCTAssertEqual(placement?.clearedRows, [0])
        XCTAssertEqual(placement?.clearedLines, 1)
        for col in 0..<12 { XCTAssertNil(engine.board[0][col]) }
        XCTAssertEqual(engine.board[0][12], 3,
                       "An adjacent patch cannot be erased by this patch's line clear")
    }

    func testCompletedLegacy24GardenBeginsNewSeasonKeepingScore() {
        let board = Array(repeating: Array<Int?>(repeating: 4, count: 24), count: 24)
        var engine = BerryEngine(board: board, tray: [one, nil, nil], score: 987)
        XCTAssertFalse(engine.hasMove())
        XCTAssertTrue(engine.beginNextEndlessSeasonIfStuck())
        XCTAssertEqual(engine.seasons, 1)
        XCTAssertEqual(engine.activeGardenSection, 0)
        XCTAssertEqual(engine.score, 987)
        XCTAssertTrue(engine.hasMove())
        XCTAssertTrue(engine.board.flatMap { $0 }.allSatisfy { $0 == nil })
    }

    func testOlderSavedGardenDecodesMissingNewSectionAndProgressKeys() throws {
        let engine = BerryEngine(side: 24, hard: true)
        let encoded = try JSONEncoder().encode(engine)
        var document = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        document.removeValue(forKey: "activeGardenSection")
        document.removeValue(forKey: "gardenPatchMoves")
        document.removeValue(forKey: "gardenPatchLines")
        let oldData = try JSONSerialization.data(withJSONObject: document)
        let restored = try JSONDecoder().decode(BerryEngine.self, from: oldData)
        XCTAssertEqual(restored.side, 24)
        XCTAssertEqual(restored.visibleSide, 12)
        XCTAssertEqual(restored.activeGardenSection, 0)
        XCTAssertEqual(restored.gardenPatchMoves, 0)
        XCTAssertEqual(restored.gardenPatchLines, 0)
    }

    func testLongEndlessRunAlwaysRecoversWithoutPurchasedShuffle() {
        var engine = BerryEngine(side: 24, hard: true)
        for _ in 0..<160 {
            if !engine.hasMove() {
                XCTAssertTrue(engine.beginNextEndlessSeasonIfStuck())
            }
            guard let move = engine.suggestedEndlessMove() else {
                return XCTFail("Expected a free, legal placement on the visible garden")
            }
            XCTAssertNotNil(engine.place(slot: move.slot, row: move.row, col: move.col))
            XCTAssertGreaterThanOrEqual(engine.score, 0)
        }
        XCTAssertEqual(engine.moves, 160)
        XCTAssertTrue(engine.seasons >= 1 || engine.activeGardenSection > 0)
    }
}
