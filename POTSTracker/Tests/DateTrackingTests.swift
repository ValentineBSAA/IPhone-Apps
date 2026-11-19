import XCTest
@testable import POTSTracker

final class DateTrackingTests: XCTestCase {
    func testLastSevenDaysIncludesReferenceDay() {
        let calendar = Calendar(identifier: .gregorian)
        let reference = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: 14))!
        let days = DateTracking.lastSevenDays(reference: reference, calendar: calendar)
        XCTAssertEqual(days.count, 7)
        XCTAssertTrue(calendar.isDate(days.last!, inSameDayAs: reference))
        XCTAssertEqual(calendar.dateComponents([.day], from: days.first!, to: days.last!).day, 6)
    }

    func testLeapDayExistsWhenInSevenDayRange() {
        let calendar = Calendar(identifier: .gregorian)
        let reference = calendar.date(from: DateComponents(year: 2028, month: 3, day: 2, hour: 10))!
        let days = DateTracking.lastSevenDays(reference: reference, calendar: calendar)
        XCTAssertTrue(days.contains { calendar.component(.month, from: $0) == 2 && calendar.component(.day, from: $0) == 29 })
    }
}
