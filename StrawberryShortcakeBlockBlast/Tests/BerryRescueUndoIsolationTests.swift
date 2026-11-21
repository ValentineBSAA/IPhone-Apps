import Foundation
import XCTest
@testable import BerryBlockBlast

/// D3f first safety slice: actual paid Shuffle and Undo ledger/receipt
/// paths with disposable stores. These call real engine/session methods;
/// a true blocked Story Game Over overlay/tap test remains separate.
@MainActor
final class BerryRescueUndoIsolationTests: XCTestCase {
    private struct Inventory: Codable {
        var berries: Int
        var undos: Int
        var shuffles: Int
        var totalEarnedBerries: Int
        var hints: Int
    }

    private let inventoryKey = "berryblockblast.inventory.v3"
    private let rewardsKey = "berryblockblast.rewards.v1"

    private func suite() throws -> (name: String, store: UserDefaults) {
        let name = "com.valentinebsaa.berry.d3f.\(UUID().uuidString)"
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }

    private func seed(_ store: UserDefaults, berries: Int,
                      undos: Int = 2, shuffles: Int = 0) throws {
        store.set(try JSONEncoder().encode(Inventory(
            berries: berries, undos: undos, shuffles: shuffles,
            totalEarnedBerries: 0, hints: 0)), forKey: inventoryKey)
    }

    private func open(_ store: UserDefaults,
                      ledger: BerryEconomyLedger,
                      mode: BerryMode) -> BerryGameSession {
        let game = BerryGameSession(checkoutDefaults: store,
                                    checkoutLedger: ledger)
        game.selectMode(mode)
        return game
    }

    private func decodedWallet(_ store: UserDefaults) throws -> Inventory {
        try JSONDecoder().decode(Inventory.self,
            from: XCTUnwrap(store.data(forKey: inventoryKey)))
    }

    func testRealStoryShufflePurchaseSpendsExactPriceOnlyInDisposableLedgerAndReceipt() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let price = BerryEconomy.shufflePrice
        try seed(store, berries: price, shuffles: 0)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = open(store, ledger: ledger, mode: .story)
        let score = game.engine.score
        let moves = game.engine.moves
        XCTAssertTrue(game.canContinueWithShuffle)
        XCTAssertTrue(game.buyAndContinueWithShuffle())
        XCTAssertTrue(game.engine.hasMove())
        XCTAssertEqual(game.engine.score, score)
        XCTAssertEqual(game.engine.moves, moves)
        XCTAssertEqual(game.berries, 0)
        XCTAssertEqual(ledger.spent, price)
        XCTAssertEqual(ledger.spentByItem["Shuffle Continue"], price)
        XCTAssertEqual(store.stringArray(forKey: rewardsKey)?.count, 1)
        XCTAssertTrue(store.stringArray(forKey: rewardsKey)?.first?
                      .contains("Shuffle Continue") == true)
        XCTAssertEqual(try decodedWallet(store).berries, 0)
        let restarted = open(store,
            ledger: BerryEconomyLedger(defaults: store), mode: .story)
        XCTAssertEqual(restarted.berries, 0)
        XCTAssertEqual(store.stringArray(forKey: rewardsKey)?.count, 1)
        XCTAssertFalse(restarted.buyAndContinueWithShuffle())
        XCTAssertEqual(ledger.spent, price)
    }

    func testInsufficientWalletCannotBuyShuffleOrChangeLedgerReceipts() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let price = BerryEconomy.shufflePrice
        XCTAssertGreaterThan(price, 0)
        try seed(store, berries: price - 1, shuffles: 0)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = open(store, ledger: ledger, mode: .story)
        let score = game.engine.score
        XCTAssertFalse(game.buyAndContinueWithShuffle())
        XCTAssertEqual(game.berries, price - 1)
        XCTAssertEqual(game.engine.score, score)
        XCTAssertEqual(ledger.spent, 0)
        XCTAssertNil(store.stringArray(forKey: rewardsKey))
        XCTAssertEqual(try decodedWallet(store).berries, price - 1)
    }

    func testPaidShuffleRefusesAlreadyOwnedChargesAndClassic() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let price = BerryEconomy.shufflePrice
        try seed(store, berries: price, shuffles: 1)
        let ledger = BerryEconomyLedger(defaults: store)
        let story = open(store, ledger: ledger, mode: .story)
        XCTAssertFalse(story.buyAndContinueWithShuffle())
        XCTAssertEqual(story.berries, price)
        XCTAssertEqual(story.shuffles, 1)
        try seed(store, berries: price, shuffles: 0)
        let classic = open(store, ledger: ledger, mode: .classic)
        XCTAssertFalse(classic.buyAndContinueWithShuffle())
        XCTAssertEqual(classic.berries, price)
        XCTAssertEqual(ledger.spent, 0)
        XCTAssertNil(store.stringArray(forKey: rewardsKey))
    }

    func testRealLineEarningUndoReversesIsolatedLedgerAndReceiptOnly() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: 0, undos: 2, shuffles: 1)
        store.set(8, forKey: "berryblockblast.endless.boardSize.v056b2")
        let one = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 2)
        var board = Array(repeating: Array<Int?>(repeating: nil, count: 8),
                          count: 8)
        for col in 0..<7 { board[0][col] = 1 }
        var fixture = BerryEngine(board: board,
            tray: [one, one, one], score: 10)
        XCTAssertNotNil(fixture.place(slot: 0, row: 3, col: 3))
        XCTAssertEqual(fixture.moves, 1)
        store.set(try JSONEncoder().encode(fixture),
                  forKey: BerryGameSession.endlessSaveKey(side: 8))
        let ledger = BerryEconomyLedger(defaults: store)
        let game = open(store, ledger: ledger, mode: .endless)
        let preScore = game.engine.score
        let preMoves = game.engine.moves
        XCTAssertTrue(game.drop(slot: 1, row: 0, col: 7))
        XCTAssertEqual(game.engine.moves, preMoves + 1)
        XCTAssertGreaterThan(game.berries, 0)
        let earnings = game.berries
        XCTAssertEqual(ledger.earnedByMode[BerryMode.endless.rawValue], earnings)
        XCTAssertEqual(store.stringArray(forKey: rewardsKey)?.count, 1)
        XCTAssertGreaterThan(game.undo(), 0)
        XCTAssertEqual(game.berries, 0)
        XCTAssertEqual(game.engine.score, preScore)
        XCTAssertEqual(game.engine.moves, preMoves)
        XCTAssertEqual(ledger.earnedByMode[BerryMode.endless.rawValue], 0)
        XCTAssertEqual(store.stringArray(forKey: rewardsKey], [])
        XCTAssertEqual(try decodedWallet(store).berries, 0)
        XCTAssertEqual(game.undos, 1)
    }

    func testRealPlayerWalletLedgerAndAllThreeEndlessSavesStayUnchanged() throws {
        let keys = [
            inventoryKey, rewardsKey,
            "berryberryblast.economy.spent.v0510",
            "berryberryblast.economy.purchases.v0510",
            "berryberryblast.economy.modeEarnings.v0510",
            "berryblockblast.story.level",
            "berryblockblast.award.birthday-2026",
            "berryberryblast.daily.attempt.v0510"
        ] + [8, 12, 24].map {
            BerryGameSession.endlessSaveKey(side: $0)
        }
        let before = keys.map {
            UserDefaults.standard.object(forKey: $0) as? NSObject
        }
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        try seed(store, berries: BerryEconomy.shufflePrice, shuffles: 0)
        let ledger = BerryEconomyLedger(defaults: store)
        let game = open(store, ledger: ledger, mode: .story)
        XCTAssertTrue(game.buyAndContinueWithShuffle())
        XCTAssertEqual(ledger.spent, BerryEconomy.shufflePrice)
        let after = keys.map {
            UserDefaults.standard.object(forKey: $0) as? NSObject
        }
        XCTAssertEqual(before, after)
    }
}
