import Foundation

/// D0e: a narrow, versioned recovery intent for standard-tool purchases.
/// Stores the FULL post-purchase inventory and the ABSOLUTE spending totals
/// before touching separate legacy UserDefaults keys. Replaying that final
/// state is idempotent: it never deducts a second time.
///
/// This offers best-effort interruption recovery if the intent has reached
/// preferences storage. UserDefaults is not a durable transactional database,
/// and there is no guarantee of survival through power loss before persistence.
@MainActor
enum BerryStandardPurchaseJournal {
    static let pendingKey = "berryberryblast.standardTools.pendingPurchase.v1"
    static let inventoryKey = "berryblockblast.inventory.v3"

    struct Entry: Codable, Equatable {
        let version: Int
        let transactionID: UUID
        let tool: BerryStandardToolKind
        let price: Int
        let berriesAfter: Int
        let chargesAfter: Int
        let inventoryAfter: Data
        let spentAfter: Int
        let spentByItemAfter: Int
    }

    private struct InventoryShape: Decodable {
        let berries: Int
        let undos: Int
        let shuffles: Int
        let totalEarnedBerries: Int
        let hints: Int
    }

    static func prepare(
        receipt: BerryStandardToolPurchaseReceipt,
        inventoryAfter: Data,
        ledger: BerryEconomyLedger
    ) -> Entry? {
        let currentItem = ledger.spentByItem[receipt.tool.rawValue, default: 0]
        guard ledger.spent >= 0, currentItem >= 0,
              receipt.berriesAfter >= 0, receipt.chargesAfter >= 0,
              receipt.price == receipt.tool.price else { return nil }
        let (spentAfter, totalOverflow) =
            ledger.spent.addingReportingOverflow(receipt.price)
        let (spentByItemAfter, itemOverflow) =
            currentItem.addingReportingOverflow(receipt.price)
        guard !totalOverflow, !itemOverflow else { return nil }

        let entry = Entry(
            version: 1,
            transactionID: UUID(),
            tool: receipt.tool,
            price: receipt.price,
            berriesAfter: receipt.berriesAfter,
            chargesAfter: receipt.chargesAfter,
            inventoryAfter: inventoryAfter,
            spentAfter: spentAfter,
            spentByItemAfter: spentByItemAfter
        )
        return isValid(entry) ? entry : nil
    }

    private static func isValid(_ entry: Entry) -> Bool {
        guard entry.version == 1, entry.price == entry.tool.price,
              entry.berriesAfter >= 0, entry.chargesAfter >= 0,
              entry.spentAfter >= entry.price,
              entry.spentByItemAfter >= entry.price,
              let inventory = try? JSONDecoder().decode(
                InventoryShape.self, from: entry.inventoryAfter),
              inventory.berries == entry.berriesAfter,
              inventory.undos >= 0, inventory.shuffles >= 0,
              inventory.hints >= 0, inventory.totalEarnedBerries >= 0 else {
            return false
        }
        switch entry.tool {
        case .undo: return inventory.undos == entry.chargesAfter
        case .shuffle: return inventory.shuffles == entry.chargesAfter
        case .hint: return inventory.hints == entry.chargesAfter
        }
    }

    /// Journal first. If an unresolved/corrupted journal is already present,
    /// refuse a new purchase instead of overwriting its recovery evidence.
    static func stage(_ entry: Entry, in defaults: UserDefaults) -> Bool {
        guard isValid(entry), defaults.object(forKey: pendingKey) == nil,
              let bytes = try? JSONEncoder().encode(entry) else { return false }
        defaults.set(bytes, forKey: pendingKey)
        return defaults.data(forKey: pendingKey) == bytes
    }

    /// Reapply ABSOLUTE after-state, never incrementing totals during replay.
    /// The intent remains until both state keys and the in-memory ledger
    /// reflect the intended purchase.
    @discardableResult
    static func recover(
        in defaults: UserDefaults,
        ledger: BerryEconomyLedger
    ) -> Bool {
        guard let bytes = defaults.data(forKey: pendingKey),
              let entry = try? JSONDecoder().decode(Entry.self, from: bytes),
              isValid(entry) else { return false }
        defaults.set(entry.inventoryAfter, forKey: inventoryKey)
        ledger.applyStandardToolSpendRecovery(
            totalAfter: entry.spentAfter,
            item: entry.tool.rawValue,
            itemAfter: entry.spentByItemAfter
        )
        guard defaults.data(forKey: inventoryKey) == entry.inventoryAfter,
              ledger.spent == entry.spentAfter,
              ledger.spentByItem[entry.tool.rawValue] == entry.spentByItemAfter
        else { return false }
        defaults.removeObject(forKey: pendingKey)
        return defaults.object(forKey: pendingKey) == nil
    }

    static func hasUnresolvedIntent(in defaults: UserDefaults) -> Bool {
        defaults.object(forKey: pendingKey) != nil
    }
}
