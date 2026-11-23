import XCTest
import CoreBluetooth
@testable import CrispCompanion

final class BLEPacketComparisonTests: XCTestCase {
    func testIdenticalMessagesAreSharedAcrossPhases() {
        var comparator = BLEInMemoryComparator()
        comparator.record(Data([1, 2, 3]), channel: "FFF1", phase: .baseline)
        comparator.record(Data([1, 2, 3]), channel: "FFF1", phase: .baseline)
        comparator.record(Data([1, 2, 3]), channel: "FFF1", phase: .adjustments)
        XCTAssertEqual(comparator.summary.baselineEvents, 2)
        XCTAssertEqual(comparator.summary.baselineUnique, 1)
        XCTAssertEqual(comparator.summary.adjustmentUnique, 1)
        XCTAssertEqual(comparator.summary.sharedPatterns, 1)
        XCTAssertEqual(comparator.summary.newPatterns, 0)
    }

    func testChangedPacketCountsAsNewWithinSameChannel() {
        var comparator = BLEInMemoryComparator()
        comparator.record(Data([1, 2, 3]), channel: "FFF1", phase: .baseline)
        comparator.record(Data([1, 2, 4]), channel: "FFF1", phase: .adjustments)
        XCTAssertEqual(comparator.summary.newPatterns, 1)
        XCTAssertEqual(comparator.summary.sharedPatterns, 0)
        comparator.markPhysicalAdjustment()
        XCTAssertEqual(comparator.summary.markers, 1)
    }

    func testSameBytesDifferentChannelNotConflated() {
        var comparator = BLEInMemoryComparator()
        comparator.record(Data([7]), channel: "FFF1", phase: .baseline)
        comparator.record(Data([7]), channel: BLEObservationPolicy.secondaryNotify.uuidString,
                          phase: .adjustments)
        XCTAssertEqual(comparator.summary.sharedPatterns, 0)
        XCTAssertEqual(comparator.summary.newPatterns, 1)
        XCTAssertEqual(comparator.summary.adjustmentFFE2, 1)
    }

    func testResetErasesBothComparisonStages() {
        var comparator = BLEInMemoryComparator()
        comparator.record(Data([5]), channel: "FFF1", phase: .baseline)
        comparator.markPhysicalAdjustment()
        comparator.reset()
        XCTAssertEqual(comparator.summary, BLEComparisonSummary())
    }

    func testNoConnectionOnInitializationAnd45SecondWindow() {
        let model = BLEPacketComparatorModel()
        XCTAssertFalse(model.running)
        XCTAssertFalse(model.baselineComplete)
        XCTAssertFalse(model.adjustmentsComplete)
        XCTAssertEqual(BLEObservationPolicy.duration, 45)
    }

    func testOnlyKnownNotificationTargetsPermitted() {
        XCTAssertEqual(BLEObservationPolicy.allowedServices.count, 2)
        XCTAssertFalse(BLEObservationPolicy.allowsNotification(
            service: CBUUID(string: "F000FFC0-0451-4000-B000-000000000000"),
            characteristic: CBUUID(string: "F000FFC1-0451-4000-B000-000000000000")
        ))
    }
}
