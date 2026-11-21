import Foundation
import XCTest
@testable import BerryBlockBlast

#if BERRY_INTERNAL_QA
@MainActor
final class BerryDeveloperToolActionLabTests: XCTestCase {
    func testAllElevenOneTapRealPremiumToolScenariosPass() {
        var lab = BerryDeveloperToolActionLab()
        XCTAssertEqual(BerryQAToolActionScenario.allCases.count, 11)
        for choice in BerryQAToolActionScenario.allCases {
            lab.prepare(choice)
            let receipt = lab.run()
            XCTAssertEqual(receipt.scenario, choice)
            XCTAssertTrue(receipt.passed, "\(choice.rawValue): \(receipt.actual)")
            XCTAssertTrue(receipt.realPlayerDataUnchanged, choice.rawValue)
            XCTAssertEqual(receipt.expected, choice.expected)
            XCTAssertFalse(receipt.actual.isEmpty)
        }
    }

    func testOneTapTrowelSavesAndReopensActualEngine() {
        var lab = BerryDeveloperToolActionLab()
        lab.prepare(.trowel)
        let receipt = lab.run()
        XCTAssertTrue(receipt.passed, receipt.actual)
        XCTAssertTrue(receipt.actual.contains("restart charge 0"))
        XCTAssertTrue(receipt.actual.contains("empty"))
    }

    func testOneTapSeedAndGoldenRescueVerifySaveState() {
        var lab = BerryDeveloperToolActionLab()
        lab.prepare(.seed)
        let seed = lab.run()
        XCTAssertTrue(seed.passed, seed.actual)
        XCTAssertTrue(seed.actual.contains("planted"))
        lab.prepare(.golden)
        let golden = lab.run()
        XCTAssertTrue(golden.passed, golden.actual)
        XCTAssertTrue(golden.actual.contains("rescue used true"))
    }

    func testOneTapGoldenRepeatAndInvalidActionSpendNoExtraCharges() {
        var lab = BerryDeveloperToolActionLab()
        lab.prepare(.goldenRepeat)
        let second = lab.run()
        XCTAssertTrue(second.passed, second.actual)
        XCTAssertTrue(second.actual.contains("second false"))
        lab.prepare(.invalid)
        let invalid = lab.run()
        XCTAssertTrue(invalid.passed, invalid.actual)
        XCTAssertTrue(invalid.actual.contains("unchanged"))
    }

    func testOneTapMegaGardenPreservesAllIndependentBoardSizes() {
        var lab = BerryDeveloperToolActionLab()
        lab.prepare(.mega)
        let receipt = lab.run()
        XCTAssertTrue(receipt.passed, receipt.actual)
        XCTAssertTrue(receipt.actual.contains("other gardens safe"))
    }

    func testOneTapActualPurchaseUsePersistsWalletLedgerAndToolConsumption() {
        var lab = BerryDeveloperToolActionLab()
        lab.prepare(.buyAndUse)
        let receipt = lab.run()
        XCTAssertTrue(receipt.passed, receipt.actual)
        XCTAssertTrue(receipt.actual.contains("wallet 0"))
        XCTAssertTrue(receipt.actual.contains("spent 150"))
        XCTAssertTrue(receipt.actual.contains("charges 0"))
    }

    func testRepeatAndResetStartFreshWithoutPreviousSaveOrCharge() {
        var lab = BerryDeveloperToolActionLab()
        lab.prepare(.buyAndUse)
        let first = lab.run()
        let again = lab.run()
        XCTAssertTrue(first.passed, first.actual)
        XCTAssertEqual(first.actual, again.actual)
        lab.prepare(.invalid)
        XCTAssertNil(lab.latest)
        XCTAssertTrue(lab.run().passed)
        lab.discard()
        XCTAssertNil(lab.latest)
        XCTAssertEqual(lab.scenario, .trowel)
    }

    func testAllToolActionScenariosLeaveOwnerDefaultsUntouched() {
        let keys = ["berryblockblast.inventory.v3",
                    "berryberryblast.premium.charges.v059",
                    "berryblockblast.endless.boardSize.v056b2",
                    "berryblockblast.endless.legacyMigrated.v056b2",
                    "berryblockblast.best-score.v1",
                    "berryberryblast.economy.spent.v0510",
                    "berryberryblast.economy.purchases.v0510",
                    "berryblockblast.cottage.decorations"] +
                    [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let before = keys.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        var lab = BerryDeveloperToolActionLab()
        for choice in BerryQAToolActionScenario.allCases {
            lab.prepare(choice)
            let receipt = lab.run()
            XCTAssertTrue(receipt.passed, receipt.actual)
            XCTAssertTrue(receipt.realPlayerDataUnchanged, choice.rawValue)
        }
        let after = keys.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        XCTAssertEqual(before, after)
    }
}
#endif
