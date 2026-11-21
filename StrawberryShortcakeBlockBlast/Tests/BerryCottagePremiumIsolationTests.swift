import Foundation
import XCTest
@testable import BerryBlockBlast

/// D1b real GameSession Cottage and premium purchase regression. Each test
/// uses disposable preferences and its own real ledger, never the owner wallet.
@MainActor
final class BerryCottagePremiumIsolationTests: XCTestCase {
    private struct Inventory: Codable {
        let berries: Int
        let undos: Int
        let shuffles: Int
        let totalEarnedBerries: Int
        let hints: Int
    }

    private let inventoryKey = "berryblockblast.inventory.v3"
    private let cottageKey = "berryblockblast.cottage.decorations"
    private let premiumKey = "berryberryblast.premium.charges.v059"
    private let premiumOwnedKey = "berryberryblast.premium.permanent.v059"

    private func suite() throws -> (String, UserDefaults) {
        let name = "com.valentinebsaa.berry.d1b.\(UUID().uuidString)"
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }

    private func seed(_ defaults: UserDefaults, berries: Int,
                      decorations: Int = 0,
                      charges: [String: Int] = [:],
                      permanent: [String] = []) throws {
        let item = Inventory(berries: berries, undos: 2, shuffles: 2,
                             totalEarnedBerries: 93, hints: 1)
        defaults.set(try JSONEncoder().encode(item), forKey: inventoryKey)
        defaults.set(decorations, forKey: cottageKey)
        defaults.set(charges, forKey: premiumKey)
        defaults.set(permanent, forKey: premiumOwnedKey)
    }

    private func wallet(_ defaults: UserDefaults) throws -> Int {
        let bytes = try XCTUnwrap(defaults.data(forKey: inventoryKey))
        return try JSONDecoder().decode(Inventory.self, from: bytes).berries
    }

    private func verifyAllEndlessSlots(_ defaults: UserDefaults,
                                        expected: [String: Data],
                                        file: StaticString = #filePath,
                                        line: UInt = #line) {
        for (key, original) in expected {
            XCTAssertEqual(defaults.data(forKey: key), original,
                           "A shop-only action changed the saved garden \(key)",
                           file: file, line: line)
        }
    }

    private func seedEndlessSlots(_ defaults: UserDefaults) -> [String: Data] {
        var originals: [String: Data] = [:]
        for side in [8, 12, 24] {
            let key = BerryGameSession.endlessSaveKey(side: side)
            let bytes = Data([UInt8(side), 0xD1, 0xB0, 0xB5])
            defaults.set(bytes, forKey: key)
            originals[key] = bytes
        }
        return originals
    }

    func testCottageUsesOriginalEscalatingPricesAndReloadsOwnership() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 210)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        XCTAssertEqual(game.nextCottageDecorationPrice, 60)
        game.buyCottageDecoration()
        XCTAssertEqual(game.cottageDecorations, 1)
        XCTAssertEqual(game.nextCottageDecorationPrice, 90)
        game.buyCottageDecoration()
        XCTAssertEqual(game.cottageDecorations, 2)
        XCTAssertEqual(game.berries, 60)
        XCTAssertEqual(try wallet(store), 60)
        XCTAssertEqual(ledger.spent, 150)
        XCTAssertEqual(ledger.spentByItem["Cottage Decoration"], 150)
        let reloaded = BerryGameSession(checkoutDefaults: store,
                                         checkoutLedger: BerryEconomyLedger(defaults: store))
        XCTAssertEqual(reloaded.cottageDecorations, 2)
        XCTAssertEqual(reloaded.berries, 60)
        XCTAssertEqual(reloaded.nextCottageDecorationPrice, 130)
    }

    func testCottageUnderfundedAndSoldOutDoNotWriteAnyPurchase() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 59)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        let original = try XCTUnwrap(store.data(forKey: inventoryKey))
        game.buyCottageDecoration()
        XCTAssertEqual(store.data(forKey: inventoryKey), original)
        XCTAssertEqual(game.cottageDecorations, 0)
        XCTAssertEqual(ledger.spent, 0)
        try seed(store, berries: 700, decorations: BerryEconomy.cottagePrices.count)
        let soldOut = BerryGameSession(checkoutDefaults: store,
                                       checkoutLedger: BerryEconomyLedger(defaults: store))
        let soldOutInventory = try XCTUnwrap(store.data(forKey: inventoryKey))
        XCTAssertNil(soldOut.nextCottageDecorationPrice)
        soldOut.buyCottageDecoration()
        XCTAssertEqual(store.data(forKey: inventoryKey), soldOutInventory)
        XCTAssertEqual(soldOut.cottageDecorations, BerryEconomy.cottagePrices.count)
    }

    func testPremiumOriginalSKUPricesAndPurchasedChargesPersist() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 3_000)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        let items: [(String, Int)] = [("trowel", 150), ("twister", 200),
                                      ("seed", 230), ("golden-strawberry", 250),
                                      ("pantry", 600), ("spyglass", 900)]
        for (id, price) in items {
            XCTAssertTrue(game.buyPremium(id), "Expected accepted SKU: \(id)")
            XCTAssertEqual(ledger.spentByItem[id], price)
        }
        XCTAssertEqual(game.berries, 670)
        XCTAssertEqual(try wallet(store), 670)
        XCTAssertEqual(ledger.spent, 2330)
        XCTAssertEqual(game.premiumCharges["trowel"], 1)
        XCTAssertEqual(game.premiumCharges["twister"], 3)
        XCTAssertEqual(game.premiumCharges["seed"], 1)
        XCTAssertEqual(game.premiumCharges["golden-strawberry"], 1)
        XCTAssertTrue(game.premiumOwned.contains("pantry"))
        XCTAssertTrue(game.premiumOwned.contains("spyglass"))
        let reopened = BerryGameSession(checkoutDefaults: store,
                                        checkoutLedger: BerryEconomyLedger(defaults: store))
        XCTAssertEqual(reopened.premiumCharges, game.premiumCharges)
        XCTAssertEqual(reopened.premiumOwned, game.premiumOwned)
        XCTAssertEqual(reopened.berries, 670)
    }

    func testPremiumUnknownAndUnderfundedRequestsNeverCharge() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 149)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        let original = try XCTUnwrap(store.data(forKey: inventoryKey))
        XCTAssertFalse(game.buyPremium("made-up-tool"))
        for id in ["trowel", "twister", "seed", "golden-strawberry", "pantry", "spyglass"] {
            XCTAssertFalse(game.buyPremium(id), id)
        }
        XCTAssertEqual(store.data(forKey: inventoryKey), original)
        XCTAssertEqual(game.premiumCharges, [:])
        XCTAssertEqual(game.premiumOwned, [])
        XCTAssertEqual(ledger.spent, 0)
        XCTAssertEqual(game.berries, 149)
    }

    func testPermanentPremiumCannotBeBoughtTwiceEvenAfterReopen() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 2_000)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        XCTAssertTrue(game.buyPremium("pantry"))
        XCTAssertTrue(game.buyPremium("spyglass"))
        let inventoryAfter = try XCTUnwrap(store.data(forKey: inventoryKey))
        XCTAssertFalse(game.buyPremium("pantry"))
        XCTAssertFalse(game.buyPremium("spyglass"))
        let reopened = BerryGameSession(checkoutDefaults: store,
                                        checkoutLedger: BerryEconomyLedger(defaults: store))
        XCTAssertFalse(reopened.buyPremium("pantry"))
        XCTAssertFalse(reopened.buyPremium("spyglass"))
        XCTAssertEqual(store.data(forKey: inventoryKey), inventoryAfter)
        XCTAssertEqual(ledger.spent, 1500)
        XCTAssertEqual(try wallet(store), 500)
        XCTAssertEqual(Set(reopened.premiumOwned), Set(["pantry", "spyglass"]))
    }

    func testPremiumChargeOverflowRejectsBeforeSpending() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 500, charges: ["twister": Int.max - 2])
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        let originalInventory = try XCTUnwrap(store.data(forKey: inventoryKey))
        XCTAssertFalse(game.buyPremium("twister"))
        XCTAssertEqual(game.premiumCharges["twister"], Int.max - 2)
        XCTAssertEqual(store.data(forKey: inventoryKey), originalInventory)
        XCTAssertEqual(ledger.spent, 0)
        XCTAssertEqual(game.berries, 500)
    }

    func testCottageAndPremiumMenuBuysPreserveAllThreeEndlessSaves() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 3_000)
        let originals = seedEndlessSlots(store)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        let originalEngine = try JSONEncoder().encode(game.engine)
        game.buyCottageDecoration()
        XCTAssertTrue(game.buyPremium("twister"))
        XCTAssertTrue(game.buyPremium("pantry"))
        XCTAssertTrue(game.buyPremium("golden-strawberry"))
        verifyAllEndlessSlots(store, expected: originals)
        XCTAssertEqual(try JSONEncoder().encode(game.engine), originalEngine)
        XCTAssertEqual(ledger.spent, 60 + 200 + 600 + 250)
        XCTAssertEqual(try wallet(store), 1_890)
        let reopened = BerryGameSession(checkoutDefaults: store,
                                        checkoutLedger: BerryEconomyLedger(defaults: store))
        XCTAssertEqual(reopened.cottageDecorations, 1)
        XCTAssertTrue(reopened.premiumOwned.contains("pantry"))
        XCTAssertEqual(reopened.premiumCharges["twister"], 3)
        verifyAllEndlessSlots(store, expected: originals)
    }

    func testLegacyCottageAndPremiumOwnershipRemainIntact() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 1_000, decorations: 2,
                 charges: ["twister": 2], permanent: ["pantry"])
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        XCTAssertEqual(game.cottageDecorations, 2)
        XCTAssertEqual(game.nextCottageDecorationPrice, 130)
        XCTAssertFalse(game.buyPremium("pantry"))
        XCTAssertTrue(game.buyPremium("trowel"))
        game.buyCottageDecoration()
        XCTAssertEqual(game.cottageDecorations, 3)
        XCTAssertEqual(game.premiumCharges["twister"], 2)
        XCTAssertEqual(game.premiumCharges["trowel"], 1)
        XCTAssertEqual(game.premiumOwned, ["pantry"])
        XCTAssertEqual(ledger.spent, 280)
        XCTAssertEqual(try wallet(store), 720)
    }

    func testInvalidPremiumUsePreservesChargesAndSavedEndless() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 250, charges: ["trowel": 1])
        let originals = seedEndlessSlots(store)
        let game = BerryGameSession(checkoutDefaults: store,
                                    checkoutLedger: BerryEconomyLedger(defaults: store))
        XCTAssertFalse(game.useGoldenTrowel(row: -1, col: 999))
        XCTAssertEqual(game.premiumCharges["trowel"], 1)
        XCTAssertEqual(store.dictionary(forKey: premiumKey) as? [String: Int],
                       ["trowel": 1])
        XCTAssertEqual(try wallet(store), 250)
        verifyAllEndlessSlots(store, expected: originals)
    }

    func testDisposableCottageAndPremiumSessionDoesNotModifyPlayerDefaults() throws {
        let watched = [inventoryKey, cottageKey, premiumKey, premiumOwnedKey,
                       "berryberryblast.economy.spent.v0510",
                       "berryberryblast.economy.purchases.v0510",
                       "berryblockblast.rewards.v1",
                       "berryblockblast.shop.owned.v056b2"] +
                      [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let before = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 2_500)
        let game = BerryGameSession(checkoutDefaults: store,
                                    checkoutLedger: BerryEconomyLedger(defaults: store))
        game.buyCottageDecoration()
        XCTAssertTrue(game.buyPremium("pantry"))
        XCTAssertTrue(game.buyPremium("twister"))
        let after = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        for index in watched.indices {
            XCTAssertEqual(before[index], after[index],
                           "Isolated D1b checkout changed player key \(watched[index])")
        }
    }
}
