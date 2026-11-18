import CoreGraphics

/// Shared, deterministic budget for the gameplay screen.
/// GeometryReader supplies the *safe* content height. Do not subtract the
/// safe-area insets from that height a second time. Reserve only the small
/// visual gutters actually applied by the view and leave all touch controls
/// fully accessible on 393-point iPhone 14 Pro and iPhone 16 screens.
enum BerryGameplayLayout {
    /// A no-ghost game setting cannot make a piece in hand invisible.
    /// The same rule applies to Mystery, Outline and Sweet Assist.
    static func showsCarriedPiece(previewStyle: String,
                                  dragging: Bool,
                                  fingerKnown: Bool) -> Bool {
        dragging && fingerKnown
    }

    static func boardSize(width: CGFloat, height: CGFloat, topInset: CGFloat,
                          bottomInset: CGFloat, mode: BerryMode,
                          megaGarden: Bool = false) -> CGFloat {
        let compact = height < 740
        let spacing: CGFloat = compact ? 4 : 5
        let topPad = max(6, topInset * 0.18)
        let bottomPad = max(6, bottomInset * 0.18)
        let topBar: CGFloat = compact ? 40 : 45
        let score: CGFloat = mode == .classic ? 69 :
            mode == .superHard ? 87 :
            mode == .challenge ? 87 : 51
        let objective: CGFloat = mode == .story ? 0 : 17
        let chapter: CGFloat = mode == .story ? (compact ? 33 : 36) +
            (compact ? 36 : 40) : 0
        let daily: CGFloat = mode == .daily ? 36 : 0
        let endless: CGFloat = megaGarden ? 38 : 0
        let hint: CGFloat = 13
        let tray: CGFloat = compact ? 58 : 65
        let toolBar: CGFloat = 48
        let counters: CGFloat = 25
        // title, score, objective/chapter, board, hint, tray, tools, counters.
        // Smaller gap budget for seven common blocks, extra for chapters.
        let gaps: CGFloat = spacing * (mode == .story ? 8 : 7)
        // Board touch wrapper now has only 3-point padding on each side.
        let border: CGFloat = 6
        // Defensive margin for differences in the internal HUD layout,
        // Dynamic Type and rounding. All listed controls remain tappable.
        let cushion: CGFloat = 12
        let occupied = topBar + score + objective + chapter + daily + endless +
            hint + tray + toolBar + counters + gaps +
            topPad + bottomPad + border + cushion
        let byHeight = max(150, height - occupied)
        // Six horizontal points of outer content padding plus 6-point board
        // interaction frame must fit fully inside the safe-area width.
        let byWidth = max(150, min(width, 510) - 12)
        return min(465, byWidth, byHeight)
    }
}
