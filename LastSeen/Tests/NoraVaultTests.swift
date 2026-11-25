import XCTest
import UIKit
@testable import LastSeen

@MainActor
final class NoraVaultTests: XCTestCase {
    func testApprovedMediaAndLegacyAliasesLoad() throws {
        let names = NoraPhotoCatalog.photos.map(\.id) + ["Nora_Profile", "Photo_Locked_Texture"]
        XCTAssertEqual(Set(names).count, 16)
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
        XCTAssertEqual(visible(), 3)
        XCTAssertTrue(world.reply(to: .maya, text: world.tutorialChoices[0]))
        world.recordTutorialVisit("note")
        XCTAssertEqual(visible(), 5)
        world.recordTutorialVisit("desk")
        XCTAssertEqual(visible(), 5)
        world.recordTutorialVisit("reservation")
        XCTAssertEqual(visible(), 7)
        world.recordTutorialVisit("journal")
        XCTAssertEqual(visible(), 9)
        let privatePhotos = NoraPhotoCatalog.photos.filter(\.privateAlbum)
        XCTAssertEqual(privatePhotos.count, 5)
        XCTAssertTrue(privatePhotos.allSatisfy { !$0.available(flags: world.state.flags, authenticated: true) })
        let one = privatePhotos[0]
        let flags = world.state.flags.union(["nora-photo-unlocked-" + one.id])
        XCTAssertFalse(one.available(flags: flags))
        XCTAssertTrue(one.available(flags: flags, authenticated: true))
        XCTAssertTrue(privatePhotos.dropFirst().allSatisfy { !$0.available(flags: flags, authenticated: true) })
        world.resetPhoneTutorial()
        XCTAssertEqual(visible(), 9)
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
