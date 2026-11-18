import Foundation

/// Small, testable state transitions for timed gameplay across iPhone
/// Lock Screen, notification shade, phone calls, and app switching.
/// The timer is authoritative, never an accumulating count of UI callbacks.
enum BerryTimedLifecycle {
    static func pausedSeconds(deadline: Date?, pausedAt: Date, fallback: Int) -> Int {
        BerryCountdownMath.seconds(deadline: deadline, now: pausedAt,
                                   pausedAt: pausedAt, fallback: fallback)
    }

    static func restoredDeadline(_ deadline: Date?, pausedAt: Date,
                                 resumedAt: Date) -> Date? {
        guard let deadline else { return nil }
        return deadline.addingTimeInterval(max(0, resumedAt.timeIntervalSince(pausedAt)))
    }

    static func canResume(foreground: Bool, running: Bool,
                          manualPause: Bool, anyOverlayOpen: Bool,
                          pausedAt: Date?) -> Bool {
        foreground && running && !manualPause && !anyOverlayOpen && pausedAt != nil
    }

    static func canPlay(now: Date, deadline: Date?, running: Bool,
                        foreground: Bool, pausedAt: Date?) -> Bool {
        guard foreground, running, pausedAt == nil,
              let deadline else { return false }
        return now < deadline
    }
}
