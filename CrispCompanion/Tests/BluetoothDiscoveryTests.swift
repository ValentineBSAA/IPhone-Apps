import XCTest
@testable import CrispCompanion

final class BluetoothDiscoveryTests: XCTestCase {
    func testExactModelNamesAreProminent() {
        let exact = BLEDiscovery(id: UUID(), name: "CAF-P583S-KUS", advertisedServices: [], signalStrength: -57)
        XCTAssertTrue(exact.modelMatch)
        XCTAssertTrue(exact.possibleFryer)
        XCTAssertEqual(exact.description, "COSORI Dual Blaze model-name match")
    }

    func testUnrelatedDevicesAreNotGuessed() {
        let tv = BLEDiscovery(id: UUID(), name: "[TV] Samsung", advertisedServices: [], signalStrength: -47)
        XCTAssertFalse(tv.possibleFryer)
        XCTAssertTrue(tv.description.contains("TV"))
        let unnamed = BLEDiscovery(id: UUID(), name: "Unnamed Bluetooth device", advertisedServices: [], signalStrength: -62)
        XCTAssertFalse(unnamed.possibleFryer)
        XCTAssertEqual(unnamed.description, "Unknown Bluetooth device")
    }

    func testNoAutomaticConnectOnLaunch() {
        let model = BluetoothDiscoveryModel()
        XCTAssertFalse(model.scanning)
        XCTAssertFalse(model.inspectionInProgress)
        XCTAssertTrue(model.inspectedServices.isEmpty)
    }
}
