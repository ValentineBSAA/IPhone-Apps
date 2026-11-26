import XCTest
import UIKit
import AVFoundation
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
    func testFourRestartRecordingsDecodeAsFiniteOneShotAudio() throws {
        let bundle = Bundle(for: GameStore.self)
        XCTAssertEqual(Set(RestartAudio.assetNames).count, 4)
        for name in RestartAudio.assetNames {
            let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "wav"), name)
            let audio = try AVAudioPlayer(contentsOf: url)
            XCTAssertTrue(audio.duration.isFinite, name)
            XCTAssertGreaterThan(audio.duration, 0, name)
            XCTAssertEqual(audio.numberOfLoops, 0, name)
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
