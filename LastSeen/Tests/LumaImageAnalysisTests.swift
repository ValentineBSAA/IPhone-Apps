import XCTest
@testable import LastSeen

@MainActor final class LumaImageAnalysisTests:XCTestCase {
    func testApprovedPhotoCollectionsDecodeAndProduceSamples() throws {
        let originals=(1...29).map{String(format:"Recovered_B27_%02d",$0)}
        let archive=(1...11).map{String(format:"Nora_Archive_%02d",$0)}
        let camera=NoraPhotoCatalog.photos.map(\.id)
        let all=originals+archive+camera
        XCTAssertEqual(Set(all).count,54)
        for asset in all {
            let image=try XCTUnwrap(PortraitImages.load(asset),asset)
            XCTAssertGreaterThan(image.size.width,200,asset)
            XCTAssertGreaterThan(image.size.height,200,asset)
            let bins=try XCTUnwrap(RecoveredImageAnalysis.brightnessBins(image),asset)
            XCTAssertEqual(bins.count,3,asset)
            XCTAssertEqual(bins.reduce(0,+),1024,asset)
        }
    }
    func testSharedClassifierDoesNotShareCharacterResponses() {
        let predictions:[(String,Float)]=[("building",0.98),("room",0.88),("person",0.99),("plant",0.2)]
        let labels=LocalSceneClassifier.categories(predictions)
        XCTAssertEqual(labels,["building","interior"])
        XCTAssertEqual(RelaySupportPhotoAnalysis.categories(predictions),labels)
        XCTAssertTrue(LocalSceneClassifier.valid(labels))
        XCTAssertFalse(LocalSceneClassifier.valid(["person"]))
        let alex=RelaySupportPhotoAnalysis.reply(labels)
        let luma=LumaImageAnalysisReport(asset:"Nora_Archive_08",bins:[600,300,124],labels:labels).description
        XCTAssertNotEqual(alex,luma)
        XCTAssertFalse(alex.contains("Nora"))
        XCTAssertFalse(alex.contains("1,024"))
        XCTAssertTrue(luma.contains("1,024"))
    }
    func testAssistantAccessSnapshotDetectsRevocationWithoutSelectedRecord() {
        var world = RestoredPhoneBackup.snapshot()
        world.flags.formUnion(["phone-tutorial-finished", "web.visited.archive", VeilArchive.discovery,
                              "veil.viewed.Nora_Archive_08", LumaAssistantTrust.acknowledgement])
        let before = LumaAssistantAccessSnapshot(world)
        XCTAssertTrue(before.recordIDs.contains("image:Nora_Archive_08"))
        world.flags.insert("veil.viewed.Nora_Archive_09")
        let expanded = LumaAssistantAccessSnapshot(world)
        XCTAssertFalse(expanded.revokes(before))
        world.flags.remove(VeilArchive.discovery)
        let revoked = LumaAssistantAccessSnapshot(world)
        XCTAssertTrue(revoked.revokes(expanded))
        XCTAssertFalse(revoked.recordIDs.contains("image:Nora_Archive_08"))
        world.flags.insert(VeilArchive.discovery)
        let restored = LumaAssistantAccessSnapshot(world)
        XCTAssertFalse(restored.revokes(revoked))
        world.flags.remove(LumaAssistantTrust.acknowledgement)
        XCTAssertTrue(LumaAssistantAccessSnapshot(world).revokes(restored))
        XCTAssertTrue(LumaAssistantAccessSnapshot(PhoneWorldStore(persistToDisk: false).state).revokes(restored))
    }

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
