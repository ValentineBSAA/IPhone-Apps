import XCTest
import UIKit
@testable import LastSeen

@MainActor
final class NoraVaultTests: XCTestCase {
    func testApprovedMediaAndLegacyAliasesLoad() throws {
        let names = NoraPhotoCatalog.photos.map(\.id) + ["Nora_Profile", "Photo_Locked_Texture"]
        XCTAssertEqual(Set(names).count, 26)
        XCTAssertEqual(NoraPhotoCatalog.photos.filter{$0.id.hasPrefix("WorldPhoto_E01_")}.count,10)
        for name in names {
            let photo = try XCTUnwrap(PortraitImages.load(name), name)
            XCTAssertGreaterThan(photo.size.width, 200)
        }
        let approved = try XCTUnwrap(PortraitImages.load("Nora_Profile")?.pngData())
        for index in 1...4 {
            XCTAssertEqual(PortraitImages.load(String(format: "Contact_Nora_%02d", index))?.pngData(), approved)
        }
        XCTAssertEqual(RestoredPhoneBackup.ownerPortrait, "Nora_Profile")
    }

    func testDiscoveryGatesAndReplay() {
        let world = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        world.startPhoneTutorial()
        func visible() -> Int {
            NoraPhotoCatalog.photos.filter { $0.available(flags: world.state.flags) }.count
        }
        XCTAssertEqual(visible(), 13)
        XCTAssertTrue(world.reply(to: .maya, text: world.tutorialChoices[0]))
        world.recordTutorialVisit("note")
        XCTAssertEqual(visible(), 15)
        world.recordTutorialVisit("desk")
        XCTAssertEqual(visible(), 15)
        world.recordTutorialVisit("reservation")
        XCTAssertEqual(visible(), 17)
        world.recordTutorialVisit("journal")
        XCTAssertEqual(visible(), 19)
        let privatePhotos = NoraPhotoCatalog.photos.filter(\.privateAlbum)
        XCTAssertEqual(privatePhotos.count, 5)
        XCTAssertTrue(privatePhotos.allSatisfy { !$0.available(flags: world.state.flags, authenticated: true) })
        let one = privatePhotos[0]
        let flags = world.state.flags.union(["nora-photo-unlocked-" + one.id])
        XCTAssertFalse(one.available(flags: flags))
        XCTAssertTrue(one.available(flags: flags, authenticated: true))
        XCTAssertTrue(privatePhotos.dropFirst().allSatisfy { !$0.available(flags: flags, authenticated: true) })
        world.resetPhoneTutorial()
        XCTAssertEqual(visible(), 19)
    }

    func testPrivateRecoveryRequiresAuthenticatedSessionAndEarnedRecords() throws {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        XCTAssertFalse(w.recoverPrivatePhoto("Nora_Photo_10",authenticated:true))
        w.startPhoneTutorial()
        XCTAssertTrue(w.reply(to:.maya,text:w.tutorialChoices[0]))
        for id in ["note","desk","reservation","journal"] {w.recordTutorialVisit(id)}
        XCTAssertFalse(w.recoverPrivatePhoto("Nora_Photo_10",authenticated:false))
        XCTAssertTrue(w.recoverPrivatePhoto("Nora_Photo_10",authenticated:true))
        XCTAssertFalse(w.recoverPrivatePhoto("Nora_Photo_11",authenticated:true))
        w.visitWebRecord("studio")
        w.visitWebRecord("archive")
        let asset=try XCTUnwrap(LumaWebCatalog.page("archive-records")?.images.first)
        w.inspectWebAttachment(asset)
        XCTAssertFalse(w.state.flags.contains("web.inspected."+asset))
        w.visitWebRecord("archive-records")
        w.inspectWebAttachment(asset)
        XCTAssertTrue(w.recoverPrivatePhoto("Nora_Photo_11",authenticated:true))
        XCTAssertTrue(w.recoverPrivatePhoto("Nora_Collage_01",authenticated:true))
        XCTAssertFalse(w.recoverPrivatePhoto("Nora_Photo_12",authenticated:true))
        w.visitWebRecord("archive-review")
        w.visitWebRecord("studio-news")
        XCTAssertTrue(w.submitWebReview("A copy may have a different import date from its original capture."))
        w.visitWebRecord("archive-collection")
        w.visitWebRecord("archive-ledger")
        XCTAssertTrue(w.recoverPrivatePhoto("Nora_Photo_12",authenticated:true))
        XCTAssertTrue(w.recoverPrivatePhoto("Nora_Collage_02",authenticated:true))
        XCTAssertFalse(w.recoverPrivatePhoto("unknown",authenticated:true))
        XCTAssertFalse(w.recoverPrivatePhoto("Nora_Photo_01",authenticated:true))
        let restored=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        for item in NoraPhotoCatalog.photos.filter(\.privateAlbum) {
            XCTAssertTrue(item.available(flags:restored.flags,authenticated:true))
            XCTAssertFalse(item.available(flags:restored.flags,authenticated:false))
            XCTAssertNil(RecoveredImageAnalysis.record(item.id,in:restored))
            XCTAssertNil(LumaAssistantEvidence.selected("image:"+item.id,in:restored))
        }
    }

    func testReactiveMessagesAndReceiptPersistence() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("world.json")
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        try RestoredPhoneBackup.restore(to: url, now: now)
        let world = PhoneWorldStore(storageURL: url)
        world.startPhoneTutorial(now: now)
        let text = "  I used a jailbreak.  "
        XCTAssertTrue(world.sendReactive(to: .maya, text: text, now: now))
        XCTAssertEqual(world.messages(.maya).last?.text, text)
        XCTAssertNil(world.messages(.maya).last?.recipientReadAt)
        world.markRead(.maya)
        XCTAssertNil(world.messages(.maya).last?.recipientReadAt)
        world.advancePendingReplies(now: now.addingTimeInterval(1))
        XCTAssertNotNil(world.messages(.maya).last?.recipientReadAt)
        XCTAssertTrue(world.isTyping(.maya, now: now.addingTimeInterval(1)))
        let resumed = PhoneWorldStore(storageURL: url)
        resumed.advancePendingReplies(now: now.addingTimeInterval(8))
        XCTAssertTrue(resumed.messages(.maya).last?.text.contains("jailbreak") == true)
        XCTAssertFalse(resumed.state.flags.contains("phone-tutorial-replied"))
        XCTAssertFalse(resumed.hasPendingReply(.maya))
        let count = resumed.messages(.maya).count
        resumed.advancePendingReplies(now: now.addingTimeInterval(10))
        XCTAssertEqual(resumed.messages(.maya).count, count)
        XCTAssertTrue(resumed.sendReactive(to: .maya, text: "I'm the repair technician.", now: now.addingTimeInterval(11)))
        resumed.advancePendingReplies(now: now.addingTimeInterval(20))
        XCTAssertTrue(resumed.state.flags.contains("phone-tutorial-replied"))
        XCTAssertFalse(resumed.state.flags.contains("nora-photo-notes"))
        XCTAssertTrue(resumed.sendReactive(to: .denise, text: "banana spaceship", now: now.addingTimeInterval(21)))
        resumed.advancePendingReplies(now: now.addingTimeInterval(30))
        XCTAssertTrue(resumed.messages(.denise).last?.text.contains("clarify") == true)
        XCTAssertFalse(resumed.sendReactive(to: .maya, text: "   "))
    }

    func testBannerRouting() {
        XCTAssertFalse(PhoneConversationPresentation.shouldShowBanner(for: .maya, visible: .maya, locked: false, covered: false))
        XCTAssertTrue(PhoneConversationPresentation.shouldShowBanner(for: .denise, visible: .maya, locked: false, covered: false))
        XCTAssertTrue(PhoneConversationPresentation.shouldShowBanner(for: .maya, visible: nil, locked: false, covered: false))
        XCTAssertFalse(PhoneConversationPresentation.shouldShowBanner(for: .maya, visible: nil, locked: true, covered: false))
    }
}
