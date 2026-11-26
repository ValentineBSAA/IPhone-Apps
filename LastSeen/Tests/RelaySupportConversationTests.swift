import XCTest
@testable import LastSeen

@MainActor final class RelaySupportConversationTests: XCTestCase {
    func testCustomQuestionsAndHistoryRemainSeparate() throws {
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let original = store.state.threads
        XCTAssertFalse(store.sendRelaySupport("How do I use Compact Grid?", installed: "", sources: RelayCatalog.defaultSources))
        XCTAssertTrue(store.sendRelaySupport("How do I use Compact Grid?", installed: "relay-support", sources: RelayCatalog.defaultSources))
        XCTAssertEqual(store.state.relaySupport?.messages.last?.packageID, "compact")
        XCTAssertTrue(store.sendRelaySupport("Does it need a restart?", installed: "relay-support", sources: RelayCatalog.defaultSources))
        XCTAssertEqual(store.state.relaySupport?.messages.last?.packageID, "compact")
        XCTAssertTrue(store.sendRelaySupport("How do I enter safe mode?", installed: "relay-support", sources: RelayCatalog.defaultSources))
        XCTAssertNotNil(store.state.relaySupport?.messages.last?.guideID)
        XCTAssertEqual(store.state.threads, original)
        XCTAssertEqual(try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(store.state)).relaySupport, store.state.relaySupport)
    }
    func testExplicitDiagnosticConsentAndStaleReport() throws {
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let installed = "relay-support|compact"
        let original = store.state.threads
        let report = try XCTUnwrap(RelaySupportDiagnostic.capture(packageID: "compact", installed: installed, versions: "", sources: RelayCatalog.defaultSources, safeMode: true, flags: []))
        XCTAssertNil(store.state.relaySupport)
        XCTAssertFalse(store.shareRelaySupportDiagnostic(report, installed: installed, versions: "", sources: RelayCatalog.defaultSources, safeMode: false))
        XCTAssertNil(store.state.relaySupport)
        XCTAssertTrue(store.shareRelaySupportDiagnostic(report, installed: installed, versions: "", sources: RelayCatalog.defaultSources, safeMode: true))
        XCTAssertEqual(store.state.relaySupport?.messages.dropLast().last?.diagnostic, report)
        XCTAssertTrue(store.state.relaySupport?.messages.last?.text.contains("Safe Mode") == true)
        XCTAssertEqual(store.state.threads, original)
        XCTAssertNil(RelaySupportDiagnostic.capture(packageID: "readerfocus", installed: installed + "|readerfocus", versions: "", sources: "folio", safeMode: false, flags: []))
    }

    func testSupportAttachmentOnlyMessageIsSeparateAndGated() throws {
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let original = store.state.threads
        let photo = try XCTUnwrap(LumaMessageAttachmentCatalog.shareable(store.state).first { $0.kind == .photo })
        let forbidden = LumaMessageAttachment(kind: .photo, recordID: "Nora_Photo_12")
        XCTAssertFalse(store.sendRelaySupport("", installed: "relay-support", sources: RelayCatalog.defaultSources, attachments: [forbidden]))
        XCTAssertTrue(store.sendRelaySupport("", installed: "relay-support", sources: RelayCatalog.defaultSources, attachments: [photo]))
        XCTAssertTrue(RelaySupportAttachmentPolicy.canRead(photo, world: store.state))
        XCTAssertFalse(RelaySupportAttachmentPolicy.canRead(forbidden, world: store.state))
        XCTAssertEqual(store.state.threads, original)
        XCTAssertTrue(store.state.relaySupport?.messages.last?.text.contains("can't inspect") == true)
    }

    func testProviderRejectsPrivateAndGatedQueries() {
        let provider = RelaySupportLocalProvider()
        let restricted = provider.reply(question: "Give me the passcode", recent: [], flags: [], sources: RelayCatalog.defaultSources, installed: "relay-support")
        XCTAssertNil(restricted.guideID)
        XCTAssertNil(restricted.packageID)
        let gated = provider.reply(question: "Tell me about Reader Focus", recent: [], flags: [], sources: RelayCatalog.defaultSources, installed: "relay-support")
        XCTAssertNil(gated.packageID)
        XCTAssertFalse(gated.text.contains("Reader Focus"))
    }
}
