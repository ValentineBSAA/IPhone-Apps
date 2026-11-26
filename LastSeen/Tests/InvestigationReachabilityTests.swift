import XCTest
@testable import LastSeen

/// Confidential acceptance fixture. The tutorial boundary is seeded;
/// all subsequent investigation progress uses actual store actions.
@MainActor final class InvestigationReachabilityTests: XCTestCase {
    func testConnectedRouteAcrossCheckpoints() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var initial = RestoredPhoneBackup.snapshot(now: now)
        initial.flags.insert("phone-tutorial-finished")
        var w = PhoneWorldStore(initial: initial, persistToDisk: false)
        XCTAssertFalse(w.completeInvestigationReview(now: now))
        XCTAssertFalse(w.finishInvestigation(.minimal, now: now))
        w.visitWebRecord("studio", now: now)
        w.visitWebRecord("studio-notes", now: now)
        w.advanceInvestigation(now:now.addingTimeInterval(91))
        w.visitWebRecord("archive", now: now)
        w.visitWebRecord("archive-records", now: now)
        w.visitWebRecord("archive-review", now: now)
        w.visitWebRecord("studio-news", now: now)
        XCTAssertFalse(LumaWebCatalog.isReviewReady(w.state.flags))
        let image = try XCTUnwrap(LumaWebCatalog.page("archive-records")?.images.first)
        w.inspectWebAttachment(image, now: now)
        XCTAssertTrue(w.submitWebReview("A copy may have a different import date from its original capture.", now: now))
        w.visitWebRecord("archive-collection", now: now)
        w.visitWebRecord("archive-ledger", now: now)
        w.advanceInvestigation(now: now)
        XCTAssertEqual(w.connected.pendingMail.filter { $0.record.id == InvestigationReview.mailID }.count, 1)
        // Simulate an interrupted legacy queue write after the request flag.
        var interrupted = w.state
        interrupted.connectedWorld?.pendingMail.removeAll { $0.record.id == InvestigationReview.mailID }
        w = PhoneWorldStore(initial: interrupted, persistToDisk: false)
        XCTAssertFalse(w.state.flags.contains(InvestigationReview.read))
        w.advanceInvestigation(now: now)
        w.advanceInvestigation(now: now.addingTimeInterval(2))
        XCTAssertEqual(w.connected.pendingMail.filter { $0.record.id == InvestigationReview.mailID }.count, 1)
        w.advanceConnectedMail(now: now.addingTimeInterval(24))
        XCTAssertFalse(LumaMailCatalog.visible(w.state).contains { $0.id == InvestigationReview.mailID })
        w.advanceConnectedMail(now: now.addingTimeInterval(25))
        w.advanceInvestigation(now: now.addingTimeInterval(26))
        XCTAssertFalse(w.connected.pendingMail.contains { $0.record.id == InvestigationReview.mailID })
        // The critical correspondence remains recoverable after moving folders.
        w.moveConnectedMail(InvestigationReview.mailID,folder:"archive")
        XCTAssertTrue(LumaMailCatalog.mailbox(w.state,folder:"archive").contains{$0.id==InvestigationReview.mailID})
        w.moveConnectedMail(InvestigationReview.mailID,folder:"trash")
        XCTAssertTrue(LumaMailCatalog.mailbox(w.state,folder:"trash").contains{$0.id==InvestigationReview.mailID})
        w.recordInvestigationMailRead(InvestigationReview.mailID)
        w.visitWebRecord(InvestigationReview.pageID, now: now.addingTimeInterval(26))
        w.setInvestigationReviewChoice("a", value: 0)
        w.setInvestigationReviewChoice("b", value: 1)
        w.setInvestigationReviewChoice("c", value: 2)
        XCTAssertTrue(w.completeInvestigationReview(now: now.addingTimeInterval(27)))
        w.visitWebRecord(InvestigationResolution.indexID, now: now.addingTimeInterval(28))
        w.visitWebRecord(InvestigationResolution.noteID, now: now.addingTimeInterval(29))
        var late = w.state
        late.connectedWorld?.pendingMail.removeAll { $0.record.id == InvestigationResolution.mailID }
        w = PhoneWorldStore(initial: late, persistToDisk: false)
        w.advanceInvestigation(now: now.addingTimeInterval(30))
        w.advanceInvestigation(now: now.addingTimeInterval(31))
        XCTAssertEqual(w.connected.pendingMail.filter { $0.record.id == InvestigationResolution.mailID }.count, 1)
        w.advanceConnectedMail(now: now.addingTimeInterval(42))
        w.recordInvestigationMailRead(InvestigationResolution.mailID)
        w.visitWebRecord(InvestigationResolution.conclusionID, now: now.addingTimeInterval(43))
        XCTAssertTrue(EntityEcho.active(w.state.flags))
        XCTAssertFalse(w.finishInvestigation(.minimal,now:now))
        XCTAssertFalse(w.removeEntityEcho(answers:EntityEcho.solution,repair:[],epoch:w.checkpointEpoch))
        XCTAssertTrue(w.removeEntityEcho(answers:EntityEcho.solution,repair:EntityEcho.repairOrder,epoch:w.checkpointEpoch))
        XCTAssertFalse(EntityEcho.active(w.state.flags))
        let saved = try JSONEncoder().encode(w.state)
        for choice in InvestigationResolution.Choice.allCases {
            let restored = PhoneWorldStore(initial: try JSONDecoder().decode(PhoneWorld.self, from: saved), persistToDisk: false)
            XCTAssertTrue(restored.finishInvestigation(choice, now: now.addingTimeInterval(44)))
            XCTAssertEqual(InvestigationResolution.ending(restored.state), choice)
            restored.advanceInvestigation(now: now.addingTimeInterval(100))
            XCTAssertFalse(restored.connected.pendingMail.contains { $0.record.id == InvestigationResolution.mailID })
        }
    }

    func testMissingScriptedMessagesReconcileWithoutReplayingExistingHistory() throws {
        let now=Date(timeIntervalSince1970:1800000000)
        var initial=RestoredPhoneBackup.snapshot(now:now)
        initial.flags.formUnion(["phone-tutorial-finished","web.visited.studio","investigation.contact.received"])
        let w=PhoneWorldStore(initial:initial,persistToDisk:false)
        XCTAssertFalse(w.messages(.unknown).contains{$0.id=="unknown-intro-v1"})
        w.advanceInvestigation(now:now)
        let first=try XCTUnwrap(w.messages(.unknown).first{$0.id=="unknown-intro-v1"})
        w.markRead(.unknown)
        w.advanceInvestigation(now:now.addingTimeInterval(10))
        XCTAssertEqual(w.messages(.unknown).filter{$0.id==first.id}.count,1)
        XCTAssertEqual(w.messages(.unknown).first{$0.id==first.id}?.at,first.at)
        XCTAssertEqual(w.messages(.unknown).first{$0.id==first.id}?.read,true)
        var interrupted=w.state
        interrupted.flags.formUnion(["investigation.chapter2.reviewed","web.visited.archive-ledger","investigation.chapter2.ledgerAcknowledged"])
        let resumed=PhoneWorldStore(initial:interrupted,persistToDisk:false)
        resumed.advanceInvestigation(now:now.addingTimeInterval(20))
        resumed.advanceInvestigation(now:now.addingTimeInterval(21))
        XCTAssertEqual(resumed.messages(.unknown).filter{$0.id=="unknown-review-v2"}.count,1)
        XCTAssertEqual(resumed.messages(.unknown).filter{$0.id==first.id}.count,1)
        var revoked=interrupted
        revoked.flags.remove("phone-tutorial-finished")
        let unavailable=PhoneWorldStore(initial:revoked,persistToDisk:false)
        unavailable.advanceInvestigation(now:now)
        XCTAssertFalse(unavailable.messages(.unknown).contains{$0.id=="unknown-review-v2"})
    }

    func testRequestMarkerDoesNotGrantAccess() {
        var state = RestoredPhoneBackup.snapshot()
        state.flags.formUnion([InvestigationReview.requested, InvestigationResolution.requested])
        let w = PhoneWorldStore(initial: state, persistToDisk: false)
        w.advanceInvestigation()
        XCTAssertFalse(w.connected.pendingMail.contains { $0.record.id == InvestigationReview.mailID || $0.record.id == InvestigationResolution.mailID })
        XCTAssertFalse(w.completeInvestigationReview())
        XCTAssertFalse(w.finishInvestigation(.minimal))
    }
}
