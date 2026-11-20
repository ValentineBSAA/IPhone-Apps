import XCTest
import CoreGraphics
@testable import BerryBlockBlast

final class BerryGameplayGeometryRegressionTests: XCTestCase {
    func testSafeAreaSizingAcrossPhonesAndModes() {
        let cases: [(String, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            ("393pt responsive layout", 393, 759, 59, 34),
            ("iPhone 16e", 390, 748, 59, 34),
            ("compact", 375, 690, 47, 34),
            ("narrow", 320, 650, 47, 34),
            ("wide", 430, 835, 62, 34)
        ]
        for (name, width, height, top, bottom) in cases {
            for mode in BerryMode.allCases {
                let board = BerryGameplayLayout.boardSize(
                    width: width, height: height,
                    topInset: top, bottomInset: bottom, mode: mode,
                    megaGarden: mode == .endless)
                XCTAssertTrue(board.isFinite, "\(name): \(mode)")
                XCTAssertGreaterThanOrEqual(board, 150, "\(name): \(mode)")
                XCTAssertLessThanOrEqual(
                    BerryBoardContainment.fullFrameSide(playableSide: board) + 6,
                    width + 0.01, "\(name): \(mode) frame overflow")
                XCTAssertLessThanOrEqual(board, height - 110, "\(name): \(mode)")
            }
        }
    }

    func testClassicBoardUsesScreenWidthWithoutCrowdingTray() {
        for width: CGFloat in [393, 430] {
            let board = BerryGameplayLayout.boardSize(
                width: width, height: 759,
                topInset: 59, bottomInset: 34, mode: .classic)
            XCTAssertGreaterThanOrEqual(board, width * 0.90,
                "Wider Build 4.6 board should use the screen safely")
            XCTAssertLessThanOrEqual(board,
                width * BerryGameplayLayout.boardWidthFraction + 0.01,
                "Board must obey the shared layout-width policy")
            XCTAssertLessThanOrEqual(board, width * 0.93,
                "Leave a visible frame/HUD margin even as the board expands")
            XCTAssertLessThanOrEqual(
                BerryBoardContainment.fullFrameSide(playableSide: board) + 6,
                width + 0.01)
        }
    }

    func testEveryRefillAndPlacementKeepsRemainingVisiblePiecesValid() {
        for seed in 1...200 {
            var engine = BerryEngine(seed: UInt64(seed))
            XCTAssertEqual(engine.tray.count, 3)
            for piece in engine.tray.compactMap({ $0 }) {
                XCTAssertFalse(piece.points.isEmpty)
                XCTAssertGreaterThan(piece.width, 0)
                XCTAssertGreaterThan(piece.height, 0)
            }
            guard let move = engine.suggestedMove() else {
                XCTFail("Seed \(seed): dealt a hand without a legal placement")
                continue
            }
            let before = engine.tray
            XCTAssertNotNil(engine.place(slot: move.slot, row: move.row, col: move.col))
            XCTAssertNil(engine.tray[move.slot], "Used slot was not marked used")
            for slot in 0..<3 where slot != move.slot {
                XCTAssertEqual(engine.tray[slot], before[slot],
                    "Placing a piece must not mutate another tray slot")
            }
        }
    }
}
