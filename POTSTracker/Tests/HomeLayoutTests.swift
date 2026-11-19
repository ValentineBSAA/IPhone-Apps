import XCTest
@testable import POTSTracker

final class HomeLayoutTests: XCTestCase {
    func testDefaultHomeIsShortAndPrioritized() {
        let modules = HomeLayout.orderedModules(from: HomeLayout.moduleDefault)
        XCTAssertEqual(modules.map(\.id), ["today", "recent", "checkIn", "favorites"])
        XCTAssertEqual(HomeLayout.pinned(from: HomeLayout.pinDefault).map(\.id),
                       ["symptom", "heartRate", "bloodPressure", "journal"])
    }

    func testHomeSectionReorderingPersistsStableIDs() {
        let shuffled = HomeLayout.move("favorites", in: HomeLayout.orderedModules(from: HomeLayout.moduleDefault).map(\.id), by: -1)
        XCTAssertEqual(HomeLayout.orderedModules(from: shuffled).map(\.id),
                       ["today", "recent", "favorites", "checkIn"])
    }

    func testBadStoredPreferencesCannotInventTrackersOrLoseSections() {
        XCTAssertEqual(HomeLayout.orderedModules(from: "recent,recent,invalid,today").map(\.id),
                       ["recent", "today", "checkIn", "favorites"])
        XCTAssertEqual(HomeLayout.pinned(from: "journal,invalid,journal,heartRate").map(\.id),
                       ["journal", "heartRate"])
        XCTAssertEqual(HomeLayout.pinned(from: "").count, 0)
    }

    func testMoveAtBoundariesDoesNotCorruptPreferences() {
        XCTAssertEqual(HomeLayout.move("today", in: ["today", "checkIn"], by: -1),
                       "today,checkIn")
        XCTAssertEqual(HomeLayout.move("checkIn", in: ["today", "checkIn"], by: 1),
                       "today,checkIn")
    }
}