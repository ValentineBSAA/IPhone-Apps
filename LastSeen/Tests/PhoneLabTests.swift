import XCTest
@testable import LastSeen

final class PhoneLabTests: XCTestCase {
    func testSettingsEffectivePreviewAndDimming() {
        for preference in [false,true] {
            for biometrics in [false,true] {
                for shield in [false,true] {
                    XCTAssertEqual(LumaSettingsPolicy.hidesMessagePreviews(preference:preference,biometrics:biometrics,shield:shield),preference || biometrics || shield)
                }
            }
        }
        XCTAssertEqual(LumaSettingsPolicy.clampedBrightness(-1),0.35)
        XCTAssertEqual(LumaSettingsPolicy.clampedBrightness(2),1)
        XCTAssertEqual(LumaSettingsPolicy.clampedBrightness(.nan),0.9)
        XCTAssertEqual(LumaSettingsPolicy.displayDimming(1),0)
        XCTAssertEqual(LumaSettingsPolicy.displayDimming(0.35),0.4875,accuracy:0.0001)
    }
    @MainActor func testSettingsCheckpointScope() {
        XCTAssertTrue(LumaSaveStore.keys.contains("lastseen.recovery.effects"))
        XCTAssertTrue(LumaSaveStore.keys.contains("lastseen.lab.hideLockPreviews"))
        XCTAssertFalse(LumaSaveStore.keys.contains("lastseen.lab.nativeAlerts"))
        XCTAssertFalse(LumaSaveStore.keys.contains("lastseen.permissions.biometricPrepared"))
        XCTAssertFalse(LumaSaveStore.keys.contains("lastseen.security.appearanceEnrolled"))
    }

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
