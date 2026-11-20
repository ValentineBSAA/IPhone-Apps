#if canImport(CoreGraphics)
import CoreGraphics
#else
// Foundation provides CGFloat for the Linux geometry preflight.
import Foundation
#endif

/// Shared, deterministic budget for the gameplay screen.
/// GeometryReader supplies the *safe* content height. Do not subtract the
/// safe-area insets from that height a second time. Reserve only the small
/// visual gutters actually applied by the view and leave all touch controls
/// fully accessible on the required iPhone 16e and other logical screen sizes.
enum BerryGameplayLayout {
    /// Shared inset of the physical board wrapper around its painted cells.
    /// Used identically for board touches, drag geometry and size budgeting.
    static let boardTouchMargin: CGFloat = 3
    /// Reserved ONLY for the decorative frame outside the touch-tracked grid.
    static let gardenFrameInset: CGFloat = 8
    /// Shared Build 4.6 width budget. XCTest and the pre-simulator Swift
    /// geometry check read this same value instead of stale percentages.
    static let boardWidthFraction: CGFloat = 0.92

    /// A no-ghost game setting cannot make a piece in hand invisible.
    /// The same rule applies to Mystery, Outline and Sweet Assist.
    static func showsCarriedPiece(previewStyle: String,
                                  dragging: Bool,
                                  fingerKnown: Bool) -> Bool {
        dragging && fingerKnown
    }

    /// iPhone 16e, 14 Pro, and other displays are laid out in logical points,
    /// never physical pixels or hard-coded device model identifiers.
    static func stackSpacing(for height: CGFloat) -> CGFloat {
        height < 740 ? 4 : 5
    }

    /// Every persistent HUD element contributes to the height budget. The
    /// board uses whatever is left, capped to a comfortable share of width.
    /// This is intentionally NOT a fixed 8x8 size: all modes, including the
    /// visible 12x12 sectors of Mega Garden, share one responsive geometry.
    static func boardSize(width: CGFloat, height: CGFloat, topInset: CGFloat,
                          bottomInset: CGFloat, mode: BerryMode,
                          megaGarden: Bool = false,
                          touchDiagnostics: Bool = false) -> CGFloat {
        let compact = height < 740
        let spacing = stackSpacing(for: height)
        // GeometryReader's height already excludes the safe-area top and
        // bottom. Never subtract those insets a second time.
        let topPad = max(4, topInset * 0.12)
        let bottomPad = max(4, bottomInset * 0.12)
        let topBar: CGFloat = compact ? 40 : 45
        let score: CGFloat = mode == .classic ? 69 :
            (mode == .superHard || mode == .challenge) ? 87 : 51
        let objective: CGFloat = mode == .story ? 0 :
            mode == .endless ? (compact ? 27 : 32) : 17
        let chapter: CGFloat = mode == .story ?
            (compact ? 33 + 36 : 36 + 40) : 0
        let daily: CGFloat = mode == .daily ? 36 : 0
        let endless: CGFloat = megaGarden ? 38 : 0
        let hint: CGFloat = 13
        let tray: CGFloat = compact ? 58 : 65
        let toolBar: CGFloat = 48
        let counters: CGFloat = 25
        let diagnostic: CGFloat = touchDiagnostics ? 20 : 0
        // Two flexible spacers absorb surplus space; an extra gap is
        // reserved whenever diagnostic / chapter / daily rows are present.
        let extraRows = (mode == .story ? 2 : 0) +
                        (mode == .daily ? 1 : 0) +
                        (megaGarden ? 1 : 0) +
                        (touchDiagnostics ? 1 : 0)
        let gaps = spacing * CGFloat(7 + extraRows)
        let border = (boardTouchMargin + gardenFrameInset) * 2
        let cushion: CGFloat = 10
        let reserved = topBar + score + objective + chapter + daily +
            endless + hint + tray + toolBar + counters + diagnostic +
            gaps + topPad + bottomPad + border + cushion
        let byHeight = height - reserved

        let horizontalOuterMargin: CGFloat = 6
        let byWidth = min(width, 510) - horizontalOuterMargin - border
        // Use more of the 16e's screen while retaining the 3pt board
        // touch margin, 8pt exterior-only Blossom border and safe HUD/tray.
        // The vertical height budget still wins whenever rows need room.
        let comfortableWidth = width * boardWidthFraction
        let requested = min(465, comfortableWidth, byWidth, byHeight)
        // The lower floor is for unusually constrained screens only; when
        // possible the 12x12 sector remains comfortably over 250pt.
        return max(150, requested)
    }
}
