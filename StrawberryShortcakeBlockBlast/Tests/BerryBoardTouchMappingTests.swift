import XCTest
import CoreGraphics
@testable import BerryBlockBlast

final class BerryBoardTouchMappingTests: XCTestCase {
    /// No visual-only acceptance: every *actual* outer board touch frame
    /// must map square centers back to the same engine cell coordinates.
    func testEightAndTwelveCellBoardsMatchTouchGeometryAcrossPhoneWidths() {
        let one = BerryPiece(points: [.init(row: 0, col: 0)], tint: 0)
        for width: CGFloat in [320, 375, 393, 430] {
            let boardSize = max(150, width - 12)
            let rim = BerryGameplayLayout.boardTouchMargin
            let wrapper = CGRect(x: 10, y: 140,
                                 width: boardSize + rim * 2,
                                 height: boardSize + rim * 2)
            for side in [8, 12] {
                let cell = (boardSize - CGFloat(side - 1) * 3) / CGFloat(side)
                let step = cell + 3
                for row in 0..<side {
                    for col in 0..<side {
                        let finger = CGPoint(
                            x: wrapper.minX + rim + CGFloat(col) * step + cell / 2,
                            y: wrapper.minY + rim + CGFloat(row) * step + cell / 2)
                        guard let mapped = BerryDropGeometry.target(
                            for: finger, board: wrapper, piece: one, side: side)
                        else {
                            XCTFail("Board target missing: width \(width), side \(side), row \(row), col \(col)")
                            continue
                        }
                        XCTAssertEqual(mapped.row, row)
                        XCTAssertEqual(mapped.col, col)
                    }
                }
            }
        }
    }

    func testTouchesOutsideBoardHaveNoUnboundedPlacementTarget() {
        let piece = BerryPiece(points: [.init(row: 0, col: 0)], tint: 4)
        let board = CGRect(x: 10, y: 120, width: 387, height: 387)
        XCTAssertNil(BerryDropGeometry.target(
            for: CGPoint(x: -100, y: -100), board: board, piece: piece, side: 8))
        XCTAssertNil(BerryDropGeometry.target(
            for: CGPoint(x: 1000, y: 1000), board: board, piece: piece, side: 12))
    }

    func testBoardSizeMatchesSingleRimConstantOnBoth393PointPhones() {
        for label in ["iPhone 14 Pro", "iPhone 16"] {
            let board = BerryGameplayLayout.boardSize(
                width: 393, height: 759, topInset: 0,
                bottomInset: 0, mode: .classic)
            XCTAssertGreaterThanOrEqual(board, 370, label)
            XCTAssertLessThanOrEqual(
                board + 2 * BerryGameplayLayout.boardTouchMargin + 6,
                393 + 0.001, label)
        }
    }
}
