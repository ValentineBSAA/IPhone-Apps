import XCTest
import Foundation
@testable import BerryBlockBlast

final class BerryTimedLifecycleTests: XCTestCase {
    func testLockAndUnlockRestoresTimeAndMovesAfterLongBackground() {
        let start = Date(timeIntervalSince1970: 20000)
        let initialDeadline = start.addingTimeInterval(180)
        let paused = start.addingTimeInterval(62)
        let before = BerryTimedLifecycle.pausedSeconds(
            deadline: initialDeadline, pausedAt: paused, fallback: 180)
        XCTAssertEqual(before, 118)

        for lockDuration: TimeInterval in [0.3, 5, 90, 240, 3600] {
            let resumed = paused.addingTimeInterval(lockDuration)
            let restored = BerryTimedLifecycle.restoredDeadline(
                initialDeadline, pausedAt: paused, resumedAt: resumed)
            XCTAssertEqual(BerryCountdownMath.seconds(
                deadline: restored, now: resumed,
                pausedAt: nil, fallback: 0), before)
            XCTAssertTrue(BerryTimedLifecycle.canPlay(
                now: resumed, deadline: restored, running: true,
                foreground: true, pausedAt: nil),
                "Unlock after \(lockDuration)s must permit gameplay")
            XCTAssertFalse(BerryTimedLifecycle.canPlay(
                now: resumed, deadline: initialDeadline, running: true,
                foreground: false, pausedAt: paused),
                "A locked phone must reject moves")
        }
    }

    func testLockedPhoneAndInterruptedPauseBlockGameplayWithoutCorruptingTime() {
        let started = Date(timeIntervalSince1970: 1000)
        let deadline = started.addingTimeInterval(180)
        let paused = started.addingTimeInterval(80)
        XCTAssertFalse(BerryTimedLifecycle.canPlay(
            now: paused, deadline: deadline, running: true,
            foreground: false, pausedAt: nil))
        XCTAssertFalse(BerryTimedLifecycle.canPlay(
            now: paused, deadline: deadline, running: true,
            foreground: true, pausedAt: paused))
        XCTAssertTrue(BerryTimedLifecycle.canResume(
            foreground: true, running: true, manualPause: false,
            anyOverlayOpen: false, pausedAt: paused))
        XCTAssertFalse(BerryTimedLifecycle.canResume(
            foreground: false, running: true, manualPause: false,
            anyOverlayOpen: false, pausedAt: paused))
        XCTAssertFalse(BerryTimedLifecycle.canResume(
            foreground: true, running: true, manualPause: true,
            anyOverlayOpen: false, pausedAt: paused))
        XCTAssertFalse(BerryTimedLifecycle.canResume(
            foreground: true, running: true, manualPause: false,
            anyOverlayOpen: true, pausedAt: paused))
    }

    func testDuplicateResumeCannotExtendTimerTwice() {
        let paused = Date(timeIntervalSince1970: 4000)
        let resumed = paused.addingTimeInterval(125)
        let original = paused.addingTimeInterval(48)
        let corrected = BerryTimedLifecycle.restoredDeadline(original,
                            pausedAt: paused, resumedAt: resumed)
        XCTAssertEqual(corrected?.timeIntervalSince1970 ?? 0,
                       original.addingTimeInterval(125).timeIntervalSince1970,
                       accuracy: 0.0001)
        // Caller clears pausedTimerAt after resuming. Missing pause state
        // must prevent a second deadline extension from an active callback.
        XCTAssertFalse(BerryTimedLifecycle.canResume(
            foreground: true, running: true, manualPause: false,
            anyOverlayOpen: false, pausedAt: nil))
    }

    func testExpiredRunStaysExpiredAndDoesNotAwardExtraTimeOnUnlock() {
        let now = Date(timeIntervalSince1970: 5000)
        XCTAssertFalse(BerryTimedLifecycle.canPlay(
            now: now, deadline: now, running: true,
            foreground: true, pausedAt: nil))
        XCTAssertFalse(BerryTimedLifecycle.canPlay(
            now: now, deadline: now.addingTimeInterval(30),
            running: false, foreground: true, pausedAt: nil))
        XCTAssertFalse(BerryTimedLifecycle.canResume(
            foreground: true, running: false, manualPause: false,
            anyOverlayOpen: false, pausedAt: now))
    }

    func testRealCountdownRestartsAfterForegroundTransition() {
        let start = Date(timeIntervalSince1970: 6000)
        let deadline = start.addingTimeInterval(180)
        let paused = start.addingTimeInterval(12)
        let resumed = paused.addingTimeInterval(500)
        let corrected = BerryTimedLifecycle.restoredDeadline(
            deadline, pausedAt: paused, resumedAt: resumed)
        XCTAssertEqual(BerryCountdownMath.seconds(
            deadline: corrected, now: resumed,
            pausedAt: nil, fallback: 180), 168)
        XCTAssertEqual(BerryCountdownMath.seconds(
            deadline: corrected, now: resumed.addingTimeInterval(10.1),
            pausedAt: nil, fallback: 180), 158)
    }
}
