import XCTest
@testable import LastSeen

final class PhoneLabTests: XCTestCase {
    @MainActor
    func testIndependentWorldFilesAndPersistence() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let labURL = root.appendingPathComponent("lab.json")
        let storyURL = root.appendingPathComponent("legacy.json")
        let legacy = PhoneWorldStore(storageURL: storyURL)
        let original = try Data(contentsOf: storyURL)
        let lab = PhoneWorldStore(storageURL: labURL)
        let id = lab.addNote(title: "Lab test", body: "Only in lab")
        lab.markRead(.maya)
        XCTAssertTrue(lab.reply(to: .maya, text: "Coffee sounds good!"))
        let restored = PhoneWorldStore(storageURL: labURL)
        XCTAssertEqual(restored.state.notes.first(where: { $0.id == id })?.body, "Only in lab")
        XCTAssertEqual(restored.state.progress["maya"], 1)
        XCTAssertFalse(legacy.state.notes.contains { $0.id == id })
        XCTAssertEqual(try Data(contentsOf: storyURL), original)
        XCTAssertTrue(restored.state.flags.isEmpty)
    }
}
