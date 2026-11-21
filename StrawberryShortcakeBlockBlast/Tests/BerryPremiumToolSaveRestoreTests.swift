import Foundation
import XCTest
@testable import BerryBlockBlast

/// D2a: production GameSession premium use with a real initialized engine,
/// disposable wallet/preferences and an actual save/reopen. No player keys touched.
@MainActor
final class BerryPremiumToolSaveRestoreTests: XCTestCase {
    private struct Inventory: Codable {
        let berries: Int
        let undos: Int
        let shuffles: Int
        let totalEarnedBerries: Int
        let hints: Int
    }

    private let inventoryKey = "berryblockblast.inventory.v3"
    private let chargesKey = "berryberryblast.premium.charges.v059"
    private let sizeKey = "berryblockblast.endless.boardSize.v056b2"

    private func sandbox() throws -> (String, UserDefaults) {
        let name = "com.valentinebsaa.berry.d2a.\(UUID().uuidString)"
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }

    private func startedBoard(side: Int) -> BerryEngine {
        let one = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 2)
        let board = Array(repeating: Array<Int?>(repeating: nil, count: side),
                          count: side)
        var engine = BerryEngine(board: board, tray: [one, nil, nil], score: 100)
        XCTAssertNotNil(engine.place(slot: 0, row: 1, col: 1))
        XCTAssertGreaterThan(engine.moves, 0)
        XCTAssertNotNil(engine.board[1][1])
        XCTAssertTrue(engine.hasMove())
        return engine
    }

    private func prepare(_ store: UserDefaults, side: Int = 8,
                         charges: [String: Int]) throws -> BerryEngine {
        let inv = Inventory(berries: 500, undos: 2, shuffles: 2,
                            totalEarnedBerries: 15, hints: 1)
        store.set(try JSONEncoder().encode(inv), forKey: inventoryKey)
        store.set(charges, forKey: chargesKey)
        store.set(side, forKey: sizeKey)
        let start = startedBoard(side: side)
        store.set(try JSONEncoder().encode(start),
                  forKey: BerryGameSession.endlessSaveKey(side: side))
        return start
    }

    private func open(_ store: UserDefaults) -> BerryGameSession {
        let session = BerryGameSession(checkoutDefaults: store,
                                       checkoutLedger: BerryEconomyLedger(defaults: store))
        session.selectMode(.endless)
        return session
    }

    private func saved(_ store: UserDefaults, side: Int = 8) throws -> BerryEngine {
        let bytes = try XCTUnwrap(store.data(forKey: BerryGameSession.endlessSaveKey(side: side)))
        return try JSONDecoder().decode(BerryEngine.self, from: bytes)
    }

    func testRealTrowelClearsOccupiedCellPersistsChargeAndRestoresAfterRestart() throws {
        let (name, store) = try sandbox()
        defer { store.removePersistentDomain(forName: name) }
        let initial = try prepare(store, charges: ["trowel": 1])
        let game = open(store)
        XCTAssertEqual(game.engine.moves, initial.moves)
        XCTAssertNotNil(game.engine.board[1][1])
        XCTAssertTrue(game.useGoldenTrowel(row: 1, col: 1))
        XCTAssertNil(game.engine.board[1][1])
        XCTAssertEqual(game.premiumCharges["trowel"], 0)
        XCTAssertEqual(game.berries, 500)
        XCTAssertNil(try saved(store).board[1][1])
        let reopened = open(store)
        XCTAssertNil(reopened.engine.board[1][1])
        XCTAssertEqual(reopened.engine.moves, initial.moves)
        XCTAssertEqual(reopened.engine.score, initial.score)
        XCTAssertEqual(reopened.premiumCharges["trowel"], 0)
    }

    func testRealStarberrySeedPlantsIntoEmptyCellAndSurvivesReopen() throws {
        let (name, store) = try sandbox()
        defer { store.removePersistentDomain(forName: name) }
        let initial = try prepare(store, charges: ["seed": 1])
        let game = open(store)
        XCTAssertNil(game.engine.board[3][3])
        XCTAssertTrue(game.useStarberrySeed(row: 3, col: 3))
        XCTAssertEqual(game.engine.board[3][3], 0)
        XCTAssertEqual(game.engine.moves, initial.moves + 1)
        XCTAssertEqual(game.premiumCharges["seed"], 0)
        XCTAssertEqual(game.berries, 500)
        XCTAssertEqual(try saved(store).board[3][3], 0)
        let reopened = open(store)
        XCTAssertEqual(reopened.engine.board[3][3], 0)
        XCTAssertEqual(reopened.engine.moves, initial.moves + 1)
        XCTAssertEqual(reopened.premiumCharges["seed"], 0)
    }

    func testRealGoldenStrawberryClearsOccupiedBoardPreservesScoreAndOneUseLimit() throws {
        let (name, store) = try sandbox()
        defer { store.removePersistentDomain(forName: name) }
        let initial = try prepare(store, charges: ["golden-strawberry": 1])
        let game = open(store)
        XCTAssertTrue(game.canContinueWithGoldenStrawberry)
        XCTAssertTrue(game.useGoldenStrawberry())
        XCTAssertTrue(game.engine.goldenRescueUsed)
        XCTAssertTrue(game.engine.board.flatMap { $0 }.allSatisfy { $0 == nil })
        XCTAssertEqual(game.engine.score, initial.score)
        XCTAssertEqual(game.premiumCharges["golden-strawberry"], 0)
        XCTAssertTrue(try saved(store).goldenRescueUsed)
        let reopened = open(store)
        XCTAssertTrue(reopened.engine.goldenRescueUsed)
        XCTAssertEqual(reopened.engine.score, initial.score)
        XCTAssertFalse(reopened.canContinueWithGoldenStrawberry)
        XCTAssertFalse(reopened.useGoldenStrawberry())
        XCTAssertEqual(reopened.premiumCharges["golden-strawberry"], 0)
    }

    func testInvalidToolTargetsDoNotConsumePurchasedChargesOrRewriteSavedBoard() throws {
        let (name, store) = try sandbox()
        defer { store.removePersistentDomain(forName: name) }
        _ = try prepare(store, charges: ["trowel": 1, "seed": 1])
        let key = BerryGameSession.endlessSaveKey(side: 8)
        let before = try XCTUnwrap(store.data(forKey: key))
        let game = open(store)
        // 8×8 mode selection may update migration bookkeeping. Capture
        // persisted bytes BEFORE invalid actions, not afterward.
        let afterSelect = try XCTUnwrap(store.data(forKey: key))
        XCTAssertFalse(game.useGoldenTrowel(row: -1, col: 30))
        XCTAssertFalse(game.useStarberrySeed(row: 1, col: 1))
        XCTAssertEqual(game.premiumCharges["trowel"], 1)
        XCTAssertEqual(game.premiumCharges["seed"], 1)
        XCTAssertEqual(store.data(forKey: key), afterSelect)
        XCTAssertEqual(try saved(store).moves, 1)
        XCTAssertEqual(game.engine.moves, 1)
        XCTAssertGreaterThan(before.count, 0)
    }

    func test24By24ToolUseUpdatesOnlyItsOwnSlotAndKeepsOtherSizes() throws {
        let (name, store) = try sandbox()
        defer { store.removePersistentDomain(forName: name) }
        let first = startedBoard(side: 8)
        let second = startedBoard(side: 12)
        let k8 = BerryGameSession.endlessSaveKey(side: 8)
        let k12 = BerryGameSession.endlessSaveKey(side: 12)
        store.set(try JSONEncoder().encode(first), forKey: k8)
        store.set(try JSONEncoder().encode(second), forKey: k12)
        let before8 = try XCTUnwrap(store.data(forKey: k8))
        let before12 = try XCTUnwrap(store.data(forKey: k12))
        _ = try prepare(store, side: 24, charges: ["trowel": 1])
        let game = open(store)
        XCTAssertEqual(game.engine.side, 24)
        XCTAssertNotNil(game.engine.board[1][1])
        XCTAssertTrue(game.useGoldenTrowel(row: 1, col: 1))
        XCTAssertEqual(store.data(forKey: k8), before8)
        XCTAssertEqual(store.data(forKey: k12), before12)
        XCTAssertNil(try saved(store, side: 24).board[1][1])
        let reopened = open(store)
        XCTAssertEqual(reopened.engine.side, 24)
        XCTAssertNil(reopened.engine.board[1][1])
        XCTAssertEqual(reopened.premiumCharges["trowel"], 0)
    }

    func testIsolatedEndlessRestoreNeverChangesNormalPlayerSettings() throws {
        let watched = [inventoryKey, chargesKey, sizeKey,
                       "berryblockblast.endless.legacyMigrated.v056b2",
                       "berryblockblast.best-score.v1"] +
                      [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let before = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        let (name, store) = try sandbox()
        defer { store.removePersistentDomain(forName: name) }
        _ = try prepare(store, charges: ["trowel": 1])
        let game = open(store)
        XCTAssertTrue(game.useGoldenTrowel(row: 1, col: 1))
        _ = open(store)
        let after = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        XCTAssertEqual(before, after)
    }
}
