import Foundation
import XCTest
@testable import BerryBlockBlast

/// D1a: actual BerryGameSession.buyCosmetic, with real ledger and inventory
/// writes directed to a disposable UserDefaults suite. No live game wallet,
/// owned items, cosmetics, rewards or current Endless saves are touched.
@MainActor
final class BerryBoutiqueCheckoutIsolationTests: XCTestCase {
    private struct Inventory: Codable, Equatable {
        let berries: Int
        let undos: Int
        let shuffles: Int
        let totalEarnedBerries: Int
        let hints: Int
    }

    private let inventoryKey = "berryblockblast.inventory.v3"
    private let ownedKey = "berryblockblast.shop.owned.v056b2"
    private let rewardsKey = "berryblockblast.rewards.v1"
    private let skinKey = "berryblockblast.shop.equippedBlockSkin.v056b2"
    private let boardKey = "berryberryblast.board.surface.v059"

    private func suite() throws -> (name: String, defaults: UserDefaults) {
        let name = "com.valentinebsaa.berry.d1a.\(UUID().uuidString)"
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }

    private func seed(_ store: UserDefaults, berries: Int = 200,
                      owned: [String] = [], rewards: [String] = []) throws {
        let inv = Inventory(berries: berries, undos: 2, shuffles: 2,
                            totalEarnedBerries: 50, hints: 1)
        store.set(try JSONEncoder().encode(inv), forKey: inventoryKey)
        store.set(owned, forKey: ownedKey)
        store.set(rewards, forKey: rewardsKey)
    }

    private func inventory(_ store: UserDefaults) throws -> Inventory {
        try JSONDecoder().decode(Inventory.self, from:
            XCTUnwrap(store.data(forKey: inventoryKey)))
    }

    func testOfficialCosmeticPriceCatalogKeepsApprovedPrices() {
        let expected: [String: Int] = [
            "strawberry-fruit": 0, "blueberry-blocks": 90,
            "vanilla-blocks": 90, "rose-border": 75,
            "mint-border": 75, "berry-sparkle": 100,
            "raspberry-blocks": 110, "lemon-blocks": 110,
            "chocolate-blocks": 120, "mint-blocks": 110,
            "blackberry-blocks": 130
        ]
        XCTAssertEqual(BerryBoutiquePurchasePolicy.prices, expected)
        XCTAssertNil(BerryBoutiquePurchasePolicy.price(for: "seasonal-frame"))
        XCTAssertNil(BerryBoutiquePurchasePolicy.price(for: "surface-glass"))
    }

    func testRealPurchasePersistsOwnershipReceiptWalletAndLedger() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 90)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)

        XCTAssertTrue(game.buyCosmetic(id: "blueberry-blocks", cost: 90))

        XCTAssertEqual(game.berries, 0)
        XCTAssertEqual(try inventory(store).berries, 0)
        XCTAssertEqual(game.ownedCosmetics, ["blueberry-blocks"])
        XCTAssertEqual(store.stringArray(forKey: ownedKey), ["blueberry-blocks"])
        XCTAssertEqual(ledger.spent, 90)
        XCTAssertEqual(ledger.spentByItem["blueberry-blocks"], 90)
        XCTAssertTrue(game.rewardsLog.first?.contains("blueberry-blocks") == true)
        XCTAssertEqual(store.stringArray(forKey: rewardsKey), game.rewardsLog)
    }

    func testRealUnderfundedPurchaseDoesNotWriteInventoryOwnershipOrReceipt() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 89)
        let bytes = try XCTUnwrap(store.data(forKey: inventoryKey))
        let owned = store.stringArray(forKey: ownedKey)
        let receipts = store.stringArray(forKey: rewardsKey)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)

        XCTAssertFalse(game.buyCosmetic(id: "blueberry-blocks", cost: 90))
        XCTAssertEqual(store.data(forKey: inventoryKey), bytes)
        XCTAssertEqual(store.stringArray(forKey: ownedKey), owned)
        XCTAssertEqual(store.stringArray(forKey: rewardsKey), receipts)
        XCTAssertEqual(game.berries, 89)
        XCTAssertEqual(ledger.spent, 0)
    }

    func testUnknownProductOrSpoofedPriceCannotPurchase() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 500)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        let before = try XCTUnwrap(store.data(forKey: inventoryKey))

        XCTAssertFalse(game.buyCosmetic(id: "blueberry-blocks", cost: 1))
        XCTAssertFalse(game.buyCosmetic(id: "blueberry-blocks", cost: -90))
        XCTAssertFalse(game.buyCosmetic(id: "unknown-inventory", cost: 0))
        XCTAssertFalse(game.buyCosmetic(id: "surface-glass", cost: 0))
        XCTAssertEqual(game.berries, 500)
        XCTAssertEqual(game.ownedCosmetics, [])
        XCTAssertEqual(store.data(forKey: inventoryKey), before)
        XCTAssertEqual(ledger.spent, 0)
    }

    func testDuplicateOwnedCosmeticCannotDebitTwiceEvenAfterReopen() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 220)
        let ledger = BerryEconomyLedger(defaults: store)
        let first = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)

        XCTAssertTrue(first.buyCosmetic(id: "vanilla-blocks", cost: 90))
        let saved = try XCTUnwrap(store.data(forKey: inventoryKey))
        XCTAssertFalse(first.buyCosmetic(id: "vanilla-blocks", cost: 90))
        XCTAssertEqual(store.data(forKey: inventoryKey), saved)
        XCTAssertEqual(ledger.spent, 90)
        let reopened = BerryGameSession(checkoutDefaults: store,
                                        checkoutLedger: BerryEconomyLedger(defaults: store))
        XCTAssertTrue(reopened.ownedCosmetics.contains("vanilla-blocks"))
        XCTAssertFalse(reopened.buyCosmetic(id: "vanilla-blocks", cost: 90))
        XCTAssertEqual(reopened.berries, 130)
        XCTAssertEqual(store.stringArray(forKey: ownedKey), ["vanilla-blocks"])
    }

    func testFreeStrawberryBlocksGrantOnceWithoutSpending() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 0)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)

        XCTAssertTrue(game.buyCosmetic(id: "strawberry-fruit", cost: 0))
        XCTAssertFalse(game.buyCosmetic(id: "strawberry-fruit", cost: 0))
        XCTAssertEqual(game.berries, 0)
        XCTAssertEqual(ledger.spent, 0)
        XCTAssertEqual(ledger.spentByItem["strawberry-fruit"], nil)
        XCTAssertEqual(store.stringArray(forKey: ownedKey), ["strawberry-fruit"])
    }

    func testLegacyOwnershipAndExistingEquipSettingsSurvivePurchase() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 250, owned: ["blueberry-blocks"])
        store.set("blueberry-blocks", forKey: skinKey)
        store.set("blossom-glass", forKey: boardKey)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)

        XCTAssertFalse(game.buyCosmetic(id: "blueberry-blocks", cost: 90))
        XCTAssertTrue(game.buyCosmetic(id: "rose-border", cost: 75))
        XCTAssertEqual(game.ownedCosmetics, ["blueberry-blocks", "rose-border"])
        XCTAssertEqual(store.string(forKey: skinKey), "blueberry-blocks")
        XCTAssertEqual(store.string(forKey: boardKey), "blossom-glass")
        XCTAssertEqual(game.berries, 175)
        XCTAssertEqual(ledger.spentByItem["rose-border"], 75)
    }

    func testMenuCosmeticAndHelperPurchasesNeverEraseSavedEndlessBoards() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 400)
        var snapshots: [String: Data] = [:]
        for side in [8, 12, 24] {
            let key = BerryGameSession.endlessSaveKey(side: side)
            let bytes = Data([UInt8(side), 0xB1, 0x05, 0x14])
            store.set(bytes, forKey: key)
            snapshots[key] = bytes
        }
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)

        XCTAssertTrue(game.buyCosmetic(id: "rose-border", cost: 75))
        game.buyUndo()
        game.buyHint()
        XCTAssertEqual(game.berries, 400 - 75 -
                       BerryEconomy.undoPrice - BerryEconomy.hintPrice)
        for (key, bytes) in snapshots {
            XCTAssertEqual(store.data(forKey: key), bytes,
                           "An unrelated Endless save was changed by shopping: \(key)")
        }
    }

    func testBoutiqueRewardHistoryStillCapsAtTwentyEntries() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let older = (0..<20).map { "Legacy reward \($0)" }
        try seed(store, berries: 200, rewards: older)
        let game = BerryGameSession(checkoutDefaults: store,
                                    checkoutLedger: BerryEconomyLedger(defaults: store))
        XCTAssertTrue(game.buyCosmetic(id: "mint-border", cost: 75))
        XCTAssertEqual(game.rewardsLog.count, 20)
        XCTAssertEqual(store.stringArray(forKey: rewardsKey)?.count, 20)
        XCTAssertTrue(game.rewardsLog[0].contains("mint-border"))
        XCTAssertFalse(game.rewardsLog.contains("Legacy reward 19"))
    }

    func testDisposableBoutiquePurchaseDoesNotWriteRealPlayerPreferences() throws {
        let keys = [inventoryKey, ownedKey, rewardsKey,
                    skinKey, boardKey, "berryberryblast.economy.spent.v0510",
                    "berryberryblast.economy.purchases.v0510",
                    BerryGameSession.endlessSaveKey(side: 8),
                    BerryGameSession.endlessSaveKey(side: 12),
                    BerryGameSession.endlessSaveKey(side: 24)]
        let before = keys.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 400)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        XCTAssertTrue(game.buyCosmetic(id: "blackberry-blocks", cost: 130))
        XCTAssertTrue(game.buyCosmetic(id: "berry-sparkle", cost: 100))
        XCTAssertEqual(game.berries, 170)
        XCTAssertEqual(ledger.spent, 230)

        let after = keys.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        for i in keys.indices {
            XCTAssertEqual(before[i], after[i],
                           "D1a touched normal player preference key \(keys[i])")
        }
    }
}
