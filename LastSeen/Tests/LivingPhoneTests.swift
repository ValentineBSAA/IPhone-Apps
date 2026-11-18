import XCTest
@testable import LastSeen

@MainActor
final class LivingPhoneTests: XCTestCase {
    private var timestamp: Date {
        Date(timeIntervalSince1970: 1_800_000_000)
    }

    func testFictionalWorldStartsWithTwoOrdinaryConversations() {
        let world = PhoneWorldStore(persistToDisk: false, now: timestamp)
        XCTAssertEqual(world.messages(.maya).count, 2)
        XCTAssertEqual(world.messages(.denise).count, 1)
        XCTAssertGreaterThanOrEqual(world.state.notes.count, 2)
        XCTAssertEqual(world.state.events.count, 2)
    }

    func testEverydayRepliesAreAuthoredAndPersisted() {
        let world = PhoneWorldStore(persistToDisk: false, now: timestamp)
        XCTAssertTrue(world.reply(to: .maya, text: "Coffee sounds good!", now: timestamp))
        XCTAssertFalse(world.reply(to: .maya, text: "Coffee sounds good!", now: timestamp))
        XCTAssertEqual(world.messages(.maya).count, 4)
        XCTAssertEqual(world.state.progress["maya"], 1)
        XCTAssertTrue(world.reply(to: .maya, text: "See you soon!", now: timestamp))
        XCTAssertEqual(world.state.progress["maya"], 2)
        XCTAssertTrue(world.choices(.maya).isEmpty)
    }

    func testUnrecognizedMessagesDoNotPretendToSend() {
        let world = PhoneWorldStore(persistToDisk: false, now: timestamp)
        let before = world.messages(.denise).count
        XCTAssertFalse(world.reply(to: .denise, text: "Can you help me defeat a monster?", now: timestamp))
        XCTAssertEqual(world.messages(.denise).count, before)
    }

    func testReadReceiptsAndInboxCounts() {
        let world = PhoneWorldStore(persistToDisk: false, now: timestamp)
        XCTAssertEqual(world.countUnread(.maya), 2)
        world.markRead(.maya)
        XCTAssertEqual(world.countUnread(.maya), 0)
        XCTAssertTrue(world.reply(to: .maya, text: "Coffee sounds good!", now: timestamp))
        XCTAssertEqual(world.countUnread(.maya), 1)
    }

    func testIndependentNotesCanBeEditedPinnedAndDeleted() {
        let world = PhoneWorldStore(persistToDisk: false, now: timestamp)
        let id = world.addNote(title: "Observation", body: "Something about the door.")
        world.updateNote(id, title: "Entry", body: "Look again.")
        XCTAssertEqual(world.state.notes.first(where: { $0.id == id })?.body, "Look again.")
        world.togglePin(id)
        XCTAssertTrue(world.state.notes.first(where: { $0.id == id })?.pinned ?? false)
        world.removeNote(id)
        XCTAssertNil(world.state.notes.first(where: { $0.id == id }))
    }

    func testStoryPhotoEvidenceWorksWhenItsStoryIsNotSelected() {
        let game = GameStore(initial: SavedGame(), persistToDisk: false)
        game.selectStory(.nora)
        for _ in 0..<150 {
            if game.state.sceneID == "evidence" && game.state.nextBeatIndex > 0 { break }
            if game.state.choiceReady {
                let first = game.availableChoices.first!
                XCTAssertTrue(game.choose(first.id))
            } else { game.advanceForTests() }
        }
        guard let photograph = game.messages(in: Contact.nora.id).first(where: { $0.kind == .photograph }) else {
            return XCTFail("Expected gallery photograph")
        }
        game.selectStory(.eli)
        game.inspect(photograph)
        game.selectStory(.nora)
        XCTAssertTrue(game.state.clues.contains("photograph"))
    }

    func testPhotoPackHasTenUniquelyNamedAssets() {
        let names = StoryPhotoCatalog.assets
        XCTAssertEqual(names.count, 10)
        XCTAssertEqual(Set(names).count, 10)
    }

    func testVoiceIsOffAndRealPhoneContactsAreNeverRequested() {
        XCTAssertFalse(FutureVoiceFeatures.enabled)
        XCTAssertFalse(FutureVoiceFeatures.permitCloudRecognition)
        XCTAssertFalse(FutureVoiceFeatures.showTranscriptDuringCall)
    }
}
