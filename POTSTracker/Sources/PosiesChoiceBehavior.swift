import Foundation

/// A consistent, reversible choice rule for tappable option chips.
/// Choosing the same option again clears it instead of trapping the user
/// in a selection. The form's own validation decides whether Save is enabled.
enum PosiesChoiceBehavior {
    static func toggle(_ selected: String, tapped: String, empty: String = "") -> String {
        selected == tapped ? empty : tapped
    }

    static func toggleAmount(_ current: String, tapped: Int) -> String {
        toggle(current, tapped: String(tapped))
    }

    static func toggleInSet<T: Hashable>(_ choices: Set<T>, tapped: T) -> Set<T> {
        var updated = choices
        if !updated.insert(tapped).inserted { updated.remove(tapped) }
        return updated
    }

    /// Essential preferences never get stuck with no configured mode.
    /// Re-tapping a custom choice falls back to the user's safe system/default mode.
    static func preference(_ selected: String, tapped: String, defaultValue: String) -> String {
        selected == tapped ? defaultValue : tapped
    }
}
