import XCTest
import AVFoundation
@testable import LastSeen

@MainActor final class MotionwellTests: XCTestCase {
    func testLocalMediaAndAccountPersistence() throws {
        let locked = PhoneWorldStore(persistToDisk: false)
        XCTAssertTrue(MotionwellArchive.visible(locked.state).isEmpty)
        locked.toggleMotionwellSubscription("bluehour")
        XCTAssertNil(locked.connected.motionwell)
        let world = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let clips = MotionwellArchive.visible(world.state)
        XCTAssertEqual(clips.count, 4)
        XCTAssertEqual(clips.filter(\.short).count, 2)
        for clip in clips {
            let url = try XCTUnwrap(clip.url)
            XCTAssertTrue(url.isFileURL)
            XCTAssertGreaterThan(try Data(contentsOf: url).count, 1000)
        }
        world.toggleMotionwellSubscription("bluehour")
        world.toggleMotionwellItem("studio", saved: true)
        world.toggleMotionwellItem("studio", saved: false)
        world.recordMotionwellWatch("studio", seconds: 12)
        world.recordMotionwellWatch("unknown", seconds: 99)
        XCTAssertTrue(world.addMotionwellComment("studio", text: "Nice reel"))
        XCTAssertFalse(world.addMotionwellComment("unknown", text: "Hi"))
        let copy = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(world.state))
        XCTAssertEqual(copy.connectedWorld?.motionwell, world.connected.motionwell)
        XCTAssertEqual(copy.connectedWorld?.motionwell?.watch["studio"]?.seconds, 12)
        XCTAssertNil(copy.connectedWorld?.motionwell?.watch["unknown"])
        XCTAssertEqual(copy.flags, world.state.flags)
        world.clearMotionwellHistory()
        XCTAssertTrue(world.connected.motionwell?.watch.isEmpty == true)
    }
}
