import XCTest
@testable import BerryBlockBlast

/// Regression gates for the 0.5.8 Build 2 corrective update.
/// The iOS scene/audio changes also require physical lock-screen testing.
final class BerryBuild58CorrectiveTests: XCTestCase {
    func testStoryChapterTwoExplainsThreeLines() {
        XCTAssertEqual(BerryStoryNarrative.title(for: 2), "Restore the Flower Beds")
        XCTAssertTrue(BerryStoryNarrative.opening(for: 2).contains("three whole rows or columns"))
        XCTAssertFalse(BerryStoryNarrative.encouragement(for: 2).isEmpty)
        XCTAssertFalse(BerryStoryNarrative.victory(for: 2).isEmpty)
    }

    func testStoryNarrativeHasDistinctEarlyChaptersAndCyclesSafely() {
        XCTAssertNotEqual(BerryStoryNarrative.title(for: 1), BerryStoryNarrative.title(for: 2))
        // Chapter 7 no longer repeats Chapter 1. The Story now has twelve
        // distinct chapters and only cycles after the twelfth.
        XCTAssertNotEqual(BerryStoryNarrative.title(for: 1), BerryStoryNarrative.title(for: 7))
        XCTAssertEqual(BerryStoryNarrative.title(for: 1), BerryStoryNarrative.title(for: 13))
        XCTAssertFalse(BerryStoryNarrative.opening(for: 100).isEmpty)
    }

    func testEveryBlitzVariantHasIndependentScoreKeyAndCorrectClock() {
        let variants = BerryBlitzVariant.allCases
        XCTAssertEqual(variants.count, 4)
        XCTAssertEqual(variants.map(\.seconds).sorted(), [60, 120, 300, 600])
        XCTAssertEqual(Set(variants.map(\.bestScoreKey)).count, 4)
    }

    func testTimedAndNightmareModeNamesRemainIndependent() {
        XCTAssertEqual(BerryMode.challenge.rawValue, "Berry Blitz")
        XCTAssertEqual(BerryMode.superHard.rawValue, "Strawberry Nightmare")
    }
}
