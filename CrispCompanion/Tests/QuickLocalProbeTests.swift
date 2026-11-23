import XCTest
import CoreBluetooth
@testable import CrispCompanion

final class QuickLocalProbeTests: XCTestCase {
    func testSimpleFourButtonRoutine() {
        XCTAssertEqual(QuickProbePolicy.sequence, [.airFry, .reheat, .airFry, .reheat])
        XCTAssertEqual(QuickProbePolicy.idleSeconds, 12)
        XCTAssertEqual(QuickProbePolicy.stepSeconds, 8)
    }

    func testCandidateBytePositionAndVolatileCounter() {
        let frames: [Data?] = [
            Data([10, 5, 50, 1]), Data([10, 8, 51, 1]),
            Data([10, 5, 52, 1]), Data([10, 8, 53, 1])
        ]
        let result = QuickProbeResult.compare(frames)
        XCTAssertEqual(result.candidatePositions, [1])
        XCTAssertEqual(result.airFryChanged, [2])
        XCTAssertEqual(result.reheatChanged, [2])
        XCTAssertEqual(result.firstTransitionChanged, [1, 2])
        XCTAssertEqual(result.received, 4)
    }

    func testNoFalseCandidateFromChangingCounters() {
        let frames: [Data?] = [
            Data([1, 2]), Data([3, 4]),
            Data([5, 6]), Data([7, 8])
        ]
        XCTAssertTrue(QuickProbeResult.compare(frames).candidatePositions.isEmpty)
    }

    func testMissingPacketIsHonestAboutNoComparison() {
        let result = QuickProbeResult.compare([Data([1]), nil, Data([1]), Data([2])])
        XCTAssertEqual(result.received, 3)
        XCTAssertTrue(result.candidatePositions.isEmpty)
        XCTAssertTrue(result.explanation.contains("Incomplete"))
    }

    func testUnequalFrameSizesPreventFalseOffsetMapping() {
        let result = QuickProbeResult.compare([
            Data([1,2]), Data([3]), Data([1,2]), Data([3,4])
        ])
        XCTAssertTrue(result.candidatePositions.isEmpty)
        XCTAssertTrue(result.explanation.contains("lengths"))
    }

    func testSummaryContainsNoRawPacketValues() {
        let result = QuickProbeResult.compare([
            Data([99, 5]), Data([99, 8]), Data([99, 5]), Data([99, 8])
        ])
        let text = result.safeReport(idleCount: 0, perStep: [1,1,1,1])
        XCTAssertTrue(text.contains("Possible preset-sensitive offsets (zero-based): 1"))
        XCTAssertTrue(text.contains("Notifications per step: 1,1,1,1"))
        XCTAssertFalse(text.contains("payload="))
        XCTAssertFalse(text.contains("secretKey"))
    }

    func testStrictNotificationAllowlistAndNoAutoconnect() {
        let model = QuickProbeModel()
        XCTAssertFalse(model.running)
        XCTAssertNil(model.result)
        XCTAssertTrue(QuickProbePolicy.permits(CBUUID(string: "FFF0"), CBUUID(string: "FFF1")))
        XCTAssertFalse(QuickProbePolicy.permits(CBUUID(string: "FFF0"), CBUUID(string: "FFF2")))
        XCTAssertFalse(QuickProbePolicy.permits(
            CBUUID(string: "F000FFC0-0451-4000-B000-000000000000"),
            CBUUID(string: "F000FFC1-0451-4000-B000-000000000000")
        ))
    }
}
