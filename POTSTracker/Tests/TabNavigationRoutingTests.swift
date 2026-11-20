import XCTest
@testable import POTSTracker

/// The former bug was a stale Journal NavigationLink inside Home's cached
/// NavigationStack. These tests lock in root-navigation identity on tab entry.
final class TabNavigationRoutingTests: XCTestCase {
    func testReturningToHomeFromEveryOtherTabResetsHomeStack() {
        var routing = TabNavigationRevisions()
        XCTAssertEqual(routing.revision(for: .home), 0)

        for previousTab: TrackerTab in [.log, .history, .more] {
            routing.resetDestination(previousTab)
            let priorHome = routing.revision(for: .home)
            routing.resetDestination(.home)
            XCTAssertEqual(routing.revision(for: .home), priorHome + 1,
                           "Returning from \(previousTab) must recreate Home at its root")
        }
        XCTAssertEqual(routing.home, 3)
    }

    func testAllFourTabsHaveIndependentRootRevisions() {
        var routing = TabNavigationRevisions()
        routing.resetDestination(.log)
        XCTAssertEqual(routing.log, 1)
        XCTAssertEqual(routing.home, 0)
        XCTAssertEqual(routing.history, 0)
        XCTAssertEqual(routing.more, 0)

        routing.resetDestination(.history)
        XCTAssertEqual(routing.history, 1)
        XCTAssertEqual(routing.home, 0)
        XCTAssertEqual(routing.log, 1)

        routing.resetDestination(.more)
        XCTAssertEqual(routing.more, 1)
        XCTAssertEqual(routing.history, 1)

        routing.resetDestination(.home)
        XCTAssertEqual(routing.home, 1)
    }

    func testJournalToAnotherTabThenHomeDiscardsThePriorHomeRoute() {
        var routing = TabNavigationRevisions()
        let journalHomeRevision = routing.home

        // Home > Journal > Log > Home: root identity must be NEW.
        routing.resetDestination(.log)
        routing.resetDestination(.home)
        XCTAssertNotEqual(routing.home, journalHomeRevision)

        // Another visit to Journal followed by History > Home also resets.
        let secondJournalHomeRevision = routing.home
        routing.resetDestination(.history)
        routing.resetDestination(.home)
        XCTAssertNotEqual(routing.home, secondJournalHomeRevision)
    }

    func testRepeatedTabTripsDoNotShareHistoryAmongTabs() {
        var routing = TabNavigationRevisions()
        for _ in 0..<10 {
            routing.resetDestination(.log)
            routing.resetDestination(.home)
            routing.resetDestination(.more)
            routing.resetDestination(.history)
        }
        XCTAssertEqual(routing.home, 10)
        XCTAssertEqual(routing.log, 10)
        XCTAssertEqual(routing.more, 10)
        XCTAssertEqual(routing.history, 10)
    }
}
