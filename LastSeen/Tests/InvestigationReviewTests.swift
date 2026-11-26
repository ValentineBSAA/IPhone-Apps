import XCTest
@testable import LastSeen

@MainActor final class InvestigationReviewTests: XCTestCase {
    func testCrossAppSequencePersistsAndRejectsPrematureReview() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        XCTAssertFalse(w.completeInvestigationReview(now: now))
        w.recordInvestigationMailRead(InvestigationReview.mailID)
        XCTAssertFalse(w.state.flags.contains(InvestigationReview.read))
        XCTAssertFalse(LumaWebCatalog.visible(w.state.flags).contains { $0.id == InvestigationReview.pageID })
        var state = w.state
        state.flags.formUnion(["phone-tutorial-finished","web.visited.studio","web.visited.studio-notes","investigation.contact.received","web.visited.archive","investigation.chapter2.reviewed","web.visited.archive-ledger","web.visited.studio-news"])
        let advanced = PhoneWorldStore(initial: state, persistToDisk: false)
        advanced.advanceInvestigation(now: now)
        advanced.advanceInvestigation(now: now)
        XCTAssertEqual(advanced.connected.pendingMail.filter { $0.record.id == InvestigationReview.mailID }.count, 1)
        advanced.recordInvestigationMailRead(InvestigationReview.mailID)
        XCTAssertFalse(advanced.state.flags.contains(InvestigationReview.read))
        advanced.advanceConnectedMail(now: now.addingTimeInterval(24))
        XCTAssertFalse(LumaMailCatalog.visible(advanced.state).contains { $0.id == InvestigationReview.mailID })
        advanced.advanceConnectedMail(now: now.addingTimeInterval(26))
        XCTAssertEqual(LumaActivityCatalog.visible(advanced.state).filter { $0.targetID == InvestigationReview.mailID }.count, 1)
        advanced.recordInvestigationMailRead(InvestigationReview.mailID)
        XCTAssertTrue(LumaWebCatalog.visible(advanced.state.flags).contains { $0.id == InvestigationReview.pageID })
        XCTAssertFalse(advanced.completeInvestigationReview(now: now))
        advanced.visitWebRecord(InvestigationReview.pageID, now: now)
        advanced.setInvestigationReviewChoice("a",value: 0)
        advanced.setInvestigationReviewChoice("b",value: 0)
        advanced.setInvestigationReviewChoice("c",value: 2)
        XCTAssertFalse(advanced.completeInvestigationReview(now: now))
        let saved = try JSONDecoder().decode(PhoneWorld.self,from: JSONEncoder().encode(advanced.state))
        let resumed = PhoneWorldStore(initial:saved,persistToDisk:false)
        XCTAssertEqual(InvestigationReview.visibleSelection(resumed.state).count,3)
        resumed.setInvestigationReviewChoice("b",value: 1)
        XCTAssertTrue(resumed.completeInvestigationReview(now: now))
        XCTAssertTrue(resumed.completeInvestigationReview(now: now))
        XCTAssertEqual(resumed.messages(.unknown).filter { $0.id == "local-review-followup-03" }.count,1)
    }
}
