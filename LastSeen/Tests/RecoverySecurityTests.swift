import XCTest
import UIKit
@testable import LastSeen

final class RecoverySecurityTests: XCTestCase {
    func testOpeningPacingAndPausePolicy() {
        XCTAssertEqual(OpeningPace.total, 128)
        XCTAssertEqual(OpeningPace.duration(3), 3)
        XCTAssertTrue(OpeningPace.canAdvance(stage: 3, connected: false, active: true))
        XCTAssertEqual(OpeningPace.duration(1), 25)
        XCTAssertEqual(OpeningPace.duration(2), 85)
        XCTAssertEqual(OpeningPace.duration(4), 15)
        XCTAssertFalse(OpeningPace.canAdvance(stage: 1, connected: false, active: true))
        XCTAssertFalse(OpeningPace.canAdvance(stage: 2, connected: false, active: true))
        XCTAssertFalse(OpeningPace.canAdvance(stage: 2, connected: true, active: false))
        XCTAssertTrue(OpeningPace.canAdvance(stage: 2, connected: true, active: true))
        XCTAssertTrue(OpeningPace.canAdvance(stage: 4, connected: false, active: true))
    }

    func testLiveTranscriptAndCinematicBoundaries() {
        XCTAssertTrue(JailbreakTranscript.lines(stage: 0, elapsed: 0).isEmpty)
        XCTAssertEqual(JailbreakTranscript.lines(stage: 1, elapsed: 25).count, 18)
        XCTAssertEqual(JailbreakTranscript.lines(stage: 2, elapsed: 85).count, 63)
        XCTAssertEqual(JailbreakTranscript.lines(stage: 3, elapsed: 0).count, 63)
        for t in 1...85 {
            let previous = JailbreakTranscript.lines(stage: 2, elapsed: t - 1)
            let current = JailbreakTranscript.lines(stage: 2, elapsed: t)
            XCTAssertEqual(Array(current.prefix(previous.count)), previous)
        }
        XCTAssertEqual(RestartPhase.opening(at: 0), .black)
        XCTAssertEqual(RestartPhase.opening(at: 2), .userspace)
        XCTAssertEqual(RestartPhase.opening(at: 8), .black)
        XCTAssertEqual(RestartPhase.opening(at: 10), .respring)
        XCTAssertEqual(RestartPhase.opening(at: 14), .respring)
    }

    func testExternalPowerProxy() {
        XCTAssertTrue(RecoveryPower.connected(.charging))
        XCTAssertTrue(RecoveryPower.connected(.full))
        XCTAssertFalse(RecoveryPower.connected(.unplugged))
        XCTAssertFalse(RecoveryPower.connected(.unknown))
    }

    func testOwnerCodeAndBiometricGate() {
        XCTAssertTrue(OwnerSecurityPolicy.accepts(OwnerSecurityPolicy.fixtureCode))
        XCTAssertFalse(OwnerSecurityPolicy.accepts(""))
        XCTAssertFalse(OwnerSecurityPolicy.accepts("000000"))
        XCTAssertFalse(OwnerSecurityPolicy.canUseBiometrics(ownerVerified: false, appearanceEnrolled: false))
        XCTAssertFalse(OwnerSecurityPolicy.canUseBiometrics(ownerVerified: true, appearanceEnrolled: false))
        XCTAssertFalse(OwnerSecurityPolicy.canUseBiometrics(ownerVerified: false, appearanceEnrolled: true))
        XCTAssertTrue(OwnerSecurityPolicy.canUseBiometrics(ownerVerified: true, appearanceEnrolled: true))
    }
}
