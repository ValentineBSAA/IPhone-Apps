import XCTest
@testable import LastSeen

@MainActor final class ContextualConversationTests: XCTestCase {
    func testContextualFollowupsAreContactLocalAndDoNotGrantAccess() {
        func plan(_ who: Neighbor, _ text: String, previous: String? = nil, recent: [String] = []) -> PhoneReplyPlan {
            PhoneReplyPolicy.plan(for: who, text: text, flags: [], tutorialStarted: false, tutorialFinished: false, previousReply: previous, recentReplies: recent)
        }
        let first = plan(.adrian, "How do you promote the studio?")
        let second = plan(.adrian, "Tell me more", previous: first.text, recent: [first.text])
        let third = plan(.adrian, "Why?", previous: second.text, recent: [first.text,second.text])
        XCTAssertEqual(Set([first.text,second.text,third.text]).count, 3)
        let unrelated = plan(.lily, "Tell me more", previous: first.text)
        XCTAssertNotEqual(unrelated.text, second.text)
        let privateRequest = plan(.adrian, "Tell me more about the passcode", previous: second.text)
        XCTAssertTrue(privateRequest.text.contains("private access"))
        XCTAssertFalse(privateRequest.startsTutorial)
        XCTAssertFalse(third.startsTutorial)
    }
    func testIndependentTopicsAndRevisitsRemainAuthored() {
        func reply(_ text: String, previous: String? = nil, recent: [String] = []) -> String? {
            PhoneEverydayConversation.reply(neighbor: .lily, text: text, previousMessage: nil, previousReply: previous, recentReplies: recent)
        }
        let combined = reply("What music do you like and what films do you watch?")
        XCTAssertEqual(combined?.components(separatedBy: "\n\n").count, 2)
        XCTAssertTrue(combined?.contains("playlists") == true)
        XCTAssertTrue(combined?.contains("film") == true)
        XCTAssertEqual(reply("Tell me more", previous: combined), "Which part did you want to talk about a little more?")
        XCTAssertNil(reply("What music do you like and what is the passcode?"))
        let first = reply("Any music recommendations?")
        let other = reply("Do you watch films?", previous: first)
        let revisit = reply("What about music?", previous: other, recent: [first ?? "", other ?? ""])
        XCTAssertNotEqual(first, revisit)
        XCTAssertNotNil(revisit)
    }

    func testCheckpointRetainsSeparateTypingTimestamp() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "typing-restore-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: root) }
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        XCTAssertTrue(w.sendReactive(to: .adrian, text: "What about documentation?", now: now))
        let pending = try XCTUnwrap(w.state.pendingReplies?.first)
        let typingAt = try XCTUnwrap(pending.typingAt)
        let saves = LumaSaveStore(root: root, defaults: defaults)
        XCTAssertTrue(saves.write("manual-1", world: w.state, now: now))
        XCTAssertTrue(saves.restore("manual-1", into: w, now: now.addingTimeInterval(60)))
        let restored = try XCTUnwrap(w.state.pendingReplies?.first)
        XCTAssertEqual(restored.typingAt, typingAt.addingTimeInterval(60))
        XCTAssertFalse(w.isTyping(.adrian, now: restored.readAt))
        XCTAssertTrue(w.isTyping(.adrian, now: typingAt.addingTimeInterval(60)))
    }

    func testNegatedOrQuotedRepairReportDoesNotAdvanceTutorial() {
        for text in ["I didn't repair the phone", "Is the phone working?", "Someone said \"I repaired the phone\"", "I am not a technician"] {
            XCTAssertFalse(PhoneReplyPolicy.plan(for: .maya, text: text, flags: [], tutorialStarted: true, tutorialFinished: false).startsTutorial)
        }
        XCTAssertTrue(PhoneReplyPolicy.plan(for: .maya, text: "I repaired the phone", flags: [], tutorialStarted: true, tutorialFinished: false).startsTutorial)
    }
    func testReadTypingDeliveryAndRestore() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        XCTAssertTrue(w.sendReactive(to: .adrian, text: "How do you promote the studio?", now: now))
        let pending = try XCTUnwrap(w.state.pendingReplies?.first)
        let typingAt = try XCTUnwrap(pending.typingAt)
        XCTAssertLessThan(pending.readAt, typingAt)
        XCTAssertLessThan(typingAt, pending.dueAt)
        w.advancePendingReplies(now: pending.readAt)
        XCTAssertFalse(w.isTyping(.adrian, now: pending.readAt))
        XCTAssertEqual(w.messages(.adrian).last?.recipientReadAt, pending.readAt)
        XCTAssertTrue(w.isTyping(.adrian, now: typingAt))
        let saved = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(w.state))
        let restored = PhoneWorldStore(initial: saved, persistToDisk: false)
        restored.advancePendingReplies(now: pending.dueAt.addingTimeInterval(10))
        XCTAssertEqual(restored.messages(.adrian).last?.at, pending.dueAt)
        XCTAssertEqual(restored.messages(.adrian).last?.text, pending.text)
        let count = restored.messages(.adrian).count
        restored.advancePendingReplies(now: pending.dueAt.addingTimeInterval(20))
        XCTAssertEqual(restored.messages(.adrian).count, count)
        XCTAssertTrue(restored.state.flags.isEmpty)
    }
    func testLegacyPendingReplyDecodesWithoutTypingTime() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let original = PhonePendingReply(id: "old", outgoingID: "old-out", neighbor: .adrian, text: "Hi", readAt: now, dueAt: now.addingTimeInterval(5), startsTutorial: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PhonePendingReply.self, from: data)
        XCTAssertNil(decoded.typingAt)
        XCTAssertEqual(decoded, original)
    }
}
