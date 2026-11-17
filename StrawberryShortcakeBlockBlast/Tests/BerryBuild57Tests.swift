import XCTest
@testable import BerryBlockBlast

final class BerryBuild57EngineTests: XCTestCase {
    private let largeL = BerryPiece(points: [BerryPoint(row: 0, col: 0),
                                             BerryPoint(row: 1, col: 0),
                                             BerryPoint(row: 2, col: 0),
                                             BerryPoint(row: 2, col: 1),
                                             BerryPoint(row: 2, col: 2)], tint: 3)

    func testLShapeCannotShrinkToFit() {
        var board = Array(repeating: Array<Int?>(repeating: nil, count: 8), count: 8)
        board[4][4] = 1
        let engine = BerryEngine(board: board, tray: [largeL, nil, nil])
        XCTAssertEqual(largeL.width, 3)
        XCTAssertEqual(largeL.height, 3)
        XCTAssertFalse(engine.canPlace(largeL, row: 2, col: 2))
        XCTAssertTrue(engine.canPlace(largeL, row: 0, col: 0))
        XCTAssertFalse(engine.canPlace(largeL, row: 7, col: 7))
    }

    func testLiftedCoordinatesHaveExactlyOneCandidate() {
        let board = CGRect(x: 20, y: 215, width: 320, height: 320)
        let finger = CGPoint(x: 112, y: 403)
        let preview = BerryDropGeometry.candidates(for: finger, board: board,
                                                   piece: largeL, side: 8)
        let release = BerryDropGeometry.candidates(for: finger, board: board,
                                                   piece: largeL, side: 8)
        XCTAssertEqual(preview.count, 1)
        XCTAssertEqual(preview.first?.row, release.first?.row)
        XCTAssertEqual(preview.first?.col, release.first?.col)
    }

    func testTrayShapesDifferentAndHintsAlwaysLegal() {
        for size in [8, 12, 24] {
            let engine = BerryEngine(side: size, hard: size == 24)
            let shapes = engine.tray.compactMap { $0 }.map(\.points)
            XCTAssertEqual(Set(shapes).count, 3)
            let suggestion = engine.suggestedMove()
            XCTAssertNotNil(suggestion)
            if let suggestion, let piece = engine.tray[suggestion.slot] {
                XCTAssertTrue(engine.canPlace(piece, row: suggestion.row, col: suggestion.col))
            }
        }
    }

    func testShuffleRescueWhenOnlyOneCellRemains() {
        var almostFull = Array(repeating: Array<Int?>(repeating: 2, count: 8), count: 8)
        almostFull[7][7] = nil
        let twin = BerryPiece(points: [BerryPoint(row: 0, col: 0),
                                       BerryPoint(row: 0, col: 1)], tint: 2)
        var engine = BerryEngine(board: almostFull, tray: [twin, nil, nil])
        XCTAssertFalse(engine.hasMove())
        XCTAssertTrue(engine.canRescueWithShuffle)
        let succeeded = engine.reshuffleTray()
        XCTAssertTrue(succeeded)
        XCTAssertTrue(engine.hasMove())
        XCTAssertNotNil(engine.suggestedMove())
    }

    func testShuffleCannotConsumeWhenBoardIsSolid() {
        let full = Array(repeating: Array<Int?>(repeating: 1, count: 8), count: 8)
        let single = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 1)
        var engine = BerryEngine(board: full, tray: [single, nil, nil])
        XCTAssertFalse(engine.canRescueWithShuffle)
        XCTAssertFalse(engine.reshuffleTray())
    }

    func testDailyHistoryKeyMatchesLocalCalendar() async {
        let sessionDateKey = await BerryGameSession.dailyDateKey()
        XCTAssertEqual(BerryDailyHistory.dateKey(for: Date()), sessionDateKey)
    }
}
