import Foundation

/// D0d. A single commit boundary shared by the real BerryGameSession
/// standard-tool checkout methods and disposable QA fixtures.
///
/// The reducer checks affordability and charge overflow BEFORE this executor
/// invokes its injected effects. No UserDefaults or live ledger is accessed
/// by this type; the caller chooses which storage/ledger to use.
enum BerryStandardToolKind: String, CaseIterable, Codable {
    case undo = "Undo"
    case shuffle = "Shuffle"
    case hint = "Hint"

    var price: Int {
        switch self {
        case .undo: return BerryEconomy.undoPrice
        case .shuffle: return BerryEconomy.shufflePrice
        case .hint: return BerryEconomy.hintPrice
        }
    }
}

struct BerryStandardToolPurchaseReceipt: Equatable {
    let tool: BerryStandardToolKind
    let price: Int
    let berriesBefore: Int
    let berriesAfter: Int
    let chargesBefore: Int
    let chargesAfter: Int
}

enum BerryStandardToolCheckout {
    /// A rejected operation does not call onCommit. A valid operation calls
    /// onCommit exactly once with checked counts. In production the callback
    /// performs the existing wallet, ledger, and save updates; a test provides
    /// an isolated UserDefaults suite and isolated BerryEconomyLedger instead.
    ///
    /// This is intentionally synchronous and NOT an idempotent UI purchase
    /// token or a crash-safe multi-key database transaction.
    @discardableResult
    static func purchase(
        _ tool: BerryStandardToolKind,
        berries: Int,
        charges: Int,
        onCommit: (BerryStandardToolPurchaseReceipt) -> Void
    ) -> Bool {
        guard let state = BerryStandardToolTransaction.purchase(
            berries: berries, charges: charges, price: tool.price
        ) else { return false }

        onCommit(BerryStandardToolPurchaseReceipt(
            tool: tool,
            price: tool.price,
            berriesBefore: berries,
            berriesAfter: state.berries,
            chargesBefore: charges,
            chargesAfter: state.charges
        ))
        return true
    }
}
