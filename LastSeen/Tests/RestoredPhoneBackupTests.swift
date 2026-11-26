import XCTest
@testable import LastSeen

final class RestoredPhoneBackupTests: XCTestCase {
    func testOpeningBackupStatusRejectsUnreadableAndUnsupportedWorld() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let url=root.appendingPathComponent("opening.json")
        XCTAssertEqual(RestoredPhoneBackup.existingStatus(at:url),.absent)
        try RestoredPhoneBackup.restore(to:url)
        XCTAssertEqual(RestoredPhoneBackup.existingStatus(at:url),.readable)
        var unsupported=RestoredPhoneBackup.snapshot()
        unsupported.version=999
        let unsupportedBytes=try JSONEncoder().encode(unsupported)
        try unsupportedBytes.write(to:url)
        XCTAssertEqual(RestoredPhoneBackup.existingStatus(at:url),.unreadable)
        XCTAssertThrowsError(try RestoredPhoneBackup.restore(to:url))
        XCTAssertEqual(try Data(contentsOf:url),unsupportedBytes)
        let bytes=Data("unreadable fixture".utf8)
        try bytes.write(to:url)
        XCTAssertEqual(RestoredPhoneBackup.existingStatus(at:url),.unreadable)
        XCTAssertThrowsError(try RestoredPhoneBackup.restore(to:url))
        XCTAssertEqual(try Data(contentsOf:url),bytes)
    }

    @MainActor
    func testDamagedLiveWorldIsPreservedUntilExplicitRecovery() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:root)}
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        let url=root.appendingPathComponent("world.json")
        let damaged=Data("unreadable fixture".utf8)
        try damaged.write(to:url)
        let store=PhoneWorldStore(storageURL:url)
        XCTAssertTrue(store.recoveryRequired)
        _ = store.addNote(title:"Transient fixture")
        XCTAssertEqual(try Data(contentsOf:url),damaged)
        try store.restoreCheckpoint(RestoredPhoneBackup.snapshot())
        XCTAssertFalse(store.recoveryRequired)
        let archives=try FileManager.default.contentsOfDirectory(at:root,includingPropertiesForKeys:nil)
            .filter{$0.lastPathComponent.hasPrefix("world.json.damaged-")}
        XCTAssertEqual(archives.count,1)
        XCTAssertEqual(try Data(contentsOf:XCTUnwrap(archives.first)),damaged)
        XCTAssertEqual(try JSONDecoder().decode(PhoneWorld.self,from:Data(contentsOf:url)).version,1)
    }

    @MainActor
    func testAutomaticRotationNeverOverwritesUnreadableSlots() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite="rotation-fixture-"+UUID().uuidString
        let defaults=try XCTUnwrap(UserDefaults(suiteName:suite))
        defer{defaults.removePersistentDomain(forName:suite);try? FileManager.default.removeItem(at:root)}
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        let damaged=Data("unreadable fixture".utf8)
        for slot in LumaSaveStore.automatic {try damaged.write(to:root.appendingPathComponent(slot+".json"))}
        let saves=LumaSaveStore(root:root,defaults:defaults)
        saves.automatic(world:RestoredPhoneBackup.snapshot(),force:true)
        XCTAssertTrue(saves.automaticFailed)
        for slot in LumaSaveStore.automatic {XCTAssertEqual(try Data(contentsOf:root.appendingPathComponent(slot+".json")),damaged)}
        saves.remove("auto-2")
        saves.automatic(world:RestoredPhoneBackup.snapshot(),force:true)
        XCTAssertFalse(saves.automaticFailed)
        XCTAssertNotNil(saves.slots["auto-2"])
        XCTAssertEqual(saves.invalid,Set(["auto-1","auto-3"]))
    }

    @MainActor
    func testMalformedSettingsReceiptBlocksWorldWritesAndPreservesIntent() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite="settings-recovery-"+UUID().uuidString
        let defaults=try XCTUnwrap(UserDefaults(suiteName:suite))
        defer{defaults.removePersistentDomain(forName:suite);try? FileManager.default.removeItem(at:root)}
        let url=root.appendingPathComponent("world.json")
        try RestoredPhoneBackup.restore(to:url)
        let original=try Data(contentsOf:url)
        let receipt=LumaRestoreJournal.url(for:url)
        let malformed=Data("unreadable receipt fixture".utf8)
        try malformed.write(to:receipt)
        let store=PhoneWorldStore(storageURL:url)
        XCTAssertFalse(store.recoveryRequired)
        XCTAssertTrue(store.settingsRecoveryRequired)
        XCTAssertFalse(store.retrySettingsRecovery())
        _ = store.addNote(title:"Blocked persistence fixture")
        XCTAssertEqual(try Data(contentsOf:url),original)
        XCTAssertThrowsError(try store.restoreCheckpoint(RestoredPhoneBackup.snapshot()))
        let prefs=try PropertyListSerialization.data(fromPropertyList:["lastseen.lab.messageSound":false],format:.binary,options:0)
        try store.restoreCheckpoint(RestoredPhoneBackup.snapshot(),
            settings:.init(preferences:prefs,playSeconds:0),defaults:defaults)
        XCTAssertFalse(store.settingsRecoveryRequired)
        XCTAssertFalse(LumaRestoreJournal.pending(worldURL:url))
        let preserved=try XCTUnwrap(FileManager.default.contentsOfDirectory(at:root,includingPropertiesForKeys:nil)
            .first{$0.lastPathComponent.hasPrefix("world.json.restore-pending.preserved-")})
        XCTAssertEqual(try Data(contentsOf:preserved),malformed)
    }

    @MainActor
    func testRestoreReceiptOnlyAppliesToCommittedWorldBytes() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite="restore-receipt-"+UUID().uuidString
        let defaults=try XCTUnwrap(UserDefaults(suiteName:suite))
        defer {defaults.removePersistentDomain(forName:suite);try? FileManager.default.removeItem(at:root)}
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        let worldURL=root.appendingPathComponent("world.json")
        let old=try JSONEncoder().encode(RestoredPhoneBackup.snapshot())
        var replacement=try JSONDecoder().decode(PhoneWorld.self,from:old)
        replacement.flags.insert("fixture-receipt")
        let target=try JSONEncoder().encode(replacement)
        let key="lastseen.lab.messageSound"
        let prefs=try PropertyListSerialization.data(fromPropertyList:[key:false],format:.binary,options:0)
        let settings=LumaRestoreJournal.Settings(preferences:prefs,playSeconds:42)
        defaults.set(true,forKey:key)
        defaults.set(true,forKey:"lastseen.security.ownerVerified")
        try old.write(to:worldURL)
        try LumaRestoreJournal.prepare(worldURL:worldURL,target:target,settings:settings)
        XCTAssertFalse(try LumaRestoreJournal.recover(worldURL:worldURL,defaults:defaults))
        XCTAssertTrue(defaults.bool(forKey:key))
        XCTAssertTrue(defaults.bool(forKey:"lastseen.security.ownerVerified"))
        XCTAssertEqual(try Data(contentsOf:worldURL),old)
        try LumaRestoreJournal.prepare(worldURL:worldURL,target:target,settings:settings)
        try target.write(to:worldURL,options:.atomic)
        XCTAssertTrue(try LumaRestoreJournal.recover(worldURL:worldURL,defaults:defaults))
        XCTAssertFalse(defaults.bool(forKey:key))
        XCTAssertFalse(defaults.bool(forKey:"lastseen.security.ownerVerified"))
        XCTAssertEqual(defaults.integer(forKey:"lastseen.saves.playSeconds"),42)
        XCTAssertEqual(try Data(contentsOf:worldURL),target)
        XCTAssertFalse(try LumaRestoreJournal.recover(worldURL:worldURL,defaults:defaults))
    }

    @MainActor
    func testRestoreIsCoherentAndDoesNotOverwriteEdits() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let destination = root.appendingPathComponent("restored.json")
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        try RestoredPhoneBackup.restore(to: destination, now: now)
        let world = PhoneWorldStore(storageURL: destination)
        XCTAssertTrue(world.messages(.maya).contains { $0.text.contains("Nora") })
        XCTAssertTrue(world.messages(.denise).contains { $0.text.contains("Nora") })
        XCTAssertTrue(world.state.notes.contains { $0.body.contains("— Nora") })
        XCTAssertTrue(world.state.flags.isEmpty)
        XCTAssertEqual(world.countUnread(.maya), 2)
        XCTAssertEqual(world.countUnread(.denise), 1)
        let id = world.addNote(title: "My test edit", body: "Preserve this")
        let bytes = try Data(contentsOf: destination)
        try RestoredPhoneBackup.restore(to: destination, now: now.addingTimeInterval(3600))
        XCTAssertEqual(try Data(contentsOf: destination), bytes)
        XCTAssertTrue(PhoneWorldStore(storageURL: destination).state.notes.contains { $0.id == id })
    }
}
