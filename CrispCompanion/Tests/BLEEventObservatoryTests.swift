import XCTest
import CoreBluetooth
@testable import CrispCompanion

final class BLEEventObservatoryTests: XCTestCase {
    func testOnlyExactModelNameIsEligible() {
        XCTAssertTrue(BLEObservationPolicy.matchesExactName("CAF-P583S-KUS"))
        XCTAssertTrue(BLEObservationPolicy.matchesExactName(" caf-p583s-kus "))
        XCTAssertFalse(BLEObservationPolicy.matchesExactName("COSORI-device"))
        XCTAssertFalse(BLEObservationPolicy.matchesExactName("CAF-P583S"))
        XCTAssertFalse(BLEObservationPolicy.matchesExactName(""))
    }

    func testOADAndCommandCharacteristicsNeverAllowed() {
        XCTAssertTrue(BLEObservationPolicy.allowsNotification(
            service: CBUUID(string: "FFF0"), characteristic: CBUUID(string: "FFF1")
        ))
        XCTAssertTrue(BLEObservationPolicy.allowsNotification(
            service: CBUUID(string: "F000FFE0-0451-4000-B000-000000000000"),
            characteristic: CBUUID(string: "F000FFE2-0451-4000-B000-000000000000")
        ))
        XCTAssertFalse(BLEObservationPolicy.allowsNotification(
            service: CBUUID(string: "FFF0"), characteristic: CBUUID(string: "FFF2")
        ))
        XCTAssertFalse(BLEObservationPolicy.allowsNotification(
            service: CBUUID(string: "F000FFE0-0451-4000-B000-000000000000"),
            characteristic: CBUUID(string: "F000FFE1-0451-4000-B000-000000000000")
        ))
        XCTAssertFalse(BLEObservationPolicy.allowsNotification(
            service: CBUUID(string: "F000FFC0-0451-4000-B000-000000000000"),
            characteristic: CBUUID(string: "F000FFC1-0451-4000-B000-000000000000")
        ))
        XCTAssertFalse(BLEObservationPolicy.allowedServices.contains(
            CBUUID(string: "F000FFC0-0451-4000-B000-000000000000")
        ))
    }

    func testMetadataDoesNotContainPayloadOrDeviceIdentifiers() {
        let event = BLEObservationEvent(secondsAfterStart: 9, channel: "FFF1", byteCount: 24)
        XCTAssertEqual(event.secondsAfterStart, 9)
        XCTAssertEqual(event.channel, "FFF1")
        XCTAssertEqual(event.byteCount, 24)
        XCTAssertEqual(BLEObservationPolicy.duration, 45)
    }

    func testObserverDoesNotScanOrConnectOnInitialization() {
        let observer = BLEEventObservatory()
        XCTAssertFalse(observer.isRunning)
        XCTAssertFalse(observer.foundExactModel)
        XCTAssertEqual(observer.eventCount, 0)
        XCTAssertTrue(observer.events.isEmpty)
    }
}
