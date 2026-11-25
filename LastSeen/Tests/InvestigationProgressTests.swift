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
