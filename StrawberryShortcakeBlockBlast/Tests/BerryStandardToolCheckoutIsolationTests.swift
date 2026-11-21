import Foundation
import XCTest
@testable import BerryBlockBlast

/// D0d: These tests execute the REAL BerryGameSession standard-tool methods,
/// their actual inventory JSON encoding, and the REAL BerryEconomyLedger.
/// A unique UserDefaults suite and ledger instance isolate every test case.
/// Do not interpret this suite as testing all Story/Daily/Boutique save paths.
@MainActor
final class BerryStandardToolCheckoutIsolationTests: XCTestCase {
    private let inventoryKey = "berryblockblast.inventory.v3"

    private struct Inventory: Codable, Equatable {
        var berries: Int
        var undos: Int
        var shuffles: Int
        var totalEarnedBerries: Int
        var hints: Int
    }

    private struct OldInventory: Codable {
        var berries: Int
        var undos: Int
        var shuffles: Int
        var totalEarnedBerries: Int
    }

    private func suite(_ label: String) throws -> UserDefaults {
        let domain = "com.valentinebsaa.berry.d0d.\(label).\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: domain))
        defaults.set(domain, forKey: "d0d.test.suite")
        return defaults
    }

    private func setup(
        _ defaults: UserDefaults,
        berries: Int,
        undos: Int = 0,
        shuffles: Int = 0,
        hints: Int = 0,
        total: Int = 27
    ) throws {
        let payload = Inventory(berries: berries, undos: undos,
                                shuffles: shuffles, totalEarnedBerries: total,
                                hints: hints)
        defaults.set(try JSONEncoder().encode(payload), forKey: inventoryKey)
    }

    private func stored(_ defaults: UserDefaults) throws -> Inventory {
        let bytes = try XCTUnwrap(defaults.data(forKey: inventoryKey))
        return try JSONDecoder().decode(Inventory.self, from: bytes)
    }

    func testRealUndoCheckoutDebitsAndPersistsInIsolatedSuiteAndRealLedger() throws {
        let defaults = try suite("undo")
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        try setup(defaults, berries: BerryEconomy.undoPrice, undos: 2)
        let ledger = BerryEconomyLedger(defaults: defaults)
        let session = BerryGameSession(checkoutDefaults: defaults, checkoutLedger: ledger)

        session.buyUndo()

        XCTAssertEqual(session.berries, 0)
        XCTAssertEqual(session.undos, 3)
        XCTAssertEqual(try stored(defaults),
                       Inventory(berries: 0, undos: 3, shuffles: 0,
                                 totalEarnedBerries: 27, hints: 0))
        XCTAssertEqual(ledger.spent, BerryEconomy.undoPrice)
        XCTAssertEqual(ledger.spentByItem["Undo"], BerryEconomy.undoPrice)
    }

    func testRealShuffleAndHintCheckoutPersistExactCostsAndActualLedger() throws {
        let defaults = try suite("both")
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        try setup(defaults, berries: 150)
        let ledger = BerryEconomyLedger(defaults: defaults)
        let session = BerryGameSession(checkoutDefaults: defaults, checkoutLedger: ledger)

        session.buyShuffle()
        session.buyHint()

        XCTAssertEqual(session.berries, 150 - BerryEconomy.shufflePrice - BerryEconomy.hintPrice)
        XCTAssertEqual(session.shuffles, 1)
        XCTAssertEqual(session.hints, 1)
        let saved = try stored(defaults)
        XCTAssertEqual(saved.berries, session.berries)
        XCTAssertEqual(saved.shuffles, 1)
        XCTAssertEqual(saved.hints, 1)
        XCTAssertEqual(ledger.spent, BerryEconomy.shufflePrice + BerryEconomy.hintPrice)
        XCTAssertEqual(ledger.spentByItem["Shuffle"], BerryEconomy.shufflePrice)
        XCTAssertEqual(ledger.spentByItem["Hint"], BerryEconomy.hintPrice)
    }

    func testRealInsufficientFundsRejectedWithoutLedgerOrSaveMutation() throws {
        let defaults = try suite("insufficient")
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        try setup(defaults, berries: BerryEconomy.shufflePrice - 1, shuffles: 4)
        let before = try XCTUnwrap(defaults.data(forKey: inventoryKey))
        let ledger = BerryEconomyLedger(defaults: defaults)
        let session = BerryGameSession(checkoutDefaults: defaults, checkoutLedger: ledger)

        session.buyShuffle()

        XCTAssertEqual(defaults.data(forKey: inventoryKey), before)
        XCTAssertEqual(session.berries, BerryEconomy.shufflePrice - 1)
        XCTAssertEqual(session.shuffles, 4)
        XCTAssertEqual(ledger.spent, 0)
        XCTAssertTrue(ledger.spentByItem.isEmpty)
    }

    func testRealOverflowRejectedWithoutWritingOrSpending() throws {
        let defaults = try suite("overflow")
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        try setup(defaults, berries: 300, hints: Int.max)
        let initial = try XCTUnwrap(defaults.data(forKey: inventoryKey))
        let ledger = BerryEconomyLedger(defaults: defaults)
        let session = BerryGameSession(checkoutDefaults: defaults, checkoutLedger: ledger)

        session.buyHint()

        XCTAssertEqual(defaults.data(forKey: inventoryKey), initial)
        XCTAssertEqual(session.berries, 300)
        XCTAssertEqual(session.hints, Int.max)
        XCTAssertEqual(ledger.spent, 0)
    }

    func testRealSessionCanReloadPurchasesFromSameIsolatedSuite() throws {
        let defaults = try suite("reopen")
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        try setup(defaults, berries: 100, undos: 0)
        let ledger = BerryEconomyLedger(defaults: defaults)
        let first = BerryGameSession(checkoutDefaults: defaults, checkoutLedger: ledger)
        first.buyUndo()
        let second = BerryGameSession(checkoutDefaults: defaults, checkoutLedger:
            BerryEconomyLedger(defaults: defaults))

        XCTAssertEqual(second.berries, 100 - BerryEconomy.undoPrice)
        XCTAssertEqual(second.undos, 1)
        XCTAssertEqual(try stored(defaults).berries, second.berries)
    }

    func testActualInventoryDecoderPreservesLegacyMissingHintCompatibility() throws {
        let defaults = try suite("legacy")
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        let old = OldInventory(berries: 100, undos: 2, shuffles: 1,
                               totalEarnedBerries: 33)
        defaults.set(try JSONEncoder().encode(old), forKey: inventoryKey)
        let ledger = BerryEconomyLedger(defaults: defaults)
        let session = BerryGameSession(checkoutDefaults: defaults, checkoutLedger: ledger)

        XCTAssertEqual(session.hints, 0)
        session.buyHint()

        let converted = try stored(defaults)
        XCTAssertEqual(converted.hints, 1)
        XCTAssertEqual(converted.totalEarnedBerries, 33)
        XCTAssertEqual(converted.berries, 100 - BerryEconomy.hintPrice)
    }

    func testLiveDefaultPreferencesAndSharedLedgerStayUntouchedByIsolatedPurchases() throws {
        let beforeInventory = UserDefaults.standard.data(forKey: inventoryKey)
        let beforeSpent = UserDefaults.standard.object(forKey:
            "berryberryblast.economy.spent.v0510") as? Int
        let beforeItems = UserDefaults.standard.dictionary(forKey:
            "berryberryblast.economy.purchases.v0510") as? [String:Int]

        let defaults = try suite("isolated")
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        try setup(defaults, berries: 200)
        let ledger = BerryEconomyLedger(defaults: defaults)
        let session = BerryGameSession(checkoutDefaults: defaults, checkoutLedger: ledger)
        session.buyUndo()
        session.buyShuffle()
        session.buyHint()

        XCTAssertEqual(ledger.spent, BerryEconomy.undoPrice +
                       BerryEconomy.shufflePrice + BerryEconomy.hintPrice)
        XCTAssertEqual(UserDefaults.standard.data(forKey: inventoryKey), beforeInventory)
        XCTAssertEqual(UserDefaults.standard.object(forKey:
            "berryberryblast.economy.spent.v0510") as? Int, beforeSpent)
        XCTAssertEqual(UserDefaults.standard.dictionary(forKey:
            "berryberryblast.economy.purchases.v0510") as? [String:Int], beforeItems)
    }

    func testCheckoutCallbackNotInvokedForRejectedPayment() {
        var calls = 0
        let accepted = BerryStandardToolCheckout.purchase(
            .hint, berries: BerryEconomy.hintPrice - 1, charges: 0
        ) { _ in calls += 1 }
        XCTAssertFalse(accepted)
        XCTAssertEqual(calls, 0)
    }

    func testCheckoutCallbackEmitsOneExactReceipt() {
        var calls = 0
        var receipt: BerryStandardToolPurchaseReceipt?
        let accepted = BerryStandardToolCheckout.purchase(
            .undo, berries: 90, charges: 4
        ) { current in
            calls += 1
            receipt = current
        }
        XCTAssertTrue(accepted)
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(receipt?.berriesBefore, 90)
        XCTAssertEqual(receipt?.berriesAfter, 90 - BerryEconomy.undoPrice)
        XCTAssertEqual(receipt?.chargesBefore, 4)
        XCTAssertEqual(receipt?.chargesAfter, 5)
        XCTAssertEqual(receipt?.tool, .undo)
        XCTAssertEqual(receipt?.price, BerryEconomy.undoPrice)
    }

    private func defaultsSuiteName(_ defaults: UserDefaults) -> String {
        // Suite-only test domains are uniquely named; cache the suite name in
        // a marker rather than relying on undocumented UserDefaults APIs.
        defaults.string(forKey: "d0d.test.suite") ?? ""
    }
}
