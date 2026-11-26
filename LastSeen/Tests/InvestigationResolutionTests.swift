import XCTest
@testable import LastSeen

@MainActor final class InvestigationResolutionTests: XCTestCase {
    func testTwoDecisionsAndCheckpointRoundTrip() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let base = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        XCTAssertFalse(base.finishInvestigation(.minimal, now: now))
        XCTAssertFalse(LumaWebCatalog.visible(base.state.flags).contains { $0.id == InvestigationResolution.indexID })
        var s = base.state
        s.flags.formUnion(["phone-tutorial-finished","web.visited.studio","investigation.chapter2.reviewed","web.visited.archive-ledger","web.visited.studio-news"])
        let w = PhoneWorldStore(initial: s, persistToDisk: false)
        w.advanceInvestigation(now: now)
        w.advanceConnectedMail(now: now.addingTimeInterval(26))
        w.recordInvestigationMailRead(InvestigationReview.mailID)
        w.visitWebRecord(InvestigationReview.pageID, now: now)
        w.setInvestigationReviewChoice("a",value:0)
        w.setInvestigationReviewChoice("b",value:1)
        w.setInvestigationReviewChoice("c",value:2)
        XCTAssertTrue(w.completeInvestigationReview(now:now))
        w.visitWebRecord(InvestigationResolution.noteID,now:now)
        XCTAssertFalse(w.state.flags.contains("web.visited."+InvestigationResolution.noteID))
        w.visitWebRecord(InvestigationResolution.indexID,now:now)
        w.visitWebRecord(InvestigationResolution.noteID,now:now)
        w.advanceInvestigation(now:now)
        XCTAssertEqual(w.connected.pendingMail.filter{$0.record.id==InvestigationResolution.mailID}.count,1)
        w.recordInvestigationMailRead(InvestigationResolution.mailID)
        XCTAssertFalse(w.state.flags.contains(InvestigationResolution.read))
        w.advanceConnectedMail(now:now.addingTimeInterval(13))
        w.recordInvestigationMailRead(InvestigationResolution.mailID)
        XCTAssertFalse(w.finishInvestigation(.minimal,now:now))
        w.visitWebRecord(InvestigationResolution.conclusionID,now:now)
        XCTAssertTrue(EntityEcho.active(w.state.flags))
        XCTAssertFalse(w.finishInvestigation(.minimal,now:now))
        XCTAssertFalse(w.removeEntityEcho(answers:EntityEcho.solution,repair:[],epoch:w.checkpointEpoch))
        XCTAssertTrue(w.removeEntityEcho(answers:EntityEcho.solution,repair:EntityEcho.repairOrder,epoch:w.checkpointEpoch))
        XCTAssertFalse(EntityEcho.active(w.state.flags))
        let checkpoint = try JSONEncoder().encode(w.state)
        for choice in InvestigationResolution.Choice.allCases {
            let branch = PhoneWorldStore(initial:try JSONDecoder().decode(PhoneWorld.self,from:checkpoint),persistToDisk:false)
            XCTAssertTrue(branch.finishInvestigation(choice,now:now))
            XCTAssertTrue(branch.finishInvestigation(choice,now:now))
            XCTAssertEqual(InvestigationResolution.ending(branch.state),choice)
            XCTAssertEqual(branch.messages(.maya).filter{$0.id=="local-resolution-in"}.count,1)
            let other: InvestigationResolution.Choice = choice == .minimal ? .retain : .minimal
            XCTAssertFalse(branch.finishInvestigation(other,now:now))
            let encoded = try JSONEncoder().encode(branch.state)
            XCTAssertEqual(InvestigationResolution.ending(try JSONDecoder().decode(PhoneWorld.self,from:encoded)),choice)
        }
    }
}
