import UIKit

/// Resolves approved artwork safely during staged asset integration.
/// When the approved final image arrives in Assets.xcassets, the normal
/// requested name wins automatically. Until then, reuse an existing
/// bundled image without changing any player data or asset files.
enum BerryArtResolver {
    static let temporaryFallbacks: [String: String] = [
        "BerryVillageMap": "BerryStory",
        "BerryQuestBoardArt": "HarvestReward",
        "BerryJournalArt": "Milestone"
    ]

    static func displayName(for requested: String) -> String {
        guard let fallback = temporaryFallbacks[requested] else {
            return requested
        }
        return UIImage(named: requested) == nil ? fallback : requested
    }
}
