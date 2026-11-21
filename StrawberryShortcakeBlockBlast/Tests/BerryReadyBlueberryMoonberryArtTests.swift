import UIKit
import XCTest
@testable import BerryBlockBlast

/// Built-in offline artwork readiness checks. The preview must never imply
/// that a real Moonberry balance or Night Market checkout exists yet.
@MainActor
final class BerryReadyBlueberryMoonberryArtTests: XCTestCase {
    func testSixApprovedPreviewImagesAreRealBundledPNGs() {
        let approved = [
            "Moonberry_Currency",
            "Night_Moonberry_Currency",
            "Approved_Night_Market_Storefront",
            "Night_Approved_Night_Market_Storefront",
            "BerryRewardBlueberrySparkle",
            "BerryRewardMoonberryNightmare"
        ]
        for name in approved {
            XCTAssertNotNil(UIImage(named: name),
                            "Approved artwork image missing from this iPhone app: \(name)")
        }
    }

    func testBlueberryAndMoonberryRewardsAlreadyExistInTrophyCatalog() {
        XCTAssertTrue(BerryTrophyCatalog.rewards.contains {
            $0.id == "blueberry-sparkle" && $0.artwork == "BerryRewardBlueberrySparkle"
        })
        XCTAssertTrue(BerryTrophyCatalog.rewards.contains {
            $0.id == "moonberry-nightmare" && $0.artwork == "BerryRewardMoonberryNightmare"
        })
    }
}
