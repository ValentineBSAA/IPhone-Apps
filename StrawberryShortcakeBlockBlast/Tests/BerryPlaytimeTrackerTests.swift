import XCTest
@testable import BerryBlockBlast

@MainActor
final class BerryPlaytimeTrackerTests: XCTestCase {
    func testAllTwelveGameModeTimelinesAreIndependent() {
        let modes = BerryPlaytimeTracker.modeCatalog
        XCTAssertEqual(modes.count, 12)
        XCTAssertEqual(Set(modes.map { $0.id }).count, 12)
        for id in ["endless-8", "endless-12", "endless-24",
                   "blitz-60", "blitz-120", "blitz-300", "blitz-600",
                   "classic", "story", "daily", "cozy", "nightmare"] {
            XCTAssertTrue(modes.contains(where: { $0.id == id }), id)
        }
    }

    func testSessionsSplitAtLocalMidnightWithoutLosingTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Phoenix"))
        let before = try XCTUnwrap(calendar.date(from:
            DateComponents(year: 2026, month: 11, day: 17,
                           hour: 23, minute: 59, second: 50)))
        let after = before.addingTimeInterval(20)
        let segments = BerryPlaytimeTracker.segments(from: before, to: after,
                                                     calendar: calendar)
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].day, "2026-11-17")
        XCTAssertEqual(segments[1].day, "2026-11-18")
        XCTAssertEqual(segments[0].seconds, 10, accuracy: 0.01)
        XCTAssertEqual(segments[1].seconds, 10, accuracy: 0.01)
    }

    func testTimestampsUseTwelveHourClockWithAMPM() throws {
        let cal = Calendar.current
        let afternoon = try XCTUnwrap(cal.date(from:
            DateComponents(year: 2026, month: 11, day: 17,
                           hour: 13, minute: 5, second: 0)))
        let label = BerryPlaytimeTracker.clock(afternoon)
        XCTAssertEqual(label, "1:05 PM")
    }

    func testSavedModeSessionsPreserveRealStartStopAndDuration() throws {
        let start = Date(timeIntervalSince1970: 1_795_000_000)
        let source = BerryPlaytimeTracker.ModeSession(
            id: UUID(), modeID: "story", title: "Berry Story",
            startedAt: start, endedAt: start.addingTimeInterval(402),
            activeSeconds: 382)
        let data = try JSONEncoder().encode([source])
        let restored = try JSONDecoder().decode(
            [BerryPlaytimeTracker.ModeSession].self, from: data)
        XCTAssertEqual(restored.count, 1)
        XCTAssertEqual(restored[0].modeID, "story")
        XCTAssertEqual(restored[0].startedAt, start)
        XCTAssertEqual(restored[0].endedAt, start.addingTimeInterval(402))
        XCTAssertEqual(restored[0].activeSeconds, 382)
    }

    func testDisplayFormattingWorksForShortAndLongVisits() {
        XCTAssertEqual(BerryPlaytimeTracker.display(0), "0m 0s")
        XCTAssertEqual(BerryPlaytimeTracker.display(83), "1m 23s")
        XCTAssertEqual(BerryPlaytimeTracker.display(3672), "1h 1m")
    }
}
