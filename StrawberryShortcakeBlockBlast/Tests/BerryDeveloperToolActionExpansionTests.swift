import Foundation
import XCTest
@testable import BerryBlockBlast

#if BERRY_INTERNAL_QA
/// D2d tests the expanded real-handler Tool Action Lab, never owner game state.
@MainActor
final class BerryDeveloperToolActionExpansionTests: XCTestCase {
    private func run(_ choice: BerryQAToolActionScenario) -> BerryQAToolActionReceipt {
        var lab = BerryDeveloperToolActionLab()
        lab.prepare(choice)
        let result = lab.run()
        XCTAssertEqual(result.scenario, choice)
        XCTAssertTrue(result.passed, result.actual)
        XCTAssertTrue(result.realPlayerDataUnchanged, result.actual)
        return result
    }

    func testActualTwisterRotationAndSavedChargesInOneTap() {
        let receipt = run(.twister)
        XCTAssertTrue(receipt.actual.contains("Rotated true"))
        XCTAssertTrue(receipt.actual.contains("restart charges 2"))
        XCTAssertTrue(receipt.actual.contains("different shape true"))
    }

    func testActualPantryStashAndRestoredPieceInOneTap() {
        let receipt = run(.pantry)
        XCTAssertTrue(receipt.actual.contains("Stashed true"))
        XCTAssertTrue(receipt.actual.contains("reserve restored true"))
        XCTAssertTrue(receipt.actual.contains("swapped true"))
        XCTAssertTrue(receipt.actual.contains("final tray matches true"))
    }

    func testMegaGoldenRescueClearsAllSectionsAndPreservesOtherSaves() {
        let receipt = run(.megaGolden)
        XCTAssertTrue(receipt.actual.contains("Four sections occupied true"))
        XCTAssertTrue(receipt.actual.contains("rescued true"))
        XCTAssertTrue(receipt.actual.contains("clear true"))
        XCTAssertTrue(receipt.actual.contains("other saves safe"))
    }

    func testCombinedGoldenCheckoutIsRealAndExactlyOnce() {
        let receipt = run(.goldenCheckout)
        XCTAssertTrue(receipt.actual.contains("Rescued true"))
        XCTAssertTrue(receipt.actual.contains("second refused true"))
        XCTAssertTrue(receipt.actual.contains("wallet 0"))
        XCTAssertTrue(receipt.actual.contains("spent 250"))
        XCTAssertTrue(receipt.actual.contains("receipt count 1"))
    }

    func testAllElevenOneTapActionsRemainIsolatedAcrossReselectionResetAndRerun() {
        var lab = BerryDeveloperToolActionLab()
        XCTAssertEqual(BerryQAToolActionScenario.allCases.count, 11)
        for choice in BerryQAToolActionScenario.allCases {
            lab.prepare(choice)
            XCTAssertNil(lab.latest)
            let first = lab.run()
            let second = lab.run()
            XCTAssertTrue(first.passed, "\(choice.rawValue): \(first.actual)")
            XCTAssertEqual(first.actual, second.actual, "\(choice.rawValue): repeat drift")
            XCTAssertTrue(first.realPlayerDataUnchanged, choice.rawValue)
            XCTAssertEqual(first.expected, choice.expected)
        }
        lab.discard()
        XCTAssertNil(lab.latest)
        XCTAssertEqual(lab.scenario, .trowel)
    }

    func testExtendedActionsNeverChangeNormalPlayerWalletLedgerReceiptsOrSavedGames() {
        let keys = [
            "berryblockblast.inventory.v3",
            "berryberryblast.premium.charges.v059",
            "berryberryblast.premium.permanent.v059",
            "berryblockblast.endless.boardSize.v056b2",
            "berryblockblast.endless.legacyMigrated.v056b2",
            "berryblockblast.best-score.v1",
            "berryblockblast.rewards.v1",
            "berryberryblast.economy.spent.v0510",
            "berryberryblast.economy.purchases.v0510"
        ] + [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let before = keys.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        for choice in [BerryQAToolActionScenario.twister, .pantry,
                       .megaGolden, .goldenCheckout] {
            let receipt = run(choice)
            XCTAssertTrue(receipt.realPlayerDataUnchanged, choice.rawValue)
        }
        let after = keys.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        XCTAssertEqual(before, after)
    }
}
#endif
