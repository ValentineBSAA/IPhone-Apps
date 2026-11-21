import Foundation

#if BERRY_INTERNAL_QA
/// All the receipts in this lab come from the real production GameSession
/// checkout methods with an entirely separate, disposable UserDefaults suite.
/// No mock purchase rules or live player wallet are involved.
enum BerryQACommerceScenario: String, CaseIterable, Identifiable {
    case cottageExact = "Cottage Exact Price"
    case cottageShort = "Cottage 1 Berry Short"
    case twisterPurchase = "Twister 3 Charges"
    case premiumShort = "Premium Not Enough"
    case pantryDuplicate = "Pantry Buy Twice"
    case savedGardenSafety = "Protect 3 Gardens"
    case invalidTrowel = "Invalid Trowel Use"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .cottageExact: return "Start with 60 disposable strawberries. Buy the first Cottage decoration."
        case .cottageShort: return "Start with 59 test strawberries. Try the 60-berry Cottage upgrade."
        case .twisterPurchase: return "Pay exactly 200 test strawberries for three Twister charges."
        case .premiumShort: return "Try to buy the 150-berry Trowel with 149 test berries."
        case .pantryDuplicate: return "Buy a permanent Pantry upgrade, then attempt to purchase it again."
        case .savedGardenSafety: return "Shop in a fresh menu session with three preloaded 8, 12 and 24 Endless save slots."
        case .invalidTrowel: return "Use a bought Trowel at an invalid board cell. Its charge must remain."
        }
    }

    var expected: String {
        switch self {
        case .cottageExact: return "One decoration; wallet 0; spending ledger 60."
        case .cottageShort: return "No decoration; wallet 59; no spending."
        case .twisterPurchase: return "Three Twister charges; wallet 0; spending ledger 200."
        case .premiumShort: return "Purchase rejected; wallet 149; no charges or spending."
        case .pantryDuplicate: return "One permanent upgrade, one debit of 600 and no duplicate."
        case .savedGardenSafety: return "All 8×8, 12×12 and 24×24 saves unchanged byte-for-byte."
        case .invalidTrowel: return "Failed tool use; Trowel charge remains 1; no save changed."
        }
    }
}

struct BerryQACommerceReceipt: Equatable {
    let scenario: BerryQACommerceScenario
    let passed: Bool
    let expected: String
    let actual: String
    let playerDataUnchanged: Bool
}

/// Sheet-local selection and receipt only. The real isolated GameSession,
/// wallet and ledger are created, exercised and destroyed during run().
@MainActor
struct BerryDeveloperCommerceLab {
    private struct Inventory: Codable {
        let berries: Int
        let undos: Int
        let shuffles: Int
        let totalEarnedBerries: Int
        let hints: Int
    }

    private let inventoryKey = "berryblockblast.inventory.v3"
    private let cottageKey = "berryblockblast.cottage.decorations"
    private let chargesKey = "berryberryblast.premium.charges.v059"
    private let permanentKey = "berryberryblast.premium.permanent.v059"
    private let storeName = "com.valentinebsaa.berry.internalQA.commerce.v1"

    private(set) var scenario: BerryQACommerceScenario = .cottageExact
    private(set) var latest: BerryQACommerceReceipt?

    mutating func prepare(_ next: BerryQACommerceScenario) {
        scenario = next
        latest = nil
    }

    mutating func discard() {
        scenario = .cottageExact
        latest = nil
        UserDefaults(suiteName: storeName)?.removePersistentDomain(forName: storeName)
    }

    @discardableResult
    mutating func run() -> BerryQACommerceReceipt {
        let selected = scenario
        let watched = [inventoryKey, cottageKey, chargesKey, permanentKey,
                       "berryberryblast.economy.spent.v0510",
                       "berryberryblast.economy.purchases.v0510",
                       "berryblockblast.rewards.v1",
                       "berryblockblast.shop.owned.v056b2"] +
                      [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let actualBefore = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }

        guard let store = UserDefaults(suiteName: storeName) else {
            let failure = BerryQACommerceReceipt(scenario: selected, passed: false,
                expected: selected.expected, actual: "Test storage unavailable. No purchase attempted.",
                playerDataUnchanged: true)
            latest = failure
            return failure
        }

        // Clear remnants after an interrupted previous QA session. Neither
        // this fixed suite nor any test data share the application's defaults.
        store.removePersistentDomain(forName: storeName)
        defer { store.removePersistentDomain(forName: storeName) }

        let initialBerries: Int
        switch selected {
        case .cottageExact: initialBerries = 60
        case .cottageShort: initialBerries = 59
        case .twisterPurchase: initialBerries = 200
        case .premiumShort: initialBerries = 149
        case .pantryDuplicate: initialBerries = 600
        case .savedGardenSafety: initialBerries = 1200
        case .invalidTrowel: initialBerries = 0
        }

        let inventory = Inventory(berries: initialBerries, undos: 2,
                                  shuffles: 2, totalEarnedBerries: 93, hints: 1)
        guard let data = try? JSONEncoder().encode(inventory) else {
            let failure = BerryQACommerceReceipt(scenario: selected, passed: false,
                expected: selected.expected, actual: "Could not prepare disposable test inventory.",
                playerDataUnchanged: true)
            latest = failure
            return failure
        }
        store.set(data, forKey: inventoryKey)
        if selected == .invalidTrowel {
            store.set(["trowel": 1], forKey: chargesKey)
        }

        var sentinels: [String: Data] = [:]
        if selected == .savedGardenSafety || selected == .invalidTrowel {
            for side in [8, 12, 24] {
                let key = BerryGameSession.endlessSaveKey(side: side)
                let bytes = Data([UInt8(side), 0xB1, 0xC0, 0xC1])
                sentinels[key] = bytes
                store.set(bytes, forKey: key)
            }
        }

        let ledger = BerryEconomyLedger(defaults: store)
        let game = BerryGameSession(checkoutDefaults: store, checkoutLedger: ledger)
        var passed = false
        var actual = ""
        switch selected {
        case .cottageExact:
            game.buyCottageDecoration()
            passed = game.cottageDecorations == 1 &&
                     game.berries == 0 && ledger.spent == 60 &&
                     ledger.spentByItem["Cottage Decoration"] == 60
            actual = "Owned \(game.cottageDecorations), wallet \(game.berries), ledger \(ledger.spent)."

        case .cottageShort:
            game.buyCottageDecoration()
            passed = game.cottageDecorations == 0 &&
                     game.berries == 59 && ledger.spent == 0
            actual = "Owned \(game.cottageDecorations), wallet \(game.berries), ledger \(ledger.spent)."

        case .twisterPurchase:
            let purchased = game.buyPremium("twister")
            passed = purchased && game.premiumCharges["twister"] == 3 &&
                     game.berries == 0 && ledger.spent == 200
            actual = "Bought \(purchased), charges \(game.premiumCharges["twister"] ?? 0), wallet \(game.berries), ledger \(ledger.spent)."

        case .premiumShort:
            let purchased = game.buyPremium("trowel")
            passed = !purchased && game.berries == 149 &&
                     game.premiumCharges["trowel", default: 0] == 0 &&
                     ledger.spent == 0
            actual = "Bought \(purchased), wallet \(game.berries), ledger \(ledger.spent)."

        case .pantryDuplicate:
            let first = game.buyPremium("pantry")
            let second = game.buyPremium("pantry")
            passed = first && !second &&
                     game.premiumOwned.filter({ $0 == "pantry" }).count == 1 &&
                     game.berries == 0 && ledger.spent == 600
            actual = "First \(first), duplicate \(second), owned \(game.premiumOwned.count), spent \(ledger.spent)."

        case .savedGardenSafety:
            game.buyCottageDecoration()
            let twister = game.buyPremium("twister")
            let pantry = game.buyPremium("pantry")
            let savesOK = sentinels.allSatisfy { store.data(forKey: $0.key) == $0.value }
            passed = twister && pantry && savesOK &&
                     game.berries == 340 && ledger.spent == 860
            actual = "8/12/24 saves \(savesOK ? "unchanged" : "CHANGED"), wallet \(game.berries), ledger \(ledger.spent)."

        case .invalidTrowel:
            let used = game.useGoldenTrowel(row: -1, col: 999)
            let savesOK = sentinels.allSatisfy { store.data(forKey: $0.key) == $0.value }
            passed = !used && game.premiumCharges["trowel"] == 1 &&
                     savesOK && ledger.spent == 0
            actual = "Used \(used), charge \(game.premiumCharges["trowel"] ?? 0), saves \(savesOK ? "unchanged" : "CHANGED")."
        }

        let actualAfter = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        let playerSafe = actualBefore == actualAfter
        if !playerSafe {
            passed = false
            actual += " WARNING: normal player preference changed."
        }
        let receipt = BerryQACommerceReceipt(scenario: selected, passed: passed,
            expected: selected.expected, actual: actual, playerDataUnchanged: playerSafe)
        latest = receipt
        return receipt
    }
}
#endif
