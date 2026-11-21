import Foundation
import XCTest
@testable import BerryBlockBlast

/// D3f: genuine Story-mode Shuffle checkout with real injected ledger/storage.
/// This verifies handler safety, not native Game Over screen taps or a
/// genuinely blocked Story engine; those are the separate D3f UI gate.
@MainActor
final class BerryShuffleContinueIsolationTests: XCTestCase {
    private struct Inventory: Codable {
        var berries: Int
        var undos: Int
        var shuffles: Int
        var totalEarnedBerries: Int
        var hints: Int
    }

    private let inventoryKey = "berryblockblast.inventory.v3"
    private let receiptsKey = "berryblockblast.rewards.v1"

    private func suite() throws -> (name: String, defaults: UserDefaults) {
        let name = "com.valentinebsaa.berry.d3f.\(UUID().uuidString)"
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }

    private func initialize(_ store: UserDefaults, wallet: Int,
                            shuffles: Int = 0) throws {
        let inventory = Inventory(berries: wallet, undos: 2,
                                  shuffles: shuffles,
                                  totalEarnedBerries: 0, hints: 0)
        store.set(try JSONEncoder().encode(inventory), forKey: inventoryKey)
    }

    private func game(_ defaults: UserDefaults, mode: BerryMode = .story)
        -> BerryGameSession {
        let session = BerryGameSession(
            checkoutDefaults: defaults,
            checkoutLedger: BerryEconomyLedger(defaults: defaults))
        session.selectMode(mode)
        return session
    }

    private func wallet(_ store: UserDefaults) throws -> Int {
        let bytes = try XCTUnwrap(store.data(forKey: inventoryKey))
        return try JSONDecoder().decode(Inventory.self, from: bytes).berries
    }

    func testActualFiftyBerryStoryShufflePurchasePersistsWalletLedgerAndReceipt() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try initialize(store, wallet: BerryEconomy.shufflePrice)
        let ledger = BerryEconomyLedger(defaults: store)
        let session = BerryGameSession(
            checkoutDefaults: store, checkoutLedger: ledger)
        session.selectMode(.story)
        XCTAssertTrue(session.canContinueWithShuffle)
        XCTAssertEqual(session.shuffles, 0)
        let score = session.engine.score
        let moves = session.engine.moves
        let lines = session.engine.totalLines

        XCTAssertTrue(session.buyAndContinueWithShuffle())
        XCTAssertEqual(session.berries, 0)
        XCTAssertEqual(try wallet(store), 0)
        XCTAssertEqual(session.shuffles, 0)
        XCTAssertEqual(session.engine.score, score)
        XCTAssertEqual(session.engine.moves, moves)
        XCTAssertEqual(session.engine.totalLines, lines)
        XCTAssertEqual(ledger.spent, BerryEconomy.shufflePrice)
        XCTAssertEqual(ledger.spentByItem["Shuffle Continue"],
                       BerryEconomy.shufflePrice)
        XCTAssertEqual(store.stringArray(forKey: receiptsKey)?.count, 1)
        XCTAssertTrue(store.stringArray(forKey: receiptsKey)?.first?
                      .contains("Shuffle Continue") == true)
        XCTAssertFalse(session.buyAndContinueWithShuffle())

        let reopened = game(store)
        XCTAssertEqual(reopened.berries, 0)
        XCTAssertEqual(BerryEconomyLedger(defaults: store).spent,
                       BerryEconomy.shufflePrice)
        XCTAssertEqual(store.stringArray(forKey: receiptsKey)?.count, 1)
        // Story deliberately starts a fresh board on new mode entry. It is
        // incorrect to claim its in-progress board survives relaunch.
    }

    func testInsufficientWalletRejectsCheckoutWithoutSpendingOrReceipt() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try initialize(store, wallet: BerryEconomy.shufflePrice - 1)
        let session = game(store)
        let before = store.data(forKey: inventoryKey)
        XCTAssertFalse(session.buyAndContinueWithShuffle())
        XCTAssertEqual(store.data(forKey: inventoryKey), before)
        XCTAssertEqual(session.berries, BerryEconomy.shufflePrice - 1)
        XCTAssertEqual(BerryEconomyLedger(defaults: store).spent, 0)
        XCTAssertNil(store.stringArray(forKey: receiptsKey))
        XCTAssertEqual(session.engine.moves, 0)
    }

    func testOwnedShuffleAndDisallowedModesRejectAnotherCheckout() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try initialize(store, wallet: 400, shuffles: 1)
        let owned = game(store)
        XCTAssertFalse(owned.buyAndContinueWithShuffle())
        XCTAssertEqual(owned.shuffles, 1)
        XCTAssertEqual(owned.berries, 400)
        XCTAssertEqual(BerryEconomyLedger(defaults: store).spent, 0)

        // These modes deliberately cannot buy a Game Over Shuffle; neither
        // a wallet change nor a receipt should occur.
        for mode in [BerryMode.classic, .challenge, .superHard] {
            let other = game(store, mode: mode)
            XCTAssertFalse(other.canContinueWithShuffle)
            XCTAssertFalse(other.buyAndContinueWithShuffle())
            XCTAssertEqual(other.berries, 400)
        }
        XCTAssertNil(store.stringArray(forKey: receiptsKey))
        XCTAssertEqual(try wallet(store), 400)
    }

    func testCombinedStoryShuffleNeverMutatesRealPlayerDataOrEndlessSaves() throws {
        let ownerKeys = [
            inventoryKey, receiptsKey,
            "berryberryblast.economy.spent.v0510",
            "berryberryblast.economy.purchases.v0510",
            "berryblockblast.story.level",
            "berryblockblast.award.chapter-2",
            "berryblockblast.endless.boardSize.v056b2",
            "berryblockblast.best-score.v1"
        ] + [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let before = ownerKeys.map {
            UserDefaults.standard.object(forKey: $0) as? NSObject
        }

        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try initialize(store, wallet: BerryEconomy.shufflePrice)
        let otherSaves = [8, 12, 24].map { size -> (String, Data) in
            let key = BerryGameSession.endlessSaveKey(side: size)
            return (key, Data([UInt8(size), 0xD3, 0xF0]))
        }
        for (key, data) in otherSaves { store.set(data, forKey: key) }

        let story = game(store)
        XCTAssertTrue(story.buyAndContinueWithShuffle())
        XCTAssertEqual(BerryEconomyLedger(defaults: store).spent,
                       BerryEconomy.shufflePrice)
        for (key, data) in otherSaves {
            XCTAssertEqual(store.data(forKey: key), data)
        }
        let after = ownerKeys.map {
            UserDefaults.standard.object(forKey: $0) as? NSObject
        }
        XCTAssertEqual(before, after)
    }
}
