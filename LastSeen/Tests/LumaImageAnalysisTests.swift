import XCTest
@testable import LastSeen

@MainActor final class LumaImageAnalysisTests:XCTestCase {
    func testImageHandoffRequiresCurrentCheckpointEvenWhenRecordSurvives() throws {
        var state=RestoredPhoneBackup.snapshot()
        state.flags.formUnion(["phone-tutorial-finished","investigation.contact.received","web.visited.archive","web.visited.archive-records","web.inspected.Recovered_B27_02",VeilArchive.discovery,"veil.viewed.Recovered_B27_02"])
        let w=PhoneWorldStore(initial:state,persistToDisk:false)
        let asset="Recovered_B27_02"
        let oldEpoch=w.checkpointEpoch
        let handoff=try XCTUnwrap(LumaImageHandoff.make(asset,epoch:oldEpoch,in:w.state))
        XCTAssertEqual(handoff.resolve(epoch:oldEpoch,in:w.state),asset)
        XCTAssertNil(LumaImageHandoff.make("Nora_Photo_10",epoch:oldEpoch,in:w.state))
        XCTAssertNil(LumaImageHandoff.make("WorldPhoto_E01_01",epoch:oldEpoch,in:w.state))
        var revoked=w.state
        revoked.flags.remove("web.visited.archive-records")
        XCTAssertNil(handoff.resolve(epoch:oldEpoch,in:revoked))
        try w.restoreCheckpoint(w.state)
        XCTAssertNotEqual(w.checkpointEpoch,oldEpoch)
        XCTAssertNotNil(RecoveredImageAnalysis.record(asset,in:w.state))
        XCTAssertNil(handoff.resolve(epoch:w.checkpointEpoch,in:w.state))
        XCTAssertEqual(LumaImageHandoff.make(asset,epoch:w.checkpointEpoch,in:w.state)?.resolve(epoch:w.checkpointEpoch,in:w.state),asset)
    }

    func testPhotoLibraryFiltersAndAdjacentNavigation() {
        let favorites:Set<String>=["Nora_Photo_01","Nora_Photo_04","Nora_Photo_10","Nora_Collage_01"]
        XCTAssertEqual(NoraPhotoCatalog.library([],filter:.library).count,19)
        XCTAssertEqual(NoraPhotoCatalog.library([],filter:.recovered).count,13)
        XCTAssertEqual(NoraPhotoCatalog.library([],filter:.favorites,favorites:favorites).map(\.id),["Nora_Photo_01"])
        let flags:Set<String>=["nora-photo-notes","nora-photo-unlocked-Nora_Photo_10","nora-photo-unlocked-Nora_Collage_01"]
        XCTAssertEqual(NoraPhotoCatalog.library(flags,filter:.recovered).count,15)
        XCTAssertEqual(NoraPhotoCatalog.library(flags,filter:.favorites,favorites:favorites).map(\.id),["Nora_Photo_01","Nora_Photo_04"])
        XCTAssertEqual(NoraPhotoCatalog.adjacent("Nora_Photo_01",offset:1,flags:flags,filter:.favorites,favorites:favorites)?.id,"Nora_Photo_04")
        XCTAssertNil(NoraPhotoCatalog.adjacent("Nora_Photo_01",offset:-1,flags:flags,filter:.library))
        XCTAssertEqual(NoraPhotoCatalog.adjacent("Nora_Photo_05",offset:1,flags:flags,filter:.recovered)?.id,"WorldPhoto_E01_01")
        XCTAssertNil(NoraPhotoCatalog.adjacent("WorldPhoto_E01_10",offset:1,flags:flags,filter:.recovered))
        XCTAssertNil(NoraPhotoCatalog.adjacent("Nora_Photo_10",offset:-1,flags:flags,filter:.library))
        XCTAssertNil(NoraPhotoCatalog.adjacent("Nora_Photo_01",offset:99,flags:flags,filter:.library))
        XCTAssertEqual(NoraPhotoCatalog.library([],filter:.favorites,favorites:favorites).count,1)
    }

    func testArtworkExposureAndPrivateDisplayContract() {
        let all=Set((1...29).map{String(format:"Recovered_B27_%02d",$0)})
        let held:Set<String>=["Recovered_B27_06"]
        let reflection:Set<String>=["Recovered_B27_21","Recovered_B27_24","Recovered_B27_28"]
        let assigned=all.subtracting(held.union(reflection))
        XCTAssertEqual(Set(VeilArchive.reflectionAssets),reflection)
        XCTAssertEqual(assigned.count,25)
        XCTAssertEqual(Set(LumaWebCatalog.pages.flatMap(\.images)),assigned)
        XCTAssertEqual(all.subtracting(assigned).count,4)
        XCTAssertNil(PortraitImages.load("Recovered_B27_06"))
        var state=RestoredPhoneBackup.snapshot()
        state.flags.formUnion(["phone-tutorial-finished","investigation.contact.received","web.visited.archive","web.visited.archive-records"])
        // Forged/stale inspection markers cannot expose unused or held art.
        for id in all.subtracting(assigned).union(["WorldPhoto_E01_01","Nora_Photo_10","Nora_Collage_01"]) {
            state.flags.insert("web.inspected."+id)
            XCTAssertNil(RecoveredImageAnalysis.record(id,in:state))
            XCTAssertNil(LumaAssistantEvidence.selected("image:"+id,in:state))
        }
        state.flags.insert("web.inspected.Recovered_B27_02")
        XCTAssertNil(RecoveredImageAnalysis.record("Recovered_B27_02",in:state))
        state.flags.insert(VeilArchive.discovery)
        state.flags.insert("veil.viewed.Recovered_B27_02")
        XCTAssertNotNil(RecoveredImageAnalysis.record("Recovered_B27_02",in:state))
        state.flags.remove("web.visited.archive-records")
        XCTAssertNil(RecoveredImageAnalysis.record("Recovered_B27_02",in:state))
        let privateID="Nora_Photo_10"
        var flags:Set<String>=["phone-tutorial-finished","nora-photo-journal","nora-photo-unlocked-"+privateID]
        XCTAssertTrue(NoraPhotoCatalog.privateDisplayAllowed(privateID,flags:flags,authenticated:true,active:true))
        XCTAssertFalse(NoraPhotoCatalog.privateDisplayAllowed(privateID,flags:flags,authenticated:false,active:true))
        XCTAssertFalse(NoraPhotoCatalog.privateDisplayAllowed(privateID,flags:flags,authenticated:true,active:false))
        flags.remove("nora-photo-journal")
        XCTAssertFalse(NoraPhotoCatalog.privateDisplayAllowed(privateID,flags:flags,authenticated:true,active:true))
        XCTAssertFalse(NoraPhotoCatalog.privateDisplayAllowed("Nora_Photo_01",flags:flags,authenticated:true,active:true))
    }

    func testApprovedPhotoCollectionsDecodeAndProduceSamples() throws {
        let originals=(1...29).filter{$0 != 6}.map{String(format:"Recovered_B27_%02d",$0)}
        let archive=(1...11).map{String(format:"Nora_Archive_%02d",$0)}
        let camera=NoraPhotoCatalog.photos.map(\.id)
        let all=originals+archive+camera+VeilArchive.homeAssets
        XCTAssertEqual(Set(all).count,69)
        XCTAssertEqual(all.count,69)
        XCTAssertNil(PortraitImages.load("Recovered_B27_06"))
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
