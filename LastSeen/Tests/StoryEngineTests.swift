import XCTest
@testable import LastSeen

@MainActor
final class StoryEngineTests: XCTestCase {
    private func drain(_ game: GameStore, limit: Int = 250) {
        for _ in 0..<limit {
            if game.state.choiceReady || game.state.endingID != nil { return }
            game.advanceForTests()
        }
        XCTFail("Story softlocked before reaching a choice or ending")
    }

    private func play(_ contact: Contact, _ choices: [String],
                      inspectClues: Bool = true) -> GameStore {
        let game = GameStore(initial: SavedGame(), persistToDisk: false)
        game.selectStory(contact)
        for id in choices {
            drain(game)
            if inspectClues {
                for message in game.allMessages where message.kind == .photograph || message.kind == .voiceNote {
                    game.inspect(message)
                }
            }
            XCTAssertTrue(game.choose(id), "Unable to select \(id) from \(game.state.sceneID)")
        }
        drain(game)
        return game
    }

    func testNoraThreeEndingsRemainReachable() {
        XCTAssertEqual(play(.nora, ["opening_kind", "photo_path", "stairs", "investigate", "escape"]).state.endingID, "safe_ending")
        XCTAssertEqual(play(.nora, ["opening_direct", "unknown_path", "nora_check", "nora_trust_early"]).state.endingID, "loop_ending")
        XCTAssertEqual(play(.nora, ["opening_ignore", "caretaker_path", "elevator", "eli_trust_early"]).state.endingID, "taken_ending")
    }

    func testIndependentEliAndUnit7Endings() {
        XCTAssertEqual(play(.eli, ["eli_careful", "eli_exit"]).state.endingID, "eli_safe")
        XCTAssertEqual(play(.eli, ["eli_skeptic", "eli_door"]).state.endingID, "eli_bad")
        XCTAssertEqual(play(.unit7, ["unit7_who", "unit7_no"]).state.endingID, "unit7_safe")
        XCTAssertEqual(play(.unit7, ["unit7_where", "unit7_yes"]).state.endingID, "unit7_bad")
    }

    func testNoMessagesLeakIntoOtherConversation() {
        let game = GameStore(initial: SavedGame(), persistToDisk: false)
        game.selectStory(.nora)
        game.advanceForTests()
        XCTAssertEqual(game.messages(in: Contact.nora.id).count, 1)
        XCTAssertEqual(game.messages(in: Contact.eli.id).count, 0)
        XCTAssertEqual(game.messages(in: Contact.unit7.id).count, 0)
        game.selectStory(.eli)
        XCTAssertEqual(game.messages(in: Contact.nora.id).count, 1)
        XCTAssertEqual(game.messages(in: Contact.eli.id).count, 0)
        game.advanceForTests()
        XCTAssertEqual(game.messages(in: Contact.eli.id).count, 1)
        game.selectStory(.nora)
        XCTAssertEqual(game.messages(in: Contact.nora.id).count, 1)
        XCTAssertEqual(game.state.nextBeatIndex, 1)
        game.advanceForTests()
        XCTAssertEqual(game.messages(in: Contact.nora.id).count, 2)
        XCTAssertEqual(game.messages(in: Contact.eli.id).count, 1)
    }

    func testNoraEvidenceMustBeInspectedBeforeEscape() throws {
        let game = play(.nora, ["opening_kind", "photo_path", "stairs", "investigate"], inspectClues: false)
        XCTAssertFalse(game.choose("escape"))
        let photo = try XCTUnwrap(game.allMessages.first(where: { $0.kind == .photograph }))
        let transcript = try XCTUnwrap(game.allMessages.first(where: { $0.kind == .voiceNote }))
        game.inspect(photo)
        XCTAssertFalse(game.choose("escape"))
        game.inspect(transcript)
        XCTAssertTrue(game.choose("escape"))
        drain(game)
        XCTAssertEqual(game.state.endingID, "safe_ending")
    }

    func testNoFictionalCallUIIsScheduled() {
        for scene in SoloStories.scenes.values {
            XCTAssertFalse(scene.beats.contains(where: { $0.kind == .call }),
                           "\(scene.id) still attempts a call without recorded audio")
        }
    }

    func testEachStoryBranchCanReachAnEnding() throws {
        let scenes = SoloStories.scenes
        var reached = Set<String>()
        for contact in Contact.allCases {
            var pending = [SoloStories.start(for: contact.id)]
            while let node = pending.popLast() {
                guard reached.insert(node).inserted else { continue }
                let scene = try XCTUnwrap(scenes[node])
                if let next = scene.next { pending.append(next) }
                pending.append(contentsOf: scene.choices.map(\.next))
                if scene.next == nil && scene.choices.isEmpty {
                    XCTAssertNotNil(scene.ending, "Unfinished scene: \(scene.id)")
                }
            }
        }
        XCTAssertEqual(reached.count, scenes.count, "One or more scene paths are unreachable")
    }

    func testReplayOnlyClearsActiveConversation() {
        let game = GameStore(initial: SavedGame(), persistToDisk: false)
        game.selectStory(.nora)
        game.advanceForTests()
        game.selectStory(.eli)
        game.advanceForTests()
        game.restart()
        XCTAssertTrue(game.messages(in: Contact.eli.id).isEmpty)
        XCTAssertEqual(game.messages(in: Contact.nora.id).count, 1)
        game.selectStory(.nora)
        XCTAssertEqual(game.state.nextBeatIndex, 1)
    }

    func testChoiceIDsStayUniquePerThread() {
        let game = play(.nora, ["opening_kind", "photo_path", "stairs", "investigate", "loop"])
        let ids = game.allMessages.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testMessageTimestampsAreRealDates() {
        let game = GameStore(initial: SavedGame(), persistToDisk: false)
        game.selectStory(.nora)
        let before = Date()
        game.advanceForTests()
        let now = Date()
        XCTAssertEqual(game.allMessages.count, 1)
        XCTAssertGreaterThanOrEqual(game.allMessages[0].createdAt, before)
        XCTAssertLessThanOrEqual(game.allMessages[0].createdAt, now)
    }
}
