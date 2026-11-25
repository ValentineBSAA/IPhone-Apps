import XCTest
import UIKit
@testable import LastSeen

final class RecoverySecurityTests: XCTestCase {
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
