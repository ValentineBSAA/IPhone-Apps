import XCTest
@testable import LastSeen

@MainActor final class VeilCommunityTests:XCTestCase {
    func testCatalogAndAccess() {
        var world=RestoredPhoneBackup.snapshot()
        XCTAssertTrue(VeilCommunity.visible(world).isEmpty)
        world.flags.formUnion(["phone-tutorial-finished","web.visited.archive",VeilArchive.discovery])
        XCTAssertEqual(VeilCommunity.visible(world).count,10)
        XCTAssertNil(VeilCommunity.thread("image-index",in:world))
        world.flags.formUnion(["veil.correspondence.opened","veil.viewed.Nora_Archive_08"])
        let threads=VeilCommunity.visible(world)
        XCTAssertEqual(threads.count,12)
        XCTAssertEqual(Set(threads.map(\.id)).count,12)
        XCTAssertEqual(threads.flatMap(\.replies).count,36)
        XCTAssertTrue(threads.allSatisfy{VeilCommunity.handles.contains($0.author) && $0.replies.allSatisfy{VeilCommunity.handles.contains($0.author)}})
        let store=PhoneWorldStore(initial:world,persistToDisk:false)
        store.recordVeilThreadOpened("quiet-tapes",packages:"",safeMode:false)
        XCTAssertTrue(VeilCommunity.opened(store.state).isEmpty)
        store.recordVeilThreadOpened("quiet-tapes",packages:"veil",safeMode:false)
        XCTAssertEqual(VeilCommunity.opened(store.state).map(\.id),["quiet-tapes"])
        XCTAssertNotNil(LumaAssistantEvidence.selected("veil:thread:quiet-tapes",in:store.state))
        store.toggleVeilThreadBookmark("quiet-tapes",packages:"veil",safeMode:false)
        XCTAssertEqual(VeilCommunity.bookmarkIDs(store.state),["quiet-tapes"])
        store.toggleVeilThreadBookmark("quiet-tapes",packages:"veil",safeMode:true)
        XCTAssertEqual(VeilCommunity.bookmarkIDs(store.state),["quiet-tapes"])
        var revoked=store.state
        revoked.flags.remove(VeilArchive.discovery)
        XCTAssertTrue(VeilCommunity.bookmarkIDs(revoked).isEmpty)
        XCTAssertNil(LumaAssistantEvidence.selected("veil:thread:quiet-tapes",in:revoked))
    }
}
