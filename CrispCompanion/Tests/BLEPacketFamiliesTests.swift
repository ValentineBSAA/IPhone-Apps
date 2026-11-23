import XCTest
import CoreBluetooth
@testable import CrispCompanion

final class BLEPacketFamiliesTests: XCTestCase {
    // All frames are fabricated for XCTest. The kettle header is NOT
    // assumed to apply to the actual air fryer.
    private func packet(type: UInt8, sequence: UInt8, check: UInt8,
                        magic: UInt8 = 0xA5, declaredPayload: UInt8 = 4) -> Data {
        Data([magic, type, sequence, declaredPayload, 0, check, 1, 2, 3, 4])
    }

    func testThreePhysicalPromptsAndManualStart() {
        XCTAssertEqual(BLEPacketFamilyPolicy.sequence, [.airFry, .reheat, .airFry])
        XCTAssertEqual(BLEPacketFamilyPolicy.baselineSeconds, 10)
        XCTAssertEqual(BLEPacketFamilyPolicy.windowSeconds, 9)
        let model = BLEPacketFamilyModel()
        XCTAssertFalse(model.running)
        XCTAssertNil(model.result)
    }

    func testUnknownTypeStillGetsAnonymousConsistentCategory() {
        var s = BLEPacketFamilyAccumulator()
        s.observe(packet(type: 0x99, sequence: 30, check: 100), phase: 0)
        s.observe(packet(type: 0x99, sequence: 31, check: 99), phase: 1)
        s.observe(packet(type: 0x99, sequence: 32, check: 98), phase: 2)
        let r = s.safeReport()
        XCTAssertEqual(r.stepEvents, [1,1,1])
        XCTAssertEqual(r.idleEvents, 0)
        XCTAssertEqual(r.distinctAnonymousTypes, 1)
        XCTAssertEqual(r.anonymousTypeDistribution, ["none", "A×1", "A×1", "A×1"])
        XCTAssertEqual(r.a5MagicMatches, 3)
        XCTAssertEqual(r.declaredLengthMatches, 3)
        XCTAssertEqual(r.bothMagicAndLengthMatches, 3)
        XCTAssertEqual(r.fullDocumentedKettleTypeMatches, 0)
        XCTAssertEqual(r.equalLengthAdjacentPairs, 2)
        XCTAssertEqual(r.sameAnonymousTypePairs, 2)
        XCTAssertEqual(r.sequencePlusOnePairs, 2)
        XCTAssertEqual(r.constantSequenceSumPairs, 2)
    }

    func testChangingTypesGetSeparateLabelsThenReturnToOriginal() {
        var s = BLEPacketFamilyAccumulator()
        s.observe(packet(type: 0x43, sequence: 10, check: 20), phase: 0)
        s.observe(packet(type: 0x99, sequence: 11, check: 19), phase: 1)
        s.observe(packet(type: 0x43, sequence: 12, check: 18), phase: 2)
        let r = s.safeReport()
        XCTAssertEqual(r.distinctAnonymousTypes, 2)
        XCTAssertEqual(r.anonymousTypeDistribution, ["none", "A×1", "B×1", "A×1"])
        XCTAssertEqual(r.sameAnonymousTypePairs, 0)
        XCTAssertEqual(r.sequencePlusOnePairs, 2)
    }

    func testRealisticIdleAndMultiplePacketsPerWindow() {
        var s = BLEPacketFamilyAccumulator()
        s.observe(packet(type: 0x88, sequence: 1, check: 2), phase: -1)
        s.observe(packet(type: 0x88, sequence: 2, check: 1), phase: 0)
        s.observe(packet(type: 0x66, sequence: 3, check: 0), phase: 0)
        let r = s.safeReport()
        XCTAssertEqual(r.idleEvents, 1)
        XCTAssertEqual(r.stepEvents, [2,0,0])
        XCTAssertEqual(r.anonymousTypeDistribution, ["A×1", "A×1,B×1", "none", "none"])
    }

    func testBadMagicAndWrongLengthNeverPassFullHeader() {
        var s = BLEPacketFamilyAccumulator()
        s.observe(packet(type: 0x22, sequence: 1, check: 3,
                         magic: 0x55), phase: 0)
        s.observe(packet(type: 0x22, sequence: 2, check: 2,
                         declaredPayload: 5), phase: 1)
        let r = s.safeReport()
        XCTAssertEqual(r.knownKettleTypeMatches, 2)
        XCTAssertEqual(r.a5MagicMatches, 1)
        XCTAssertEqual(r.declaredLengthMatches, 1)
        XCTAssertEqual(r.bothMagicAndLengthMatches, 0)
        XCTAssertEqual(r.fullDocumentedKettleTypeMatches, 0)
    }

    func testShortFrameBreaksAdjacentComparison() {
        var s = BLEPacketFamilyAccumulator()
        s.observe(packet(type: 0x70, sequence: 1, check: 6), phase: 0)
        s.observe(Data([0xA5, 0x70, 0x02]), phase: 1)
        s.observe(packet(type: 0x70, sequence: 3, check: 4), phase: 2)
        let r = s.safeReport()
        XCTAssertEqual(r.shortFrames, 1)
        XCTAssertEqual(r.packetLengthSet, [3,10])
        XCTAssertEqual(r.equalLengthAdjacentPairs, 0)
        XCTAssertEqual(r.distinctAnonymousTypes, 1)
    }

    func testDifferentPacketLengthsBreakAdjacentComparison() {
        var s = BLEPacketFamilyAccumulator()
        s.observe(packet(type: 0x70, sequence: 1, check: 6), phase: 0)
        var longer = packet(type: 0x70, sequence: 2, check: 5)
        longer.append(1)
        s.observe(longer, phase: 1)
        XCTAssertEqual(s.safeReport().equalLengthAdjacentPairs, 0)
        XCTAssertEqual(s.safeReport().packetLengthSet, [10,11])
    }

    func testReportHasNoActualTypeSequenceOrPayloadValues() {
        var s = BLEPacketFamilyAccumulator()
        s.observe(packet(type: 0x99, sequence: 0x40, check: 0x74), phase: 0)
        let text = s.safeReport().safeText
        XCTAssertTrue(text.contains("Air Fry 1 categories: A×1"))
        XCTAssertTrue(text.contains("Documented kettle types 12/22: 0"))
        XCTAssertFalse(text.contains("A5 99 40"))
        XCTAssertFalse(text.contains("payload="))
        XCTAssertFalse(text.contains("0x99"))
        XCTAssertFalse(text.contains("0x40"))
        XCTAssertFalse(text.contains("deviceUUID="))
    }

    func testCapAndErasure() {
        var s = BLEPacketFamilyAccumulator()
        for i in 0..<(BLEPacketFamilyPolicy.maximumAnalyzedFrames + 2) {
            s.observe(packet(type: 0x70, sequence: UInt8(i & 0xff), check: 0), phase: 0)
        }
        XCTAssertTrue(s.safeReport().capped)
        XCTAssertEqual(s.safeReport().analyzedFrames, BLEPacketFamilyPolicy.maximumAnalyzedFrames)
        XCTAssertEqual(s.safeReport().stepEvents[0], BLEPacketFamilyPolicy.maximumAnalyzedFrames + 2)
        s.clear()
        XCTAssertEqual(s.safeReport().analyzedFrames, 0)
        XCTAssertEqual(s.safeReport().distinctAnonymousTypes, 0)
        XCTAssertEqual(s.safeReport().equalLengthAdjacentPairs, 0)
    }

    func testStrictFFF1NotificationOnlyAndNoAutoConnection() {
        XCTAssertTrue(BLEPacketFamilyPolicy.allows(CBUUID(string:"FFF0"),
                                                   CBUUID(string:"FFF1")))
        XCTAssertFalse(BLEPacketFamilyPolicy.allows(CBUUID(string:"FFF0"),
                                                    CBUUID(string:"FFF2")))
        XCTAssertFalse(BLEPacketFamilyPolicy.allows(
            CBUUID(string:"F000FFC0-0451-4000-B000-000000000000"),
            CBUUID(string:"F000FFC1-0451-4000-B000-000000000000")))
    }
}
