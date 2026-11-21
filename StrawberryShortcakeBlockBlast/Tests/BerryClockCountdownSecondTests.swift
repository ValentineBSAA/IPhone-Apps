import Foundation
import XCTest
@testable import BerryBlockBlast

/// Regression for the real Home clock and local 6 AM/6 PM transitions.
/// The tests simulate dates; none adjusts iOS time, user saves, or currencies.
final class BerryClockCountdownSecondTests: XCTestCase {
    private func calendar(_ zone: String = "America/Phoenix") -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: zone)!
        return cal
    }

    private func date(_ h: Int, _ min: Int, _ sec: Int, cal: Calendar) -> Date {
        date(2026, 11, 21, h, min, sec, cal: cal)
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int,
                      _ min: Int, _ sec: Int, cal: Calendar) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d,
                                      hour: h, minute: min, second: sec))!
    }

    func testClockDisplays12HourLocalTimeIncludingSeconds() {
        let cal = calendar()
        XCTAssertEqual(BerryDayNightAppearance.clockText(
            date(14, 0, 37, cal: cal), calendar: cal), "2:00:37 PM")
        XCTAssertEqual(BerryDayNightAppearance.clockText(
            date(1, 5, 9, cal: cal), calendar: cal), "1:05:09 AM")
        XCTAssertEqual(BerryDayNightAppearance.clockText(
            date(0, 0, 0, cal: cal), calendar: cal), "12:00:00 AM")
        XCTAssertEqual(BerryDayNightAppearance.clockText(
            date(12, 0, 0, cal: cal), calendar: cal), "12:00:00 PM")
    }

    func testMoonlightCountdownTicksLastTwoSecondsAndSwitchesAtSixPM() {
        let cal = calendar()
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: date(17, 59, 58, cal: cal), calendar: cal), "Moonlight in 00:00:02")
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: date(17, 59, 59, cal: cal), calendar: cal), "Moonlight in 00:00:01")
        XCTAssertTrue(BerryDayNightAppearance.isNight(
            at: date(18, 0, 0, cal: cal), calendar: cal))
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: date(18, 0, 0, cal: cal), calendar: cal), "Sunrise in 12:00:00")
    }

    func testSunriseCountdownTicksLastTwoSecondsAndSwitchesAtSixAM() {
        let cal = calendar()
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: date(5, 59, 58, cal: cal), calendar: cal), "Sunrise in 00:00:02")
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: date(5, 59, 59, cal: cal), calendar: cal), "Sunrise in 00:00:01")
        XCTAssertFalse(BerryDayNightAppearance.isNight(
            at: date(6, 0, 0, cal: cal), calendar: cal))
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: date(6, 0, 0, cal: cal), calendar: cal), "Moonlight in 12:00:00")
    }

    func testFourHourCountdownDoesNotRoundUpAnExtraMinute() {
        let cal = calendar()
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: date(13, 59, 37, cal: cal), calendar: cal), "Moonlight in 04:00:23")
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: date(14, 0, 37, cal: cal), calendar: cal), "Moonlight in 03:59:23")
    }

    func testFractionalLastSecondDoesNotPrematurelyShowZero() {
        let cal = calendar()
        let almostSix = date(17, 59, 59, cal: cal).addingTimeInterval(0.80)
        XCTAssertEqual(BerryDayNightAppearance.remainingSeconds(
            at: almostSix, calendar: cal), 1)
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: almostSix, calendar: cal), "Moonlight in 00:00:01")
    }

    func testTimeZoneAndDSTRecalculateFromActualCalendarDates() {
        let phoenix = calendar()
        let eastern = calendar("America/New_York")
        let instant = date(2026, 3, 8, 15, 30, 10, cal: phoenix) // spring DST date
        let phoenixTarget = BerryDayNightAppearance.nextTransition(after: instant, calendar: phoenix)
        let easternTarget = BerryDayNightAppearance.nextTransition(after: instant, calendar: eastern)
        XCTAssertNotEqual(phoenixTarget, easternTarget)
        for cal in [phoenix, eastern] {
            let target = BerryDayNightAppearance.nextTransition(after: instant, calendar: cal)
            let components = cal.dateComponents([.hour, .minute, .second], from: target)
            XCTAssertTrue([6, 18].contains(components.hour!))
            XCTAssertEqual(components.minute, 0)
            XCTAssertEqual(components.second, 0)
            XCTAssertGreaterThan(target, instant)
        }
    }

    func testMidnightAndResumeUseCurrentWallClockNotAccumulatedTicks() {
        let cal = calendar()
        let eleven = date(2026, 11, 21, 23, 59, 59, cal: cal)
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: eleven, calendar: cal), "Sunrise in 06:00:01")
        // A foreground resume three hours later immediately recomputes from
        // its new current Date, even if no timer callbacks ran while asleep.
        let resumed = date(2026, 11, 22, 3, 0, 0, cal: cal)
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: resumed, calendar: cal), "Sunrise in 03:00:00")
    }

    func testVirtualDeveloperClockIsIsolatedAndMatchesActualDisplayLogic() {
        let cal = calendar()
        let today = date(2026, 11, 21, 12, 0, 0, cal: cal)
        let earlier = BerryDayNightAppearance.previewTime(
            on: today, hour: 17, minute: 59, second: 58, calendar: cal)!
        let after = BerryDayNightAppearance.previewTime(
            on: today, hour: 18, minute: 0, second: 0, calendar: cal)!
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: earlier, calendar: cal), "Moonlight in 00:00:02")
        XCTAssertEqual(BerryDayNightAppearance.countdownText(
            at: after, calendar: cal), "Sunrise in 12:00:00")
        XCTAssertNil(BerryDayNightAppearance.previewTime(
            on: today, hour: 24, minute: 0, second: 0, calendar: cal))
        XCTAssertNil(BerryDayNightAppearance.previewTime(
            on: today, hour: 18, minute: 60, second: 0, calendar: cal))
    }

    func testReadOnlyClockAndDeveloperPreviewNeverWriteInventoryOrSaves() {
        let suite = "berry.clock.second.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let walletKey = "berryblockblast.inventory.v3"
        let savesKey = "berryblockblast.endless.saved-8.v056b2"
        let sentinel = Data([0x41, 0x50, 0x50])
        defaults.set(sentinel, forKey: walletKey)
        defaults.set(sentinel, forKey: savesKey)
        let cal = calendar()
        let now = date(18, 0, 2, cal: cal)
        _ = BerryDayNightAppearance.clockText(now, calendar: cal)
        _ = BerryDayNightAppearance.countdownText(at: now, calendar: cal)
        _ = BerryDayNightAppearance.previewTime(on: now,
                                               hour: 17, minute: 59, second: 58,
                                               calendar: cal)
        BerryDayNightAppearance.update(now: now, defaults: defaults)
        XCTAssertEqual(defaults.data(forKey: walletKey), sentinel)
        XCTAssertEqual(defaults.data(forKey: savesKey), sentinel)
    }
}
