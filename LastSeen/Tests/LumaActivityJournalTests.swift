import XCTest
@testable import LastSeen

@MainActor final class LumaActivityJournalTests: XCTestCase {
    func testLocalReplyDeliveryAndDismissalPersist() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        let post = try XCTUnwrap(LumaSocialCatalog.visible(.afterframe, world: w.state).first { $0.id.hasPrefix("b32-community-") })
        XCTAssertTrue(LumaActivityCatalog.visible(w.state).isEmpty)
        XCTAssertTrue(w.commentSocial(postID: post.id, channel: .afterframe, text: "Thank you!", now: now))
        w.advanceSocialReplies(now: now.addingTimeInterval(17))
        XCTAssertTrue(LumaActivityCatalog.visible(w.state).isEmpty)
        w.advanceSocialReplies(now: now.addingTimeInterval(19))
        let notice = try XCTUnwrap(LumaActivityCatalog.visible(w.state).first)
        XCTAssertEqual(notice.kind, .social)
        XCTAssertEqual(notice.targetID, post.id)
        XCTAssertEqual(notice.profile, .social)
        let baseline = LumaActivityCatalog.allIDs(w.state)
        w.advanceSocialReplies(now: now.addingTimeInterval(100))
        XCTAssertTrue(LumaActivityCatalog.newEntries(w.state, previous: baseline).isEmpty)
        w.dismissActivity(notice.id)
        XCTAssertTrue(LumaActivityCatalog.visible(w.state).isEmpty)
        let decoded = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(w.state))
        XCTAssertEqual(LumaActivityCatalog.allIDs(decoded), baseline)
        XCTAssertTrue(LumaActivityCatalog.visible(decoded).isEmpty)
    }
    func testMailAndTimerDeduplication() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        XCTAssertTrue(w.sendConnectedMail(draftID: nil, peer: .adrian, subject: "Review", body: "Hello", now: now))
        w.advanceConnectedMail(now: now.addingTimeInterval(31))
        w.advanceConnectedMail(now: now.addingTimeInterval(60))
        w.recordTimerActivity(end: now.timeIntervalSince1970)
        w.recordTimerActivity(end: now.timeIntervalSince1970)
        XCTAssertEqual(LumaActivityCatalog.visible(w.state).count, 2)
        XCTAssertEqual(Set(LumaActivityCatalog.visible(w.state).map(\.id)).count, 2)
    }
    func testMutedNotificationsDoNotEraseReply() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        let post = try XCTUnwrap(LumaSocialCatalog.visible(.afterframe, world: w.state).first { $0.id.hasPrefix("b32-community-") })
        var prefs = w.socialPreferences(.afterframe)
        prefs.notificationsEnabled = false
        w.setSocialPreferences(prefs, channel: .afterframe)
        XCTAssertTrue(w.commentSocial(postID: post.id, channel: .afterframe, text: "Thanks", now: now))
        w.advanceSocialReplies(now: now.addingTimeInterval(20))
        XCTAssertTrue(LumaActivityCatalog.visible(w.state).isEmpty)
        XCTAssertTrue(w.connected.comments.contains { $0.author == post.author && $0.postID == post.id })
    }
}
