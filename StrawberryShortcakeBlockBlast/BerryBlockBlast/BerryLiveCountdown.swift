import SwiftUI
import Foundation

/// One source of truth for countdown rendering. We derive visible seconds from
/// the absolute deadline rather than decrementing a counter when a scheduled
/// callback happens. If an animation or a drag causes a missed callback, the
/// display returns to the correct current value, never an incorrect clock.
enum BerryCountdownMath {
    static func seconds(deadline: Date?, now: Date,
                        pausedAt: Date?, fallback: Int) -> Int {
        guard let deadline else { return max(0, fallback) }
        let effectiveNow = pausedAt ?? now
        return max(0, Int(ceil(deadline.timeIntervalSince(effectiveNow))))
    }

    /// Pauses are measured against wall-clock time exactly once on resume.
    /// This handles a locked iPhone that wakes long after the original
    /// deadline, without consuming the remaining Nightmare seconds.
    static func restoredDeadline(_ deadline: Date?, pausedAt: Date?,
                                 resumedAt: Date) -> Date? {
        guard let deadline, let pausedAt else { return deadline }
        return deadline.addingTimeInterval(max(0, resumedAt.timeIntervalSince(pausedAt)))
    }

    /// A displayed menu must never remain responsive while an expired,
    /// unadjusted deadline silently rejects every gameplay touch.
    static func canAcceptTimedMove(running: Bool, deadline: Date?,
                                   pausedAt: Date?, now: Date) -> Bool {
        guard running, pausedAt == nil, let deadline else { return false }
        return deadline > now
    }

    static func text(_ seconds: Int) -> String {
        String(format: "%d:%02d", max(0, seconds) / 60, max(0, seconds) % 60)
    }
}

/// Separate TimelineView prevents a 12x12 board, animated blocks, and every
/// drag update from owning the refresh of the displayed clock. This is
/// intentionally a tiny view: only the digits and their color re-evaluate.
/// The game-over state and reward logic remain in BerryGameView.
struct BerryLiveCountdown: View {
    let deadline: Date?
    let pausedAt: Date?
    let fallbackSeconds: Int
    let running: Bool
    var fontSize: CGFloat = 35
    var label: String = "Time remaining"

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.2)) { tick in
            let live = running && deadline != nil
            let remaining = live
                ? BerryCountdownMath.seconds(deadline: deadline,
                                             now: tick.date,
                                             pausedAt: pausedAt,
                                             fallback: fallbackSeconds)
                : max(0, fallbackSeconds)
            Text(BerryCountdownMath.text(remaining))
                .font(.system(size: fontSize,
                              weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(remaining <= 10 && running ?
                    BerryStyle.urgentTimerGradient : BerryStyle.timerGradient)
                .accessibilityLabel("\(label): \(remaining) seconds")
                .accessibilityIdentifier("berry-live-countdown")
                .transaction { transaction in
                    // Do not animate a frame arriving late into apparently
                    // jumping or morphing digits.
                    transaction.animation = nil
                }
        }
    }
}
