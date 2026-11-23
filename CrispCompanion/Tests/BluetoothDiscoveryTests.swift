import XCTest
@testable import CrispCompanion

final class BluetoothDiscoveryTests: XCTestCase {
    func testPossibleManufacturerNameIsOnlyAHint() {
        let candidate = BLEDiscovery(id: UUID(), name: "COSORI-device", advertisedServices: [], signalStrength: -44)
        XCTAssertTrue(candidate.possibleFryer)
        let unknown = BLEDiscovery(id: UUID(), name: "Unnamed Bluetooth device", advertisedServices: [], signalStrength: -43)
        XCTAssertFalse(unknown.possibleFryer)
    }

    func testNoScanningDuringInitialization() {
        let discovery = BluetoothDiscoveryModel()
        XCTAssertFalse(discovery.scanning)
        XCTAssertTrue(discovery.devices.isEmpty)
    }
}
