import XCTest
import UIKit
@testable import LastSeen

@MainActor final class HavenWatchTests: XCTestCase {
    func testCrossArchiveReviewRequiresOpenedMatchingSources() throws {
        var state=RestoredPhoneBackup.snapshot()
        state.flags.formUnion(["phone-tutorial-finished","web.visited.archive",VeilArchive.discovery])
        let w=PhoneWorldStore(initial:state,persistToDisk:false)
        let kitchen=HavenCamera.kitchen.asset(occupied:false)
        let living=HavenCamera.living.asset(occupied:false)
        let image="image:VEIL_Home_01"
        XCTAssertNil(LumaAssistantEvidence.selected("haven:"+kitchen,in:w.state))
        w.recordHavenSnapshotOpened("invalid")
        XCTAssertFalse(w.state.flags.contains(HavenWatchArchive.marker("invalid")))
        w.recordHavenSnapshotOpened(kitchen)
        w.recordHavenSnapshotOpened(living)
        XCTAssertNotNil(LumaAssistantEvidence.selected("haven:"+kitchen,in:w.state))
        XCTAssertFalse(w.recordHavenCrossArchiveReview(1))
        w.recordVeilCorrespondenceOpened()
        w.inspectVeilReference("board-reference")
        w.recordVeilObservation("Nora_Archive_08")
        for asset in VeilArchive.homeAssets.prefix(2) {
            w.recordVeilObservation(asset)
            XCTAssertTrue(w.completeRecoveredImageAnalysis(asset,source:2,limit:0))
        }
        w.recordVeilThreadOpened("ordinary-hours",packages:"veil",safeMode:false)
        XCTAssertTrue(w.saveEvidenceConnection(image,"veil:thread:ordinary-hours",relation:.wording))
        w.inspectVeilReference(VeilReferences.homeIndexID)
        w.recordVeilHomeIndexOpened()
        for id in VeilCommunity.disputedThreads { w.recordVeilThreadOpened(id,packages:"veil",safeMode:false) }
        XCTAssertTrue(w.recordVeilDispute(0,packages:"veil",safeMode:false))
        XCTAssertTrue(w.saveEvidenceConnection(image,"haven:"+living,relation:.source))
        XCTAssertFalse(HavenCrossArchiveReview.ready(w.state))
        XCTAssertTrue(w.saveEvidenceConnection(image,"haven:"+kitchen,relation:.wording))
        XCTAssertFalse(HavenCrossArchiveReview.ready(w.state))
        XCTAssertTrue(w.saveEvidenceConnection(image,"haven:"+kitchen,relation:.source))
        XCTAssertTrue(HavenCrossArchiveReview.ready(w.state))
        XCTAssertFalse(w.recordHavenCrossArchiveReview(0))
        XCTAssertFalse(w.recordHavenCrossArchiveReview(2))
        XCTAssertTrue(w.recordHavenCrossArchiveReview(1))
        XCTAssertTrue(w.recordHavenCrossArchiveReview(1))
        XCTAssertNotNil(LumaAssistantEvidence.selected("haven:cross-archive",in:w.state))
        XCTAssertFalse(SocialArchiveReview.ready(w.state))
        w.recordSocialArchiveDraftOpened()
        XCTAssertFalse(w.state.flags.contains(SocialArchiveReview.marker))
        w.recordVeilObservation("VEIL_Home_03")
        XCTAssertFalse(w.saveEvidenceConnection(SocialArchiveReview.readingID,"image:VEIL_Home_03",relation:.wording))
        w.recordLumaSocialOpened(.afterframe,postID:"af-04")
        w.recordLumaSocialOpened(.commonGround,postID:"cg-04")
        XCTAssertTrue(w.saveEvidenceConnection(SocialArchiveReview.readingID,"image:VEIL_Home_03",relation:.wording))
        XCTAssertTrue(w.saveEvidenceConnection(SocialArchiveReview.datesID,"veil:home-index",relation:.source))
        XCTAssertFalse(SocialArchiveReview.ready(w.state))
        XCTAssertTrue(w.saveEvidenceConnection(SocialArchiveReview.datesID,"veil:home-index",relation:.chronology))
        XCTAssertTrue(SocialArchiveReview.ready(w.state))
        XCTAssertNil(LumaAssistantEvidence.selected(SocialArchiveReview.recordID,in:w.state))
        w.recordSocialArchiveDraftOpened()
        XCTAssertTrue(SocialArchiveReview.opened(w.state))
        XCTAssertNotNil(LumaAssistantEvidence.selected(SocialArchiveReview.recordID,in:w.state))
        XCTAssertFalse(LumaSocialCatalog.visible(.afterframe,world:w.state).contains{$0.body == SocialArchiveReview.text})
        var restored=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        XCTAssertTrue(SocialArchiveReview.opened(restored))
        restored.flags.remove(LumaAssistantEvidence.socialMarker(.afterframe,"af-04"))
        XCTAssertNil(LumaAssistantEvidence.selected(SocialArchiveReview.recordID,in:restored))
        restored=w.state
        XCTAssertTrue(HavenCrossArchiveReview.reviewed(restored))
        restored.flags.remove(HavenWatchArchive.marker(kitchen))
        XCTAssertFalse(HavenCrossArchiveReview.reviewed(restored))
        XCTAssertNil(LumaAssistantEvidence.selected("haven:cross-archive",in:restored))
        restored=w.state;restored.flags.remove(VeilArchive.discovery)
        XCTAssertFalse(HavenCrossArchiveReview.reviewed(restored))
        XCTAssertNotNil(LumaAssistantEvidence.selected("haven:"+kitchen,in:restored))
    }

    func testArchiveAndPersistentPreferences() throws {
        let base = PhoneWorldStore(persistToDisk: false)
        XCTAssertTrue(HavenWatchArchive.frames(in: base.state).isEmpty)
        let world = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let frames = HavenWatchArchive.frames(in: world.state)
        XCTAssertEqual(frames.count, 10)
        XCTAssertEqual(Set(frames.map(\.id)).count, 10)
        for camera in HavenCamera.allCases {
            XCTAssertEqual(frames.filter { $0.camera == camera }.count, 2)
        }
        for frame in frames {
            XCTAssertNotNil(UIImage(named: frame.id, in: Bundle(for: PhoneWorldStore.self), compatibleWith: nil), frame.id)
        }
        XCTAssertNotNil(UIImage(named: "Icon_HavenWatch", in: Bundle(for: PhoneWorldStore.self), compatibleWith: nil))
        var prefs = HavenWatchPreferences()
        prefs.armed = true; prefs.infrared = true
        prefs.favorites = [frames[0].id, "invalid"]
        world.setHavenWatch(prefs)
        let restored = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(world.state))
        XCTAssertEqual(restored.connectedWorld?.havenWatch?.favorites, Set([frames[0].id]))
        XCTAssertEqual(restored.connectedWorld?.havenWatch?.armed, true)
        XCTAssertEqual(restored.connectedWorld?.havenWatch?.infrared, true)
        XCTAssertEqual(restored.flags, world.state.flags)
    }
}
