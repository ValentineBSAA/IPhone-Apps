import XCTest
import CoreGraphics
@testable import BerryBlockBlast

/// Responsive layout guard for both target phones and every player mode.
/// UIKit window tests separately verify actual safe area and hit tracking.
@MainActor
final class BerryResponsiveGameplayLayoutTests: XCTestCase {
    func testEveryModeFitsBothTargetScreensAndCompactSizes() {
        // GeometryReader receives safe-area content points; it must not
        // subtract top or bottom screen cutouts twice.
        let phones: [(String, CGFloat, CGFloat)] = [
            ("iPhone 16e safe area", 390, 751),
            ("iPhone 14 Pro safe area", 393, 759),
            ("compact iPhone", 320, 650),
            ("large iPhone", 430, 835)
        ]
        for (phone, width, height) in phones {
            for mode in BerryMode.allCases {
                let normal = BerryGameplayLayout.boardSize(
                    width: width, height: height,
                    topInset: 0, bottomInset: 0, mode: mode)
                let diagnostics = BerryGameplayLayout.boardSize(
                    width: width, height: height,
                    topInset: 0, bottomInset: 0, mode: mode,
                    touchDiagnostics: true)
                let exterior = BerryBoardContainment.fullFrameSide(playableSide: normal)
                XCTAssertGreaterThanOrEqual(normal, 150,
                    "\(phone) \(mode): board collapsed")
                XCTAssertLessThanOrEqual(normal, width * 0.87 + 0.5,
                    "\(phone) \(mode): board grows beyond the intended breathing room")
                XCTAssertLessThanOrEqual(exterior + 6, width + 0.5,
                    "\(phone) \(mode): frame extends past screen width")
                XCTAssertLessThanOrEqual(exterior, height - 150,
                    "\(phone) \(mode): other gameplay controls have no room")
                XCTAssertLessThanOrEqual(diagnostics, normal + 0.01,
                    "\(phone) \(mode): optional debug status must use available height")
            }
        }
    }

    func testMegaGardenAndModeSpecificRowsConsumeVerticalBudget() {
        let width: CGFloat = 390
        let height: CGFloat = 751
        let standard = BerryGameplayLayout.boardSize(
            width: width, height: height, topInset: 0, bottomInset: 0,
            mode: .endless)
        let mega = BerryGameplayLayout.boardSize(
            width: width, height: height, topInset: 0, bottomInset: 0,
            mode: .endless, megaGarden: true)
        XCTAssertLessThanOrEqual(mega, standard + 0.01)
        let story = BerryGameplayLayout.boardSize(
            width: width, height: height, topInset: 0, bottomInset: 0,
            mode: .story)
        XCTAssertLessThan(story, standard,
            "Story's chapter and dialogue must make space instead of clipping")
        let diagnostics = BerryGameplayLayout.boardSize(
            width: width, height: height, topInset: 0, bottomInset: 0,
            mode: .endless, touchDiagnostics: true)
        XCTAssertLessThanOrEqual(diagnostics, standard + 0.01)
    }

    func testBlossomFrameIsStrictlyExterior() {
        XCTAssertEqual(BerryGameplayLayout.gardenFrameInset, 8)
        XCTAssertEqual(BerryGameplayLayout.boardTouchMargin, 3)
        let inner = CGRect(x: 8, y: 8, width: 339, height: 339)
        let exterior = inner.insetBy(dx: -BerryGameplayLayout.gardenFrameInset,
                                    dy: -BerryGameplayLayout.gardenFrameInset)
        XCTAssertEqual(exterior.width, 355, accuracy: 0.01)
        XCTAssertEqual(inner.minX - exterior.minX, 8, accuracy: 0.01)
        XCTAssertEqual(inner.maxX - exterior.maxX, -8, accuracy: 0.01)
        // The new BerryBlossomEdgeFrame paints only its 7pt outer stroke
        // inside this 8pt gutter. No full-size image is overlaid on gameplay.
    }
}
