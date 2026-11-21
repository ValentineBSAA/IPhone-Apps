import XCTest
@testable import BerryBlockBlast

/// H5 read-only proof: this test class never modifies game settings, scores,
/// holiday preferences, purchases, birthday awards, saves or system clock.
final class BerrySeasonalAssetResolverTests: XCTestCase {
    private let phoenix = TimeZone(identifier: "America/Phoenix")!
    private let newYork = TimeZone(identifier: "America/New_York")!

    private func instant(_ year: Int, _ month: Int, _ day: Int,
                         _ hour: Int, _ minute: Int = 0,
                         zone: TimeZone = TimeZone(identifier: "America/Phoenix")!) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar.date(from: DateComponents(year: year, month: month,
                day: day, hour: hour, minute: minute))!
    }

    private func optedIn(region: String = "US") -> BerrySeasonalOptions {
        var options = BerrySeasonalOptions()
        options.automaticHolidaysEnabled = true
        options.countryOverride = region
        return options
    }

    private func resolve(_ role: BerrySeasonalArtRole,
                         at date: Date,
                         assets: Set<String>,
                         options: BerrySeasonalOptions,
                         zone: TimeZone? = nil,
                         region: String? = "US") -> BerrySeasonalAssetSelection {
        BerrySeasonalAssetResolver.resolve(
            role: role, existingAssetName: "ExistingGameArt",
            at: date, timeZone: zone ?? phoenix,
            deviceRegionCode: region, options: options,
            approvedInstalledAssetNames: assets)
    }

    func testArtworkIsDormantByDefaultAndDoesNotOverrideBaseMode() {
        let candidate = "BBB_Season_Christmas_Day_BerryStory"
        let result = resolve(.berryStory, at: instant(2026, 12, 25, 12),
                             assets: [candidate], options: BerrySeasonalOptions())
        XCTAssertEqual(result.selectedAssetName, "ExistingGameArt")
        XCTAssertNil(result.attemptedAssetName)
        XCTAssertEqual(result.reason, .existingGameFallback)
        XCTAssertEqual(result.event, .none)
    }

    func testHalloweenDayAndNightUseDifferentAssetsWithoutModeChanges() {
        let dayKey = "BBB_Season_Halloween_Day_MoreAdventures"
        let nightKey = "BBB_Season_Halloween_Night_MoreAdventures"
        let assets: Set<String> = [dayKey, nightKey]
        let options = optedIn()
        XCTAssertEqual(resolve(.moreAdventures, at: instant(2026, 10, 31, 5, 59),
                               assets: assets, options: options).selectedAssetName, nightKey)
        XCTAssertEqual(resolve(.moreAdventures, at: instant(2026, 10, 31, 6),
                               assets: assets, options: options).selectedAssetName, dayKey)
        XCTAssertEqual(resolve(.moreAdventures, at: instant(2026, 10, 31, 17, 59),
                               assets: assets, options: options).selectedAssetName, dayKey)
        XCTAssertEqual(resolve(.moreAdventures, at: instant(2026, 10, 31, 18),
                               assets: assets, options: options).selectedAssetName, nightKey)
    }

    func testThanksgiving2026FourthThursdayAndMissingNightBerryCollectionFallback() {
        let key = "BBB_Season_Thanksgiving_Day_BerryCollection"
        let options = optedIn()
        let day = resolve(.berryCollection, at: instant(2026, 11, 26, 12),
                          assets: [key], options: options)
        XCTAssertEqual(day.selectedAssetName, key)
        XCTAssertEqual(day.event, .thanksgiving)
        // BC-06 Thanksgiving Night is not yet generated or visually approved.
        let night = resolve(.berryCollection, at: instant(2026, 11, 26, 19),
                            assets: [key], options: options)
        XCTAssertEqual(night.selectedAssetName, "ExistingGameArt")
        XCTAssertEqual(night.attemptedAssetName,
                       "BBB_Season_Thanksgiving_Night_BerryCollection")
        XCTAssertEqual(night.reason, .unavailableSeasonalAsset)
    }

    func testNoBlankCardsForUnfinishedBirthdayCollectionVariants() {
        var options = optedIn()
        options.birthdayArtEnabled = true
        options.birthdayMonth = 7
        options.birthdayDay = 10
        let available: Set<String> = ["BBB_Season_Christmas_Day_BerryCollection"]
        for hour in [5, 6, 17, 18] {
            let selection = resolve(.berryCollection, at: instant(2026, 7, 10, hour),
                                    assets: available, options: options)
            XCTAssertEqual(selection.event, .birthday)
            XCTAssertEqual(selection.selectedAssetName, "ExistingGameArt")
            XCTAssertEqual(selection.reason, .unavailableSeasonalAsset)
        }
    }

    func testBirthdayHolidayOverlapAndTemporaryPreviewRules() {
        var options = optedIn()
        options.birthdayArtEnabled = true
        options.birthdayMonth = 12
        options.birthdayDay = 25
        let date = instant(2026, 12, 25, 12)
        let birthday = "BBB_Season_Birthday_Day_BerryStory"
        let christmas = "BBB_Season_Christmas_Day_BerryStory"
        let assets: Set<String> = [birthday, christmas]
        XCTAssertEqual(resolve(.berryStory, at: date, assets: assets,
                               options: options).selectedAssetName, birthday)
        options.choice = .preview(.christmas)
        XCTAssertEqual(resolve(.berryStory, at: date, assets: assets,
                               options: options).selectedAssetName, christmas)
        options.choice = .off
        XCTAssertEqual(resolve(.berryStory, at: date, assets: assets,
                               options: options).selectedAssetName, "ExistingGameArt")
    }

    func testClockFrameIsDecorativeOnlyAndDefaultsToLocalDayNight() {
        let dayClock = "BBB_Clock_Base_Day_ClockFrame"
        let nightClock = "BBB_Clock_Base_Night_ClockFrame"
        let assets: Set<String> = [dayClock, nightClock]
        let options = BerrySeasonalOptions()
        let night = resolve(.clockFrame, at: instant(2026, 11, 20, 0),
                            assets: assets, options: options)
        let day = resolve(.clockFrame, at: instant(2026, 11, 20, 12),
                          assets: assets, options: options)
        XCTAssertEqual(night.selectedAssetName, nightClock)
        XCTAssertEqual(day.selectedAssetName, dayClock)
        XCTAssertEqual(day.reason, .baseClockFrame)
        // No fixed numerals are selected or generated by this resolver.
        XCTAssertFalse(day.selectedAssetName.contains("12:"))
    }

    func testLocalRegionAndTimeZoneChangesNoNetworkOrGPSRequired() {
        // 06:00 UTC is Dec 24 23:00 in Phoenix, but Dec 25 01:00
        // in New York: the correct holiday counterpart is NIGHT, not Day.
        let candidate = "BBB_Season_Christmas_Night_HomeClassic"
        let available: Set<String> = [candidate]
        let instantUTC = instant(2026, 12, 25, 6, zone: TimeZone(identifier: "UTC")!)
        let phoenixChoice = resolve(.homeClassic, at: instantUTC, assets: available,
                                   options: optedIn(), zone: phoenix)
        let nycChoice = resolve(.homeClassic, at: instantUTC, assets: available,
                               options: optedIn(), zone: newYork)
        XCTAssertEqual(phoenixChoice.selectedAssetName, "ExistingGameArt")
        XCTAssertEqual(nycChoice.selectedAssetName, candidate)
        // US Thanksgiving is explicitly not applied to Canada by default.
        let canada = resolve(.homeClassic, at: instant(2026, 11, 26, 12),
                             assets: ["BBB_Season_Thanksgiving_Day_HomeClassic"],
                             options: optedIn(region: "CA"), region: "CA")
        XCTAssertEqual(canada.event, .none)
        XCTAssertEqual(canada.selectedAssetName, "ExistingGameArt")
    }

    func testUnavailableChristmasNightFallsBackRatherThanShowingWrongDayArt() {
        let dayOnly = "BBB_Season_Christmas_Day_DailyHarvest"
        let result = resolve(.dailyHarvest, at: instant(2026, 12, 25, 21),
                             assets: [dayOnly], options: optedIn())
        XCTAssertEqual(result.selectedAssetName, "ExistingGameArt")
        XCTAssertEqual(result.lighting, .night)
        XCTAssertEqual(result.reason, .unavailableSeasonalAsset)
    }

    func testResolverNeverWritesAnyGameSaveOrWalletKeys() {
        let key = "berry.seasonal.resolver.test." + UUID().uuidString
        let defaults = UserDefaults(suiteName: key)!
        defer { defaults.removePersistentDomain(forName: key) }
        defaults.set(1009, forKey: "wallet")
        defaults.set("saved-run", forKey: "currentGame")
        _ = resolve(.berryStory, at: instant(2026, 12, 25, 12),
                    assets: ["BBB_Season_Christmas_Day_BerryStory"],
                    options: optedIn())
        XCTAssertEqual(defaults.integer(forKey: "wallet"), 1009)
        XCTAssertEqual(defaults.string(forKey: "currentGame"), "saved-run")
    }
}
