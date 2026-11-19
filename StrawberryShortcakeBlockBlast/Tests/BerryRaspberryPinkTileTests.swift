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
}
