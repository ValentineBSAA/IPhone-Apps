import XCTest
@testable import LastSeen

@MainActor final class RecoveredImageAnalysisTests:XCTestCase {
    func testInspectionSessionRejectsInactiveRevokedAndSameRecordRestore() throws {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let asset="Nora_Photo_01"
        w.recordCameraAnalysisOpened(asset)
        let epoch=w.checkpointEpoch
        func current(_ source:RecoveredImageAnalysis.Source? = .cameraRoll,_ active:Bool=true)->Bool {
            RecoveredImageAnalysis.inspectionCurrent(asset,source:source,epoch:epoch,
                currentEpoch:w.checkpointEpoch,active:active,in:w.state)
        }
        XCTAssertTrue(current())
        XCTAssertFalse(current(.browser))
        XCTAssertFalse(current(nil))
        XCTAssertFalse(current(.cameraRoll,false))
        var revoked=w.state
        revoked.flags.remove(RecoveredImageAnalysis.cameraMarker(asset))
        XCTAssertFalse(RecoveredImageAnalysis.inspectionCurrent(asset,source:.cameraRoll,epoch:epoch,currentEpoch:epoch,active:true,in:revoked))
        try w.restoreCheckpoint(w.state)
        XCTAssertNotNil(RecoveredImageAnalysis.record(asset,in:w.state))
        XCTAssertFalse(current())
        XCTAssertTrue(RecoveredImageAnalysis.inspectionCurrent(asset,source:.cameraRoll,epoch:w.checkpointEpoch,currentEpoch:w.checkpointEpoch,active:true,in:w.state))
    }

    func testImageReviewOverviewAndContextualResponses() throws {
        var initial=RestoredPhoneBackup.snapshot()
        initial.flags.formUnion(["phone-tutorial-finished","investigation.contact.received","web.visited.archive",VeilArchive.discovery])
        let w=PhoneWorldStore(initial:initial,persistToDisk:false)
        let asset="VEIL_Home_01"
        func answer(_ prompt:String,_ state:PhoneWorld)->String {
            let c=LumaAssistantContext(world:state,availableApps:[.messages,.veil],wifi:false,sound:false,haptics:false,safeMode:false,installedCount:1,timerEnd:0,now:state.createdAt)
            return LumaAssistantConversation.reply(prompt,context:c,evidenceID:"image:"+asset).answer.text
        }
        XCTAssertEqual(RecoveredImageAnalysis.reviewOverview(w.state).opened,0)
        w.recordVeilCorrespondenceOpened()
        w.recordVeilObservation("Nora_Archive_08")
        w.recordVeilObservation(asset)
        XCTAssertTrue(answer("What about the shadow?",w.state).contains("haven't received"))
        XCTAssertTrue(answer("What about the contrast?",w.state).contains("don't have a recorded light-scan"))
        XCTAssertTrue(answer("What about the matching details?",w.state).contains("don't have a recorded visible-detail match"))
        XCTAssertTrue(w.completeRecoveredImageAnalysis(asset,source:2,limit:0))
        XCTAssertTrue(w.recordImageInterpretation(asset,mode:.echo,region:2))
        XCTAssertTrue(answer("What about the shadow?",w.state).contains("vague upright shadow"))
        XCTAssertFalse(answer("What about the contrast?",w.state).contains("vague upright shadow"))
        w.recordVeilObservation("VEIL_Home_03")
        XCTAssertTrue(w.recordPhotoFeatureMatch("home-counter",first:4,second:7))
        XCTAssertTrue(answer("What about the matching details?",w.state).contains("white kitchen island"))
        let overview=RecoveredImageAnalysis.reviewOverview(w.state)
        XCTAssertEqual(overview.opened,3)
        XCTAssertEqual(overview.reviewed,1)
        XCTAssertEqual(overview.light,0)
        XCTAssertEqual(overview.matched,1)
        XCTAssertEqual(overview.interpretive,1)
        XCTAssertTrue(answer("image investigation progress",w.state).contains("1 synthetic interpretations"))
        var restored=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        XCTAssertEqual(RecoveredImageAnalysis.reviewOverview(restored).matched,1)
        restored.flags.remove("veil.viewed.VEIL_Home_03")
        XCTAssertEqual(RecoveredImageAnalysis.reviewOverview(restored).matched,0)
        XCTAssertTrue(answer("What about the matching details?",restored).contains("don't have a recorded visible-detail match"))
        restored.flags.remove(VeilArchive.discovery)
        XCTAssertEqual(RecoveredImageAnalysis.reviewOverview(restored).opened,0)
        XCTAssertEqual(RecoveredImageAnalysis.reviewOverview(restored).interpretive,0)
        XCTAssertFalse(answer("What about the shadow?",restored).contains("vague upright shadow"))
    }

    func testRecurringDetailChallengesRequireBothOpenedOriginals() throws {
        var state=RestoredPhoneBackup.snapshot()
        state.flags.formUnion(["phone-tutorial-finished","web.visited.archive",VeilArchive.discovery])
        let w=PhoneWorldStore(initial:state,persistToDisk:false)
        XCTAssertTrue(PhotoFeatureMatch.available(w.state).isEmpty)
        XCTAssertFalse(w.recordPhotoFeatureMatch("home-counter",first:4,second:7))
        w.recordVeilCorrespondenceOpened()
        w.recordVeilObservation("Nora_Archive_08")
        w.recordVeilObservation("VEIL_Home_01")
        XCTAssertTrue(PhotoFeatureMatch.available(w.state).isEmpty)
        w.recordVeilObservation("VEIL_Home_03")
        XCTAssertEqual(PhotoFeatureMatch.available(w.state).map(\.id),["home-counter"])
        XCTAssertEqual(PhotoFeatureMatch.challenge("image:VEIL_Home_03","image:VEIL_Home_01",in:w.state)?.id,"home-counter")
        XCTAssertNil(PhotoFeatureMatch.challenge("image:VEIL_Home_01","image:VEIL_Home_01",in:w.state))
        XCTAssertFalse(w.recordPhotoFeatureMatch("home-counter",first:0,second:7))
        XCTAssertFalse(w.recordPhotoFeatureMatch("home-counter",first:4,second:0))
        XCTAssertFalse(w.recordPhotoFeatureMatch("home-counter",first:-1,second:9))
        XCTAssertFalse(w.recordPhotoFeatureMatch("not-a-challenge",first:4,second:7))
        XCTAssertTrue(w.recordPhotoFeatureMatch("home-counter",first:4,second:7))
        XCTAssertTrue(w.recordPhotoFeatureMatch("home-counter",first:7,second:8))
        XCTAssertEqual(w.connected.photoFeatureMatches,Set(["home-counter"]))
        XCTAssertTrue(LumaAssistantEvidence.selected("image:VEIL_Home_03",in:w.state)?.excerpts.contains(where:{$0.contains("Recorded visible-detail comparison")}) ?? false)
        w.recordVeilObservation("VEIL_Home_02")
        XCTAssertTrue(w.completeRecoveredImageAnalysis("VEIL_Home_01",source:2,limit:0))
        XCTAssertTrue(w.completeRecoveredImageAnalysis("VEIL_Home_02",source:2,limit:0))
        w.recordVeilObservation("VEIL_Home_05")
        w.recordVeilObservation("VEIL_Home_06")
        XCTAssertEqual(PhotoFeatureMatch.available(w.state).count,3)
        XCTAssertTrue(w.recordPhotoFeatureMatch("home-table",first:7,second:8))
        XCTAssertTrue(w.recordPhotoFeatureMatch("home-seating",first:3,second:6))
        var restored=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        XCTAssertEqual(PhotoFeatureMatch.available(restored).filter{PhotoFeatureMatch.completed($0,in:restored)}.count,3)
        restored.flags.remove("veil.viewed.VEIL_Home_05")
        XCTAssertFalse(PhotoFeatureMatch.available(restored).contains{$0.id=="home-table"})
        XCTAssertFalse(PhotoFeatureMatch.notes("VEIL_Home_02",in:restored).contains{$0.contains("wooden coffee table")})
        restored.flags.remove(VeilArchive.discovery)
        XCTAssertTrue(PhotoFeatureMatch.available(restored).isEmpty)
        XCTAssertTrue(PhotoFeatureMatch.notes("VEIL_Home_01",in:restored).isEmpty)
    }

    func testFeatureSelectionRejectsStaleEpochAndUnavailableChallenge() {
        let world=RestoredPhoneBackup.snapshot()
        let epoch=UUID()
        XCTAssertFalse(PhotoFeatureMatch.selectionCurrent("home-counter",epoch:nil,currentEpoch:epoch,active:true,in:world))
        XCTAssertFalse(PhotoFeatureMatch.selectionCurrent("home-counter",epoch:UUID(),currentEpoch:epoch,active:true,in:world))
        XCTAssertFalse(PhotoFeatureMatch.selectionCurrent("home-counter",epoch:epoch,currentEpoch:epoch,active:false,in:world))
        XCTAssertFalse(PhotoFeatureMatch.selectionCurrent("missing-challenge",epoch:epoch,currentEpoch:epoch,active:true,in:world))
    }
    func testAdditionalOriginalsRequireEarnedPagesAndBothInspections() throws {
        var world=RestoredPhoneBackup.snapshot()
        let pair=["Recovered_B27_23","Recovered_B27_25"]
        let gate:Set<String>=["phone-tutorial-finished","web.visited.studio","investigation.contact.received","web.visited.archive","web.visited.archive-collection","investigation.chapter2.reviewed","web.visited.archive-ledger"]
        XCTAssertFalse(LumaWebCatalog.page("archive-copy-pair")?.available(world.flags) ?? true)
        world.flags.formUnion(gate)
        XCTAssertTrue(LumaWebCatalog.page("archive-copy-pair")?.available(world.flags) ?? false)
        let store=PhoneWorldStore(initial:world,persistToDisk:false)
        store.inspectWebAttachment(pair[0])
        XCTAssertNil(RecoveredImageAnalysis.record(pair[0],in:store.state))
        store.visitWebRecord("archive-copy-pair")
        store.inspectWebAttachment(pair[0])
        XCTAssertFalse(store.recordPhotoFeatureMatch("archive-door-locks",first:4,second:4))
        store.inspectWebAttachment(pair[1])
        XCTAssertFalse(store.recordPhotoFeatureMatch("archive-door-locks",first:0,second:4))
        XCTAssertTrue(store.recordPhotoFeatureMatch("archive-door-locks",first:4,second:4))
        XCTAssertTrue(LumaAssistantEvidence.selected("image:"+pair[0],in:store.state)?.excerpts.contains{$0.contains("Recorded visible-detail comparison")} ?? false)
        XCTAssertTrue(store.completeRecoveredImageAnalysis(pair[1],source:1,limit:0))
        XCTAssertNotNil(ImageInterpretation.available(pair[1],mode:.scanlines,in:store.state))
        var restored=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(store.state))
        restored.flags.remove("web.visited.archive-ledger")
        XCTAssertNil(RecoveredImageAnalysis.record(pair[0],in:restored))
        XCTAssertFalse(PhotoFeatureMatch.available(restored).contains{$0.id=="archive-door-locks"})
        XCTAssertNil(LumaAssistantEvidence.selected("image:"+pair[0],in:restored))
        XCTAssertTrue(pair.allSatisfy{PortraitImages.load($0) != nil})
    }
    func testReviewedEverydayExpansionPhotosAreOrdinaryRecords() throws {
        let store=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let ids=(1...10).map{String(format:"WorldPhoto_E01_%02d",$0)}
        for id in ids {
            XCTAssertTrue(NoraPhotoCatalog.library(store.state.flags,filter:.recovered).contains{$0.id==id})
            XCTAssertNil(RecoveredImageAnalysis.record(id,in:store.state))
            XCTAssertNotNil(PortraitImages.load(id))
            store.recordCameraAnalysisOpened(id)
            XCTAssertTrue(store.completeRecoveredImageAnalysis(id,source:0,limit:0))
            XCTAssertTrue(LumaAssistantEvidence.selected("image:"+id,in:store.state)?.excerpts.contains{$0.hasPrefix("Visible scene:")} ?? false)
        }
        XCTAssertEqual(Set(NoraPhotoCatalog.photos.filter{$0.id.hasPrefix("WorldPhoto_E01_")}.map(\.id)),Set(ids))
        XCTAssertFalse(NoraPhotoCatalog.photos.contains{$0.id=="WorldPhoto_E01_11"})
        XCTAssertEqual(NoraPhotoCatalog.library(store.state.flags,filter:.favorites,favorites:Set(ids)).map(\.id),ids)
    }
    func testSceneStudiesRemainOptionalAndHeldArtIsUnlisted() throws {
        let store=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let page=try XCTUnwrap(LumaWebCatalog.page("studio-scene-studies"))
        XCTAssertFalse(page.available(store.state.flags))
        store.visitWebRecord("studio-projects")
        store.visitWebRecord("studio-reference-gallery")
        XCTAssertTrue(page.available(store.state.flags))
        store.inspectWebAttachment("Recovered_B27_04")
        XCTAssertNil(RecoveredImageAnalysis.record("Recovered_B27_04",in:store.state))
        store.visitWebRecord(page.id)
        for id in page.images {
            XCTAssertNotNil(PortraitImages.load(id))
            store.inspectWebAttachment(id)
            XCTAssertNotNil(RecoveredImageAnalysis.record(id,in:store.state))
            XCTAssertTrue(LumaAssistantEvidence.selected("image:"+id,in:store.state)?.excerpts.contains{$0.hasPrefix("Visible scene:")} ?? false)
        }
        XCTAssertEqual(page.images.count,4)
        XCTAssertFalse(LumaWebCatalog.pages.flatMap(\.images).contains("Recovered_B27_06"))
        XCTAssertFalse(VeilArchive.media(store.state).contains("Recovered_B27_06"))
        var revoked=store.state
        revoked.flags.remove("web.visited.studio-reference-gallery")
        XCTAssertNil(RecoveredImageAnalysis.record("Recovered_B27_04",in:revoked))
    }
    func testStudioReferenceGalleriesAndBrandComparison() throws {
        let store=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let ids=["studio-workbench-gallery","studio-environment-gallery","studio-environment-variants"]
        XCTAssertTrue(ids.allSatisfy{LumaWebCatalog.page($0)?.available(store.state.flags)==false})
        store.visitWebRecord("studio-projects")
        store.visitWebRecord("studio-notes")
        store.visitWebRecord("studio-reference-gallery")
        XCTAssertTrue(ids.allSatisfy{LumaWebCatalog.page($0)?.available(store.state.flags)==true})
        let assets=ids.flatMap{LumaWebCatalog.page($0)?.images ?? []}
        XCTAssertEqual(assets.count,10)
        XCTAssertEqual(Set(assets).count,10)
        XCTAssertTrue(assets.allSatisfy{PortraitImages.load($0) != nil && LumaWebCatalog.referenceDescriptions[$0] != nil})
        store.inspectWebAttachment("Recovered_B27_07")
        XCTAssertNil(RecoveredImageAnalysis.record("Recovered_B27_07",in:store.state))
        for id in ids {
            store.visitWebRecord(id)
            for asset in LumaWebCatalog.page(id)?.images ?? [] {store.inspectWebAttachment(asset)}
        }
        XCTAssertFalse(store.recordPhotoFeatureMatch("studio-sign-review",first:0,second:2))
        XCTAssertTrue(store.recordPhotoFeatureMatch("studio-sign-review",first:2,second:0))
        XCTAssertEqual(RecoveredImageAnalysis.visible(store.state).filter{assets.contains($0.id)}.count,10)
        XCTAssertTrue(LumaAssistantEvidence.selected("image:Recovered_B27_09",in:store.state)?.excerpts.contains{$0.contains("Recorded visible-detail comparison")} ?? false)
        var revoked=store.state
        revoked.flags.remove("web.visited.studio-notes")
        XCTAssertFalse(PhotoFeatureMatch.available(revoked).contains{$0.id=="studio-sign-review"})
        XCTAssertNil(LumaAssistantEvidence.selected("image:Recovered_B27_07",in:revoked))
        XCTAssertNotNil(RecoveredImageAnalysis.record("Recovered_B27_19",in:revoked))
    }
    func testRegionalLightPairValidation() {
        let sample=[10,80,220,10,110,220,40,90,160]
        XCTAssertTrue(RecoveredImageAnalysis.validLightPair(sample,dark:0,bright:2))
        XCTAssertTrue(RecoveredImageAnalysis.validLightPair(sample,dark:3,bright:5))
        XCTAssertFalse(RecoveredImageAnalysis.validLightPair(sample,dark:2,bright:0))
        XCTAssertFalse(RecoveredImageAnalysis.validLightPair(sample,dark:0,bright:0))
        XCTAssertFalse(RecoveredImageAnalysis.validLightPair(sample,dark:-1,bright:9))
        XCTAssertFalse(RecoveredImageAnalysis.validLightPair(Array(repeating:10,count:9),dark:0,bright:1))
        XCTAssertFalse(RecoveredImageAnalysis.validLightPair([0,255],dark:0,bright:1))
        XCTAssertFalse(RecoveredImageAnalysis.validLightPair([-1,80,220,10,110,220,40,90,160],dark:0,bright:2))
    }

    func testRegionalLightScanUsesAuthorizedOriginalAndPersistsOnlyCompletion() throws {
        var state=RestoredPhoneBackup.snapshot()
        state.flags.formUnion(["phone-tutorial-finished","web.visited.archive",VeilArchive.discovery])
        let w=PhoneWorldStore(initial:state,persistToDisk:false)
        let asset="Nora_Archive_08"
        XCTAssertFalse(w.recordRegionalLightReview(asset,dark:0,bright:1))
        XCTAssertFalse(w.recordRegionalLightReview("missing-asset",dark:0,bright:1))
        w.recordVeilObservation(asset)
        XCTAssertFalse(w.recordRegionalLightReview(asset,dark:0,bright:1))
        XCTAssertTrue(w.completeRecoveredImageAnalysis(asset,source:2,limit:0))
        let image=try XCTUnwrap(PortraitImages.load(asset))
        let values=try XCTUnwrap(RecoveredImageAnalysis.regionalLight(image))
        XCTAssertEqual(values.count,9)
        XCTAssertTrue(values.allSatisfy{(0...255).contains($0)})
        XCTAssertEqual(RecoveredImageAnalysis.regionalLight(image),values)
        let low=try XCTUnwrap(values.min()),high=try XCTUnwrap(values.max())
        XCTAssertGreaterThan(high,low)
        let dark=try XCTUnwrap(values.firstIndex(of:low)),bright=try XCTUnwrap(values.firstIndex(of:high))
        XCTAssertFalse(w.recordRegionalLightReview(asset,dark:bright,bright:dark))
        XCTAssertNil(RecoveredImageAnalysis.lightNote(asset,in:w.state))
        XCTAssertTrue(w.recordRegionalLightReview(asset,dark:dark,bright:bright))
        XCTAssertTrue(w.recordRegionalLightReview(asset,dark:dark,bright:bright))
        XCTAssertEqual(w.connected.regionalLightReviews,Set([asset]))
        XCTAssertTrue(LumaAssistantEvidence.selected("image:"+asset,in:w.state)?.excerpts.contains(where:{$0.contains("regional light scan completed")}) ?? false)
        var restored=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        XCTAssertNotNil(RecoveredImageAnalysis.lightNote(asset,in:restored))
        restored.connectedWorld?.recoveredImageReviews=[]
        XCTAssertNil(RecoveredImageAnalysis.lightNote(asset,in:restored))
        restored=w.state
        restored.flags.remove(VeilArchive.discovery)
        XCTAssertNil(RecoveredImageAnalysis.lightNote(asset,in:restored))
    }

    func testStagedHomeArchiveRequiresOpenedAndReviewedRecords() throws {
        var state = RestoredPhoneBackup.snapshot()
        state.flags.formUnion(["phone-tutorial-finished","web.visited.archive",VeilArchive.discovery])
        let w = PhoneWorldStore(initial:state,persistToDisk:false)
        XCTAssertEqual(VeilArchive.media(w.state).count,11)
        XCTAssertNil(VeilArchive.mediaTitle("VEIL_Home_01",in:w.state))
        w.recordVeilObservation("VEIL_Home_01")
        XCTAssertNil(RecoveredImageAnalysis.record("VEIL_Home_01",in:w.state))
        w.recordVeilCorrespondenceOpened()
        w.recordVeilObservation("Nora_Archive_08")
        XCTAssertEqual(VeilArchive.media(w.state).count,14)
        XCTAssertEqual(VeilArchive.mediaTitle("VEIL_Home_01",in:w.state),"Recovered photograph 12")
        XCTAssertNil(VeilArchive.mediaTitle("VEIL_Home_04",in:w.state))
        for asset in VeilArchive.homeAssets.prefix(2) {
            XCTAssertFalse(w.completeRecoveredImageAnalysis(asset,source:2,limit:0))
            w.recordVeilObservation(asset)
            XCTAssertTrue(w.completeRecoveredImageAnalysis(asset,source:2,limit:0))
        }
        XCTAssertEqual(VeilArchive.media(w.state).count,17)
        let titles=VeilArchive.media(w.state).compactMap{VeilArchive.mediaTitle($0,in:w.state)}
        XCTAssertEqual(Set(titles).count,17)
        XCTAssertEqual(VeilArchive.mediaTitle("VEIL_Home_01",in:w.state),"Recovered photograph 12")
        XCTAssertEqual(LumaAssistantEvidence.selected("image:VEIL_Home_01",in:w.state)?.title,titles[11])
        w.recordVeilObservation("VEIL_Home_03")
        XCTAssertTrue(w.saveEvidenceConnection("image:VEIL_Home_01","image:VEIL_Home_03",relation:.source))
        XCTAssertTrue(EvidenceConnection.visible(w.state).first?.discussion(in:w.state)?.contains("white kitchen island") ?? false)
        w.recordVeilObservation("VEIL_Home_04")
        XCTAssertTrue(w.completeRecoveredImageAnalysis("VEIL_Home_04",source:2,limit:0))
        XCTAssertTrue(w.recordImageInterpretation("VEIL_Home_04",mode:.scanlines,region:1))
        var restored = try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        XCTAssertEqual(VeilArchive.homeMedia(restored).count,6)
        restored.flags.remove("veil.viewed.VEIL_Home_01")
        XCTAssertEqual(VeilArchive.homeMedia(restored).count,3)
        XCTAssertNil(RecoveredImageAnalysis.record("VEIL_Home_04",in:restored))
        XCTAssertNil(VeilArchive.mediaTitle("VEIL_Home_04",in:restored))
        restored.flags.remove(VeilArchive.discovery)
        XCTAssertTrue(VeilArchive.homeMedia(restored).isEmpty)
        XCTAssertNil(LumaAssistantEvidence.selected("image:VEIL_Home_03",in:restored))
    }

    func testMultiCollectionAndUnlockRoute() throws {
        let store=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        XCTAssertTrue(RecoveredImageAnalysis.visible(store.state).isEmpty)
        store.recordCameraAnalysisOpened("Nora_Photo_01")
        store.recordCameraAnalysisOpened("Nora_Photo_12")
        XCTAssertNotNil(RecoveredImageAnalysis.record("Nora_Photo_01",in:store.state))
        XCTAssertNil(RecoveredImageAnalysis.record("Nora_Photo_12",in:store.state))
        XCTAssertFalse(store.completeRecoveredImageAnalysis("Nora_Photo_01",source:2,limit:0))
        XCTAssertTrue(store.completeRecoveredImageAnalysis("Nora_Photo_01",source:0,limit:0))
        XCTAssertTrue(store.completeRecoveredImageAnalysis("Nora_Photo_01",source:0,limit:0))
        XCTAssertEqual(store.connected.recoveredImageReviews?.count,1)
        var initial=store.state
        initial.flags.insert("phone-tutorial-finished")
        let w=PhoneWorldStore(initial:initial,persistToDisk:false)
        let package=try XCTUnwrap(RelayCatalog.package("veil"))
        let install=RelayChange(package:package,action:.install)
        XCTAssertFalse(RelayPlan.valid([install],sources:RelayCatalog.requiredSourceIDs,installed:[],flags:w.state.flags))
        w.visitWebRecord("studio")
        w.visitWebRecord("archive")
        w.visitWebRecord("veil-guide")
        XCTAssertTrue(VeilArchive.authorized(w.state))
        XCTAssertTrue(RelayPlan.valid([install],sources:RelayCatalog.requiredSourceIDs,installed:[],flags:w.state.flags))
        w.inspectVeilReference("directory-reference")
        XCTAssertNotNil(VeilReferences.target("directory-reference",in:w.state))
        XCTAssertNil(VeilArchive.resolve("boards",in:w.state))
        w.recordVeilCorrespondenceOpened()
        w.inspectVeilReference("board-reference")
        XCTAssertNotNil(VeilReferences.target("board-reference",in:w.state))
        XCTAssertEqual(VeilCommunity.visible(w.state).count,11)
        w.recordVeilObservation("Nora_Archive_08")
        XCTAssertNotNil(RecoveredImageAnalysis.record("Nora_Archive_08",in:w.state))
        XCTAssertTrue(w.completeRecoveredImageAnalysis("Nora_Archive_08",source:2,limit:0))
        XCTAssertNotNil(RecoveredImageAnalysis.summary("Nora_Archive_08",in:w.state))
        w.visitWebRecord("archive-records")
        let image=try XCTUnwrap(LumaWebCatalog.page("archive-records")?.images.first)
        w.inspectWebAttachment(image)
        XCTAssertNotNil(RecoveredImageAnalysis.record(image,in:w.state))
        XCTAssertTrue(w.completeRecoveredImageAnalysis(image,source:1,limit:0))
        let saved=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        XCTAssertEqual(saved.connectedWorld?.recoveredImageReviews?.count,3)
        var revoked=saved
        revoked.flags.remove(VeilArchive.discovery)
        XCTAssertNil(RecoveredImageAnalysis.summary("Nora_Archive_08",in:revoked))
        XCTAssertNil(VeilReferences.target("board-reference",in:revoked))
    }
}
