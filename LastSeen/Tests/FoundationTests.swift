import XCTest
import UIKit
@testable import LastSeen

@MainActor
final class FoundationTests: XCTestCase {
    func testFoundationArtworkAndPreservedWallpaperIDs() throws {
        XCTAssertEqual(Set(LumaDesign.assetNames).count, 26)
        XCTAssertEqual(LumaDesign.wallpaperChoices(midnight: false).count, 10)
        XCTAssertEqual(LumaDesign.wallpaperChoices(midnight: true).count, 11)
        XCTAssertEqual(LumaDesign.resolvedWallpaper(2, midnight: false), 0)
        XCTAssertEqual(LumaDesign.resolvedWallpaper(2, midnight: true), 2)
        for name in LumaDesign.assetNames {
            let image = try XCTUnwrap(PortraitImages.load(name), name)
            XCTAssertGreaterThan(image.size.width, 200)
        }
    }
    func testSaveRoundTripAndRotation() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "foundation-tests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: root) }
        let world = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let store = LumaSaveStore(root: root, defaults: defaults)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        defaults.set(4, forKey: "lastseen.lab.wallpaper")
        defaults.set(true, forKey: "lastseen.security.ownerVerified")
        world.startPhoneTutorial(now: now)
        XCTAssertTrue(world.sendReactive(to: .maya, text: "Hello there", now: now))
        XCTAssertTrue(store.write("manual-1", world: world.state, now: now))
        let original = world.state
        for i in 1...5 { store.automatic(world: world.state, now: now.addingTimeInterval(Double(i * 60)), force: true) }
        XCTAssertEqual(store.slots.count, 4)
        XCTAssertEqual(store.slots["manual-1"]?.date, now)
        _ = world.addNote(title: "After save")
        defaults.set(7, forKey: "lastseen.lab.wallpaper")
        XCTAssertTrue(store.restore("manual-1", into: world, now: now.addingTimeInterval(600)))
        XCTAssertEqual(world.state.notes, original.notes)
        XCTAssertEqual(world.state.flags, original.flags)
        XCTAssertEqual(world.state.threads, original.threads)
        XCTAssertEqual(defaults.integer(forKey: "lastseen.lab.wallpaper"), 4)
        XCTAssertFalse(defaults.bool(forKey: "lastseen.security.ownerVerified"))
        XCTAssertEqual(world.state.pendingReplies?.first?.dueAt, original.pendingReplies?.first?.dueAt.addingTimeInterval(600))
        try Data("damaged".utf8).write(to: root.appendingPathComponent("manual-2.json"))
        store.refresh()
        XCTAssertTrue(store.invalid.contains("manual-2"))
        XCTAssertFalse(store.restore("manual-2", into: world))
        XCTAssertEqual(world.state.threads, original.threads)
    }
    func testManualCooldownAcrossSlotsAndStoreRecreation() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "manual-cooldown-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: root) }
        let world = RestoredPhoneBackup.snapshot()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let store = LumaSaveStore(root: root, defaults: defaults)
        XCTAssertTrue(store.writeManual("manual-1", world: world, now: now))
        XCTAssertFalse(store.writeManual("manual-2", world: world, now: now.addingTimeInterval(59)))
        let reopened = LumaSaveStore(root: root, defaults: defaults)
        XCTAssertFalse(reopened.writeManual("manual-3", world: world, now: now.addingTimeInterval(59)))
        XCTAssertTrue(reopened.writeManual("manual-2", world: world, now: now.addingTimeInterval(60)))
        XCTAssertFalse(reopened.writeManual("auto-1", world: world, now: now.addingTimeInterval(120)))
    }
    func testFictionalPhoneHistoryAndFavoritesRoundTrip() throws {
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        store.toggleFavoriteContact(.maya)
        store.recordCallAttempt(.maya)
        XCTAssertEqual(store.state.favoriteContacts, ["maya"])
        let decoded = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(store.state))
        XCTAssertEqual(decoded.callHistory?.first?.contact, .maya)
        XCTAssertEqual(decoded.favoriteContacts, ["maya"])
        try store.restoreCheckpoint(decoded)
        store.toggleFavoriteContact(.maya)
        XCTAssertEqual(store.state.favoriteContacts, [])
    }
    func testLiveStatsPreserveLifetimeAcrossCheckpoint() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite="live-statistics-"+UUID().uuidString
        let defaults=try XCTUnwrap(UserDefaults(suiteName:suite))
        defer { defaults.removePersistentDomain(forName:suite); try? FileManager.default.removeItem(at:root) }
        defaults.set(80,forKey:"lastseen.saves.playSeconds")
        let store=LumaSaveStore(root:root,defaults:defaults)
        let world=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let date=Date(timeIntervalSince1970:1_800_000_000)
        XCTAssertEqual(store.lifetimeSeconds,80)
        XCTAssertEqual(store.sessionSeconds,0)
        XCTAssertNil(store.nextAutomaticSeconds(interval:0))
        XCTAssertTrue(store.writeManual("manual-1",world:world.state,now:date))
        for i in 1...60 { store.tick(world:world.state,minutes:1,now:date.addingTimeInterval(Double(i))) }
        XCTAssertEqual(store.lifetimeSeconds,140)
        XCTAssertEqual(store.sessionSeconds,60)
        XCTAssertEqual(store.lastSuccessfulAutomatic,date.addingTimeInterval(60))
        XCTAssertEqual(store.nextAutomaticSeconds(interval:1),60)
        XCTAssertTrue(store.restore("manual-1",into:world,now:date.addingTimeInterval(90)))
        XCTAssertEqual(store.playSeconds,80)
        XCTAssertEqual(store.lifetimeSeconds,140)
        XCTAssertEqual(store.sessionSeconds,60)
        let reopened=LumaSaveStore(root:root,defaults:defaults)
        XCTAssertEqual(reopened.lifetimeSeconds,140)
        XCTAssertEqual(reopened.sessionSeconds,0)
        XCTAssertEqual(reopened.lastSuccessfulAutomatic,date.addingTimeInterval(60))
    }
    func testWorldDocumentResourcesAndGate() throws {
        var world=RestoredPhoneBackup.snapshot()
        XCTAssertEqual(WorldDocumentCatalog.visible(world).count,8)
        XCTAssertNil(WorldDocumentCatalog.document("WorldDoc_01_04",world:world))
        XCTAssertNil(WorldDocumentCatalog.document("WorldDoc_01_05",world:world))
        world.flags.insert("web.visited.archive")
        XCTAssertEqual(WorldDocumentCatalog.visible(world).count,9)
        world.flags.insert("investigation.chapter2.reviewed")
        XCTAssertEqual(WorldDocumentCatalog.visible(world).count,10)
        for doc in WorldDocumentCatalog.visible(world) {
            XCTAssertGreaterThan(doc.fullText.count,150)
            XCTAssertNotNil(Bundle.main.url(forResource:doc.id,withExtension:"docx"))
        }
        for name in ["Icon_Afterframe","Icon_Connective","Icon_CommonGround","Icon_VoiceMemos"] {
            XCTAssertNotNil(PortraitImages.load(name))
        }
        XCTAssertFalse(WorldDocumentCatalog.search("Friday",world:world).isEmpty)
    }
    func testPeriodicCheckpointAndOff() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "foundation-interval-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: root) }
        let store = LumaSaveStore(root: root, defaults: defaults)
        let world = RestoredPhoneBackup.snapshot()
        for _ in 0..<60 { store.tick(world: world, minutes: 0) }
        XCTAssertTrue(store.slots.isEmpty)
        for _ in 0..<59 { store.tick(world: world, minutes: 1) }
        XCTAssertTrue(store.slots.isEmpty)
        store.tick(world: world, minutes: 1)
        XCTAssertEqual(store.slots.count, 1)
        for _ in 0..<300 { store.tick(world: world, minutes: 0) }
        XCTAssertEqual(store.slots.count, 1)
    }
}
