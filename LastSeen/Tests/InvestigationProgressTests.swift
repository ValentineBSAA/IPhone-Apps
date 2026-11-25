import XCTest
@testable import LastSeen
@MainActor final class InvestigationProgressTests: XCTestCase {
    func testAnonymousContactAndArchiveGates() throws {
        var state=RestoredPhoneBackup.snapshot()
        let w=PhoneWorldStore(initial:state,persistToDisk:false)
        XCTAssertFalse(Neighbor.visible(in:w.state).contains(.unknown))
        XCTAssertFalse(LumaWebCatalog.visible(w.state.flags).contains{$0.id=="archive"})
        w.visitWebRecord("archive"); XCTAssertFalse(w.state.flags.contains("web.visited.archive"))
        w.visitWebRecord("studio"); XCTAssertFalse(Neighbor.visible(in:w.state).contains(.unknown))
        state=w.state; state.flags.insert("phone-tutorial-finished")
        let recovered=PhoneWorldStore(initial:state,persistToDisk:false)
        recovered.advanceInvestigation(); recovered.advanceInvestigation()
        XCTAssertEqual(recovered.messages(.unknown).count,1)
        XCTAssertEqual(Neighbor.unknown.portraitAssetName,"")
        XCTAssertTrue(LumaWebCatalog.visible(recovered.state.flags).contains{$0.id=="archive"})
        recovered.visitWebRecord("archive")
        XCTAssertTrue(LumaWebCatalog.visible(recovered.state.flags).contains{$0.id=="archive-records"})
        XCTAssertTrue(recovered.sendReactive(to:.unknown,text:"Are you Nora?"))
        recovered.advancePendingReplies(now:Date().addingTimeInterval(20))
        XCTAssertEqual(recovered.messages(.unknown).count,3)
        XCTAssertFalse(recovered.messages(.unknown).last!.text.contains("I am Nora"))
        let saved=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(recovered.state))
        XCTAssertEqual(saved.threads["unknown"]?.count,3)
    }
    func testBrowserHistoryAndChapterReview() throws {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        XCTAssertFalse(LumaWebCatalog.search("Review collection",flags:w.state.flags).contains{$0.id=="archive-collection"})
        XCTAssertFalse(w.submitWebReview("A copy may have a different import date from its original capture."))
        var state=w.state
        state.flags.formUnion(["phone-tutorial-finished","web.visited.studio"])
        let restored=PhoneWorldStore(initial:state,persistToDisk:false)
        restored.advanceInvestigation()
        restored.visitWebRecord("archive")
        restored.visitWebRecord("archive-records")
        restored.visitWebRecord("archive-review")
        restored.visitWebRecord("studio-news")
        XCTAssertFalse(LumaWebCatalog.isReviewReady(restored.state.flags))
        restored.inspectWebAttachment(LumaWebCatalog.page("archive-records")!.images[0])
        XCTAssertTrue(LumaWebCatalog.isReviewReady(restored.state.flags))
        XCTAssertFalse(restored.submitWebReview("Every recovered image is independently verified."))
        XCTAssertTrue(restored.submitWebReview("A copy may have a different import date from its original capture."))
        XCTAssertTrue(LumaWebCatalog.visible(restored.state.flags).contains{$0.id=="archive-collection"})
        restored.visitWebRecord("archive-collection")
        restored.visitWebRecord("archive-ledger")
        restored.advanceInvestigation()
        XCTAssertEqual(restored.messages(.unknown).filter{$0.id=="unknown-review-v2"}.count,1)
        let rows=LumaBrowserHistory.decode("",legacy:"cafe|books")
        XCTAssertEqual(rows.map(\.pageID),["cafe","books"])
        XCTAssertNil(rows[0].date)
        let date=Date(timeIntervalSince1970:1000)
        let newer=LumaBrowserHistory.record("cafe",in:rows,now:date)
        XCTAssertEqual(LumaBrowserHistory.decode(LumaBrowserHistory.encode(newer),legacy:""),newer)
        XCTAssertEqual(newer.map(\.pageID),["cafe","books","cafe"])
        XCTAssertEqual(newer.last?.date,date)
        let gated=LumaBrowserHistory.record("archive-collection",in:newer)
        XCTAssertEqual(LumaBrowserHistory.visible(gated,flags:[]),newer)
    }
    func testCompletedUnlockReportAcknowledgedWithoutGrantingProgress() {
        let plan=PhoneReplyPolicy.plan(for:.maya,text:"I figured out how to unlock it. I don't know where Nora is.",flags:["phone-tutorial-replied"],tutorialStarted:true,tutorialFinished:true)
        XCTAssertTrue(plan.text.contains("glad"))
        XCTAssertFalse(plan.startsTutorial)
    }
    func testMediaAndProgressAreGated() {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        XCTAssertEqual(InvestigationProgress.steps(w.state.flags).filter(\.done).count,0)
        let asset=LumaWebCatalog.page("archive-records")!.images.first!
        w.inspectWebAttachment(asset)
        XCTAssertFalse(w.state.flags.contains("web.inspected."+asset))
        for i in 1...29 { XCTAssertNotNil(PortraitImages.load(String(format:"Recovered_B27_%02d",i))) }
        XCTAssertEqual(Set(LumaWebCatalog.pages.map(\.id)).count,LumaWebCatalog.pages.count)
    }
}
