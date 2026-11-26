import XCTest
@testable import LastSeen

@MainActor final class Build33ResetAndIdentityTests: XCTestCase {
    func testNewGameClearsWorldAndFictionalSecurityWithoutErasingConsent() throws {
        let name = "Build33Reset-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName:name))
        defer { defaults.removePersistentDomain(forName:name) }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        defer { try? FileManager.default.removeItem(at:root) }
        let now = Date()
        var old = RestoredPhoneBackup.snapshot(now:now.addingTimeInterval(-1000))
        old.flags.insert("phone-tutorial-finished")
        old.flags.insert("web.visited.studio")
        let world = PhoneWorldStore(initial:old,persistToDisk:false)
        let saves = LumaSaveStore(root:root,defaults:defaults)
        defaults.set(true,forKey:"lastseen.security.ownerVerified")
        defaults.set(true,forKey:"lastseen.security.appearanceEnrolled")
        defaults.set(true,forKey:"lastseen.permissions.reviewed.v1")
        XCTAssertTrue(saves.write("manual-1",world:world.state,now:now.addingTimeInterval(-500)))
        XCTAssertTrue(saves.startNewGame(into:world,now:now))
        XCTAssertFalse(world.state.flags.contains("phone-tutorial-finished"))
        XCTAssertFalse(world.state.flags.contains("web.visited.studio"))
        XCTAssertFalse(defaults.bool(forKey:"lastseen.security.ownerVerified"))
        XCTAssertFalse(defaults.bool(forKey:"lastseen.security.appearanceEnrolled"))
        XCTAssertTrue(defaults.bool(forKey:"lastseen.permissions.reviewed.v1"))
        XCTAssertEqual(defaults.integer(forKey:"lastseen.recovery.stage"),0)
        XCTAssertNil(saves.slots["manual-1"])
        XCTAssertFalse(saves.restore("manual-1",into:world))
    }
    func testNewSocialPostUsesRestoredOwner() throws {
        let world = PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        XCTAssertTrue(world.publishSocial(channel:.afterframe,text:"A new local post"))
        let post = try XCTUnwrap(world.connected.posts.last)
        XCTAssertEqual(post.author,RestoredPhoneBackup.ownerName)
        XCTAssertEqual(post.handle,"nora.b")
        XCTAssertEqual(post.portrait,RestoredPhoneBackup.ownerPortrait)
    }
}
