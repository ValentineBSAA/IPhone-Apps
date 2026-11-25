import XCTest
@testable import LastSeen

@MainActor final class DayblinkTests: XCTestCase {
    func testRestoredArchiveAndOnceOnlyDelivery() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let base = PhoneWorldStore(persistToDisk: false)
        XCTAssertTrue(DayblinkArchive.records(base.state, friend: .maya).isEmpty)
        XCTAssertFalse(base.sendDayblink(friend: .maya, text: "Hi", now: now))
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        XCTAssertEqual(DayblinkArchive.records(w.state, friend: .maya).count, 2)
        XCTAssertFalse(w.openDayblink("dayblink-maya-expired", friend: .maya))
        XCTAssertTrue(w.sendDayblink(friend: .maya, text: "Thank you!", now: now))
        w.advanceDayblink(now: now.addingTimeInterval(13))
        XCTAssertTrue(LumaActivityCatalog.visible(w.state).isEmpty)
        w.advanceDayblink(now: now.addingTimeInterval(15))
        let notice = try XCTUnwrap(LumaActivityCatalog.visible(w.state).first)
        XCTAssertEqual(notice.kind, .dayblink)
        XCTAssertTrue(notice.hidePreview(in: w.state))
        let id = try XCTUnwrap(notice.targetID)
        XCTAssertTrue(w.openDayblink(id, friend: .maya))
        XCTAssertFalse(w.openDayblink(id, friend: .maya))
        XCTAssertTrue(LumaActivityCatalog.visible(w.state).isEmpty)
        let restored = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(w.state))
        let other = PhoneWorldStore(initial: restored, persistToDisk: false)
        XCTAssertFalse(other.openDayblink(id, friend: .maya))
        other.advanceDayblink(now: now.addingTimeInterval(60))
        XCTAssertEqual(other.connected.dayblink?.messages.count, 2)
    }
    func testMuteDoesNotPreventDelivery() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        w.setDayblinkMuted(.lily, muted: true)
        XCTAssertTrue(w.sendDayblink(friend: .lily, text: "Hi", now: now))
        w.advanceDayblink(now: now.addingTimeInterval(30))
        XCTAssertTrue(LumaActivityCatalog.visible(w.state).isEmpty)
        XCTAssertEqual(w.connected.dayblink?.messages.count, 2)
        XCTAssertTrue(w.connected.dayblink?.muted.contains(.lily) == true)
    }
}
