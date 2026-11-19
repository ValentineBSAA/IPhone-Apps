import XCTest
@testable import BerryBlockBlast

final class BerryBuild4PolishTests: XCTestCase {
    func testComboPreviewMilestonesArePresentationOnlyValues() {
        // These constructors only create Views. They do not own or alter a
        // BerryGameSession, the score engine, or persistent rewards.
        let milestones = [10, 20, 30, 50]
        let views = milestones.map { BerryComboMilestoneBanner(milestone: $0) }
        XCTAssertEqual(views.map(\.milestone), milestones)
    }

    func testPolishBuildIdentityIsDistinct() {
        XCTAssertEqual(BerryBuildIdentity.revisionName, "BUILD 4.2 • RESPONSIVE QA")
        XCTAssertEqual(BerryBuildIdentity.sourceBranch, "feature/berry-build4-r3-responsive-layout")
    }
}
