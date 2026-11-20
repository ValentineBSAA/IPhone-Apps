import XCTest
import UIKit
@testable import BerryBlockBlast

final class BerryBuild4PolishTests: XCTestCase {
    func testComboPreviewMilestonesArePresentationOnlyValues() {
        // These constructors only create Views. They do not own or alter a
        // BerryGameSession, the score engine, or persistent rewards.
        let milestones = [10, 20, 30, 50]
        let views = milestones.map { BerryComboMilestoneBanner(milestone: $0) }
        XCTAssertEqual(views.map(\.milestone), milestones)
    }

    func testApprovedDarkRaspberryPinkTileIsBundled() {
        guard let image = UIImage(named: "Tile_Pink") else {
            XCTFail("Approved darker pink tile missing from Assets.car")
            return
        }
        XCTAssertEqual(image.size.width, 160, accuracy: 0.5)
        XCTAssertEqual(image.size.height, 160, accuracy: 0.5)
    }

    func testPolishBuildIdentityIsDistinct() {
        // Older Build 4.4 identity was deliberately superseded by Build 4.5.
        XCTAssertEqual(BerryBuildIdentity.revisionName, "BUILD 4.5 • FAIR PLAY LAB")
        XCTAssertEqual(BerryBuildIdentity.sourceBranch, "feature/berry-build4-r6-fair-play-lab")
    }
}
