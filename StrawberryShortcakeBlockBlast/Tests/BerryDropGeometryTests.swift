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
}
