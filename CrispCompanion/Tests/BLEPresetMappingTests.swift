import XCTest
import CoreBluetooth
@testable import CrispCompanion

final class BLEPresetMappingTests: XCTestCase {
    func testPhysicalPanelOrderHas12UniquePresets() {
        XCTAssertEqual(FryerPresetMap.order.count, 12)
        XCTAssertEqual(Set(FryerPresetMap.order).count, 12)
        XCTAssertEqual(FryerPresetMap.order[0], .chicken)
        XCTAssertEqual(FryerPresetMap.order[1], .vegetables)
        XCTAssertEqual(FryerPresetMap.order[6], .airFry)
        XCTAssertEqual(FryerPresetMap.order[11], .broil)
    }

    func testSameNotificationRepeatsAcrossPasses() {
        var map = PresetSignatureMap()
        map.add(Data([1,2,3]), channel: "FFF1", preset: .chicken, pass: 0)
        map.add(Data([1,2,3]), channel: "FFF1", preset: .chicken, pass: 1)
        let result = map.result(for: .chicken)
        XCTAssertEqual(result.firstPackets, 1)
        XCTAssertEqual(result.secondPackets, 1)
        XCTAssertEqual(result.repeatedPatterns, 1)
        XCTAssertEqual(result.idlePatterns, 0)
    }

    func testDifferentMessagesAreNotFalselyMatched() {
        var map = PresetSignatureMap()
        map.add(Data([1,2,3]), channel: "FFF1", preset: .roast, pass: 0)
        map.add(Data([9,8,7]), channel: "FFF1", preset: .roast, pass: 1)
        XCTAssertEqual(map.result(for: .roast).repeatedPatterns, 0)
    }

    func testSameBytesDifferentBLEChannelsAreNotConflated() {
        var map = PresetSignatureMap()
        map.add(Data([3]), channel: "FFF1", preset: .fries, pass: 0)
        map.add(Data([3]), channel: BLEObservationPolicy.secondaryNotify.uuidString,
                preset: .fries, pass: 1)
        XCTAssertEqual(map.result(for: .fries).repeatedPatterns, 0)
    }

    func testIdlePatternsAreFlaggedAndResetRemovesAllEvidence() {
        var map = PresetSignatureMap()
        map.addIdle(Data([4]), channel: "FFF1")
        map.add(Data([4]), channel: "FFF1", preset: .bake, pass: 0)
        XCTAssertEqual(map.result(for: .bake).idlePatterns, 1)
        map.clear()
        XCTAssertEqual(map.result(for: .bake).firstPackets, 0)
        XCTAssertEqual(map.result(for: .bake).idlePatterns, 0)
    }

    func testNoAutomaticConnectionAndHardGATTAllowlist() {
        let model = BLEPresetMapper()
        XCTAssertFalse(model.connected)
        XCTAssertFalse(model.listening)
        XCTAssertFalse(model.canArm)
        XCTAssertFalse(FryerPresetMap.isAllowed(
            CBUUID(string: "F000FFC0-0451-4000-B000-000000000000"),
            CBUUID(string: "F000FFC1-0451-4000-B000-000000000000")
        ))
        XCTAssertFalse(FryerPresetMap.isAllowed(
            CBUUID(string: "FFF0"), CBUUID(string: "FFF2")
        ))
        XCTAssertEqual(FryerPresetMap.listeningWindow, 5)
    }
}
