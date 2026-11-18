import XCTest
@testable import BerryBlockBlast

final class BerryStoryNarrativeTests: XCTestCase {
    func testTwelveOriginalChaptersHaveDistinctTitles() {
        let titles = (1...12).map { BerryStoryNarrative.title(for: $0) }
        XCTAssertEqual(titles.count, 12)
        XCTAssertEqual(Set(titles).count, 12,
                       "Story progression must not repeat after the first festival")
    }

    func testEveryStoryChapterHasOpeningProgressAndEndingDialogue() {
        for chapter in 1...12 {
            let opening = BerryStoryNarrative.opening(for: chapter)
            let encouragement = BerryStoryNarrative.encouragement(for: chapter)
            let victory = BerryStoryNarrative.victory(for: chapter)
            XCTAssertGreaterThan(opening.count, 30)
            XCTAssertGreaterThan(encouragement.count, 25)
            XCTAssertGreaterThan(victory.count, 30)
            XCTAssertNotEqual(opening, victory)
        }
    }

    func testLongRunningStoryRemainsValidAfterChapterTwelve() {
        XCTAssertFalse(BerryStoryNarrative.title(for: 13).isEmpty)
        XCTAssertFalse(BerryStoryNarrative.opening(for: 24).isEmpty)
    }
}
