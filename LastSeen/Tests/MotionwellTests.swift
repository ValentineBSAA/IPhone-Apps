import XCTest
import AVFoundation
@testable import LastSeen

@MainActor final class MotionwellTests: XCTestCase {
    func testFeedAndWatchPositionBounds() {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        XCTAssertEqual(MotionwellArchive.feed(w.state,filter:"Shorts").count,2)
        XCTAssertEqual(MotionwellArchive.feed(w.state,filter:"Home",query:"  @bluehour ").map(\.id),["studio"])
        XCTAssertTrue(MotionwellArchive.feed(w.state,filter:"Saved").isEmpty)
        w.toggleMotionwellItem("studio",saved:true)
        XCTAssertEqual(MotionwellArchive.feed(w.state,filter:"Saved").map(\.id),["studio"])
        XCTAssertEqual(MotionwellArchive.progress(.nan,duration:60),0)
        XCTAssertEqual(MotionwellArchive.progress(99,duration:60),60)
        XCTAssertEqual(MotionwellArchive.resume(59,duration:60),0)
        XCTAssertEqual(MotionwellArchive.resume(20,duration:60),20)
        var revoked=w.state
        revoked.everydayArchiveRevision=nil
        XCTAssertTrue(MotionwellArchive.feed(revoked,filter:"Saved").isEmpty)
    }

    func testScheduledUploadsAndChannelPreferences() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        store.toggleMotionwellSubscription("maplecafe")
        store.toggleMotionwellSubscription("avery.green")
        store.setMotionwellChannelAlerts("avery.green", enabled: false)
        store.advanceMotionwell(now: now)
        store.advanceMotionwell(now: now.addingTimeInterval(89))
        XCTAssertEqual(MotionwellArchive.visible(store.state).count, 4)
        store.advanceMotionwell(now: now.addingTimeInterval(90))
        XCTAssertEqual(MotionwellArchive.visible(store.state).count, 5)
        let notice = try XCTUnwrap(LumaActivityCatalog.visible(store.state).first { $0.kind == .motionwell })
        XCTAssertEqual(notice.targetID, "cafe-lunch")
        XCTAssertTrue(notice.hidePreview(in: store.state))
        store.setMotionwellNotifications(enabled: true, previews: true)
        XCTAssertFalse(notice.hidePreview(in: store.state))
        store.advanceMotionwell(now: now.addingTimeInterval(240))
        XCTAssertEqual(MotionwellArchive.visible(store.state).count, 6)
        XCTAssertEqual(LumaActivityCatalog.visible(store.state).filter { $0.kind == .motionwell }.count, 1)
        store.markMotionwellUploadSeen("cafe-lunch")
        XCTAssertFalse(notice.canPresent(in: store.state))
        store.advanceMotionwell(now: now.addingTimeInterval(600))
        XCTAssertEqual((store.connected.activityJournal ?? []).filter { $0.kind == .motionwell }.count, 1)
        XCTAssertEqual(try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(store.state)).connectedWorld?.motionwell, store.connected.motionwell)
        for upload in MotionwellArchive.scheduled { XCTAssertNotNil(upload.clip.url) }
    }

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
