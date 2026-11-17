import XCTest
@testable import LastSeen

@MainActor
final class StoryEngineTests: XCTestCase {
    private func drain(_ game: GameStore, limit: Int = 400) {
        for _ in 0..<limit {
            if game.state.choiceReady || game.state.endingID != nil { return }
            game.advanceForTests()
        }
        XCTFail("Story softlocked before next choice or ending")
    }

    private func run(_ route: [String], collectClues: Bool = true) -> GameStore {
        let game = GameStore(initial: SavedGame(), persistToDisk: false)
        for choice in route {
            drain(game)
            if collectClues {
                for message in game.allMessages where message.kind != .text {
                    game.inspect(message)
                }
            }
            XCTAssertTrue(game.choose(choice), "Failed to select \(choice) in scene \(game.state.sceneID)")
        }
        drain(game)
        return game
    }

    func testAllThreeEndingsAreReachable() {
        XCTAssertEqual(
            run(["opening_kind", "photo_path", "stairs", "investigate", "escape"]).state.endingID,
            "safe_ending"
        )
        XCTAssertEqual(
            run(["opening_direct", "unknown_path", "nora_check", "nora_trust_early"]).state.endingID,
            "loop_ending"
        )
        XCTAssertEqual(
            run(["opening_ignore", "caretaker_path", "elevator", "eli_trust_early"]).state.endingID,
            "taken_ending"
        )
    }

    func testSecretExitRequiresRealEvidence() {
        let game = run(["opening_kind", "photo_path", "stairs", "investigate"], collectClues: false)
        XCTAssertFalse(game.choose("escape"))
        XCTAssertEqual(game.state.sceneID, "threshold")
        let photo = try! XCTUnwrap(game.allMessages.first(where: { $0.kind == .photograph }))
        let audio = try! XCTUnwrap(game.allMessages.first(where: { $0.kind == .voiceNote }))
        game.inspect(photo)
        XCTAssertFalse(game.choose("escape"))
        game.inspect(audio)
        XCTAssertTrue(game.choose("escape"))
        drain(game)
        XCTAssertEqual(game.state.endingID, "safe_ending")
    }

    func testMessagesHaveUniqueStableIDs() {
        let game = run(["opening_kind", "caretaker_path", "stairs", "investigate", "loop"])
        let ids = game.allMessages.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
        XCTAssertGreaterThan(ids.count, 25)
    }

    func testRestartPreservesPreferencesButClearsStory() {
        let game = run(["opening_kind", "caretaker_path", "stairs", "investigate", "loop"])
        game.setAudio(false)
        game.setHaptics(false)
        game.restart()
        XCTAssertNil(game.state.endingID)
        XCTAssertEqual(game.state.sceneID, StoryScript.firstScene)
        XCTAssertEqual(game.state.nextBeatIndex, 0)
        XCTAssertTrue(game.state.messages.isEmpty)
        XCTAssertFalse(game.state.audioEnabled)
        XCTAssertFalse(game.state.hapticsEnabled)
    }

    func testSceneGraphIsConnectedAndEveryBranchReachesEnding() {
        let scenes = StoryScript.scenes
        XCTAssertFalse(scenes.isEmpty)
        var visited = Set<String>()
        var stack = [StoryScript.firstScene]
        while let id = stack.popLast() {
            guard visited.insert(id).inserted else { continue }
            let scene = try! XCTUnwrap(scenes[id], "Unknown scene \(id)")
            if let next = scene.next {
                XCTAssertNotNil(scenes[next], "Missing auto-transition \(next)")
                stack.append(next)
            }
            for choice in scene.choices {
                XCTAssertNotNil(scenes[choice.next], "Missing destination \(choice.next)")
                stack.append(choice.next)
            }
            if scene.next == nil && scene.choices.isEmpty {
                XCTAssertNotNil(scene.ending, "Dead end in scene \(id)")
            }
        }
        XCTAssertEqual(visited.count, scenes.count, "Some authored scenes cannot be reached")
    }
}
