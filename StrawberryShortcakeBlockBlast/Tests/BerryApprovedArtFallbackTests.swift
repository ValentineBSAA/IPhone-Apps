import UIKit
import XCTest
@testable import BerryBlockBlast

/// D4 art integration: don't introduce blank Village/Quest/Journal graphics
/// while exact approved artwork has not yet arrived in the asset catalog.
@MainActor
final class BerryApprovedArtFallbackTests: XCTestCase {
    func testAllThreeMissingImageReferencesHaveExistingApprovedFallbacks() {
        XCTAssertEqual(BerryArtResolver.temporaryFallbacks.count, 3)
        for (missingName, fallbackName) in BerryArtResolver.temporaryFallbacks {
            XCTAssertFalse(missingName.isEmpty)
            XCTAssertNotNil(UIImage(named: fallbackName),
                            "Approved fallback \(fallbackName) must be bundled")
        }
    }

    func testResolverShowsMissingApprovedFallbackAndPrefersExactWhenAvailable() {
        for (requested, approvedFallback) in BerryArtResolver.temporaryFallbacks {
            let expected = UIImage(named: requested) == nil ? approvedFallback : requested
            XCTAssertEqual(BerryArtResolver.displayName(for: requested), expected)
        }
    }

    func testVillageQuestJournalNamesResolveToRealUIImageOnSimulator() {
        for requested in ["BerryVillageMap", "BerryQuestBoardArt", "BerryJournalArt"] {
            let selectedName = BerryArtResolver.displayName(for: requested)
            XCTAssertNotNil(UIImage(named: selectedName),
                            "Missing image \(requested) resolved as \(selectedName)")
        }
    }

    func testOtherApprovedAndUnknownNamesRemainUnchanged() {
        for valid in ["BerryStory", "HarvestReward", "Milestone",
                      "CottageDecorations", "DailyHarvest"] {
            XCTAssertEqual(BerryArtResolver.displayName(for: valid), valid)
            XCTAssertNotNil(UIImage(named: valid))
        }
        XCTAssertEqual(BerryArtResolver.displayName(for: "NotAnApprovedAsset"),
                       "NotAnApprovedAsset")
    }
}
