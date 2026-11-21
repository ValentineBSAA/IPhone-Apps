import Foundation
import XCTest
@testable import BerryBlockBlast

#if BERRY_INTERNAL_QA
@MainActor
final class BerryDeveloperQuestStoryLabTests: XCTestCase {
    private func run(_ choice: BerryQAQuestStoryScenario) -> BerryQAQuestStoryReceipt {
        var lab = BerryDeveloperQuestStoryLab()
        lab.prepare(choice)
        let result = lab.run()
        XCTAssertEqual(result.scenario, choice)
        XCTAssertTrue(result.passed, "\(choice.rawValue): \(result.actual)")
        XCTAssertTrue(result.playerDataUnchanged, choice.rawValue)
        XCTAssertEqual(result.expected, choice.expected)
        XCTAssertFalse(result.actual.isEmpty)
        return result
    }

    func testAllFiveOneTapRealQuestAndStoryScenariosPass() {
        XCTAssertEqual(BerryQAQuestStoryScenario.allCases.count, 5)
        for choice in BerryQAQuestStoryScenario.allCases {
            _ = run(choice)
        }
    }

    func testOneTapEighteenMoveQuestPaysTwentyOnceAndRestores() {
        let result = run(.moves)
        XCTAssertTrue(result.actual.contains("First claim true"))
        XCTAssertTrue(result.actual.contains("second refused true"))
        XCTAssertTrue(result.actual.contains("restart wallet 20"))
        XCTAssertTrue(result.actual.contains("receipts 1"))
    }

    func testOneTapStoryChapterClaimAndRewardPayOnlyOnce() {
        let result = run(.chapters)
        XCTAssertTrue(result.actual.contains("Chapter progress 1"))
        XCTAssertTrue(result.actual.contains("quest true"))
        XCTAssertTrue(result.actual.contains("restart wallet 60"))
        XCTAssertTrue(result.actual.contains("receipts 2"))
    }

    func testOneTapFourDayQuestRotationUsesVirtualClock() {
        let result = run(.rotation)
        XCTAssertTrue(result.actual.contains("Each day three unique true"))
        XCTAssertTrue(result.actual.contains("all four excluded once true"))
    }

    func testOneTapVillageUnlockLevelsUseOnlyTemporaryStoryAndDailyHistory() {
        let result = run(.village)
        XCTAssertTrue(result.actual.contains("Village progression 1 → 2 → 4 → 5"))
    }

    func testOneTapWrongWalletNeverPaysTheUnrelatedGameSession() {
        let result = run(.wrongWallet)
        XCTAssertTrue(result.actual.contains("Wrong wallet refused true"))
        XCTAssertTrue(result.actual.contains("matching paid true"))
        XCTAssertTrue(result.actual.contains("other wallet 0"))
    }

    func testAllFiveOneTapScenariosRepeatIndependentlyAndReset() {
        var lab = BerryDeveloperQuestStoryLab()
        for choice in BerryQAQuestStoryScenario.allCases {
            lab.prepare(choice)
            XCTAssertNil(lab.latest)
            let first = lab.run()
            let again = lab.run()
            XCTAssertTrue(first.passed, first.actual)
            XCTAssertEqual(first.actual, again.actual, choice.rawValue)
            XCTAssertTrue(first.playerDataUnchanged)
        }
        lab.reset()
        XCTAssertNil(lab.latest)
        XCTAssertEqual(lab.selected, .moves)
    }
}
#endif
