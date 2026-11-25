import XCTest
@testable import LastSeen

@MainActor final class RecoveryCircuitTests: XCTestCase {
    func testDependencyValidationAndEarnedGate() throws {
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let package = try XCTUnwrap(RelayCatalog.package("fieldnotes"))
        let change = RelayChange(package: package, action: .install)
        XCTAssertFalse(RecoveryCircuit.valid(["Mount","Index","Verify"], stage: 0))
        XCTAssertFalse(RecoveryCircuit.valid([], stage: -1))
        XCTAssertFalse(w.completeRecoveryCircuit(verified: []))
        XCTAssertFalse(RelayPlan.valid([change], sources: ["utilities"], installed: []))
        XCTAssertFalse(RelayCatalog.visible(package, sources: ["utilities"], installed: []))
        XCTAssertTrue(w.completeRecoveryCircuit(verified: RecoveryCircuit.stages))
        XCTAssertFalse(w.completeRecoveryCircuit(verified: RecoveryCircuit.stages))
        XCTAssertTrue(RelayPlan.valid([change], sources: ["utilities"], installed: [], flags: w.state.flags))
        let encoded = try JSONEncoder().encode(w.state)
        XCTAssertTrue(RecoveryCircuit.unlocked(try JSONDecoder().decode(PhoneWorld.self, from: encoded).flags))
        try w.restoreCheckpoint(RestoredPhoneBackup.snapshot())
        XCTAssertFalse(RecoveryCircuit.unlocked(w.state.flags))
    }
    func testNotebookPersistsSeparatelyAndEdits() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("notes.json")
        let b = FieldNotebook(url: url)
        var entry = FieldEntry()
        XCTAssertFalse(b.put(entry))
        entry.text = "Test observation"
        XCTAssertTrue(b.put(entry))
        entry.status = "Resolved"
        XCTAssertTrue(b.put(entry))
        let second = FieldNotebook(url: url)
        XCTAssertEqual(second.entries.count, 1)
        XCTAssertEqual(second.entries.first?.status, "Resolved")
        XCTAssertTrue(second.remove(entry.id))
        XCTAssertTrue(FieldNotebook(url: url).entries.isEmpty)
    }
}
