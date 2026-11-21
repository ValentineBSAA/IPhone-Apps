import XCTest
@testable import BerryBlockBlast

/// H0 prototype tests. No holiday UI or automated rewards are enabled.
final class BerrySeasonalCalendarTests: XCTestCase {
    private func localDate(_ year: Int, _ month: Int, _ day: Int,
                           hour: Int = 12, minute: Int = 0,
                           zone: String = "America/Phoenix") -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func optedIn(
        region: String? = "US",
        birthday: (Int, Int)? = nil,
        choice: BerrySeasonalDisplayChoice = .automatic
    ) -> BerrySeasonalOptions {
        var options = BerrySeasonalOptions()
        options.choice = choice
        options.automaticHolidaysEnabled = true
        options.countryOverride = region
        if let birthday = birthday {
            options.birthdayArtEnabled = true
            options.birthdayMonth = birthday.0
            options.birthdayDay = birthday.1
        }
        return options
    }

    func testDefaultDormantEvenOnChristmas() {
        let result = BerrySeasonalCalendar.resolve(
            at: localDate(2026, 12, 25), deviceRegionCode: "US",
            options: BerrySeasonalOptions())
        XCTAssertEqual(result.event, .none)
        XCTAssertEqual(result.source, .baseline)
    }

    func testHalloweenAndChristmasAfterOptIn() {
        let options = optedIn()
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: localDate(2026, 10, 31), options: options).event, .halloween)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: localDate(2026, 12, 25), options: options).event, .christmas)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: localDate(2026, 12, 26), options: options).event, .none)
    }

    func testUSThanksgivingFourthThursdayInNovember2026() {
        let options = optedIn()
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: localDate(2026, 11, 26), options: options).event, .thanksgiving)
        for day in [19, 25, 27, 28, 30] {
            XCTAssertEqual(BerrySeasonalCalendar.resolve(
                at: localDate(2026, 11, day), options: options).event, .none)
        }
    }

    func testThanksgivingNotAppliedWorldwide() {
        var options = optedIn(region: nil)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: localDate(2026, 11, 26), deviceRegionCode: "CA",
            options: options).event, .none)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: localDate(2026, 11, 26), deviceRegionCode: nil,
            options: options).event, .none)
        options.countryOverride = " us "
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: localDate(2026, 11, 26), deviceRegionCode: "CA",
            options: options).event, .thanksgiving)
    }

    func testMonthDayBirthdayOptInAndChristmasOverlap() {
        let options = optedIn(birthday: (12, 25))
        let result = BerrySeasonalCalendar.resolve(
            at: localDate(2026, 12, 25), options: options)
        XCTAssertEqual(result.event, .birthday)
        XCTAssertEqual(result.source, .optedInBirthday)
    }

    func testBirthdayDoesNotTriggerWithoutSeparateArtOptIn() {
        var options = optedIn(birthday: (12, 25))
        options.birthdayArtEnabled = false
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: localDate(2026, 12, 25), options: options).event, .christmas)
    }

    func testLeapDayBirthdayExactDateOnly() {
        let options = optedIn(birthday: (2, 29))
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: localDate(2028, 2, 29), options: options).event, .birthday)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: localDate(2027, 2, 28), options: options).event, .none)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: localDate(2027, 3, 1), options: options).event, .none)
        XCTAssertTrue(BerrySeasonalCalendar.validBirthday(month: 2, day: 29))
        XCTAssertFalse(BerrySeasonalCalendar.validBirthday(month: 2, day: 30))
        XCTAssertFalse(BerrySeasonalCalendar.validBirthday(month: 4, day: 31))
    }

    func testManualPreviewAndOffTakePriority() {
        let atChristmas = localDate(2026, 12, 25)
        let preview = optedIn(birthday: (12, 25), choice: .preview(.halloween))
        let disabled = optedIn(birthday: (12, 25), choice: .off)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: atChristmas, options: preview).event, .halloween)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: atChristmas, options: preview).source, .manualPreview)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: atChristmas, options: disabled).event, .none)
    }

    func testRealTimeZoneChangesHolidayDay() {
        // At one actual instant it is Dec 24 in Phoenix and Dec 25 in NYC.
        let instant = localDate(2026, 12, 25, hour: 6, zone: "UTC")
        let options = optedIn()
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: instant, timeZone: TimeZone(identifier: "America/Phoenix")!,
            options: options).event, .none)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: instant, timeZone: TimeZone(identifier: "America/New_York")!,
            options: options).event, .christmas)
    }

    func testDSTDateUsesLocalCalendarNotFixed24HourOffsets() {
        let options = optedIn()
        let beforeSpringForward = localDate(2026, 3, 8, hour: 1, minute: 59,
                                            zone: "America/New_York")
        let afterSpringForward = beforeSpringForward.addingTimeInterval(120)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: beforeSpringForward, timeZone: TimeZone(identifier: "America/New_York")!,
            options: options).event, .none)
        XCTAssertEqual(BerrySeasonalCalendar.resolve(
            at: afterSpringForward, timeZone: TimeZone(identifier: "America/New_York")!,
            options: options).event, .none)
    }

    func testNoSideEffectsToExistingBirthdayOrEconomy() {
        let suite = "berry.season.audit." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(1200, forKey: "qa-wallet-sentinel")
        defaults.set(12, forKey: "berryberryblast.birthday.month.v0511")
        defaults.set(25, forKey: "berryberryblast.birthday.day.v0511")
        _ = BerrySeasonalCalendar.resolve(
            at: localDate(2026, 12, 25), options: optedIn(birthday: (12, 25)))
        XCTAssertEqual(defaults.integer(forKey: "qa-wallet-sentinel"), 1200)
        XCTAssertEqual(defaults.integer(forKey: "berryberryblast.birthday.month.v0511"), 12)
        XCTAssertEqual(defaults.integer(forKey: "berryberryblast.birthday.day.v0511"), 25)
    }
}
