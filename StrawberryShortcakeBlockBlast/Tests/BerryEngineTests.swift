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

    func testDailySeedReproducesSamePieceShapesAndColors() {
        let first = BerryEngine(seed: 20261116)
        let second = BerryEngine(seed: 20261116)
        XCTAssertEqual(first.tray.map { $0?.points }, second.tray.map { $0?.points })
        XCTAssertEqual(first.tray.map { $0?.tint }, second.tray.map { $0?.tint })
    }

    func testLegacySaveWithoutNewOptionalFieldsDecodes() throws {
        let game = BerryEngine(seed: 20261116)
        let encoded = try JSONEncoder().encode(game)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "randomState")
        object.removeValue(forKey: "cozyPieces")
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder().decode(BerryEngine.self, from: legacy)
        XCTAssertEqual(restored.board, game.board)
        XCTAssertEqual(restored.tray, game.tray)
    }

    func testRejectsCorruptedSaveDimensions() throws {
        let game = BerryEngine()
        let encoded = try JSONEncoder().encode(game)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["board"] = [[NSNull()]]
        let corrupted = try JSONSerialization.data(withJSONObject: object)
        XCTAssertThrowsError(try JSONDecoder().decode(BerryEngine.self, from: corrupted))
    }

    func testCozyModeProducesPlayableSmallPieces() {
        let game = BerryEngine(cozy: true)
        XCTAssertEqual(game.tray.compactMap { $0 }.count, 3)
        XCTAssertTrue(game.tray.compactMap { $0 }.allSatisfy { $0.points.count <= 4 })
        XCTAssertTrue(game.hasMove())
    }

    func testNightmareStartsWithTwelveByTwelveBoardAndHardPieces() {
        let game = BerryEngine(side: 12, hard: true)
        XCTAssertEqual(game.side, 12)
        XCTAssertEqual(game.board.count, 12)
        XCTAssertTrue(game.board.allSatisfy { $0.count == 12 })
        XCTAssertEqual(game.tray.compactMap { $0 }.count, 3)
        XCTAssertTrue(game.tray.compactMap { $0 }.allSatisfy { $0.points.count >= 4 })
        XCTAssertTrue(game.hasMove())
    }

    func testNightmareLargePiecesStayWithinBoardAndPersist() throws {
        // Exercise repeated deals so 7-9-square pieces do not break encoding
        // or placement on the larger board.
        var largestPieceSeen = 0
        for _ in 0..<100 {
            let game = BerryEngine(side: 12, hard: true)
            largestPieceSeen = max(largestPieceSeen, game.tray.compactMap { $0 }.map { $0.points.count }.max() ?? 0)
            XCTAssertTrue(game.tray.compactMap { $0 }.allSatisfy { $0.points.count >= 5 })
            for piece in game.tray.compactMap({ $0 }) {
                XCTAssertLessThanOrEqual(piece.width, 12)
                XCTAssertLessThanOrEqual(piece.height, 12)
            }
            let restored = try JSONDecoder().decode(BerryEngine.self, from: JSONEncoder().encode(game))
            XCTAssertEqual(restored.side, 12)
            XCTAssertEqual(restored.tray, game.tray)
            if let piece = game.tray[0] {
                XCTAssertTrue(game.canPlace(piece, row: 0, col: 0))
            }
        }
        XCTAssertGreaterThanOrEqual(largestPieceSeen, 7, "Nightmare should actually deal its larger shapes")
    }

    func testNightmareRejectsOutOfBoundsAndPersistsDimensions() throws {
        var game = BerryEngine(side: 12, hard: true)
        let piece = try XCTUnwrap(game.tray[0])
        XCTAssertFalse(game.canPlace(piece, row: 12, col: 12))
        XCTAssertNotNil(game.place(slot: 0, row: 0, col: 0))
        let restored = try JSONDecoder().decode(BerryEngine.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(restored.side, 12)
        XCTAssertEqual(restored.board, game.board)
    }

    func testLegacySaveWithoutBoardSizeStillLoadsAsClassic() throws {
        let game = BerryEngine()
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        payload.removeValue(forKey: "side")
        payload.removeValue(forKey: "hardPieces")
        let restored = try JSONDecoder().decode(BerryEngine.self, from: JSONSerialization.data(withJSONObject: payload))
        XCTAssertEqual(restored.side, 8)
        XCTAssertEqual(restored.board.count, 8)
        XCTAssertEqual(restored.tray.count, 3)
    }

    func testNightmareClearsTwelveCellRow() {
        var board = Array(repeating: Array<Int?>(repeating: nil, count: 12), count: 12)
        for col in 0..<11 { board[0][col] = 1 }
        let piece = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 2)
        var game = BerryEngine(board: board, tray: [piece, nil, nil], hard: true)
        let result = game.place(slot: 0, row: 0, col: 11)
        XCTAssertEqual(result?.clearedRows, [0])
        XCTAssertEqual(result?.clearedColumns, [])
        XCTAssertTrue(game.board[0].allSatisfy { $0 == nil })
        XCTAssertEqual(game.side, 12)
        XCTAssertEqual(game.score, 311)
    }

    func testNightmareClearsTwelveCellColumn() {
        var board = Array(repeating: Array<Int?>(repeating: nil, count: 12), count: 12)
        for row in 0..<11 { board[row][11] = 1 }
        let piece = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 3)
        var game = BerryEngine(board: board, tray: [piece, nil, nil], hard: true)
        let result = game.place(slot: 0, row: 11, col: 11)
        XCTAssertEqual(result?.clearedColumns, [11])
        XCTAssertTrue((0..<12).allSatisfy { game.board[$0][11] == nil })
    }

    private func emptyBoard() -> [[Int?]] {
        Array(repeating: Array(repeating: nil, count: 8), count: 8)
    }
}
