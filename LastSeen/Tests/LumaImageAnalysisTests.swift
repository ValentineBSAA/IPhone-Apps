import XCTest
@testable import LastSeen

@MainActor final class LumaImageAnalysisTests:XCTestCase {
    func testReportValidationAndAuthorization() throws {
        var state=RestoredPhoneBackup.snapshot()
        let asset="Nora_Archive_08"
        let report=LumaImageAnalysisReport(asset:asset,bins:[600,300,124],labels:["building"])
        XCTAssertTrue(report.valid)
        XCTAssertFalse(LumaImageAnalysisReport(asset:asset,bins:[1,2,3],labels:[]).valid)
        XCTAssertFalse(LumaImageAnalysisReport(asset:asset,bins:[600,300,124],labels:["unapproved identity"]).valid)
        XCTAssertFalse(LumaImageAnalysis.permitted(asset,world:state,security:"Standard"))
        state.flags.formUnion(["phone-tutorial-finished","investigation.contact.received","web.visited.archive",VeilArchive.discovery])
        let store=PhoneWorldStore(initial:state,persistToDisk:false)
        store.recordVeilObservation(asset)
        XCTAssertTrue(LumaImageAnalysis.permitted(asset,world:store.state,security:"Standard"))
        XCTAssertFalse(LumaImageAnalysis.permitted(asset,world:store.state,security:"Safest"))
        XCTAssertNil(LumaImageAnalysis.verified(report,recordID:"image:Nora_Archive_09",world:store.state,security:"Standard"))
        XCTAssertNil(LumaImageAnalysis.verified(report,recordID:"image:"+asset,world:store.state,security:"Safest"))
        let c=LumaAssistantContext(world:store.state,availableApps:[.messages],wifi:false,sound:false,haptics:false,safeMode:false,installedCount:0,timerEnd:0,now:state.createdAt)
        let reply=LumaAssistantConversation.reply("What can you see in this image?",context:c,evidenceID:"image:"+asset,visualReport:report)
        XCTAssertTrue(reply.answer.text.contains("Possible broad categories"))
        let hidden=LumaAssistantConversation.reply("What can you see in this image?",context:c,evidenceID:"image:"+asset,visualReport:report,imageSecurity:"Safest")
        XCTAssertFalse(hidden.answer.text.contains("Possible broad categories"))
        XCTAssertEqual(LumaAssistantConversation.reply("Tell me the password",context:c,evidenceID:"image:"+asset,visualReport:report).answer.clipID,"denied")
        state=store.state;state.flags.remove(VeilArchive.discovery)
        XCTAssertNil(LumaImageAnalysis.verified(report,recordID:"image:"+asset,world:state,security:"Standard"))
    }
}
