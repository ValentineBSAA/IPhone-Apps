import Foundation

#if BERRY_INTERNAL_QA
/// D2b: one-tap REAL premium-tool usage, saved board and restart verification.
/// Every scenario creates a disposable UserDefaults suite and a real ledger.
/// It never passes the owner's active GameSession into the lab.
enum BerryQAToolActionScenario: String, CaseIterable, Identifiable {
    case trowel = "Trowel Removes Cell"
    case seed = "Seed Plants Cell"
    case golden = "Golden Rescue"
    case goldenRepeat = "Golden Only Once"
    case invalid = "Invalid Tool Targets"
    case mega = "Mega Garden Save"
    case buyAndUse = "Buy & Use Trowel"

    var id: String { rawValue }
    var explanation: String {
        switch self {
        case .trowel: return "Use an owned Trowel on an occupied 8×8 cell and reopen the saved garden."
        case .seed: return "Plant a Starberry Seed on an empty board cell and verify the next saved session."
        case .golden: return "Rescue an occupied garden with the Golden Strawberry and preserve score."
        case .goldenRepeat: return "Restart after Golden Strawberry rescue and try to use the rescue twice."
        case .invalid: return "Try a Trowel outside the board and a Seed on an occupied cell."
        case .mega: return "Remove a cell from a saved 24×24 garden without touching separate 8×8 or 12×12 saves."
        case .buyAndUse: return "Pay the real 150-berry Trowel price, use the tool, reopen and check wallet, ledger and charges."
        }
    }
    var expected: String {
        switch self {
        case .trowel: return "Cell empty after restart, charge 0; previous score and moves safe."
        case .seed: return "Cell planted, moves +1, charge 0, saved and restored."
        case .golden: return "Board cleared, score unchanged, charge 0 and rescue limit saved."
        case .goldenRepeat: return "Second rescue blocked even after restart, with no extra charge."
        case .invalid: return "Both actions rejected; tool charges and board bytes unchanged."
        case .mega: return "24×24 tool changes persist; saved 8×8 and 12×12 gardens untouched."
        case .buyAndUse: return "Wallet 0, ledger 150, cleared cell and no remaining Trowel after restart."
        }
    }
}

struct BerryQAToolActionReceipt: Equatable {
    let scenario: BerryQAToolActionScenario
    let passed: Bool
    let expected: String
    let actual: String
    let realPlayerDataUnchanged: Bool
}

/// Only result and selection live in UI state; all real engine/session
/// instances are created and destroyed on one synchronous user tap.
@MainActor
struct BerryDeveloperToolActionLab {
    private struct Inventory: Codable {
        let berries: Int
        let undos: Int
        let shuffles: Int
        let totalEarnedBerries: Int
        let hints: Int
    }

    private let inventoryKey = "berryblockblast.inventory.v3"
    private let chargesKey = "berryberryblast.premium.charges.v059"
    private let boardSizeKey = "berryblockblast.endless.boardSize.v056b2"

    private(set) var scenario: BerryQAToolActionScenario = .trowel
    private(set) var latest: BerryQAToolActionReceipt?

    mutating func prepare(_ next: BerryQAToolActionScenario) {
        scenario = next
        latest = nil
    }

    mutating func discard() {
        latest = nil
        scenario = .trowel
    }

    @discardableResult
    mutating func run() -> BerryQAToolActionReceipt {
        let selection = scenario
        let watchedKeys = [inventoryKey, chargesKey, boardSizeKey,
                           "berryblockblast.endless.legacyMigrated.v056b2",
                           "berryblockblast.best-score.v1",
                           "berryberryblast.economy.spent.v0510",
                           "berryberryblast.economy.purchases.v0510",
                           "berryblockblast.rewards.v1",
                           "berryblockblast.cottage.decorations"] +
                          [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let originalPlayer = watchedKeys.map {
            UserDefaults.standard.object(forKey: $0) as? NSObject
        }

        let testName = "com.valentinebsaa.berry.d2b.\(UUID().uuidString)"
        guard let store = UserDefaults(suiteName: testName) else {
            let receipt = BerryQAToolActionReceipt(scenario: selection,
                passed: false, expected: selection.expected,
                actual: "Disposable test storage could not be opened.",
                realPlayerDataUnchanged: true)
            latest = receipt
            return receipt
        }
        defer { store.removePersistentDomain(forName: testName) }

        let side = selection == .mega ? 24 : 8
        let wallet = selection == .buyAndUse ? 150 : 0
        let inv = Inventory(berries: wallet, undos: 2, shuffles: 2,
                            totalEarnedBerries: 15, hints: 1)
        guard let bytes = try? JSONEncoder().encode(inv) else {
            let receipt = BerryQAToolActionReceipt(scenario: selection,
                passed: false, expected: selection.expected,
                actual: "Could not prepare isolated inventory.",
                realPlayerDataUnchanged: true)
            latest = receipt
            return receipt
        }
        store.set(bytes, forKey: inventoryKey)
        store.set(side, forKey: boardSizeKey)
        var startCharges: [String: Int] = [:]
        switch selection {
        case .trowel, .mega: startCharges["trowel"] = 1
        case .seed: startCharges["seed"] = 1
        case .golden, .goldenRepeat: startCharges["golden-strawberry"] = 1
        case .invalid:
            startCharges["trowel"] = 1
            startCharges["seed"] = 1
        case .buyAndUse: break
        }
        store.set(startCharges, forKey: chargesKey)

        // Create a real one-move playable board, not a fake success flag.
        let piece = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 2)
        let empty = Array(repeating: Array<Int?>(repeating: nil, count: side),
                          count: side)
        var board = BerryEngine(board: empty, tray: [piece, nil, nil], score: 100)
        guard board.place(slot: 0, row: 1, col: 1) != nil,
              let initialSave = try? JSONEncoder().encode(board) else {
            let receipt = BerryQAToolActionReceipt(scenario: selection,
                passed: false, expected: selection.expected,
                actual: "Could not construct a real playable board fixture.",
                realPlayerDataUnchanged: true)
            latest = receipt
            return receipt
        }
        store.set(initialSave, forKey: BerryGameSession.endlessSaveKey(side: side))
        var otherSaved: [String: Data] = [:]
        if side == 24 {
            for otherSide in [8, 12] {
                let key = BerryGameSession.endlessSaveKey(side: otherSide)
                let exact = Data([UInt8(otherSide), 0xD2, 0xB0, 0x02])
                otherSaved[key] = exact
                store.set(exact, forKey: key)
            }
        }

        let ledger = BerryEconomyLedger(defaults: store)
        func openGame() -> BerryGameSession {
            let game = BerryGameSession(
                checkoutDefaults: store,
                checkoutLedger: BerryEconomyLedger(defaults: store))
            game.selectMode(.endless)
            return game
        }
        func savedEngine() -> BerryEngine? {
            let key = BerryGameSession.endlessSaveKey(side: side)
            guard let saved = store.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(BerryEngine.self, from: saved)
        }

        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        game.selectMode(.endless)
        let initialScore = game.engine.score
        let initialMoves = game.engine.moves
        var passed = false
        var actual = ""

        switch selection {
        case .trowel:
            let used = game.useGoldenTrowel(row: 1, col: 1)
            let reopened = openGame()
            passed = used && reopened.engine.board[1][1] == nil &&
                     reopened.premiumCharges["trowel"] == 0 &&
                     reopened.engine.score == initialScore &&
                     reopened.engine.moves == initialMoves &&
                     savedEngine()?.board[1][1] == nil
            actual = "Used \(used); saved cell \(savedEngine()?.board[1][1] == nil ? "empty" : "occupied"); restart charge \(reopened.premiumCharges["trowel"] ?? -1)."

        case .seed:
            let used = game.useStarberrySeed(row: 3, col: 3)
            let reopened = openGame()
            passed = used && reopened.engine.board[3][3] == 0 &&
                     reopened.engine.moves == initialMoves + 1 &&
                     reopened.premiumCharges["seed"] == 0 &&
                     savedEngine()?.board[3][3] == 0
            actual = "Used \(used); saved cell \(savedEngine()?.board[3][3] == 0 ? "planted" : "missing"); restart moves \(reopened.engine.moves); charges \(reopened.premiumCharges["seed"] ?? -1)."

        case .golden:
            let used = game.useGoldenStrawberry()
            let reopened = openGame()
            let emptyAfter = reopened.engine.board.flatMap { $0 }.allSatisfy { $0 == nil }
            passed = used && emptyAfter && reopened.engine.goldenRescueUsed &&
                     reopened.engine.score == initialScore &&
                     reopened.premiumCharges["golden-strawberry"] == 0 &&
                     savedEngine()?.goldenRescueUsed == true
            actual = "Used \(used); restart board \(emptyAfter ? "clear" : "occupied"); score \(reopened.engine.score); rescue used \(reopened.engine.goldenRescueUsed)."

        case .goldenRepeat:
            let first = game.useGoldenStrawberry()
            let reopened = openGame()
            let second = reopened.useGoldenStrawberry()
            passed = first && !second && reopened.engine.goldenRescueUsed &&
                     reopened.premiumCharges["golden-strawberry"] == 0 &&
                     reopened.engine.score == initialScore
            actual = "First rescue \(first); second \(second); restart charge \(reopened.premiumCharges["golden-strawberry"] ?? -1)."

        case .invalid:
            let key = BerryGameSession.endlessSaveKey(side: side)
            let beforeInvalid = store.data(forKey: key)
            let first = game.useGoldenTrowel(row: -1, col: 30)
            let second = game.useStarberrySeed(row: 1, col: 1)
            passed = !first && !second &&
                     game.premiumCharges["trowel"] == 1 &&
                     game.premiumCharges["seed"] == 1 &&
                     store.data(forKey: key) == beforeInvalid
            actual = "Trowel \(first), Seed \(second); charges \(game.premiumCharges["trowel"] ?? -1)/\(game.premiumCharges["seed"] ?? -1); save \(store.data(forKey: key) == beforeInvalid ? "unchanged" : "CHANGED")."

        case .mega:
            let used = game.useGoldenTrowel(row: 1, col: 1)
            let reopened = openGame()
            let othersSafe = otherSaved.allSatisfy {
                store.data(forKey: $0.key) == $0.value
            }
            passed = used && reopened.engine.side == 24 &&
                     reopened.engine.board[1][1] == nil &&
                     reopened.premiumCharges["trowel"] == 0 && othersSafe
            actual = "Used \(used), 24×24 saved \(reopened.engine.board[1][1] == nil); other gardens \(othersSafe ? "safe" : "CHANGED")."

        case .buyAndUse:
            let bought = game.buyPremium("trowel")
            let used = game.useGoldenTrowel(row: 1, col: 1)
            let reopened = openGame()
            passed = bought && used && reopened.engine.board[1][1] == nil &&
                     reopened.berries == 0 &&
                     reopened.premiumCharges["trowel"] == 0 &&
                     ledger.spent == 150 && ledger.spentByItem["trowel"] == 150
            actual = "Bought \(bought), used \(used); wallet \(reopened.berries); charges \(reopened.premiumCharges["trowel"] ?? -1); spent \(ledger.spent)."
        }

        let currentPlayer = watchedKeys.map {
            UserDefaults.standard.object(forKey: $0) as? NSObject
        }
        let playerSafe = originalPlayer == currentPlayer
        if !playerSafe {
            passed = false
            actual += " WARNING: normal player preferences changed."
        }
        let result = BerryQAToolActionReceipt(
            scenario: selection, passed: passed, expected: selection.expected,
            actual: actual, realPlayerDataUnchanged: playerSafe)
        latest = result
        return result
    }
}
#endif
