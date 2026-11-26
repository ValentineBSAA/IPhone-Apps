import XCTest
@testable import LastSeen

@MainActor final class CommunityActivityTests: XCTestCase {
    func testRebasedCommunityReplyNeverPredatesItsParent() throws {
        let start=Date(timeIntervalSince1970:1_800_000_000)
        let release=try XCTUnwrap(LumaCommunityActivity.releases.first)
        let post=try XCTUnwrap(LumaCommunityActivity.post(release,start:start))
        let rebased=start.addingTimeInterval(-500)
        let reply=try XCTUnwrap(LumaCommunityActivity.reply(release,post:post,start:rebased))
        XCTAssertEqual(reply.date,post.date.addingTimeInterval(release.replyDelay))
        var state=RestoredPhoneBackup.snapshot(now:start)
        var connected=state.connectedWorld ?? LumaConnectedState()
        connected.communityActivity=LumaCommunityActivityState(start:rebased,posts:[post])
        state.connectedWorld=connected
        let w=PhoneWorldStore(initial:state,persistToDisk:false)
        w.advanceCommunityActivity(now:post.date)
        XCTAssertFalse(w.connected.communityActivity?.comments.contains(where:{$0.postID==post.id}) ?? true)
        w.advanceCommunityActivity(now:reply.date)
        XCTAssertEqual(w.connected.communityActivity?.comments.filter{$0.postID==post.id},[reply])
    }

    func testPendingSocialReplyReservesCapacityAndSurvivesTemporaryArchiveLoss() throws {
        let now=Date(timeIntervalSince1970:1_800_000_000)
        var state=RestoredPhoneBackup.snapshot(now:now)
        let post=try XCTUnwrap(LumaSocialCatalog.visible(.afterframe,world:state).first{$0.handle=="iris.vale"})
        var connected=state.connectedWorld ?? LumaConnectedState()
        let reply=LumaSocialComment(id:"fixture-pending",postID:post.id,author:post.author,body:"Thanks for the comment.",date:now)
        connected.pendingSocialReplies=[.init(channel:.afterframe,reply:reply,dueAt:now)]
        connected.comments=(0..<299).map{.init(id:"fixture-\($0)",postID:post.id,author:"Repair desk",body:"Fixture",date:now)}
        state.connectedWorld=connected
        let w=PhoneWorldStore(initial:state,persistToDisk:false)
        XCTAssertFalse(w.commentSocial(postID:post.id,channel:.afterframe,text:"Another comment",now:now))
        w.advanceSocialReplies(now:now)
        XCTAssertEqual(w.connected.comments.count,300)
        XCTAssertEqual(w.connected.comments.filter{$0.id==reply.id}.count,1)
        XCTAssertTrue((w.connected.pendingSocialReplies ?? []).isEmpty)
        var revoked=state
        revoked.everydayArchiveRevision=nil
        let locked=PhoneWorldStore(initial:revoked,persistToDisk:false)
        locked.advanceSocialReplies(now:now)
        XCTAssertEqual(locked.connected.pendingSocialReplies?.first?.reply.id,reply.id)
    }

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
