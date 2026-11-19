import Foundation

/// Check-ins keep the person's own wording separate from the selected feeling.
///
/// Backward-compatible with the original records:
/// - v0.1.4: title = "Better", posture = ""
/// - v0.1.5+: title = user-editable heading, posture = "Better", notes = optional details
///
/// This reuses existing local fields so an in-place update never has to migrate
/// the Core Data store or risk the person's previously recorded entries.
enum CheckInFormat {
    static let feelings = ["Better", "Usual", "Worse", "Much worse", "Not sure"]

    static func defaultTitle(for feeling: String) -> String {
        switch feeling {
        case "Better": return "Feeling better"
        case "Usual": return "Feeling as usual"
        case "Worse": return "Feeling worse"
        case "Much worse": return "Feeling much worse"
        case "Not sure": return "Not sure how I feel"
        default: return "How I feel"
        }
    }

    static func feeling(title: String, posture: String) -> String? {
        // Only interpret recognized strings as check-in feelings. The same
        // posture field is still used normally for HR / BP and never mixed.
        if feelings.contains(posture) { return posture }
        if feelings.contains(title) { return title }
        return feelings.first(where: { defaultTitle(for: $0) == title })
    }

    static func titleWasSuggested(_ title: String) -> Bool {
        feelings.contains(title) || feelings.contains(where: { defaultTitle(for: $0) == title })
    }

    static func shortDetail(feeling: String?, notes: String) -> String {
        let clean = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if let feeling {
            return clean.isEmpty ? "Check-in · \(feeling)" : "\(feeling) · \(clean)"
        }
        return clean.isEmpty ? "Daily check-in" : clean
    }
}