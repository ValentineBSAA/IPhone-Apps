import XCTest
import UIKit
@testable import LastSeen

@MainActor final class HavenWatchTests: XCTestCase {
    func testArchiveAndPersistentPreferences() throws {
        let base = PhoneWorldStore(persistToDisk: false)
        XCTAssertTrue(HavenWatchArchive.frames(in: base.state).isEmpty)
        let world = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let frames = HavenWatchArchive.frames(in: world.state)
        XCTAssertEqual(frames.count, 10)
        XCTAssertEqual(Set(frames.map(\.id)).count, 10)
        for camera in HavenCamera.allCases {
            XCTAssertEqual(frames.filter { $0.camera == camera }.count, 2)
        }
        for frame in frames {
            XCTAssertNotNil(UIImage(named: frame.id, in: Bundle(for: PhoneWorldStore.self), compatibleWith: nil), frame.id)
        }
        XCTAssertNotNil(UIImage(named: "Icon_HavenWatch", in: Bundle(for: PhoneWorldStore.self), compatibleWith: nil))
        var prefs = HavenWatchPreferences()
        prefs.armed = true; prefs.infrared = true
        prefs.favorites = [frames[0].id, "invalid"]
        world.setHavenWatch(prefs)
        let restored = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(world.state))
        XCTAssertEqual(restored.connectedWorld?.havenWatch?.favorites, Set([frames[0].id]))
        XCTAssertEqual(restored.connectedWorld?.havenWatch?.armed, true)
        XCTAssertEqual(restored.connectedWorld?.havenWatch?.infrared, true)
        XCTAssertEqual(restored.flags, world.state.flags)
    }
}
