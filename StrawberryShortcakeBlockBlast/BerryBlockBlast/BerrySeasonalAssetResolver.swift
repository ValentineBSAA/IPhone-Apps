import Foundation

/// H5: Non-UI, offline-only artwork selection prototype.
/// Intentionally dormant. The game keeps its existing artwork and game modes
/// until approved RGBA/Xcode assets and physical iPhone QA are complete.
enum BerrySeasonalArtRole: String, CaseIterable {
    case homeClassic = "HomeClassic"
    case berryStory = "BerryStory"
    case dailyHarvest = "DailyHarvest"
    case moreAdventures = "MoreAdventures"
    case cottageDecorations = "CottageDecorations"
    case berryCollection = "BerryCollection"
    case clockFrame = "ClockFrame"
}

enum BerrySeasonalLighting: String {
    case day = "Day"
    case night = "Night"
}

struct BerrySeasonalAssetSelection: Equatable {
    enum Reason: Equatable {
        case approvedSeasonalAsset
        case baseClockFrame
        case existingGameFallback
        case unavailableSeasonalAsset
    }

    /// The current safe fallback is an existing built-in game asset.
    /// The caller is responsible for providing a valid existing name.
    let selectedAssetName: String
    /// An attempted candidate may be absent because seasonal art is incomplete.
    let attemptedAssetName: String?
    let lighting: BerrySeasonalLighting
    let event: BerrySeasonalEvent
    let reason: Reason
}

/// Resolves a **visual appearance only**. Never mutates mode, story,
/// purchases, wallet, rewards, birthdays, save data, or UserDefaults.
/// Does not use GPS, location services, network or device-region inference.
enum BerrySeasonalAssetResolver {
    /// Matches the existing cosmetic clock's 6 AM / 6 PM visual boundaries.
    /// Time zone is injectable: no simulator clock changes needed for QA.
    static func lighting(at date: Date, timeZone: TimeZone) -> BerrySeasonalLighting {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour >= 18 ? .night : .day
    }

    static func resolve(
        role: BerrySeasonalArtRole,
        existingAssetName: String,
        at date: Date,
        timeZone: TimeZone,
        deviceRegionCode: String?,
        options: BerrySeasonalOptions,
        approvedInstalledAssetNames: Set<String>
    ) -> BerrySeasonalAssetSelection {
        let event = BerrySeasonalCalendar.resolve(
            at: date,
            timeZone: timeZone,
            deviceRegionCode: deviceRegionCode,
            options: options
        ).event
        let light = lighting(at: date, timeZone: timeZone)

        // The regular clock frame is separate from holiday artwork. In every
        // case its numerals must be dynamically rendered by SwiftUI text.
        let proposed: String?
        switch event {
        case .none:
            proposed = role == .clockFrame ?
                "BBB_Clock_Base_\(light.rawValue)_ClockFrame" : nil
        case .halloween, .christmas, .thanksgiving, .birthday:
            let eventName: String
            switch event {
            case .halloween: eventName = "Halloween"
            case .christmas: eventName = "Christmas"
            case .thanksgiving: eventName = "Thanksgiving"
            case .birthday: eventName = "Birthday"
            case .none: eventName = "" // Unreachable: event is not .none.
            }
            let prefix = role == .clockFrame ? "BBB_Clock" : "BBB_Season"
            proposed = "\(prefix)_\(eventName)_\(light.rawValue)_\(role.rawValue)"
        }

        guard let proposed else {
            return BerrySeasonalAssetSelection(
                selectedAssetName: existingAssetName,
                attemptedAssetName: nil,
                lighting: light,
                event: event,
                reason: .existingGameFallback
            )
        }

        // Only names from a verified and reviewed installed resource catalog
        // may be passed here. Raw ArtSource originals are never directly used.
        guard approvedInstalledAssetNames.contains(proposed) else {
            return BerrySeasonalAssetSelection(
                selectedAssetName: existingAssetName,
                attemptedAssetName: proposed,
                lighting: light,
                event: event,
                reason: .unavailableSeasonalAsset
            )
        }

        return BerrySeasonalAssetSelection(
            selectedAssetName: proposed,
            attemptedAssetName: proposed,
            lighting: light,
            event: event,
            reason: event == .none ? .baseClockFrame : .approvedSeasonalAsset
        )
    }
}
