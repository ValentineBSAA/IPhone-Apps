import XCTest
@testable import LastSeen

@MainActor final class Build33AccountHistoryTests:XCTestCase {
    func testSocialSessionsAreIndependentAndWritesRequireSession() throws {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let post=try XCTUnwrap(LumaSocialCatalog.visible(.afterframe,world:w.state).first)
        w.setSocialSignedIn(false,channel:.afterframe)
        XCTAssertFalse(w.socialPreferences(.afterframe).signedIn)
        XCTAssertTrue(w.socialPreferences(.connective).signedIn)
        XCTAssertFalse(w.publishSocial(channel:.afterframe,text:"Signed out"))
        XCTAssertFalse(w.commentSocial(postID:post.id,channel:.afterframe,text:"Signed out"))
        w.toggleSocial(.like,postID:post.id,channel:.afterframe)
        XCTAssertFalse(w.connected.likes.contains(post.id))
        XCTAssertTrue(w.publishSocial(channel:.connective,text:"Other account"))
        w.setSocialSignedIn(true,channel:.afterframe)
        XCTAssertTrue(w.commentSocial(postID:post.id,channel:.afterframe,text:"Restored session"))
        XCTAssertEqual(w.connected.comments.last?.author,RestoredPhoneBackup.ownerName)
    }
    func testHistoricalMailIsReadAndThreaded() throws {
        let world=RestoredPhoneBackup.snapshot()
        let records=LumaMailCatalog.visible(world).filter{$0.id.hasPrefix("years-mail-")}
        XCTAssertEqual(records.count,16)
        XCTAssertFalse(records.contains{LumaMailCatalog.isUnread($0,read:[])})
        let item=try XCTUnwrap(records.first)
        let thread=LumaMailCatalog.thread(item,in:world)
        XCTAssertEqual(thread.count,2)
        XCTAssertEqual(Set(thread.map(\.peer)),[item.peer])
        XCTAssertTrue(thread.first!.date<thread.last!.date)
    }
    func testEncodedAnonymousAddressesCannotResolveInPublicBrowser() {
        for raw in ["EXAMPLE.ONION","example%252eonion","veil:%2f%2fmedia","http://something.invalid/directory"] {
            XCTAssertTrue(LumaWebCatalog.restrictedAddress(raw))
            XCTAssertNil(LumaWebCatalog.page(raw))
            XCTAssertTrue(LumaWebCatalog.search(raw,flags:[]).isEmpty)
        }
    }
}
