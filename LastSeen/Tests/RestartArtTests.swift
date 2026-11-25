import XCTest
import UIKit
@testable import LastSeen

@MainActor
final class RestartArtTests: XCTestCase {
    func testAllTwentyApprovedImagesAreBundled() {
        let bundle = Bundle(for: GameStore.self)
        XCTAssertEqual(ApprovedArt.opening.count, 10)
        XCTAssertEqual(ApprovedArt.theme.count, 10)
        for name in ApprovedArt.opening + ApprovedArt.theme {
            XCTAssertNotNil(UIImage(named: name, in: bundle, compatibleWith: nil), name)
        }
        XCTAssertEqual(ApprovedArt.themeName(for: "Messages"), "Theme_Messages")
        XCTAssertNil(ApprovedArt.themeName(for: "Calculator"))
        XCTAssertNil(ApprovedArt.themeName(for: "Relay"))
        for name in ["RespringDown","RespringUp","UserspaceDown","UserspaceUp"] {
            XCTAssertNotNil(bundle.url(forResource: name, withExtension: "wav"), name)
        }
    }
    func testOpeningRestartSequence() {
        // OpeningPace total is owned by RecoverySecurityTests; this suite tests restart art only.
        XCTAssertEqual(OpeningPace.duration(4), OpeningPace.reboot)
        XCTAssertEqual(RestartPhase.opening(at: 0), .black)
        XCTAssertEqual(RestartPhase.opening(at: 2), .userspace)
        XCTAssertEqual(RestartPhase.opening(at: 7), .userspace)
        XCTAssertEqual(RestartPhase.opening(at: 8), .black)
        XCTAssertEqual(RestartPhase.opening(at: 10), .respring)
        XCTAssertEqual(RestartPhase.opening(at: 14), .respring)
    }
}
