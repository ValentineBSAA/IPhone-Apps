import Foundation

/// Single authoritative price list for currently purchasable Berry Boutique
/// cosmetics. This policy intentionally excludes free board surface switches
/// and all unreleased seasonal previews.
enum BerryBoutiquePurchasePolicy {
    static let prices: [String: Int] = [
        "strawberry-fruit": 0,
        "blueberry-blocks": 90,
        "vanilla-blocks": 90,
        "rose-border": 75,
        "mint-border": 75,
        "berry-sparkle": 100,
        "raspberry-blocks": 110,
        "lemon-blocks": 110,
        "chocolate-blocks": 120,
        "mint-blocks": 110,
        "blackberry-blocks": 130
    ]

    static func price(for id: String) -> Int? { prices[id] }

    /// No mutation occurs in the policy. An existing purchase cannot be
    /// bought twice, and the caller cannot substitute a lower displayed price.
    static func canPurchase(id: String, proposedCost: Int,
                            berries: Int, owned: [String]) -> Bool {
        guard let officialCost = price(for: id),
              officialCost == proposedCost, officialCost >= 0,
              berries >= officialCost, !owned.contains(id)
        else { return false }
        return true
    }
}
