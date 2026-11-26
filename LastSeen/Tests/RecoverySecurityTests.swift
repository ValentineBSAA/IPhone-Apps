import XCTest
import UIKit
@testable import LastSeen

final class RecoverySecurityTests: XCTestCase {
    func testOpeningPacingAndPausePolicy() {
        XCTAssertEqual(OpeningPace.total, 60)
        XCTAssertEqual(OpeningPace.duration(3), 3)
        XCTAssertTrue(OpeningPace.canAdvance(stage: 3, connected: false, active: true))
        XCTAssertEqual(OpeningPace.duration(1), 12)
        XCTAssertEqual(OpeningPace.duration(2), 30)
        XCTAssertEqual(OpeningPace.duration(4), 15)
        XCTAssertFalse(OpeningPace.canAdvance(stage: 1, connected: false, active: true))
        XCTAssertFalse(OpeningPace.canAdvance(stage: 2, connected: false, active: true))
        XCTAssertFalse(OpeningPace.canAdvance(stage: 2, connected: true, active: false))
        XCTAssertTrue(OpeningPace.canAdvance(stage: 2, connected: true, active: true))
        XCTAssertTrue(OpeningPace.canAdvance(stage: 4, connected: false, active: true))
    }

    func testLiveTranscriptAndCinematicBoundaries() {
        XCTAssertTrue(JailbreakTranscript.lines(stage: 0, elapsed: 0).isEmpty)
        XCTAssertEqual(JailbreakTranscript.lines(stage: 1, elapsed: OpeningPace.duration(1)).count, 38)
        XCTAssertEqual(JailbreakTranscript.lines(stage: 2, elapsed: OpeningPace.duration(2)).count, 123)
        XCTAssertEqual(JailbreakTranscript.lines(stage: 3, elapsed: 0).count, 123)
        for stage in [1, 2] {
            for tick in 1...(OpeningPace.duration(stage) * 4) {
                let previous = JailbreakTranscript.lines(stage: stage, elapsed: (tick - 1) / 4, quarter: (tick - 1) % 4)
                let current = JailbreakTranscript.lines(stage: stage, elapsed: tick / 4, quarter: tick % 4)
                XCTAssertEqual(Array(current.prefix(previous.count)), previous)
                XCTAssertLessThanOrEqual(current.count - previous.count, 2)
            }
        }
        XCTAssertGreaterThan(JailbreakTranscript.lines(stage: 1, elapsed: 0, quarter: 2).count, 0)
        XCTAssertEqual(JailbreakTranscript.lines(stage: 1, elapsed: 12), JailbreakTranscript.lines(stage: 2, elapsed: 0))
        XCTAssertEqual(JailbreakTranscript.lines(stage: 2, elapsed: 30), JailbreakTranscript.lines(stage: 3, elapsed: 0))
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

    func testAuthenticationCallbackRequiresCurrentEligibleForegroundRequest() {
        XCTAssertTrue(OwnerSecurityPolicy.acceptsCallback(currentRequest: true, eligible: true, background: false))
        XCTAssertFalse(OwnerSecurityPolicy.acceptsCallback(currentRequest: false, eligible: true, background: false))
        XCTAssertFalse(OwnerSecurityPolicy.acceptsCallback(currentRequest: true, eligible: false, background: false))
        XCTAssertFalse(OwnerSecurityPolicy.acceptsCallback(currentRequest: true, eligible: true, background: true))
    }

    func testProtectedDisplayRequiresLiveOwnerSessionAndCheckpoint() {
        for session in [false,true] {
            for passcode in [false,true] {
                for owner in [false,true] {
                    for appearance in [false,true] {
                        for active in [false,true] {
                            for current in [false,true] {
                                XCTAssertEqual(OwnerSecurityPolicy.canDisplayProtected(session:session,passcodeSession:passcode,ownerVerified:owner,appearanceEnrolled:appearance,active:active,sameCheckpoint:current),
                                               session && owner && active && current && (passcode || appearance))
                            }
                        }
                    }
                }
            }
        }
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
