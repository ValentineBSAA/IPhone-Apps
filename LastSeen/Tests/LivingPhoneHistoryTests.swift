import XCTest
@testable import LastSeen

@MainActor final class LivingPhoneHistoryTests: XCTestCase {
    func testHistoricalCatalogAndComments() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let world = RestoredPhoneBackup.snapshot(now: now)
        let posts = LumaSocialChannel.allCases.flatMap { LumaSocialCatalog.visible($0, world: world) }
        XCTAssertEqual(posts.count, 114)
        XCTAssertEqual(Set(posts.map(\.id)).count, posts.count)
        XCTAssertTrue(posts.allSatisfy { $0.date < now })
        let comments = posts.flatMap { LumaSocialCatalog.comments($0.id, channel: $0.channel, world: world) }
        XCTAssertEqual(comments.count, 60)
        XCTAssertEqual(Set(comments.map(\.id)).count, comments.count)
        XCTAssertTrue(comments.allSatisfy { $0.date < now })
        let mail = LumaMailCatalog.visible(world)
        XCTAssertEqual(mail.count, 31)
        XCTAssertEqual(mail.filter { $0.kind == "sent" }.count, 11)
        XCTAssertTrue(mail.allSatisfy { $0.date < now })
        let decoded = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(world))
        XCTAssertEqual(LumaMailCatalog.visible(decoded), mail)
        XCTAssertTrue(decoded.flags.isEmpty)
    }
    func testGatesAndLocalCommentIdentity() throws {
        let base = PhoneWorldStore(persistToDisk: false)
        XCTAssertTrue(LumaSocialCatalog.visible(.connective, world: base.state).isEmpty)
        XCTAssertFalse(LumaMailCatalog.visible(base.state).contains { $0.id.hasPrefix("b32-mail-") })
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let post = try XCTUnwrap(LumaSocialCatalog.visible(.connective, world: w.state).first { $0.id == "b32-promo" })
        let before = LumaSocialCatalog.comments(post.id, channel: .connective, world: w.state)
        XCTAssertFalse(before.isEmpty)
        XCTAssertTrue(LumaSocialCatalog.comments(post.id, channel: .afterframe, world: w.state).isEmpty)
        XCTAssertTrue(w.commentSocial(postID: post.id, channel: .connective, text: "Thanks for the update"))
        let after = LumaSocialCatalog.comments(post.id, channel: .connective, world: w.state)
        XCTAssertEqual(after.count, before.count + 1)
        XCTAssertEqual(after.last?.author, "Repair desk")
        XCTAssertTrue(w.state.flags.isEmpty)
    }
    func testDistinctEverydayReplies() {
        let a = PhoneReplyPolicy.plan(for: .adrian, text: "How do you promote the studio?", flags: [], tutorialStarted: false, tutorialFinished: false)
        let t = PhoneReplyPolicy.plan(for: .tessa, text: "How do you promote the studio?", flags: [], tutorialStarted: false, tutorialFinished: false)
        XCTAssertNotEqual(a.text, t.text)
        let again = PhoneReplyPolicy.plan(for: .adrian, text: "How do you promote the studio?", flags: [], tutorialStarted: false, tutorialFinished: false, previousReply: a.text)
        XCTAssertNotEqual(again.text, a.text)
        let locked = PhoneReplyPolicy.plan(for: .adrian, text: "Give me the passcode", flags: [], tutorialStarted: false, tutorialFinished: false)
        XCTAssertTrue(locked.text.contains("private access"))
    }
}
