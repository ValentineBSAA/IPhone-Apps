import XCTest
import CoreBluetooth
@testable import CrispCompanion

final class BLEStructureProbeTests: XCTestCase {
    private func frame(_ phase: Int, _ time: Int, _ bytes: [UInt8]) -> BLEStructureFrame {
        BLEStructureFrame(phase: phase, elapsedTenths: time, bytes: Data(bytes))
    }

    func testThreeTapSequenceAndNoImplicitBluetoothConnection() {
        XCTAssertEqual(BLEStructurePolicy.sequence, [.airFry, .reheat, .airFry])
        XCTAssertEqual(BLEStructurePolicy.idleSeconds, 10)
        XCTAssertEqual(BLEStructurePolicy.phaseSeconds, 9)
        let model = BLEStructureProbeModel()
        XCTAssertFalse(model.running)
        XCTAssertNil(model.result)
    }

    func testSumHeuristicAndPromptTimingWithoutExposingValues() {
        let frames = [
            frame(-1, 4, [0, 0, 1, 0, 0, 20]),
            frame(0, 12, [1, 1, 1, 4, 5, 20]),
            frame(1, 25, [1, 1, 2, 4, 5, 19]),
            frame(2, 10, [1, 1, 1, 4, 5, 20])
        ]
        let r = BLEStructureReport.analyze(frames, phaseCounts: [1,1,1], idleCount: 1)
        XCTAssertTrue(r.constantMod256Sum)
        XCTAssertFalse(r.constantXor)
        XCTAssertEqual(r.candidateStablePresetPositions, [2, 5])
        XCTAssertEqual(r.sameAirFryChangedPositions, [])
        XCTAssertEqual(r.firstAirFryToReheatChanged, [2, 5])
        XCTAssertEqual(r.changedTogetherPairs, 2)
        XCTAssertEqual(r.firstPromptDelayTenths, [12, 25, 10])
        XCTAssertEqual(r.totalFrames, 4)
    }

    func testChangingCounterWithoutFalsePresetProof() {
        let frames = [
            frame(0, 8, [0,0,5,0,0,15]),
            frame(1, 8, [0,0,6,0,0,16]),
            frame(2, 8, [0,0,7,0,0,17])
        ]
        let r = BLEStructureReport.analyze(frames, phaseCounts: [1,1,1], idleCount: 0)
        XCTAssertEqual(r.byte2PlusOnePairs, 2)
        XCTAssertEqual(r.byte5PlusOnePairs, 2)
        XCTAssertEqual(r.candidateStablePresetPositions, [])
        XCTAssertFalse(r.constantMod256Sum)
    }

    func testMissingEventsProduceIncompleteAnalysis() {
        let frames = [
            frame(0, 4, [1,2,3,4,5,6]),
            frame(2, 4, [1,2,3,4,5,7])
        ]
        let r = BLEStructureReport.analyze(frames, phaseCounts: [1,0,1], idleCount: 0)
        XCTAssertEqual(r.firstPromptDelayTenths, [4, nil, 4])
        XCTAssertEqual(r.candidateStablePresetPositions, [])
        XCTAssertTrue(r.note.contains("no usable"))
    }

    func testMixedLengthsDoNotCompareInvalidAdjacentPairs() {
        let frames = [
            frame(0, 3, [1,2,3,4,5,6]),
            frame(1, 5, [1,2,3,4,5,6,7]),
            frame(2, 8, [1,2,3,4,5,6])
        ]
        let r = BLEStructureReport.analyze(frames, phaseCounts: [1,1,1], idleCount: 0)
        XCTAssertEqual(r.usablePairCount, 0)
        XCTAssertEqual(r.frameLengths, [6,7])
        XCTAssertTrue(r.candidateStablePresetPositions.isEmpty)
    }

    func testSafeReportContainsNoPacketBytes() {
        let frames = [
            frame(0, 6, [11,12,13,14,15,16]),
            frame(1, 7, [11,12,14,14,15,17]),
            frame(2, 8, [11,12,13,14,15,16])
        ]
        let r = BLEStructureReport.analyze(frames, phaseCounts: [1,1,1], idleCount: 0)
        let text = r.safeSummary
        XCTAssertTrue(text.contains("Offset 2 changed pairs"))
        XCTAssertTrue(text.contains("First event after prompt (NOT exact tap latency)"))
        XCTAssertFalse(text.contains("payload="))
        XCTAssertFalse(text.contains("11,12,13,14,15,16"))
        XCTAssertFalse(text.contains("device_uuid="))
    }

    func testReadOnlyNotifyAllowlistExcludesCommandsAndOAD() {
        XCTAssertTrue(BLEStructurePolicy.isPermitted(
            service: CBUUID(string: "FFF0"), characteristic: CBUUID(string: "FFF1")))
        XCTAssertFalse(BLEStructurePolicy.isPermitted(
            service: CBUUID(string: "FFF0"), characteristic: CBUUID(string: "FFF2")))
        XCTAssertFalse(BLEStructurePolicy.isPermitted(
            service: CBUUID(string: "F000FFE0-0451-4000-B000-000000000000"),
            characteristic: CBUUID(string: "F000FFE2-0451-4000-B000-000000000000")))
        XCTAssertFalse(BLEStructurePolicy.isPermitted(
            service: CBUUID(string: "F000FFC0-0451-4000-B000-000000000000"),
            characteristic: CBUUID(string: "F000FFC1-0451-4000-B000-000000000000")))
    }
}
