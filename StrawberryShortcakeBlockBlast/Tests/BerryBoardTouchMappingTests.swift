import XCTest
import CoreGraphics
@testable import BerryBlockBlast

final class BerryBoardTouchMappingTests: XCTestCase {
    /// No visual-only acceptance: every *actual* outer board touch frame
    /// must map square centers back to the same engine cell coordinates.
    func testEightAndTwelveCellBoardsMatchTouchGeometryAcrossPhoneWidths() {
        let one = BerryPiece(points: [.init(row: 0, col: 0)], tint: 0)
        for width: CGFloat in [320, 375, 393, 430] {
            let boardSize = BerryGameplayLayout.boardSize(
                width: width, height: 759, topInset: 0,
                bottomInset: 0, mode: .classic)
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

    func testBoardSizeKeepsResponsiveMarginsAndAccurateTouchRim() {
        let phones: [(String, CGFloat)] = [
            ("iPhone 14 Pro", 393), ("iPhone 16e", 390)
        ]
        for (label, width) in phones {
            let board = BerryGameplayLayout.boardSize(
                width: width, height: 759, topInset: 0,
                bottomInset: 0, mode: .classic)
            // Previous 350pt minimum contradicted the approved 87% width
            // target, which yields 341.91pt on a 393pt safe-width screen.
            XCTAssertGreaterThanOrEqual(board, width * 0.83, label)
            XCTAssertLessThanOrEqual(board, width * 0.88, label)
            XCTAssertEqual(
                BerryBoardContainment.fullFrameSide(playableSide: board),
                board + 2 * (BerryGameplayLayout.boardTouchMargin +
                             BerryGameplayLayout.gardenFrameInset),
                accuracy: 0.01, label)
            XCTAssertLessThanOrEqual(
                BerryBoardContainment.fullFrameSide(playableSide: board) + 6,
                width + 0.001, label)
        }
    }
}
