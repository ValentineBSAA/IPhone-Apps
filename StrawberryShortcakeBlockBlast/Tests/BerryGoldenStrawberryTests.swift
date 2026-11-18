import XCTest
@testable import BerryBlockBlast

final class BerryGoldenStrawberryTests: XCTestCase {
    private var one: BerryPiece {
        BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 1)
    }

    func testRescueClearsOccupiedStoryBoardButPreservesScoreAndObjectives() {
        var board = Array(repeating: Array<Int?>(repeating: nil, count: 8), count: 8)
        board[0][0] = 2
        board[5][7] = 3
        var engine = BerryEngine(board: board, tray: [one, nil, nil], score: 125)
        XCTAssertTrue(engine.clearBoardWithGoldenStrawberry())
        XCTAssertTrue(engine.board.flatMap { $0 }.allSatisfy { $0 == nil })
        XCTAssertEqual(engine.score, 125)
        XCTAssertEqual(engine.totalLines, 0)
        XCTAssertEqual(engine.moves, 0)
        XCTAssertEqual(engine.seasons, 0)
        XCTAssertTrue(engine.hasMove())
    }

    func testEmptyBoardCannotWasteGoldenStrawberry() {
        var engine = BerryEngine(side: 8, hard: false)
        XCTAssertFalse(engine.clearBoardWithGoldenStrawberry())
        XCTAssertEqual(engine.score, 0)
        XCTAssertEqual(engine.moves, 0)
    }

    func testGoldBerryResetsAllFourMegaGardenPatchesWithoutTouchingScore() {
        var board = Array(repeating: Array<Int?>(repeating: nil, count: 24), count: 24)
        board[0][0] = 1
        board[0][14] = 2
        board[13][0] = 3
        board[23][23] = 4
        var engine = BerryEngine(board: board, tray: [one, nil, nil], score: 525)
        XCTAssertTrue(engine.clearBoardWithGoldenStrawberry())
        XCTAssertEqual(engine.score, 525)
        XCTAssertEqual(engine.activeGardenSection, 0)
        XCTAssertEqual(engine.gardenPatchMoves, 0)
        XCTAssertEqual(engine.gardenPatchLines, 0)
        XCTAssertEqual(engine.seasons, 0)
        XCTAssertTrue(engine.board.flatMap { $0 }.allSatisfy { $0 == nil })
        XCTAssertTrue(engine.hasMove())
    }
}
