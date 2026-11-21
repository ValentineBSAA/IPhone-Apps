import Foundation
import XCTest
@testable import BerryBlockBlast

/// D0e simulation of interruption points using the REAL inventory schema,
/// real injected BerryEconomyLedger and a real BerryGameSession reload.
/// Each test suite has its own disposable preference domain.
@MainActor
final class BerryStandardPurchaseRecoveryTests: XCTestCase {
    private struct Inventory: Codable, Equatable {
        let berries: Int
        let undos: Int
        let shuffles: Int
        let totalEarnedBerries: Int
        let hints: Int
    }

    private let spentKey = "berryberryblast.economy.spent.v0510"
    private let spentItemsKey = "berryberryblast.economy.purchases.v0510"

    private func suite() throws -> (String, UserDefaults) {
        let name = "com.valentinebsaa.berry.d0e.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        return (name, defaults)
    }

    private func seed(_ defaults: UserDefaults, berries: Int = 100,
                      undos: Int = 2, shuffles: Int = 1,
                      hints: Int = 0, lifetime: Int = 27) throws {
        let inventory = Inventory(berries: berries, undos: undos,
                                  shuffles: shuffles,
                                  totalEarnedBerries: lifetime, hints: hints)
        defaults.set(try JSONEncoder().encode(inventory),
                     forKey: BerryStandardPurchaseJournal.inventoryKey)
    }

    private func inventory(_ defaults: UserDefaults) throws -> Inventory {
        let bytes = try XCTUnwrap(defaults.data(
            forKey: BerryStandardPurchaseJournal.inventoryKey))
        return try JSONDecoder().decode(Inventory.self, from: bytes)
    }

    private func pendingUndo(_ ledger: BerryEconomyLedger,
                             berries: Int = 100, undos: Int = 2) throws
    -> BerryStandardPurchaseJournal.Entry {
        let receipt = BerryStandardToolPurchaseReceipt(
            tool: .undo, price: BerryEconomy.undoPrice,
            berriesBefore: berries, berriesAfter: berries - BerryEconomy.undoPrice,
            chargesBefore: undos, chargesAfter: undos + 1
        )
        let after = Inventory(
            berries: receipt.berriesAfter, undos: receipt.chargesAfter,
            shuffles: 1, totalEarnedBerries: 27, hints: 0
        )
        return try XCTUnwrap(BerryStandardPurchaseJournal.prepare(
            receipt: receipt, inventoryAfter: JSONEncoder().encode(after),
            ledger: ledger
        ))
    }

    func testSuccessfulActualUndoCheckoutClearsIntentAndRestoresOnReopen() throws {
        let (name, defaults) = try suite()
        defer { defaults.removePersistentDomain(forName: name) }
        try seed(defaults)
        let ledger = BerryEconomyLedger(defaults: defaults)
        let session = BerryGameSession(checkoutDefaults: defaults, checkoutLedger: ledger)

        session.buyUndo()

        XCTAssertEqual(session.berries, 100 - BerryEconomy.undoPrice)
        XCTAssertEqual(session.undos, 3)
        XCTAssertFalse(BerryStandardPurchaseJournal.hasUnresolvedIntent(in: defaults))
        XCTAssertEqual(ledger.spent, BerryEconomy.undoPrice)
        XCTAssertEqual(ledger.spentByItem["Undo"], BerryEconomy.undoPrice)
        XCTAssertEqual(try inventory(defaults).berries, session.berries)

        let reopened = BerryGameSession(checkoutDefaults: defaults,
                              checkoutLedger: BerryEconomyLedger(defaults: defaults))
        XCTAssertEqual(reopened.berries, session.berries)
        XCTAssertEqual(reopened.undos, session.undos)
    }

    func testJournalStagedOnlyBeforeInventoryWriteCompletesOnceOnLaunch() throws {
        let (name, defaults) = try suite()
        defer { defaults.removePersistentDomain(forName: name) }
        try seed(defaults)
        let ledger = BerryEconomyLedger(defaults: defaults)
        let intent = try pendingUndo(ledger)
        XCTAssertTrue(BerryStandardPurchaseJournal.stage(intent, in: defaults))
        XCTAssertEqual(try inventory(defaults).berries, 100)

        let restored = BerryGameSession(checkoutDefaults: defaults,
                                        checkoutLedger: ledger)
        XCTAssertEqual(restored.berries, 60)
        XCTAssertEqual(restored.undos, 3)
        XCTAssertEqual(try inventory(defaults).berries, 60)
        XCTAssertEqual(ledger.spent, 40)
        XCTAssertEqual(ledger.spentByItem["Undo"], 40)
        XCTAssertFalse(BerryStandardPurchaseJournal.hasUnresolvedIntent(in: defaults))
    }

    func testInterruptedAfterInventoryWriteCompletesLedgerWithoutDoubleDebit() throws {
        let (name, defaults) = try suite()
        defer { defaults.removePersistentDomain(forName: name) }
        try seed(defaults)
        let ledger = BerryEconomyLedger(defaults: defaults)
        let intent = try pendingUndo(ledger)
        XCTAssertTrue(BerryStandardPurchaseJournal.stage(intent, in: defaults))
        defaults.set(intent.inventoryAfter,
                     forKey: BerryStandardPurchaseJournal.inventoryKey)

        let session = BerryGameSession(checkoutDefaults: defaults,
                                       checkoutLedger: ledger)
        XCTAssertEqual(session.berries, 60)
        XCTAssertEqual(ledger.spent, 40)
        XCTAssertEqual(ledger.spentByItem["Undo"], 40)
        XCTAssertFalse(BerryStandardPurchaseJournal.hasUnresolvedIntent(in: defaults))
    }

    func testInterruptedBetweenLedgerKeysRestoresBothExactValues() throws {
        let (name, defaults) = try suite()
        defer { defaults.removePersistentDomain(forName: name) }
        try seed(defaults)
        defaults.set(12, forKey: spentKey)
        defaults.set(["Undo": 12, "Other": 7], forKey: spentItemsKey)
        let earlierLedger = BerryEconomyLedger(defaults: defaults)
        let intent = try pendingUndo(earlierLedger)
        XCTAssertEqual(intent.spentAfter, 52)
        XCTAssertEqual(intent.spentByItemAfter, 52)
        XCTAssertTrue(BerryStandardPurchaseJournal.stage(intent, in: defaults))
        defaults.set(intent.inventoryAfter,
                     forKey: BerryStandardPurchaseJournal.inventoryKey)
        defaults.set(intent.spentAfter, forKey: spentKey)
        // Simulated death here: the per-item entry is still the old 12.
        let relaunchedLedger = BerryEconomyLedger(defaults: defaults)
        let session = BerryGameSession(checkoutDefaults: defaults,
                                        checkoutLedger: relaunchedLedger)

        XCTAssertEqual(session.berries, 60)
        XCTAssertEqual(relaunchedLedger.spent, 52)
        XCTAssertEqual(relaunchedLedger.spentByItem["Undo"], 52)
        XCTAssertEqual(relaunchedLedger.spentByItem["Other"], 7)
        XCTAssertNil(defaults.object(forKey: BerryStandardPurchaseJournal.pendingKey))
    }

    func testRepeatedColdStartsCannotApplySamePendingPurchaseTwice() throws {
        let (name, defaults) = try suite()
        defer { defaults.removePersistentDomain(forName: name) }
        try seed(defaults)
        let ledger = BerryEconomyLedger(defaults: defaults)
        XCTAssertTrue(BerryStandardPurchaseJournal.stage(
            try pendingUndo(ledger), in: defaults))
        let first = BerryGameSession(checkoutDefaults: defaults,
                                     checkoutLedger: ledger)
        let nextLedger = BerryEconomyLedger(defaults: defaults)
        let second = BerryGameSession(checkoutDefaults: defaults,
                                      checkoutLedger: nextLedger)
        XCTAssertEqual(first.berries, 60)
        XCTAssertEqual(second.berries, 60)
        XCTAssertEqual(second.undos, 3)
        XCTAssertEqual(nextLedger.spent, 40)
        XCTAssertEqual(nextLedger.spentByItem["Undo"], 40)
    }

    func testMalformedJournalIsRetainedAndBlocksFurtherPurchases() throws {
        let (name, defaults) = try suite()
        defer { defaults.removePersistentDomain(forName: name) }
        try seed(defaults)
        let corrupted = Data("{broken-journal".utf8)
        defaults.set(corrupted, forKey: BerryStandardPurchaseJournal.pendingKey)
        let before = try XCTUnwrap(defaults.data(
            forKey: BerryStandardPurchaseJournal.inventoryKey))
        let ledger = BerryEconomyLedger(defaults: defaults)
        let session = BerryGameSession(checkoutDefaults: defaults, checkoutLedger: ledger)

        session.buyUndo()

        XCTAssertEqual(defaults.data(
            forKey: BerryStandardPurchaseJournal.inventoryKey), before)
        XCTAssertEqual(defaults.data(
            forKey: BerryStandardPurchaseJournal.pendingKey), corrupted)
        XCTAssertEqual(session.berries, 100)
        XCTAssertEqual(session.undos, 2)
        XCTAssertEqual(ledger.spent, 0)
    }

    func testLegacyUnrelatedSavesAndPlayerDefaultsStayUnchanged() throws {
        let originalInventory = UserDefaults.standard.data(
            forKey: BerryStandardPurchaseJournal.inventoryKey)
        let originalSpent = UserDefaults.standard.object(forKey: spentKey) as? Int
        let originalItems = UserDefaults.standard.dictionary(forKey: spentItemsKey)

        let (name, defaults) = try suite()
        defer { defaults.removePersistentDomain(forName: name) }
        try seed(defaults)
        let endlessKey = BerryGameSession.endlessSaveKey(side: 12)
        let originalEndless = Data([5, 4, 3, 2, 1])
        defaults.set(originalEndless, forKey: endlessKey)
        let ledger = BerryEconomyLedger(defaults: defaults)
        let session = BerryGameSession(checkoutDefaults: defaults, checkoutLedger: ledger)

        session.buyHint()

        XCTAssertEqual(try inventory(defaults).berries, 100 - BerryEconomy.hintPrice)
        XCTAssertEqual(defaults.data(forKey: endlessKey), originalEndless)
        XCTAssertEqual(UserDefaults.standard.data(
            forKey: BerryStandardPurchaseJournal.inventoryKey), originalInventory)
        XCTAssertEqual(UserDefaults.standard.object(forKey: spentKey) as? Int,
                       originalSpent)
        XCTAssertEqual(UserDefaults.standard.dictionary(forKey: spentItemsKey)
                        as NSDictionary?, originalItems as NSDictionary?)
    }

    func testCannotReplaceUnresolvedJournalOrPrepareOverflowedLedger() throws {
        let (name, defaults) = try suite()
        defer { defaults.removePersistentDomain(forName: name) }
        try seed(defaults)
        let ledger = BerryEconomyLedger(defaults: defaults)
        let first = try pendingUndo(ledger)
        XCTAssertTrue(BerryStandardPurchaseJournal.stage(first, in: defaults))
        XCTAssertFalse(BerryStandardPurchaseJournal.stage(first, in: defaults))
        let staged = defaults.data(forKey: BerryStandardPurchaseJournal.pendingKey)
        XCTAssertNotNil(staged)

        defaults.set(Int.max, forKey: spentKey)
        let tooLargeLedger = BerryEconomyLedger(defaults: defaults)
        XCTAssertNil(BerryStandardPurchaseJournal.prepare(
            receipt: BerryStandardToolPurchaseReceipt(
                tool: .undo, price: 40,
                berriesBefore: 100, berriesAfter: 60,
                chargesBefore: 2, chargesAfter: 3),
            inventoryAfter: first.inventoryAfter, ledger: tooLargeLedger))
        XCTAssertEqual(defaults.data(forKey: BerryStandardPurchaseJournal.pendingKey),
                       staged)
    }
}
