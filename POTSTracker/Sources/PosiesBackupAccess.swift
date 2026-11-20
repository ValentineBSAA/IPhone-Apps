import Foundation

/// Manual Files export is independent of an iCloud entitlement.
/// Face ID may be needed to include *all* private Journal entries.
/// Return an action rather than disabling a button without explanation.
enum PosiesManualBackupAccess: Equatable {
    case ready
    case needsUnlock
    case noEntries

    static func evaluate(recordCount: Int, lockEnabled: Bool, unlocked: Bool) -> Self {
        guard recordCount > 0 else { return .noEntries }
        if lockEnabled && !unlocked { return .needsUnlock }
        return .ready
    }
}
