import XCTest
@testable import LastSeen

final class RestoredPhoneBackupTests: XCTestCase {
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
