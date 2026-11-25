import XCTest
import UIKit
@testable import LastSeen

final class RecoverySecurityTests: XCTestCase {
    func testOpeningPacingAndPausePolicy() {
        XCTAssertEqual(OpeningPace.total, 125)
        XCTAssertEqual(OpeningPace.duration(1), 25)
        XCTAssertEqual(OpeningPace.duration(2), 85)
        XCTAssertEqual(OpeningPace.duration(4), 15)
        XCTAssertFalse(OpeningPace.canAdvance(stage: 1, connected: false, active: true))
        XCTAssertFalse(OpeningPace.canAdvance(stage: 2, connected: false, active: true))
        XCTAssertFalse(OpeningPace.canAdvance(stage: 2, connected: true, active: false))
        XCTAssertTrue(OpeningPace.canAdvance(stage: 2, connected: true, active: true))
        XCTAssertTrue(OpeningPace.canAdvance(stage: 4, connected: false, active: true))
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
