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
