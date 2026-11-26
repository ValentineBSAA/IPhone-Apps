import XCTest
@testable import LastSeen

@MainActor final class MessageAttachmentTests: XCTestCase {
    func testAttachmentOnlySendAndSaveRoundTrip() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        let photo = try XCTUnwrap(LumaMessageAttachmentCatalog.shareable(store.state).first { $0.kind == .photo })
        XCTAssertTrue(store.sendReactive(to: .maya, text: "", now: now, attachments: [photo]))
        let outgoing = try XCTUnwrap(store.messages(.maya).last)
        XCTAssertEqual(outgoing.attachments, [photo])
        XCTAssertTrue(LumaMessageAttachmentCatalog.canRead(photo, thread: .maya, world: store.state))
        XCTAssertFalse(LumaMessageAttachmentCatalog.canRead(photo, thread: .denise, world: store.state))
        XCTAssertEqual(store.state.pendingReplies?.last?.startsTutorial, false)
        let decoded = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(store.state))
        XCTAssertEqual(decoded.threads["maya"]?.last?.attachments, [photo])
        XCTAssertFalse(store.sendReactive(to: .maya, text: "", attachments: [photo, photo]))
    }
    func testPrivateAndUnknownReferencesCannotBeSent() {
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let forbidden = [
            LumaMessageAttachment(kind: .photo, recordID: "Nora_Photo_12"),
            LumaMessageAttachment(kind: .photo, recordID: "arbitrary-file"),
            LumaMessageAttachment(kind: .document, recordID: "WorldDoc_01_05"),
            LumaMessageAttachment(kind: .supportGuide, recordID: "relay-basics")
        ]
        for item in forbidden {
            XCTAssertFalse(store.sendReactive(to: .maya, text: "test", attachments: [item]))
        }
        XCTAssertEqual(LumaSupportGuides.all.count, 4)
        XCTAssertEqual(Set(LumaSupportGuides.all.map(\.id)).count, 4)
        XCTAssertTrue(LumaSupportGuides.all.allSatisfy { !$0.sections.isEmpty })
    }
}
