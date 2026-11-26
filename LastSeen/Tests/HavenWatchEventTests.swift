import XCTest
@testable import LastSeen

@MainActor final class HavenWatchEventTests: XCTestCase {
    private func prepared(_ now: Date) -> PhoneWorldStore {
        var s = RestoredPhoneBackup.snapshot(now: now)
        s.flags.formUnion(["phone-tutorial-finished","web.visited.studio","web.visited.studio-notes","investigation.contact.received","web.visited.archive","investigation.chapter2.reviewed","web.visited.archive-ledger","web.visited.studio-news"])
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
    func testAcknowledgementAndMuteDoNotReplayArchiveAlerts() throws {
        let now=Date(timeIntervalSince1970:1_800_000_000)
        let w=prepared(now)
        w.advanceHavenWatch(now:now)
        w.advanceHavenWatch(now:now.addingTimeInterval(9))
        let event=try XCTUnwrap(HavenWatchEvents.visible(w.state))
        XCTAssertEqual(HavenWatchEvents.history(w.state).map(\.id),[event.id])
        w.acknowledgeHavenEvent("invalid")
        XCTAssertTrue(LumaActivityCatalog.visible(w.state).contains{$0.kind == .security})
        let snapshot=w.state
        w.acknowledgeHavenEvent(event.id)
        w.acknowledgeHavenEvent(event.id)
        XCTAssertFalse(LumaActivityCatalog.visible(w.state).contains{$0.kind == .security})
        XCTAssertEqual(HavenWatchEvents.history(w.state).map(\.id),[event.id])
        let muted=PhoneWorldStore(initial:snapshot,persistToDisk:false)
        var prefs=HavenWatchPreferences()
        prefs.alertsEnabled=false
        muted.setHavenWatch(prefs)
        prefs.alertsEnabled=true
        muted.setHavenWatch(prefs)
        XCTAssertFalse(LumaActivityCatalog.visible(muted.state).contains{$0.kind == .security})
        XCTAssertEqual(HavenWatchEvents.history(muted.state).map(\.id),[event.id])
    }

    func testSnapshotFiltersRespectCurrentAccess() {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let id=HavenCamera.kitchen.asset(occupied:false)
        var prefs=HavenWatchPreferences()
        prefs.favorites=[id,"invalid"]
        w.setHavenWatch(prefs)
        XCTAssertEqual(HavenWatchArchive.filtered(w.state,camera:.kitchen).count,2)
        XCTAssertEqual(HavenWatchArchive.filtered(w.state,favoritesOnly:true).map(\.id),[id])
        XCTAssertTrue(HavenWatchArchive.filtered(w.state,openedOnly:true).isEmpty)
        w.recordHavenSnapshotOpened(id)
        XCTAssertEqual(HavenWatchArchive.filtered(w.state,camera:.kitchen,favoritesOnly:true,openedOnly:true).map(\.id),[id])
        var revoked=w.state
        revoked.everydayArchiveRevision=nil
        XCTAssertTrue(HavenWatchArchive.filtered(revoked,favoritesOnly:true).isEmpty)
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
