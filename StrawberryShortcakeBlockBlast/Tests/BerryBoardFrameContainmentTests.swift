import SwiftUI
import UIKit
import XCTest
@testable import BerryBlockBlast

/// Protect the tiny frame from ever joining a board hitbox or leaking artwork.
@MainActor
final class BerryBoardFrameContainmentTests: XCTestCase {
    func testFrameBudgetRetainsAllControlsAndLeavesVisibleBorder() {
        let phones: [(String, CGFloat, CGFloat)] = [
            ("iPhone 14 Pro", 393, 759),
            ("iPhone 16", 393, 759),
            ("Narrow", 320, 650),
            ("Wide", 430, 835)
        ]
        XCTAssertEqual(BerryGameplayLayout.gardenFrameInset, 8)
        for (label, width, height) in phones {
            for mode in BerryMode.allCases {
                let playable = BerryGameplayLayout.boardSize(
                    width: width, height: height, topInset: 0,
                    bottomInset: 0, mode: mode)
                let footprint = BerryBoardContainment.fullFrameSide(playableSide: playable)
                XCTAssertGreaterThan(playable, 150, "\(label) \(mode)")
                XCTAssertLessThanOrEqual(footprint + 6, width + 0.1,
                    "\(label) \(mode): frame must not spill beyond safe screen width")
                XCTAssertLessThanOrEqual(footprint, height - 110,
                    "\(label) \(mode): frame must leave vertical room for controls")
            }
        }
        // Build 4.2: give the surrounding UI and grid edges more breathing
        // room while keeping the puzzle board large and touch-friendly.
        let classic = BerryGameplayLayout.boardSize(
            width: 393, height: 759, topInset: 0,
            bottomInset: 0, mode: .classic)
        XCTAssertEqual(classic, 393 * 0.87, accuracy: 0.5)
        XCTAssertEqual(BerryBoardContainment.fullFrameSide(playableSide: classic),
                       classic + 22, accuracy: 0.5)
    }

    func testEveryEightAndTwelveCellCenterMapsWithFrameExcluded() {
        let piece = BerryPiece(points: [.init(row: 0, col: 0)], tint: 0)
        for width: CGFloat in [320, 375, 393, 430] {
            for side in [8, 12] {
                let mode: BerryMode = side == 8 ? .classic : .superHard
                let playable = BerryGameplayLayout.boardSize(
                    width: width, height: 759, topInset: 0, bottomInset: 0,
                    mode: mode)
                let rim = BerryGameplayLayout.boardTouchMargin
                // Frame decoration is intentionally absent from UIKit rect.
                let tracker = CGRect(x: 18, y: 130, width: playable + 2 * rim,
                                     height: playable + 2 * rim)
                let inner = BerryBoardContainment.playableRect(from: tracker)
                XCTAssertEqual(inner.width, playable, accuracy: 0.01)
                let cell = (inner.width - CGFloat(side - 1) * 3) / CGFloat(side)
                let stride = cell + 3
                for row in 0..<side {
                    for col in 0..<side {
                        let pt = CGPoint(x: inner.minX + CGFloat(col) * stride + cell / 2,
                                         y: inner.minY + CGFloat(row) * stride + cell / 2)
                        let target = BerryDropGeometry.target(
                            for: pt, board: tracker, piece: piece, side: side)
                        XCTAssertEqual(target?.row, row, "incorrect row at board edge")
                        XCTAssertEqual(target?.col, col, "incorrect column at board edge")
                    }
                }
            }
        }
    }

    func testNoPartialPreviewCanPaintOutsideVisibleCells() {
        for side in [8, 12] {
            for row in -3..<(side + 3) {
                for col in -3..<(side + 3) {
                    let allowed = BerryBoardContainment.contains(row: row, col: col, side: side)
                    XCTAssertEqual(allowed, (0..<side).contains(row) &&
                                            (0..<side).contains(col))
                }
            }
            XCTAssertFalse(BerryBoardContainment.contains(row: -1, col: 0, side: side))
            XCTAssertFalse(BerryBoardContainment.contains(row: side, col: side - 1, side: side))
            XCTAssertFalse(BerryBoardContainment.contains(row: 0, col: side, side: side))
        }

        let piece = BerryPiece(points: [
            .init(row: 0, col: 0), .init(row: 0, col: 1),
            .init(row: 0, col: 2)
        ], tint: 1)
        let clearBoard = Array(repeating: Array<Int?>(repeating: nil, count: 8), count: 8)
        let game = BerryEngine(board: clearBoard, tray: [piece, nil, nil])
        XCTAssertTrue(game.canPlace(piece, row: 0, col: 5))
        XCTAssertFalse(game.canPlace(piece, row: 0, col: 6),
                       "right-edge placement must be rejected rather than overflowing")
        XCTAssertFalse(game.canPlace(piece, row: -1, col: 0))
        XCTAssertFalse(game.canPlace(piece, row: 8, col: 0))
    }

    func testRealFrameLeavesRoomAroundTouchTargetAndTray() {
        let old = UserDefaults.standard.object(forKey: "berryblockblast.welcomed.v3")
        UserDefaults.standard.set(true, forKey: "berryblockblast.welcomed.v3")
        defer {
            if let old { UserDefaults.standard.set(old, forKey: "berryblockblast.welcomed.v3") }
            else { UserDefaults.standard.removeObject(forKey: "berryblockblast.welcomed.v3") }
        }

        for mode: BerryMode in [.classic, .endless, .superHard] {
            let screen = CGSize(width: 393, height: 759)
            let host = UIHostingController(rootView: BerryGameView(mode: mode, onExit: {})
                .frame(width: screen.width, height: screen.height))
            let window = UIWindow(frame: CGRect(origin: .zero, size: screen))
            window.rootViewController = host
            window.isHidden = false
            host.view.frame = window.bounds
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
            host.view.layoutIfNeeded()
            let descendants = everyView(host.view)
            let boards = descendants.compactMap { $0 as? BerryBoardWindowTrackingView }
            let trays = descendants.compactMap { $0 as? BerryTouchTrackingView }
            XCTAssertEqual(boards.count, 1, "\(mode) must still track exactly one board")
            XCTAssertEqual(trays.count, 3, "\(mode) must keep all three pieces")
            if let tracker = boards.first, trays.count == 3 {
                let input = tracker.convert(tracker.bounds, to: window)
                let exterior = input.insetBy(dx: -BerryGameplayLayout.gardenFrameInset,
                                            dy: -BerryGameplayLayout.gardenFrameInset)
                XCTAssertGreaterThan(exterior.width, input.width)
                XCTAssertGreaterThanOrEqual(exterior.minX, 0)
                XCTAssertLessThanOrEqual(exterior.maxX, screen.width + 1)
                XCTAssertGreaterThanOrEqual(exterior.minY, 0)
                let trayTop = trays.map { $0.convert($0.bounds, to: window).minY }.min()!
                XCTAssertLessThan(exterior.maxY, trayTop,
                                  "\(mode): new frame must not cover the tray")
            }
            let shot = UIGraphicsImageRenderer(size: screen)
                .image { host.view.layer.render(in: $0.cgContext) }
            let evidence = XCTAttachment(image: shot)
            evidence.name = "Framed-Contained-\(mode.rawValue)"
            evidence.lifetime = .keepAlways
            add(evidence)
            window.isHidden = true
        }
    }

    func testPartlyOffscreenPlacementPreviewRendersWithoutLayoutExpansion() {
        let piece = BerryPiece(points: [
            .init(row: 0, col: 0), .init(row: 0, col: 1),
            .init(row: 0, col: 2)
        ], tint: 3)
        let engine = BerryEngine(seed: 302)
        let preview = BerryDragState(slot: 0, piece: piece,
                                     row: 0, col: 7, allowed: false)
        let playable: CGFloat = 365
        let view = BerryBoard(engine: engine, preview: preview,
                             size: playable, selected: 0,
                             mode: .classic, strawberryUnlocked: false,
                             previewStyle: "ghost")
            .frame(width: playable, height: playable)
        let host = UIHostingController(rootView: view)
        let measured = host.sizeThatFits(in: CGSize(width: playable, height: playable))
        XCTAssertEqual(measured.width, playable, accuracy: 0.5)
        XCTAssertEqual(measured.height, playable, accuracy: 0.5)
    }

    private func everyView(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { everyView($0) }
    }
}
