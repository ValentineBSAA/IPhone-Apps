import SwiftUI

/// Additive, offline economy measurements introduced in 0.5.10.
/// Existing wallet, lifetime reward totals and purchase keys remain intact.
/// These stats never grant, remove or recalculate actual strawberries.
@MainActor
final class BerryEconomyLedger: ObservableObject {
    static let shared = BerryEconomyLedger()

    private static let spentKey = "berryberryblast.economy.spent.v0510"
    private static let earnedByModeKey = "berryberryblast.economy.modeEarnings.v0510"
    private static let spendingByItemKey = "berryberryblast.economy.purchases.v0510"

    @Published private(set) var spent: Int
    @Published private(set) var earnedByMode: [String:Int]
    @Published private(set) var spentByItem: [String:Int]

    /// Production remains `.shared`; QA may create a second ledger using
    /// a disposable preferences suite, leaving the real ledger untouched.
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        spent = defaults.integer(forKey: Self.spentKey)
        earnedByMode = defaults.dictionary(forKey: Self.earnedByModeKey)
            as? [String:Int] ?? [:]
        spentByItem = defaults.dictionary(forKey: Self.spendingByItemKey)
            as? [String:Int] ?? [:]
    }

    func recordSpend(_ cost: Int, item: String) {
        guard cost > 0 else { return }
        spent += cost
        spentByItem[item, default: 0] += cost
        defaults.set(spent, forKey: Self.spentKey)
        defaults.set(spentByItem, forKey: Self.spendingByItemKey)
    }

    /// Restore an already authorized standard-tool purchase by assigning
    /// absolute after-values. Safe to replay after an interrupted write:
    /// unlike recordSpend, this never counts the same purchase twice.
    /// Only the purchased item's slot is modified, preserving other items.
    func applyStandardToolSpendRecovery(totalAfter: Int, item: String,
                                        itemAfter: Int) {
        guard totalAfter >= 0, itemAfter >= 0, !item.isEmpty else { return }
        spent = totalAfter
        spentByItem[item] = itemAfter
        defaults.set(spent, forKey: Self.spentKey)
        defaults.set(spentByItem, forKey: Self.spendingByItemKey)
    }

    /// Only actual line-earned strawberries are attributed to a game mode.
    /// Story prizes, tutorial rewards and quest prizes remain outside this
    /// per-mode breakdown instead of inventing a source mode.
    func recordLineEarnings(_ amount: Int, mode: BerryMode) {
        guard amount > 0 else { return }
        earnedByMode[mode.rawValue, default: 0] += amount
        defaults.set(earnedByMode, forKey: Self.earnedByModeKey)
    }

    func reverseUndoneLineEarnings(_ amount: Int, mode: BerryMode) {
        guard amount > 0 else { return }
        earnedByMode[mode.rawValue, default: 0] =
            max(0, earnedByMode[mode.rawValue, default: 0] - amount)
        defaults.set(earnedByMode, forKey: Self.earnedByModeKey)
    }

    var mostSpentItem: (name: String, berries: Int)? {
        guard let best = spentByItem.max(by: { $0.value < $1.value }) else { return nil }
        return (best.key, best.value)
    }
}
