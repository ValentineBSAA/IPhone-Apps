import XCTest
@testable import BerryBlockBlast

final class BerryBuild46DayNightTests: XCTestCase {
    func testSixAndEighteenHourBoundaries() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        func date(_ hour: Int, _ minute: Int) -> Date {
            cal.date(from: DateComponents(year: 2026, month: 11, day: 20,
                                          hour: hour, minute: minute))!
        }
        XCTAssertTrue(BerryDayNightAppearance.isNight(at: date(5,59), calendar: cal))
        XCTAssertFalse(BerryDayNightAppearance.isNight(at: date(6,0), calendar: cal))
        XCTAssertFalse(BerryDayNightAppearance.isNight(at: date(17,59), calendar: cal))
        XCTAssertTrue(BerryDayNightAppearance.isNight(at: date(18,0), calendar: cal))
        XCTAssertEqual(BerryDayNightAppearance.nextTransition(after: date(5,59), calendar: cal),
                       date(6,0))
        XCTAssertEqual(BerryDayNightAppearance.nextTransition(after: date(17,59), calendar: cal),
                       date(18,0))
    }
    func testDayNightSettingsDoNotTouchPlayerEconomy() {
        let suite = "berry46.night." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(4, forKey: "qa-wallet-sentinel")
        let now = Date(timeIntervalSince1970: 1780000000)
        BerryDayNightAppearance.update(now: now, defaults: defaults)
        XCTAssertNotNil(defaults.object(forKey: BerryDayNightAppearance.storageKey))
        XCTAssertEqual(defaults.integer(forKey: "qa-wallet-sentinel"), 4)
    }
}
