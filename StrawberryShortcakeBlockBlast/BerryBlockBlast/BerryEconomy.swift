import Foundation

/// Berry Berry Blast 0.5.9 spending balance.
/// Rewards already earned by players never change retroactively.
/// Rare premium rescue items retain their separately defined prices.
enum BerryEconomy {
    static let undoPrice = 40
    static let shufflePrice = 50
    static let hintPrice = 35

    // Six individually owned decorations. Later additions are
    // more substantial long-term goals, not a flat-price farming loop.
    static let cottagePrices = [60, 90, 130, 180, 240, 300]

    static func nextCottagePrice(owned: Int) -> Int? {
        guard cottagePrices.indices.contains(owned) else { return nil }
        return cottagePrices[owned]
    }
}
