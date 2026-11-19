import CoreGraphics

/// Shared, deterministic budget for the gameplay screen.
/// GeometryReader supplies the *safe* content height. Do not subtract the
/// safe-area insets from that height a second time. Reserve only the small
/// visual gutters actually applied by the view and leave all touch controls
/// fully accessible on 393-point iPhone 14 Pro and iPhone 16 screens.
enum BerryGameplayLayout {
    /// Shared inset of the physical board wrapper around its painted cells.
    /// Used identically for board touches, drag geometry and size budgeting.
    static let boardTouchMargin: CGFloat = 3
    /// Reserved ONLY for the decorative frame outside the touch-tracked grid.
    static let gardenFrameInset: CGFloat = 8

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
        let topPad = max(6, topInset * 0.18)
        let bottomPad = max(6, bottomInset * 0.18)
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
        let cushion: CGFloat = 18
        let reserved = topBar + score + objective + chapter + daily +
            endless + hint + tray + toolBar + counters + diagnostic +
            gaps + topPad + bottomPad + border + cushion
        let byHeight = height - reserved

        let horizontalOuterMargin: CGFloat = 6
        let byWidth = min(width, 510) - horizontalOuterMargin - border
        // A controlled reduction from the old almost edge-to-edge 365pt
        // board: 87% of available width means a ~339-342pt playable board
        // on the two test phones. The HUD can grow without hiding the tray.
        let comfortableWidth = width * 0.87
        let requested = min(465, comfortableWidth, byWidth, byHeight)
        // The lower floor is for unusually constrained screens only; when
        // possible the 12x12 sector remains comfortably over 250pt.
        return max(150, requested)
    }
}
