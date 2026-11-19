import XCTest
import UIKit
import SwiftUI
@testable import BerryBlockBlast

@MainActor
final class BerryRaspberryPinkTileTests: XCTestCase {
    func testApprovedPinkTileIsBundledForDefaultBlockRendering() {
        let image = UIImage(named: "Tile_Pink")
        XCTAssertNotNil(image, "The approved dark raspberry tile must be in Assets.car")
        if let image {
            XCTAssertGreaterThanOrEqual(image.size.width, 128)
            XCTAssertEqual(image.size.width, image.size.height, accuracy: 0.01)
        }
    }

    func testDefaultPinkFallbackIsDistinctFromBoardBackground() {
        // Exact asset availability is checked above. The fallback is deeper
        // raspberry and must not regress to light frosting pink.
        XCTAssertEqual(BerryStyle.color(for: 1), Color(red: 0.77, green: 0.05, blue: 0.30))
    }

    func testCorrectPinkIndicesAcrossEveryGameMode() {
        // This covers Classic and Endless, plus the Story/Blitz/Nightmare
        // tint orders. Negative/overflow tints normalize to the same color.
        let cases: [(BerryMode, Set<Int>)] = [
            (.classic, [1]), (.endless, [1]),
            (.story, [0, 3]), (.challenge, [3]),
            (.superHard, [5]), (.daily, []), (.cozy, [])
        ]
        for (mode, pinkIndices) in cases {
            for tint in -12...17 {
                let normalized = (tint % 6 + 6) % 6
                XCTAssertEqual(
                    BerryPinkTilePolicy.shouldUseApprovedTile(
                        tint: tint, mode: mode, skin: "default"),
                    pinkIndices.contains(normalized),
                    "Mode \(mode), tint \(tint): default pink artwork mapped incorrectly")
            }
        }
    }

    func testBoutiqueSkinsAndPreviewsNeverBorrowDefaultPinkArtwork() {
        // Keep this set representative of purchasable and previewed styles.
        // The rule rejects ANY non-default skin, including future additions.
        let skins = [
            "strawberry-fruit", "blueberry-blocks", "vanilla-blocks",
            "raspberry-blocks", "lemon-blocks", "chocolate-blocks",
            "mint-blocks", "blackberry-blocks", "future-boutique-skin"
        ]
        for mode in BerryMode.allCases {
            for tint in 0..<6 {
                for skin in skins {
                    XCTAssertFalse(
                        BerryPinkTilePolicy.shouldUseApprovedTile(
                            tint: tint, mode: mode, skin: skin),
                        "Boutique skin \(skin), mode \(mode) must not be replaced by default pink")
                }
            }
        }
    }

    func testReturningToOriginalBlocksRestoresApprovedPink() {
        XCTAssertFalse(BerryPinkTilePolicy.shouldUseApprovedTile(
            tint: 1, mode: .endless, skin: "blueberry-blocks"))
        XCTAssertTrue(BerryPinkTilePolicy.shouldUseApprovedTile(
            tint: 1, mode: .endless, skin: "default"))
        XCTAssertFalse(BerryPinkTilePolicy.shouldUseApprovedTile(
            tint: 2, mode: .endless, skin: "default"))
    }
}
