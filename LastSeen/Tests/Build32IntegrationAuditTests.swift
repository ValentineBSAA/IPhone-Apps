import XCTest
@testable import LastSeen

@MainActor final class Build32IntegrationAuditTests: XCTestCase {
    func testBannerQueueOrdersAndSkipsDismissedActivity() throws {
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        w.recordTimerActivity(end: 100)
        w.recordTimerActivity(end: 200)
        w.recordTimerActivity(end: 300)
        let notices = LumaActivityCatalog.newEntries(w.state, previous: [])
        XCTAssertEqual(notices.count, 3)
        var queue = LumaActivityBannerQueue()
        queue.enqueue(notices, showing: nil)
        queue.enqueue(notices, showing: nil)
        XCTAssertEqual(queue.ids.count, 3)
        w.dismissActivity(notices[0].id)
        XCTAssertEqual(queue.next(in: w.state)?.id, notices[1].id)
        XCTAssertEqual(queue.next(in: w.state)?.id, notices[2].id)
        XCTAssertNil(queue.next(in: w.state))
        queue.enqueue(notices, showing: notices[1].id)
        queue.clear()
        XCTAssertTrue(queue.ids.isEmpty)
    }
    func testActivityPresentationRevalidatesAfterPreemptionAndDismissal() throws {
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        w.recordTimerActivity(end: 100)
        let notice = try XCTUnwrap(LumaActivityCatalog.visible(w.state).first { $0.kind == .timer })
        XCTAssertEqual(LumaActivityCatalog.presentedID(notice, in: w.state, unobstructed: true), notice.id)
        XCTAssertNil(LumaActivityCatalog.presentedID(notice, in: w.state, unobstructed: false))
        XCTAssertEqual(LumaActivityCatalog.presentedID(notice, in: w.state, unobstructed: true), notice.id)
        w.dismissActivity(notice.id)
        XCTAssertNil(LumaActivityCatalog.presentedID(notice, in: w.state, unobstructed: true))
        XCTAssertNil(LumaActivityCatalog.presentedID(nil, in: w.state, unobstructed: true))
    }
    func testLatePageRejectsMissingPrerequisite() {
        var flags: Set<String> = ["phone-tutorial-finished","web.visited.studio","investigation.chapter2.reviewed","web.visited.archive-ledger","investigation.chapter2.ledgerAcknowledged",InvestigationReview.requested,InvestigationReview.read,InvestigationReview.finished,"web.visited."+InvestigationReview.pageID,"web.visited."+InvestigationResolution.indexID,"web.visited."+InvestigationResolution.noteID,InvestigationResolution.requested,InvestigationResolution.read]
        XCTAssertTrue(LumaWebCatalog.visible(flags).contains { $0.id == InvestigationResolution.conclusionID })
        flags.remove("phone-tutorial-finished")
        XCTAssertFalse(LumaWebCatalog.visible(flags).contains { $0.id == InvestigationResolution.conclusionID || $0.id == InvestigationReview.pageID })
        flags.insert("phone-tutorial-finished")
        flags.remove(InvestigationResolution.read)
        XCTAssertFalse(LumaWebCatalog.visible(flags).contains { $0.id == InvestigationResolution.conclusionID })
    }
}
