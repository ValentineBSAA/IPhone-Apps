import Foundation

/// Shared, deterministic standard-tool transaction policy used by the real
/// BerryGameSession purchase handlers and the isolated Developer Garden lab.
/// No persistence, analytics, ledger writes or side effects occur here.
enum BerryStandardToolTransaction {
    struct UpdatedState: Equatable {
        let berries: Int
        let charges: Int
    }

    /// Returns nil without mutating input state when an operation is invalid.
    /// Currency must never go negative; charges cannot overflow Int.
    static func purchase(berries: Int, charges: Int, price: Int) -> UpdatedState? {
        guard berries >= 0, charges >= 0, price > 0,
              berries >= price, charges < Int.max else { return nil }
        return UpdatedState(berries: berries - price, charges: charges + 1)
    }

    /// Called only after the underlying tool action has been proven usable.
    static func consumeCharge(_ charges: Int, actionIsValid: Bool) -> Int? {
        guard actionIsValid, charges > 0 else { return nil }
        return charges - 1
    }
}
