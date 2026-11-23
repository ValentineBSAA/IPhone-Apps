import XCTest
import CoreBluetooth
@testable import CrispCompanion

final class BLEHeaderCheckTests: XCTestCase {
    // Kettle-style synthetic examples only. No heater commands or real owner data.
    private func testFrame(seq: UInt8, checksum: UInt8, type: UInt8 = 0x22) -> Data {
        Data([0xA5, type, seq, 0x04, 0x00, checksum, 0x00, 0x00, 0x00, 0x00])
    }

    func testTenByteKettleHeaderAndSequenceRelations() {
        var counter = BLEHeaderCounter()
        counter.observe(testFrame(seq: 0x40, checksum: 0x74), duringIdle: true)
        counter.observe(testFrame(seq: 0x41, checksum: 0x73), duringIdle: false)
        counter.observe(testFrame(seq: 0x42, checksum: 0x72), duringIdle: false)
        let report = counter.summary()
        XCTAssertEqual(report.idleNotifications, 1)
        XCTAssertEqual(report.changeNotifications, 2)
        XCTAssertEqual(report.tenByteFrames, 3)
        XCTAssertEqual(report.a5MagicMatches, 3)
        XCTAssertEqual(report.knownKettleTypes, 3)
        XCTAssertEqual(report.declaredLengthMatches, 3)
        XCTAssertEqual(report.fullKettleHeaderMatches, 3)
        XCTAssertEqual(report.comparedAdjacentPairs, 2)
        XCTAssertEqual(report.sequencePlusOnePairs, 2)
        XCTAssertEqual(report.constantSumPairs, 2)
    }

    func testMissingMagicRejectsFullMatchWithoutTreatingHeaderAsProof() {
        var counter = BLEHeaderCounter()
        counter.observe(Data([0xB0, 0x22, 0x11, 0x04, 0x00, 0xA3, 0,0,0,0]),
                        duringIdle: false)
        let report = counter.summary()
        XCTAssertEqual(report.tenByteFrames, 1)
        XCTAssertEqual(report.a5MagicMatches, 0)
        XCTAssertEqual(report.declaredLengthMatches, 1)
        XCTAssertEqual(report.fullKettleHeaderMatches, 0)
    }

    func testWrongTypeOrDeclaredLengthRejectsCompleteHeaderMatch() {
        var counter = BLEHeaderCounter()
        counter.observe(testFrame(seq: 5, checksum: 10, type: 0x99),
                        duringIdle: false)
        counter.observe(Data([0xA5,0x22,0x06,0x05,0x00,0x10,0,0,0,0]),
                        duringIdle: false)
        let report = counter.summary()
        XCTAssertEqual(report.knownKettleTypes, 1)
        XCTAssertEqual(report.declaredLengthMatches, 1)
        XCTAssertEqual(report.fullKettleHeaderMatches, 0)
    }

    func testTooShortMessageIsNotInterpretedAsHeader() {
        var counter = BLEHeaderCounter()
        counter.observe(Data([0xA5,0x22,0x01]), duringIdle: true)
        let report = counter.summary()
        XCTAssertEqual(report.shortFrames, 1)
        XCTAssertEqual(report.headerCandidates, 0)
        XCTAssertEqual(report.fullKettleHeaderMatches, 0)
    }

    func testCounterWrapsAtFF() {
        var counter = BLEHeaderCounter()
        counter.observe(testFrame(seq: 255, checksum: 0xB5), duringIdle: false)
        counter.observe(testFrame(seq: 0, checksum: 0xB4), duringIdle: false)
        let report = counter.summary()
        XCTAssertEqual(report.sequencePlusOnePairs, 1)
        XCTAssertEqual(report.constantSumPairs, 1)
    }

    func testCountCapAndResetClearTemporarySequence() {
        var counter = BLEHeaderCounter()
        for i in 0..<(BLEHeaderCheckPolicy.maxFrames + 4) {
            counter.observe(testFrame(seq: UInt8(i & 0xff), checksum: 0),
                            duringIdle: false)
        }
        XCTAssertTrue(counter.summary().capped)
        XCTAssertEqual(counter.summary().headerCandidates, BLEHeaderCheckPolicy.maxFrames)
        counter.reset()
        XCTAssertEqual(counter.summary().headerCandidates, 0)
        XCTAssertEqual(counter.summary().comparedAdjacentPairs, 0)
    }

    func testSummaryContainsOnlyCountsAndNoRawPacketValues() {
        var counter = BLEHeaderCounter()
        counter.observe(testFrame(seq: 0x40, checksum: 0x74), duringIdle: false)
        let text = counter.summary().safeText
        XCTAssertTrue(text.contains("First-byte kettle magic A5 matches: 1"))
        XCTAssertFalse(text.contains("A5 22 40"))
        XCTAssertFalse(text.contains("payload="))
        XCTAssertFalse(text.contains("deviceUUID="))
        XCTAssertFalse(text.contains("raw bytes"))
    }

    func testBLEIsManualAndFFF1Only() {
        let model = BLEHeaderCheckModel()
        XCTAssertFalse(model.running)
        XCTAssertNil(model.report)
        XCTAssertEqual(BLEHeaderCheckPolicy.baselineSeconds, 10)
        XCTAssertEqual(BLEHeaderCheckPolicy.physicalSeconds, 12)
        XCTAssertTrue(BLEHeaderCheckPolicy.permits(
            CBUUID(string: "FFF0"), CBUUID(string: "FFF1")))
        XCTAssertFalse(BLEHeaderCheckPolicy.permits(
            CBUUID(string: "FFF0"), CBUUID(string: "FFF2")))
        XCTAssertFalse(BLEHeaderCheckPolicy.permits(
            CBUUID(string: "F000FFC0-0451-4000-B000-000000000000"),
            CBUUID(string: "F000FFC1-0451-4000-B000-000000000000")))
    }
}
