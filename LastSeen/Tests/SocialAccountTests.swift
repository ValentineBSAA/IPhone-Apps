import XCTest
@testable import LastSeen

@MainActor final class SocialAccountTests: XCTestCase {
    func testPlatformSpecificFeedsAndSearch() throws {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let photoRows=LumaSocialCatalog.feed(.afterframe,world:w.state,filter:"Photos")
        XCTAssertFalse(photoRows.isEmpty)
        XCTAssertTrue(photoRows.allSatisfy{LumaSocialCatalog.visiblePhoto($0.post,world:w.state) != nil})
        let studio=LumaSocialCatalog.feed(.connective,world:w.state,filter:"Studio")
        XCTAssertFalse(studio.isEmpty)
        XCTAssertTrue(studio.allSatisfy{["Blue Hour Interactive","Nora Bennett","Adrian Cole","Tessa Reed"].contains($0.post.author)})
        let discussions=LumaSocialCatalog.feed(.commonGround,world:w.state,filter:"Discussions")
        XCTAssertFalse(discussions.isEmpty)
        XCTAssertTrue(discussions.allSatisfy{$0.commentCount>0})
        for channel in LumaSocialChannel.allCases {
            let rows=LumaSocialCatalog.feed(channel,world:w.state)
            XCTAssertEqual(rows.map(\.id),LumaSocialCatalog.visible(channel,world:w.state).map(\.id))
            for row in rows.prefix(5) {
                XCTAssertEqual(row.commentCount,LumaSocialCatalog.comments(row.id,channel:channel,world:w.state).count)
            }
        }
        let row=try XCTUnwrap(LumaSocialCatalog.feed(.afterframe,world:w.state,query:"  @iris.vale ").first)
        XCTAssertEqual(row.post.handle,"iris.vale")
        w.toggleSocial(.save,postID:row.id,channel:.afterframe)
        w.toggleSocial(.follow,postID:row.id,channel:.afterframe)
        XCTAssertTrue(LumaSocialCatalog.feed(.afterframe,world:w.state,filter:"Following").contains{$0.id==row.id})
        w.toggleSocialMute(row.post.author,channel:.afterframe)
        XCTAssertFalse(LumaSocialCatalog.feed(.afterframe,world:w.state).contains{$0.id==row.id})
        XCTAssertFalse(LumaSocialCatalog.feed(.afterframe,world:w.state,filter:"Following").contains{$0.id==row.id})
        XCTAssertTrue(LumaSocialCatalog.feed(.afterframe,world:w.state,filter:"Saved").contains{$0.id==row.id})
        var revoked=w.state
        revoked.everydayArchiveRevision=nil
        XCTAssertTrue(LumaSocialCatalog.feed(.afterframe,world:revoked,filter:"Saved").isEmpty)
    }

    func testIndependentCommunityAndPersistentPreferences() throws {
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let posts = LumaSocialCommunity.posts(anchor: w.state.createdAt)
        XCTAssertEqual(Set(posts.map(\.author)).count, 100)
        XCTAssertEqual(Set(posts.map(\.handle)).count, 100)
        XCTAssertEqual(posts.count, 200)
        XCTAssertEqual(Set(posts.map(\.id)).count, 200)
        XCTAssertEqual(posts.filter { LumaSocialCommunity.identityMark(for: $0) != nil }.count, 128)
        let expected: [LumaSocialChannel: Int] = [.afterframe: 21, .connective: 21, .commonGround: 22]
        for channel in LumaSocialChannel.allCases {
            XCTAssertEqual(Set(posts.filter { $0.channel == channel && LumaSocialCommunity.identityMark(for: $0) != nil }.map(\.handle)).count, expected[channel])
        }
        let author = try XCTUnwrap(posts.first?.author)
        w.toggleSocialMute(author, channel: .afterframe)
        XCTAssertTrue(w.socialPreferences(.afterframe).mutedAuthors.contains(author))
        XCTAssertFalse(w.socialPreferences(.connective).mutedAuthors.contains(author))
        var prefs = w.socialPreferences(.afterframe)
        prefs.notificationsEnabled = false
        w.setSocialPreferences(prefs, channel: .afterframe)
        let saved = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(w.state))
        let restored = PhoneWorldStore(initial: saved, persistToDisk: false)
        XCTAssertEqual(restored.socialPreferences(.afterframe), prefs)
        w.toggleSocialMute("Nora Bennett", channel: .afterframe)
        XCTAssertFalse(w.socialPreferences(.afterframe).mutedAuthors.contains("Nora Bennett"))
        w.toggleSocialMute(author, channel: .afterframe)
        XCTAssertFalse(w.socialPreferences(.afterframe).mutedAuthors.contains(author))
    }
}
