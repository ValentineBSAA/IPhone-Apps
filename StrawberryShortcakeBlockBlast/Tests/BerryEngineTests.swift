import XCTest
@testable import BerryBlockBlast

final class BerryEngineTests: XCTestCase {
    func testStartsWithEightByEightGridAndThreePieces() {
        let game = BerryEngine()
        XCTAssertEqual(game.board.count, 8)
        XCTAssertTrue(game.board.allSatisfy { $0.count == 8 && $0.allSatisfy { $0 == nil } })
        XCTAssertEqual(game.tray.compactMap { $0 }.count, 3)
        XCTAssertTrue(game.hasMove())
    }

    func testOutOfBoundsOrOverlappingPlacementRejected() {
        let piece = BerryPiece(points: [BerryPoint(row: 0, col: 0), BerryPoint(row: 0, col: 1)], tint: 0)
        var game = BerryEngine(board: emptyBoard(), tray: [piece, nil, nil])
        XCTAssertFalse(game.canPlace(piece, row: 0, col: 7))
        XCTAssertNil(game.place(slot: 0, row: 0, col: 7))
        XCTAssertNotNil(game.place(slot: 0, row: 0, col: 0))
        XCTAssertEqual(game.board[0][0], 0)
        XCTAssertEqual(game.board[0][1], 0)
    }

    func testClearsCompletedRow() {
        var board = emptyBoard()
        for col in 0..<7 { board[0][col] = 1 }
        let piece = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 2)
        var game = BerryEngine(board: board, tray: [piece, nil, nil])
        let outcome = game.place(slot: 0, row: 0, col: 7)
        XCTAssertEqual(outcome?.clearedRows, [0])
        XCTAssertEqual(outcome?.clearedColumns, [])
        XCTAssertEqual(game.score, 311)
        XCTAssertTrue(game.board[0].allSatisfy { $0 == nil })
    }

    func testClearsRowAndColumnTogether() {
        var board = emptyBoard()
        for col in 0..<7 { board[7][col] = 1 }
        for row in 0..<7 { board[row][7] = 1 }
        let piece = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 2)
        var game = BerryEngine(board: board, tray: [piece, nil, nil])
        let outcome = game.place(slot: 0, row: 7, col: 7)
        XCTAssertEqual(outcome?.clearedRows, [7])
        XCTAssertEqual(outcome?.clearedColumns, [7])
        XCTAssertEqual(game.score, 341)
        XCTAssertTrue(game.board.flatMap { $0 }.allSatisfy { $0 == nil })
    }

    func testPersistsAndRestoresBoardScoreAndTray() throws {
        var game = BerryEngine()
        if let piece = game.tray[0] {
            XCTAssertNotNil(game.place(slot: 0, row: 0, col: 0))
            XCTAssertGreaterThan(game.score, 0)
            XCTAssertEqual(game.board.flatMap { $0 }.compactMap { $0 }.count, piece.points.count)
        }
        let restored = try JSONDecoder().decode(BerryEngine.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(game.score, restored.score)
        XCTAssertEqual(game.board, restored.board)
        XCTAssertEqual(game.tray, restored.tray)
    }

    private func emptyBoard() -> [[Int?]] {
        Array(repeating: Array(repeating: nil, count: 8), count: 8)
    }
}
