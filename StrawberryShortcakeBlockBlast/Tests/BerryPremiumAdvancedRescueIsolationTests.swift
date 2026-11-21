import Foundation
import XCTest
@testable import BerryBlockBlast

/// D2c: actual premium action methods and combined Golden Strawberry checkout
/// using a disposable store + real injected ledger. No owner's preferences
/// or normal games are written by these tests.
@MainActor
final class BerryPremiumAdvancedRescueIsolationTests: XCTestCase {
    private struct Inventory: Codable {
        var berries: Int
        var undos: Int
        var shuffles: Int
        var totalEarnedBerries: Int
        var hints: Int
    }

    private let inventoryKey = "berryblockblast.inventory.v3"
    private let chargesKey = "berryberryblast.premium.charges.v059"
    private let ownedKey = "berryberryblast.premium.permanent.v059"
    private let sizeKey = "berryblockblast.endless.boardSize.v056b2"
    private let rewardsKey = "berryblockblast.rewards.v1"

    private func suite() throws -> (name: String, defaults: UserDefaults) {
        let name = "com.valentinebsaa.berry.d2c.\(UUID().uuidString)"
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }

    private func fixture(side: Int) -> BerryEngine {
        let square = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 2)
        let elbow = BerryPiece(points: [
            BerryPoint(row: 0, col: 0),
            BerryPoint(row: 1, col: 0),
            BerryPoint(row: 1, col: 1)
        ], tint: 3)
        let spare = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 4)
        var cells = Array(repeating: Array<Int?>(repeating: nil, count: side),
                          count: side)
        if side == 24 {
            // Four distinct 12×12 sections, not just the visible upper left.
            cells[1][15] = 2
            cells[14][1] = 3
            cells[21][21] = 4
        }
        var result = BerryEngine(board: cells,
                                 tray: [square, elbow, spare], score: 100)
        XCTAssertNotNil(result.place(slot: 0, row: 1, col: 1))
        XCTAssertEqual(result.moves, 1)
        XCTAssertNotNil(result.board[1][1])
        return result
    }

    @discardableResult
    private func prepare(_ defaults: UserDefaults, side: Int = 8,
                         berries: Int = 0, charges: [String: Int] = [:],
                         owned: [String] = [],
                         saveBoard: Bool = true) throws -> BerryEngine? {
        defaults.set(try JSONEncoder().encode(Inventory(
            berries: berries, undos: 2, shuffles: 2,
            totalEarnedBerries: 13, hints: 1
        )), forKey: inventoryKey)
        defaults.set(charges, forKey: chargesKey)
        defaults.set(owned, forKey: ownedKey)
        defaults.set(side, forKey: sizeKey)
        guard saveBoard else { return nil }
        let board = fixture(side: side)
        defaults.set(try JSONEncoder().encode(board),
                     forKey: BerryGameSession.endlessSaveKey(side: side))
        return board
    }

    private func open(_ defaults: UserDefaults) -> BerryGameSession {
        let game = BerryGameSession(
            checkoutDefaults: defaults,
            checkoutLedger: BerryEconomyLedger(defaults: defaults))
        game.selectMode(.endless)
        return game
    }

    private func saved(_ defaults: UserDefaults, side: Int = 8) throws -> BerryEngine {
        let key = BerryGameSession.endlessSaveKey(side: side)
        let data = try XCTUnwrap(defaults.data(forKey: key))
        return try JSONDecoder().decode(BerryEngine.self, from: data)
    }

    private func wallet(_ defaults: UserDefaults) throws -> Int {
        let data = try XCTUnwrap(defaults.data(forKey: inventoryKey))
        return try JSONDecoder().decode(Inventory.self, from: data).berries
    }

    func testRealRibbonTwisterRotatesNonSymmetricPieceConsumesOneChargeAndRestores() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try prepare(store, charges: ["twister": 3])
        let game = open(store)
        let initial = try XCTUnwrap(game.engine.tray[1])
        XCTAssertTrue(game.useRibbonTwister(slot: 1))
        let changed = try XCTUnwrap(game.engine.tray[1])
        XCTAssertNotEqual(Set(initial.points), Set(changed.points))
        XCTAssertEqual(game.premiumCharges["twister"], 2)
        XCTAssertEqual(game.berries, 0)
        XCTAssertEqual(Set(try XCTUnwrap(saved(store).tray[1]).points),
                       Set(changed.points))
        let reopened = open(store)
        XCTAssertEqual(Set(try XCTUnwrap(reopened.engine.tray[1]).points),
                       Set(changed.points))
        XCTAssertEqual(reopened.premiumCharges["twister"], 2)
        XCTAssertEqual(reopened.engine.moves, 1)
    }

    func testMissingOrSymmetricTwisterTargetDoesNotSpendOrChangeSave() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try prepare(store, charges: ["twister": 1])
        let game = open(store)
        let key = BerryGameSession.endlessSaveKey(side: 8)
        // 8×8 mode selection may update the legacy migration flag and save.
        let before = try XCTUnwrap(store.data(forKey: key))
        XCTAssertFalse(game.useRibbonTwister(slot: 0)) // slot 0 was placed
        XCTAssertFalse(game.useRibbonTwister(slot: 2)) // one-cell symmetric
        XCTAssertFalse(game.useRibbonTwister(slot: -1))
        XCTAssertEqual(game.premiumCharges["twister"], 1)
        XCTAssertEqual(store.data(forKey: key), before)
        XCTAssertEqual(try saved(store).moves, 1)
    }

    func testOwnedPicnicPantryStashAndSwapSurviveRestart() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try prepare(store, owned: ["pantry"])
        let game = open(store)
        let originalPiece = try XCTUnwrap(game.engine.tray[1])
        XCTAssertTrue(game.usePicnicPantry(slot: 1))
        XCTAssertNil(game.engine.tray[1])
        XCTAssertEqual(game.pantryPiece, originalPiece)
        XCTAssertEqual(try saved(store).pantryPiece, originalPiece)
        let reopened = open(store)
        XCTAssertTrue(reopened.premiumOwned.contains("pantry"))
        XCTAssertNil(reopened.engine.tray[1])
        XCTAssertEqual(reopened.pantryPiece, originalPiece)
        XCTAssertTrue(reopened.usePicnicPantry(slot: 1))
        XCTAssertNil(reopened.pantryPiece)
        XCTAssertEqual(reopened.engine.tray[1], originalPiece)
        let twice = open(store)
        XCTAssertNil(twice.pantryPiece)
        XCTAssertEqual(twice.engine.tray[1], originalPiece)
        XCTAssertEqual(twice.berries, 0)
    }

    func testUnownedPantryAndEmptySlotRejectWithoutChangingSave() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try prepare(store)
        let unowned = open(store)
        let key = BerryGameSession.endlessSaveKey(side: 8)
        let initialSave = try XCTUnwrap(store.data(forKey: key))
        XCTAssertFalse(unowned.usePicnicPantry(slot: 1))
        XCTAssertEqual(store.data(forKey: key), initialSave)
        store.set(["pantry"], forKey: ownedKey)
        let owned = open(store)
        let afterSelect = try XCTUnwrap(store.data(forKey: key))
        XCTAssertFalse(owned.usePicnicPantry(slot: 0))
        XCTAssertFalse(owned.usePicnicPantry(slot: -1))
        XCTAssertNil(owned.pantryPiece)
        XCTAssertEqual(store.data(forKey: key), afterSelect)
        XCTAssertEqual(owned.berries, 0)
    }

    func testReal24x24GoldenRescueClearsAllSectionsAndPreservesOtherSaves() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try prepare(store, side: 24, charges: ["golden-strawberry": 1])
        let k8 = BerryGameSession.endlessSaveKey(side: 8)
        let k12 = BerryGameSession.endlessSaveKey(side: 12)
        let old8 = Data([8, 0xD2, 0xC8])
        let old12 = Data([12, 0xD2, 0xC8])
        store.set(old8, forKey: k8)
        store.set(old12, forKey: k12)
        let game = open(store)
        XCTAssertEqual(game.engine.side, 24)
        XCTAssertNotNil(game.engine.board[1][1])
        XCTAssertNotNil(game.engine.board[1][15])
        XCTAssertNotNil(game.engine.board[14][1])
        XCTAssertNotNil(game.engine.board[21][21])
        let score = game.engine.score
        XCTAssertTrue(game.useGoldenStrawberry())
        let reopened = open(store)
        XCTAssertTrue(reopened.engine.board.flatMap { $0 }.allSatisfy { $0 == nil })
        XCTAssertTrue(reopened.engine.goldenRescueUsed)
        XCTAssertEqual(reopened.engine.score, score)
        XCTAssertEqual(reopened.premiumCharges["golden-strawberry"], 0)
        XCTAssertFalse(reopened.canContinueWithGoldenStrawberry)
        XCTAssertEqual(store.data(forKey: k8), old8)
        XCTAssertEqual(store.data(forKey: k12), old12)
    }

    func testCombinedGoldenRescueUsesActualIsolatedWalletLedgerReceiptAndRestart() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try prepare(store, berries: 250)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        game.selectMode(.endless)
        let originalScore = game.engine.score
        XCTAssertTrue(game.buyAndUseGoldenStrawberry())
        XCTAssertEqual(game.berries, 0)
        XCTAssertEqual(try wallet(store), 0)
        XCTAssertEqual(ledger.spent, 250)
        XCTAssertEqual(ledger.spentByItem["Golden Strawberry Continue"], 250)
        XCTAssertTrue(game.rewardsLog.first?.contains("Golden Strawberry Continue") == true)
        XCTAssertEqual(store.stringArray(forKey: rewardsKey), game.rewardsLog)
        let reopened = open(store)
        XCTAssertEqual(reopened.berries, 0)
        XCTAssertEqual(reopened.engine.score, originalScore)
        XCTAssertTrue(reopened.engine.goldenRescueUsed)
        XCTAssertTrue(reopened.engine.board.flatMap { $0 }.allSatisfy { $0 == nil })
        XCTAssertFalse(reopened.buyAndUseGoldenStrawberry())
        XCTAssertEqual(BerryEconomyLedger(defaults: store).spent, 250)
        XCTAssertEqual(store.stringArray(forKey: rewardsKey)?.count, 1)
    }

    func testInsufficientWalletExistingChargeOrEmptyBoardRejectCombinedRescue() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try prepare(store, berries: 249)
        let poorLedger = BerryEconomyLedger(defaults: store)
        let poorGame = BerryGameSession(checkoutDefaults: store, checkoutLedger: poorLedger)
        poorGame.selectMode(.endless)
        let snapshot = try XCTUnwrap(store.data(forKey: BerryGameSession.endlessSaveKey(side: 8)))
        XCTAssertFalse(poorGame.buyAndUseGoldenStrawberry())
        XCTAssertEqual(try wallet(store), 249)
        XCTAssertEqual(poorLedger.spent, 0)
        XCTAssertEqual(store.data(forKey: BerryGameSession.endlessSaveKey(side: 8)), snapshot)

        // Existing purchased rescue charge means the combined checkout
        // must not debit again. Use the charge through its separate action.
        store.set(["golden-strawberry": 1], forKey: chargesKey)
        let chargedGame = open(store)
        XCTAssertFalse(chargedGame.buyAndUseGoldenStrawberry())
        XCTAssertEqual(chargedGame.berries, 249)
        XCTAssertEqual(BerryEconomyLedger(defaults: store).spent, 0)

        // An empty game cannot be paid-rescued.
        let (emptyName, emptyStore) = try suite()
        defer { emptyStore.removePersistentDomain(forName: emptyName) }
        try prepare(emptyStore, berries: 250, saveBoard: false)
        let emptyGame = open(emptyStore)
        let emptyLedger = BerryEconomyLedger(defaults: emptyStore)
        XCTAssertFalse(emptyGame.buyAndUseGoldenStrawberry())
        XCTAssertEqual(emptyGame.berries, 250)
        XCTAssertEqual(emptyLedger.spent, 0)
        XCTAssertNil(emptyStore.stringArray(forKey: rewardsKey))
    }

    func testD2cDisposableActionsCannotTouchActualPlayerPreferences() throws {
        let watched = [
            inventoryKey, chargesKey, ownedKey, sizeKey, rewardsKey,
            "berryberryblast.economy.spent.v0510",
            "berryberryblast.economy.purchases.v0510",
            "berryblockblast.endless.legacyMigrated.v056b2",
            "berryblockblast.best-score.v1"
        ] + [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let before = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }

        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try prepare(store, berries: 250, charges: ["twister": 1],
                    owned: ["pantry"])
        let game = open(store)
        XCTAssertTrue(game.useRibbonTwister(slot: 1))
        XCTAssertTrue(game.usePicnicPantry(slot: 1))
        XCTAssertTrue(game.buyAndUseGoldenStrawberry())
        _ = open(store)

        let after = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        XCTAssertEqual(before, after)
    }
}
