import XCTest
@testable import LastSeen

@MainActor final class HavenWatchEventTests: XCTestCase {
    private func prepared(_ now: Date) -> PhoneWorldStore {
        var s = RestoredPhoneBackup.snapshot(now: now)
        s.flags.formUnion(["phone-tutorial-finished","web.visited.studio","investigation.chapter2.reviewed","web.visited.archive-ledger","web.visited.studio-news"])
        let w = PhoneWorldStore(initial: s, persistToDisk: false)
        w.advanceInvestigation(now: now)
        w.advanceConnectedMail(now: now.addingTimeInterval(26))
        w.recordInvestigationMailRead(InvestigationReview.mailID)
        w.visitWebRecord(InvestigationReview.pageID, now: now)
        w.setInvestigationReviewChoice("a", value: 0)
        w.setInvestigationReviewChoice("b", value: 1)
        w.setInvestigationReviewChoice("c", value: 2)
        XCTAssertTrue(w.completeInvestigationReview(now: now))
        return w
    }
    func testGatedOnceOnlyDeliveryAndRestore() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let base = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        base.advanceHavenWatch(now: now)
        XCTAssertNil(base.connected.havenEvent)
        let w = prepared(now)
        w.advanceHavenWatch(now: now)
        w.advanceHavenWatch(now: now.addingTimeInterval(7))
        XCTAssertNil(HavenWatchEvents.visible(w.state))
        let checkpoint = try JSONEncoder().encode(w.state)
        let resumed = PhoneWorldStore(initial: try JSONDecoder().decode(PhoneWorld.self, from: checkpoint), persistToDisk: false)
        resumed.advanceHavenWatch(now: now.addingTimeInterval(9))
        resumed.advanceHavenWatch(now: now.addingTimeInterval(10))
        let event = try XCTUnwrap(HavenWatchEvents.visible(resumed.state))
        let notices = LumaActivityCatalog.visible(resumed.state).filter { $0.kind == .security }
        XCTAssertEqual(notices.count, 1)
        XCTAssertEqual(notices.first?.targetID, event.id)
        XCTAssertEqual(notices.first?.profile, .security)
        XCTAssertTrue(notices.first?.hidePreview(in: resumed.state) == true)
        resumed.dismissActivity(event.id)
        XCTAssertTrue(LumaActivityCatalog.visible(resumed.state).filter { $0.kind == .security }.isEmpty)
        XCTAssertNotNil(HavenWatchEvents.visible(resumed.state))
    }
    func testDisabledAlertRetainsArchiveEvent() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let w = prepared(now)
        var prefs = HavenWatchPreferences()
        prefs.alertsEnabled = false
        w.setHavenWatch(prefs)
        w.advanceHavenWatch(now: now)
        w.advanceHavenWatch(now: now.addingTimeInterval(9))
        XCTAssertNotNil(HavenWatchEvents.visible(w.state))
        XCTAssertFalse(LumaActivityCatalog.visible(w.state).contains { $0.kind == .security })
    }
}
