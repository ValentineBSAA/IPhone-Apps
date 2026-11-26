import XCTest
@testable import LastSeen
final class PhoneYearsArchiveTests:XCTestCase {
    func testThreeYearHistoryDoesNotGrantProgress() {
        var world=RestoredPhoneBackup.snapshot(now:Date(timeIntervalSince1970:1800000000))
        let flags=world.flags
        PhoneYearsArchive.expand(&world)
        PhoneYearsArchive.expand(&world)
        let history=world.threads.values.flatMap{$0}.filter{$0.id.hasPrefix("years-")}
        XCTAssertEqual(history.count,60)
        XCTAssertEqual(Set(history.map(\.id)).count,60)
        XCTAssertTrue(history.allSatisfy{$0.at<world.createdAt && $0.read})
        XCTAssertTrue(history.contains{$0.at<world.createdAt.addingTimeInterval(-1000*86400)})
        XCTAssertEqual(world.flags,flags)
        XCTAssertEqual(world.notes.filter{$0.id.hasPrefix("years-")}.count,6)
        PhoneYearsArchive.addCalendar(to:&world)
        PhoneYearsArchive.addCalendar(to:&world)
        let events=world.events.filter{$0.id.hasPrefix("years-event-")}
        XCTAssertEqual(events.count,13)
        XCTAssertEqual(Set(events.map(\.id)).count,13)
        XCTAssertTrue(events.allSatisfy{$0.startsAt<$0.endsAt && $0.endsAt<world.createdAt})
        XCTAssertEqual(world.flags,flags)
    }
}
