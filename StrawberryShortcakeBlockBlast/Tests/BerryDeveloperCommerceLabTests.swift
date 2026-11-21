import Foundation
import XCTest
@testable import BerryBlockBlast

#if BERRY_INTERNAL_QA
@MainActor
final class BerryDeveloperCommerceLabTests: XCTestCase {
    func testAllSevenOneTapRealCommerceFixturesPass() {
        var lab = BerryDeveloperCommerceLab()
        XCTAssertEqual(BerryQACommerceScenario.allCases.count, 7)
        for scenario in BerryQACommerceScenario.allCases {
            lab.prepare(scenario)
            let receipt = lab.run()
            XCTAssertEqual(receipt.scenario, scenario)
            XCTAssertTrue(receipt.passed, "\(scenario.rawValue): \(receipt.actual)")
            XCTAssertTrue(receipt.playerDataUnchanged, scenario.rawValue)
            XCTAssertFalse(receipt.expected.isEmpty)
            XCTAssertFalse(receipt.actual.isEmpty)
        }
    }

    func testRepeatRunStartsWithFreshPurchasingStateEveryTime() {
        var lab = BerryDeveloperCommerceLab()
        lab.prepare(.pantryDuplicate)
        let first = lab.run()
        let again = lab.run()
        XCTAssertTrue(first.passed, first.actual)
        XCTAssertTrue(again.passed, again.actual)
        XCTAssertEqual(first.actual, again.actual)
    }

    func testReselectResetsReceiptAndDoesNotSpendFromPriorScenario() {
        var lab = BerryDeveloperCommerceLab()
        lab.prepare(.twisterPurchase)
        XCTAssertTrue(lab.run().passed)
        lab.prepare(.premiumShort)
        XCTAssertNil(lab.latest)
        let result = lab.run()
        XCTAssertTrue(result.passed, result.actual)
        XCTAssertTrue(result.actual.contains("wallet 149"))
    }

    func testDiscardRemovesTestStateAndClearsReceipt() {
        var lab = BerryDeveloperCommerceLab()
        lab.prepare(.savedGardenSafety)
        XCTAssertTrue(lab.run().passed)
        lab.discard()
        XCTAssertNil(lab.latest)
        XCTAssertEqual(lab.scenario, .cottageExact)
    }

    func testAllSevenScenariosPreserveNormalPersistentPlayerKeys() {
        var lab = BerryDeveloperCommerceLab()
        let keys = ["berryblockblast.inventory.v3",
                    "berryblockblast.cottage.decorations",
                    "berryberryblast.premium.charges.v059",
                    "berryberryblast.premium.permanent.v059",
                    "berryberryblast.economy.spent.v0510",
                    "berryberryblast.economy.purchases.v0510"] +
                    [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let before = keys.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        for caseID in BerryQACommerceScenario.allCases {
            lab.prepare(caseID)
            XCTAssertTrue(lab.run().playerDataUnchanged, caseID.rawValue)
        }
        let after = keys.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        XCTAssertEqual(before, after)
    }

    func testOneTapCommerceCasesAreNotMistakenForNightStoreCompletion() {
        let names = BerryQACommerceScenario.allCases.map(\.rawValue)
        XCTAssertFalse(names.contains(where: { $0.localizedCaseInsensitiveContains("Moonberry") }))
        XCTAssertFalse(names.contains(where: { $0.localizedCaseInsensitiveContains("Night Market") }))
        XCTAssertEqual(names.count, Set(names).count)
    }
}
#endif
