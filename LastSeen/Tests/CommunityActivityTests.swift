import XCTest
@testable import LastSeen

@MainActor final class CommunityActivityTests: XCTestCase {
    func testHistoricalConversationsUseKnownProfiles() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let w = RestoredPhoneBackup.snapshot(now: now)
        let posts = LumaSocialChannel.allCases.flatMap { LumaSocialCatalog.visible($0, world: w) }
        let conversations = posts.flatMap { post in LumaCommunityActivity.historicalComments(for: post) }
        XCTAssertEqual(conversations.count, 24)
        XCTAssertEqual(Set(conversations.map(\.id)).count, 24)
        for comment in conversations {
            let post = try XCTUnwrap(posts.first { $0.id == comment.postID })
            XCTAssertTrue(LumaSocialCommunity.people.contains { $0.name == comment.author && $0.channel == post.channel })
            XCTAssertGreaterThan(comment.date, post.date)
            XCTAssertLessThan(comment.date, now)
        }
    }

    func testLivePublicationAndAlerts() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let base = PhoneWorldStore(persistToDisk: false)
        base.advanceCommunityActivity(now: now)
        XCTAssertNil(base.connected.communityActivity)
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        let first = try XCTUnwrap(LumaSocialCatalog.visible(.afterframe, world: w.state).first { $0.handle == "iris.vale" })
        w.toggleSocial(.follow, postID: first.id, channel: .afterframe)
        w.advanceCommunityActivity(now: now)
        w.advanceCommunityActivity(now: now.addingTimeInterval(74))
        XCTAssertTrue(w.connected.communityActivity?.posts.isEmpty == true)
        w.advanceCommunityActivity(now: now.addingTimeInterval(75))
        let notice = try XCTUnwrap(LumaActivityCatalog.visible(w.state).first { $0.id.hasPrefix("community-post-") })
        XCTAssertEqual(notice.author, "Iris Vale")
        XCTAssertTrue(w.connected.communityActivity?.comments.isEmpty == true)
        w.advanceCommunityActivity(now: now.addingTimeInterval(110))
        XCTAssertEqual(w.connected.communityActivity?.comments.count, 1)
        w.toggleSocial(.follow, postID: first.id, channel: .afterframe)
        XCTAssertFalse(notice.canPresent(in: w.state))
        w.toggleSocial(.follow, postID: first.id, channel: .afterframe)
        XCTAssertFalse(LumaActivityCatalog.visible(w.state).contains { $0.id == notice.id })
        w.advanceCommunityActivity(now: now.addingTimeInterval(660))
        w.advanceCommunityActivity(now: now.addingTimeInterval(900))
        XCTAssertEqual(w.connected.communityActivity?.posts.count, 6)
        XCTAssertEqual(w.connected.communityActivity?.comments.count, 6)
        XCTAssertEqual((w.connected.activityJournal ?? []).filter { $0.id.hasPrefix("community-post-") }.count, 1)
        XCTAssertEqual(try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(w.state)).connectedWorld?.communityActivity, w.connected.communityActivity)
        XCTAssertTrue(w.state.flags.isEmpty)
    }
}
