import XCTest
@testable import BerryBlockBlast

/// Game Over recovery invariants: never lose a paid helper on an
/// impossible hand, and never grant free score or clear bonus lines.
final class BerryContinueRescueTests: XCTestCase {
    private var single: BerryPiece {
        BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 1)
    }

    private var double: BerryPiece {
        BerryPiece(points: [BerryPoint(row: 0, col: 0),
                            BerryPoint(row: 0, col: 1)], tint: 2)
    }

    func testShuffleContinueFindsLegalPieceInNearlyFullStoryGarden() {
        var board = Array(repeating: Array<Int?>(repeating: 3, count: 8), count: 8)
        board[7][7] = nil
        var engine = BerryEngine(board: board, tray: [double, nil, nil], score: 509)
        XCTAssertFalse(engine.hasMove())
        XCTAssertTrue(engine.canRescueWithShuffle)
        let previousBoard = engine.board
        let previousLines = engine.totalLines
        let previousMoves = engine.moves

        XCTAssertTrue(engine.reshuffleTray())
        XCTAssertTrue(engine.hasMove())
        XCTAssertEqual(engine.board, previousBoard)
        XCTAssertEqual(engine.score, 509)
        XCTAssertEqual(engine.totalLines, previousLines)
        XCTAssertEqual(engine.moves, previousMoves)
    }

    func testFullGardenCannotUseShuffleButCanUseGoldenStrawberry() {
        let full = Array(repeating: Array<Int?>(repeating: 1, count: 8), count: 8)
        var engine = BerryEngine(board: full, tray: [single, nil, nil], score: 150)
        XCTAssertFalse(engine.hasMove())
        XCTAssertFalse(engine.canRescueWithShuffle)
        XCTAssertTrue(engine.canRescueWithGoldenStrawberry)
        let before = engine
        XCTAssertFalse(engine.reshuffleTray())
        XCTAssertEqual(engine.board, before.board)
        XCTAssertEqual(engine.tray, before.tray)
        XCTAssertTrue(engine.clearBoardWithGoldenStrawberry())
        XCTAssertEqual(engine.score, 150)
        XCTAssertTrue(engine.hasMove())
        XCTAssertTrue(engine.goldenRescueUsed)
        XCTAssertFalse(engine.canRescueWithGoldenStrawberry)
    }

    func test24By24ShuffleChecksVisiblePatchNotHiddenGarden() {
        var board = Array(repeating: Array<Int?>(repeating: nil, count: 24), count: 24)
        for row in 0..<12 {
            for col in 0..<12 { board[row][col] = 2 }
        }
        var engine = BerryEngine(board: board, tray: [single, nil, nil], score: 231)
        XCTAssertFalse(engine.canRescueWithShuffle)
        XCTAssertFalse(engine.reshuffleTray())
        XCTAssertEqual(engine.score, 231)
        XCTAssertEqual(engine.activeGardenSection, 0)
        XCTAssertTrue(engine.beginNextEndlessSeasonIfStuck())
        XCTAssertEqual(engine.activeGardenSection, 1)
        XCTAssertTrue(engine.canRescueWithShuffle)
        XCTAssertTrue(engine.hasMove())
    }

    func testGoldenStrawberryDoesNotResetMovesLinesOrSeason() {
        var board = Array(repeating: Array<Int?>(repeating: nil, count: 24), count: 24)
        board[0][0] = 4
        var engine = BerryEngine(board: board, tray: [single, nil, nil], score: 913)
        let previousMoves = engine.moves
        let previousLines = engine.totalLines
        let previousSeason = engine.seasons
        XCTAssertTrue(engine.clearBoardWithGoldenStrawberry())
        XCTAssertEqual(engine.score, 913)
        XCTAssertEqual(engine.moves, previousMoves)
        XCTAssertEqual(engine.totalLines, previousLines)
        XCTAssertEqual(engine.seasons, previousSeason)
        XCTAssertFalse(engine.clearBoardWithGoldenStrawberry())
    }

    func testRescuePricingRetainsApprovedEconomy() {
        XCTAssertEqual(BerryEconomy.shufflePrice, 50)
        XCTAssertEqual(BerryGameSession.goldenStrawberryCost, 250)
        XCTAssertLessThan(BerryEconomy.shufflePrice,
                          BerryGameSession.goldenStrawberryCost)
    }
}
