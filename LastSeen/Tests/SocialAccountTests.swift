import XCTest
@testable import LastSeen

@MainActor final class SocialAccountTests: XCTestCase {
    func testIndependentCommunityAndPersistentPreferences() throws {
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let posts = LumaSocialCommunity.posts(anchor: w.state.createdAt)
        XCTAssertEqual(Set(posts.map(\.author)).count, 36)
        XCTAssertEqual(Set(posts.map(\.handle)).count, 36)
        XCTAssertEqual(posts.count, 72)
        XCTAssertEqual(Set(posts.map(\.id)).count, 72)
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
