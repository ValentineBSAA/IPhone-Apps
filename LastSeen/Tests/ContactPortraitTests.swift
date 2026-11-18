import XCTest
import UIKit
@testable import LastSeen

@MainActor
final class ContactPortraitTests: XCTestCase {
    // These are the ten exact names created by import_contacts.py.
    // A build with assets merely listed in a ZIP is not sufficient:
    // UIKit must actually resolve them from LastSeen.app's compiled catalog.
    private let mandatoryImages = [
        "Contact_Nora_01", "Contact_Nora_02",
        "Contact_Nora_03", "Contact_Nora_04",
        "Contact_Eli_01", "Contact_Eli_02", "Contact_Eli_03",
        "Contact_Unit7_01", "Contact_Unit7_02", "Contact_Unit7_03"
    ]

    func testAllTenCharacterPhotographsLoadFromCompiledAppAssets() {
        XCTAssertEqual(Set(mandatoryImages).count, 10)
        for name in mandatoryImages {
            guard let image = PortraitImages.load(name) else {
                XCTFail("Missing UIImage asset in compiled iPhone app: \(name)")
                continue
            }
            XCTAssertGreaterThanOrEqual(image.size.width, 200, name)
            XCTAssertGreaterThanOrEqual(image.size.height, 200, name)
        }
    }

    func testEveryVisibleConversationHasAnActualPortrait() {
        // The new neighbors were the ones silently falling back to initials.
        let primary = [
            "Contact_Nora_01", "Contact_Eli_01", "Contact_Unit7_01"
        ]
        let secondary = Neighbor.allCases.map(\.portraitAssetName)
        XCTAssertEqual(secondary.count, 2)
        XCTAssertEqual(Set(primary + secondary).count, 5,
                       "Two different characters may not use the same default photo")
        for name in primary + secondary {
            XCTAssertNotNil(PortraitImages.load(name),
                            "The contact image used on screen is missing: \(name)")
        }
    }

    func testNeighborPortraitsAreDistinctAndStable() {
        XCTAssertEqual(Neighbor.maya.portraitAssetName, "Contact_Maya")
        XCTAssertEqual(Neighbor.denise.portraitAssetName, "Contact_Denise")
        XCTAssertNotEqual(Neighbor.maya.portraitAssetName,
                          Neighbor.denise.portraitAssetName)
        XCTAssertFalse(Neighbor.maya.portraitAssetName.hasPrefix("Contact_Nora"))
        XCTAssertFalse(Neighbor.denise.portraitAssetName.hasPrefix("Contact_Nora"))

    }
}
