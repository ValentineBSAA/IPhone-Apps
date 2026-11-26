import XCTest
@testable import LastSeen
@MainActor final class Build33BrowserIsolationTests: XCTestCase {
    func testPublicBrowserNeverRendersRecoveredPixelsOrResolvesOnion() {
        let flags = Set(LumaWebCatalog.pages.map { "web.visited." + $0.id })
        for asset in LumaWebCatalog.restrictedMedia { XCTAssertFalse(LumaWebCatalog.allowsPublicImage(asset)) }
        for address in ["example.onion","https://EXAMPLE.ONION/path","veil://directory","example%2eonion"] {
            XCTAssertNil(LumaWebCatalog.page(address))
            XCTAssertTrue(LumaWebCatalog.search(address,flags:flags).isEmpty)
        }
    }
    func testStudioHomeAloneDoesNotContactPlayer() {
        var initial=RestoredPhoneBackup.snapshot()
        initial.flags.insert("phone-tutorial-finished")
        let world=PhoneWorldStore(initial:initial,persistToDisk:false)
        world.visitWebRecord("studio")
        XCTAssertTrue(world.messages(.unknown).isEmpty)
        world.visitWebRecord("studio-notes")
        world.advanceInvestigation(now:Date().addingTimeInterval(91))
        XCTAssertEqual(world.messages(.unknown).count,1)
        world.advanceInvestigation()
        XCTAssertEqual(world.messages(.unknown).count,1)
    }
}
