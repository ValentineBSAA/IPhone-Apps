import CoreGraphics

/// Shared, deterministic budget for the gameplay screen.
/// GeometryReader supplies the usable content height; do not subtract the
/// safe-area insets from that height a second time. Instead reserve only the
/// top/bottom padding actually applied by the view.
enum BerryGameplayLayout {
    static func boardSize(width: CGFloat, height: CGFloat, topInset: CGFloat,
                          bottomInset: CGFloat, mode: BerryMode,
                          megaGarden: Bool = false) -> CGFloat {
        let compact = height < 740
        let spacing: CGFloat = compact ? 4 : 5
        let topPad = max(8, topInset * 0.48)
        let bottomPad = max(8, bottomInset * 0.55)
        let topBar: CGFloat = compact ? 36 : 42
        let score: CGFloat = mode == .classic ? 69 :
            mode == .superHard ? 87 :
            mode == .challenge ? 83 : 51
        let objective: CGFloat = mode == .story ? 0 : 17
        let chapter: CGFloat = mode == .story ? (compact ? 33 : 36) +
            (compact ? 36 : 40) : 0
        let daily: CGFloat = mode == .daily ? 36 : 0
        let endless: CGFloat = megaGarden ? 38 : 0
        let hint: CGFloat = 13
        let tray: CGFloat = compact ? 58 : 65
        let toolBar: CGFloat = 46
        let counters: CGFloat = 25
        // title, score, objective/chapter, board, hint, tray, tools, counters.
        // Smaller gap budget for seven common blocks, extra for chapters.
        let gaps: CGFloat = spacing * (mode == .story ? 8 : 7)
        // Board interaction has a seven-point non-tappable frame on each side.
        let border: CGFloat = 14
        // Defensive margin for differences in the internal HUD layout,
        // Dynamic Type and rounding. All listed controls remain tappable.
        let cushion: CGFloat = 14
        let occupied = topBar + score + objective + chapter + daily + endless +
            hint + tray + toolBar + counters + gaps +
            topPad + bottomPad + border + cushion
        let byHeight = max(150, height - occupied)
        // Ten horizontal points of outer content padding plus 14-point board
        // interaction frame must fit 100% within the safe area.
        let byWidth = max(150, min(width, 510) - 24)
        return min(465, byWidth, byHeight)
    }
}
