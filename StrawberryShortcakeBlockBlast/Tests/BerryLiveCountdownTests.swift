import XCTest
import SwiftUI
import UIKit
@testable import BerryBlockBlast

@MainActor
final class BerryLiveCountdownTests: XCTestCase {
    func testDeadlineAlwaysUsesCurrentTimeRatherThanMissedTimerEvents() {
        let start = Date(timeIntervalSince1970: 10000)
        let deadline = start.addingTimeInterval(180)
        // Even if the UI thread misses 2, 6 or 34 seconds of callbacks,
        // the next render must reflect true time remaining.
        XCTAssertEqual(BerryCountdownMath.seconds(deadline: deadline,
                        now: start, pausedAt: nil, fallback: 180), 180)
        XCTAssertEqual(BerryCountdownMath.seconds(deadline: deadline,
                        now: start.addingTimeInterval(1.2),
                        pausedAt: nil, fallback: 180), 179)
        XCTAssertEqual(BerryCountdownMath.seconds(deadline: deadline,
                        now: start.addingTimeInterval(152.1),
                        pausedAt: nil, fallback: 180), 28)
        XCTAssertEqual(BerryCountdownMath.seconds(deadline: deadline,
                        now: start.addingTimeInterval(170.1),
                        pausedAt: nil, fallback: 180), 10)
        XCTAssertEqual(BerryCountdownMath.seconds(deadline: deadline,
                        now: start.addingTimeInterval(184),
                        pausedAt: nil, fallback: 180), 0)
    }

    func testPauseFreezesVisibleClockRegardlessOfActualWallTime() {
        let start = Date(timeIntervalSince1970: 11000)
        let deadline = start.addingTimeInterval(180)
        let paused = start.addingTimeInterval(75)
        for seconds in [75.0, 85, 150, 1000] {
            XCTAssertEqual(BerryCountdownMath.seconds(
                deadline: deadline,
                now: start.addingTimeInterval(seconds),
                pausedAt: paused, fallback: 180), 105)
        }
        // After a 40-second pause the authoritative parent deadline is
        // shifted 40 seconds so the resumed display remains continuous.
        let continued = deadline.addingTimeInterval(40)
        XCTAssertEqual(BerryCountdownMath.seconds(
            deadline: continued,
            now: start.addingTimeInterval(115),
            pausedAt: nil, fallback: 180), 105)
    }

    func testMinuteSecondFormattingAndClamping() {
        XCTAssertEqual(BerryCountdownMath.text(180), "3:00")
        XCTAssertEqual(BerryCountdownMath.text(60), "1:00")
        XCTAssertEqual(BerryCountdownMath.text(59), "0:59")
        XCTAssertEqual(BerryCountdownMath.text(9), "0:09")
        XCTAssertEqual(BerryCountdownMath.text(0), "0:00")
        XCTAssertEqual(BerryCountdownMath.text(-3), "0:00")
    }

    func testStandaloneClockRendersWithoutRebuildingFullBoard() {
        let remaining = BerryLiveCountdown(deadline: Date().addingTimeInterval(30),
                                           pausedAt: nil, fallbackSeconds: 30,
                                           running: true, fontSize: 35)
        let root = UIHostingController(rootView: remaining)
        root.view.frame = CGRect(x: 0, y: 0, width: 160, height: 60)
        root.view.layoutIfNeeded()
        XCTAssertEqual(root.view.bounds.width, 160)
        XCTAssertEqual(root.view.bounds.height, 60)
    }
}
