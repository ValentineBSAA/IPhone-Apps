import XCTest
@testable import BerryBlockBlast

final class BerryDropGeometryTests: XCTestCase {
    private let single = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 0)
    private let square = BerryPiece(points: [
        BerryPoint(row: 0, col: 0), BerryPoint(row: 0, col: 1),
        BerryPoint(row: 1, col: 0), BerryPoint(row: 1, col: 1)
    ], tint: 1)

    func testEightByEightGlobalBoardOffset() {
        let board = CGRect(x: 23, y: 272, width: 320, height: 320)
        let step = (board.width - 7 * 3) / 8 + 3
        let finger = CGPoint(x: board.minX + 4.5 * step, y: board.minY + 3.5 * step)
        let target = BerryDropGeometry.target(for: finger, board: board, piece: single, side: 8)
        XCTAssertEqual(target?.row, 3)
        XCTAssertEqual(target?.col, 4)
    }

    func testTwoByTwoPieceCentersOnRelease() {
        let board = CGRect(x: 25, y: 320, width: 320, height: 320)
        let step = (board.width - 7 * 3) / 8 + 3
        let finger = CGPoint(x: board.minX + step, y: board.minY + step)
        let target = BerryDropGeometry.target(for: finger, board: board, piece: square, side: 8)
        XCTAssertEqual(target?.row, 0)
        XCTAssertEqual(target?.col, 0)
    }

    func testTwelveByTwelveNightmareBoard() {
        let board = CGRect(x: 30, y: 252, width: 348, height: 348)
        let step = (board.width - 11 * 3) / 12 + 3
        let finger = CGPoint(x: board.minX + 6.5 * step, y: board.minY + 10.5 * step)
        let target = BerryDropGeometry.target(for: finger, board: board, piece: single, side: 12)
        XCTAssertEqual(target?.row, 10)
        XCTAssertEqual(target?.col, 6)
    }

    func testTouchFarOutsideBoardIsRejected() {
        let board = CGRect(x: 30, y: 250, width: 320, height: 320)
        XCTAssertNil(BerryDropGeometry.target(
            for: CGPoint(x: 100, y: 100), board: board, piece: square, side: 8
        ))
    }
    func testLiftedTouchJustBelowBoardCanTargetBottomRow() {
        let board = CGRect(x: 30, y: 200, width: 320, height: 320)
        let finger = CGPoint(x: 50, y: board.maxY + 22)
        let matches = BerryDropGeometry.candidates(
            for: finger, board: board, piece: single, side: 8
        )
        XCTAssertFalse(matches.isEmpty)
        XCTAssertEqual(matches.first?.row, 7)
        XCTAssertEqual(matches.first?.col, 0)
    }

    func testPreviewAndReleaseUseIdenticalTargets() {
        let board = CGRect(x: 22, y: 260, width: 350, height: 350)
        let finger = CGPoint(x: 140, y: 515)
        let preview = BerryDropGeometry.candidates(for: finger, board: board, piece: square, side: 8)
        let release = BerryDropGeometry.candidates(for: finger, board: board, piece: square, side: 8)
        XCTAssertEqual(preview.map { $0.row }, release.map { $0.row })
        XCTAssertEqual(preview.map { $0.col }, release.map { $0.col })
    }

    func testExtremeFingerOvershootCannotTargetBoard() {
        let board = CGRect(x: 25, y: 210, width: 345, height: 345)
        let matches = BerryDropGeometry.candidates(
            for: CGPoint(x: 110, y: board.maxY + 200),
            board: board, piece: square, side: 8
        )
        XCTAssertTrue(matches.isEmpty)
    }
}
