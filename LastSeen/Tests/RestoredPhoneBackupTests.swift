import XCTest
@testable import LastSeen

final class RestoredPhoneBackupTests: XCTestCase {
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
