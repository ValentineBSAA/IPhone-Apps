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

    func testGenerationContextAndStaleCompletion() throws {
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let installed = "relay-support"
        let sources = RelayCatalog.defaultSources
        XCTAssertTrue(store.sendRelaySupport("How do I use Compact Grid?", installed: installed, sources: sources))
        let request = try XCTUnwrap(store.relaySupportGenerationRequest(installed: installed, sources: sources))
        XCTAssertTrue(request.prompt.contains("Compact Grid"))
        XCTAssertFalse(request.prompt.contains("Reader Focus"))
        XCTAssertFalse(store.finishRelaySupportGeneration(request, text: "Try Reader Focus.", installed: installed, sources: sources))
        XCTAssertTrue(store.finishRelaySupportGeneration(request, text: "Compact Grid changes icon sizing.", installed: installed, sources: sources))
        XCTAssertEqual(store.state.relaySupport?.messages.last?.generatedOnDevice, true)
        XCTAssertFalse(store.finishRelaySupportGeneration(request, text: "Duplicate completion", installed: installed, sources: sources))
        XCTAssertTrue(store.sendRelaySupport("What about restarting?", installed: installed, sources: sources))
        let stale = try XCTUnwrap(store.relaySupportGenerationRequest(installed: installed, sources: sources))
        try store.restoreCheckpoint(store.state)
        XCTAssertFalse(store.finishRelaySupportGeneration(stale, text: "Late response", installed: installed, sources: sources))
        XCTAssertTrue(store.sendRelaySupport("Give me the passcode", installed: installed, sources: sources))
        XCTAssertNil(store.relaySupportGenerationRequest(installed: installed, sources: sources))
    }

    func testSharedDocumentExcerptsAndPhotoLimits() throws {
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let items = LumaMessageAttachmentCatalog.shareable(store.state)
        let document = try XCTUnwrap(items.first { $0.kind == .document })
        let photo = try XCTUnwrap(items.first { $0.kind == .photo })
        let denied = LumaMessageAttachment(kind: .document, recordID: "WorldDoc_01_05")
        XCTAssertTrue(RelaySupportDocumentContext.excerpts(items: [denied], question: "read this", world: store.state).isEmpty)
        XCTAssertTrue(RelaySupportDocumentContext.excerpts(items: [photo], question: "read this", world: store.state).isEmpty)
        let excerpts = RelaySupportDocumentContext.excerpts(items: [document, photo], question: "summarize this", world: store.state)
        XCTAssertEqual(excerpts.map(\.recordID), [document.recordID])
        XCTAssertLessThanOrEqual(try XCTUnwrap(excerpts.first).excerpt.count, 900)
        XCTAssertTrue(store.sendRelaySupport("Summarize this document", installed: "relay-support", sources: RelayCatalog.defaultSources, attachments: [document, photo]))
        XCTAssertTrue(store.state.relaySupport?.messages.last?.text.contains("can't analyze") == true)
        let request = try XCTUnwrap(store.relaySupportGenerationRequest(installed: "relay-support", sources: RelayCatalog.defaultSources))
        XCTAssertTrue(request.prompt.contains("Explicitly shared document excerpts"))
        XCTAssertTrue(request.prompt.contains("No image pixels"))
        XCTAssertFalse(request.prompt.contains("WorldDoc_01_05"))
    }

    func testDiagnosticFollowupIsHistorical() throws {
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let installed = "relay-support|compact"
        let sources = RelayCatalog.defaultSources
        let report = try XCTUnwrap(RelaySupportDiagnostic.capture(packageID: "compact", installed: installed, versions: "", sources: sources, safeMode: true, flags: []))
        XCTAssertTrue(store.shareRelaySupportDiagnostic(report, installed: installed, versions: "", sources: sources, safeMode: true))
        XCTAssertTrue(store.sendRelaySupport("Why is it still paused?", installed: installed, sources: sources))
        let answer = try XCTUnwrap(store.state.relaySupport?.messages.last)
        XCTAssertTrue(answer.text.contains("not a live check"))
        XCTAssertTrue(answer.text.contains("fresh report"))
        XCTAssertEqual(answer.packageID, "compact")
    }

    func testSupportActivityIsIndependentAndDeduplicated() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        let installed = "relay-support"
        let original = store.state.threads
        store.advanceRelaySupportActivity(installed: "", now: now)
        XCTAssertNil(store.state.relaySupport)
        store.advanceRelaySupportActivity(installed: installed, now: now)
        XCTAssertFalse(LumaActivityCatalog.visible(store.state).contains { $0.kind == .support })
        store.advanceRelaySupportActivity(installed: installed, now: now.addingTimeInterval(3))
        let notice = try XCTUnwrap(LumaActivityCatalog.visible(store.state).first { $0.kind == .support })
        XCTAssertEqual(notice.appTitle, "Relay Support")
        XCTAssertTrue(notice.hidePreview(in: store.state))
        store.setRelaySupportPreferences(previews: true, installed: installed)
        XCTAssertFalse(notice.hidePreview(in: store.state))
        store.advanceRelaySupportActivity(installed: installed, now: now.addingTimeInterval(9))
        XCTAssertEqual(LumaActivityCatalog.visible(store.state).filter { $0.kind == .support }.count, 1)
        store.advanceRelaySupportActivity(installed: "", now: now.addingTimeInterval(10))
        XCTAssertFalse(notice.canPresent(in: store.state))
        store.advanceRelaySupportActivity(installed: installed, now: now.addingTimeInterval(11))
        store.markRelaySupportRead(installed: installed)
        XCTAssertFalse(notice.canPresent(in: store.state))
        XCTAssertEqual(store.state.threads, original)
    }

    func testPhotoClassificationLimitsAndStaleResult() throws {
        XCTAssertEqual(RelaySupportPhotoAnalysis.categories([("person", 0.99), ("cat", 0.9), ("tree", 0.4), ("plant", 0.8)]), ["cat", "plant"])
        XCTAssertFalse(RelaySupportPhotoAnalysis.valid(["person"]))
        XCTAssertTrue(RelaySupportPhotoAnalysis.valid([]))
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let photo = try XCTUnwrap(LumaMessageAttachmentCatalog.shareable(store.state).first { $0.kind == .photo })
        let installed = "relay-support"
        XCTAssertNil(store.relaySupportPhotoRequest(photo, installed: installed))
        XCTAssertTrue(store.sendRelaySupport("", installed: installed, sources: RelayCatalog.defaultSources, attachments: [photo]))
        let request = try XCTUnwrap(store.relaySupportPhotoRequest(photo, installed: installed))
        XCTAssertFalse(store.finishRelaySupportPhoto(request, labels: ["person"], installed: installed))
        XCTAssertTrue(store.finishRelaySupportPhoto(request, labels: ["plant"], installed: installed))
        XCTAssertFalse(store.finishRelaySupportPhoto(request, labels: ["plant"], installed: installed))
        XCTAssertNil(store.relaySupportPhotoRequest(photo, installed: installed))
        XCTAssertTrue(store.sendRelaySupport("", installed: installed, sources: RelayCatalog.defaultSources, attachments: [photo]))
        let stale = try XCTUnwrap(store.relaySupportPhotoRequest(photo, installed: installed))
        try store.restoreCheckpoint(store.state)
        XCTAssertFalse(store.finishRelaySupportPhoto(stale, labels: [], installed: installed))
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
