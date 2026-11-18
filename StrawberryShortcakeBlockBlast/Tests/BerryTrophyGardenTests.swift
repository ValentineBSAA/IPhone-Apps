import XCTest
@testable import BerryBlockBlast

/// Non-negotiable rules for permanent special-block cosmetics.
final class BerryTrophyGardenTests: XCTestCase {
    private let rewards = BerryTrophyCatalog.rewards
    private func earned(_ id: String, lines: Int, chapter: Int = 1,
                        runs: Int = 0, bestNightmareLines: Int = 0,
                        legacy: Bool = false) -> Bool {
        guard let reward = rewards.first(where: { $0.id == id }) else { return false }
        return BerryTrophyCatalog.unlocked(reward, lifetimeLines: lines, chapter: chapter,
                                           survivals: runs, nightmareBest: bestNightmareLines,
                                           legacy: legacy)
    }

    func testExactlyTenUniqueRewardsWithDistinctArtwork() {
        XCTAssertEqual(rewards.count, 10)
        XCTAssertEqual(Set(rewards.map(\.id)).count, 10)
        XCTAssertEqual(Set(rewards.map(\.artwork)).count, 10)
        XCTAssertTrue(rewards.allSatisfy { (0...5).contains($0.tintIndex) })
    }

    func testLegacyStrawberryRedRemainsEarnedWithoutExtraWork() {
        XCTAssertTrue(earned("strawberry-red", lines: 0, legacy: true))
        XCTAssertTrue(earned("strawberry-red", lines: 10))
        XCTAssertFalse(earned("strawberry-red", lines: 9))
    }

    func testLifetimeRewardsCannotBeCollectedPrematurely() {
        let thresholds: [(String, Int)] = [
            ("golden-honey", 100), ("blueberry-sparkle", 250),
            ("mint-leaf-jelly", 450), ("raspberry-bloom", 700),
            ("peach-fizz", 1000), ("lavender-dream", 1400),
            ("coconut-cream", 2000)
        ]
        for (id, target) in thresholds {
            XCTAssertFalse(earned(id, lines: target - 1), "\(id) unlocked too soon")
            XCTAssertTrue(earned(id, lines: target), "\(id) did not unlock on target")
        }
    }

    func testRoyalBerryRequiresBothChapterFiveAndTwoThousandFiveHundredLines() {
        XCTAssertFalse(earned("royal-berry", lines: 2500, chapter: 5))
        XCTAssertFalse(earned("royal-berry", lines: 2499, chapter: 6))
        XCTAssertTrue(earned("royal-berry", lines: 2500, chapter: 6))
    }

    func testMoonberryRequiresFiveRealSurvivalsAndTwelveLinesInOneRun() {
        XCTAssertFalse(earned("moonberry-nightmare", lines: 9999, runs: 4, bestNightmareLines: 12))
        XCTAssertFalse(earned("moonberry-nightmare", lines: 9999, runs: 5, bestNightmareLines: 11))
        XCTAssertTrue(earned("moonberry-nightmare", lines: 0, runs: 5, bestNightmareLines: 12))
    }

    func testRewardTitlesAndVisualsNeverModifyPuzzleRules() {
        XCTAssertNotNil(rewards.first(where: { $0.artwork == "BerryRewardStrawberryRed" }))
        let game = BerryEngine()
        XCTAssertEqual(game.side, 8)
        XCTAssertEqual(game.tray.count, 3)
    }
}
