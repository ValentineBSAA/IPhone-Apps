import SwiftUI
import UIKit

enum BerryStyle {
    static let chocolate = Color(red: 0.38, green: 0.20, blue: 0.24)
    static let strawberry = Color(red: 0.91, green: 0.21, blue: 0.37)
    static let cream = Color(red: 1.00, green: 0.97, blue: 0.92)
    static let softPink = Color(red: 1.00, green: 0.87, blue: 0.90)
    static let leaf = Color(red: 0.34, green: 0.63, blue: 0.36)
    /// The glowing Classic Score's palette, reused on all numerical progress.
    /// Text remains rendered with SwiftUI so dynamic scores and accessibility
    /// work normally on iOS 16.
    static let candyNumberGradient = LinearGradient(
        colors: [strawberry,
                 Color(red: 1.00, green: 0.36, blue: 0.48),
                 Color(red: 0.92, green: 0.50, blue: 0.14)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )


    /// Distinct timers: purple berry-glass under normal conditions and
    /// red-to-gold urgency for the final ten seconds.
    static let timerGradient = LinearGradient(
        colors: [Color(red: 0.49, green: 0.18, blue: 0.65),
                 Color(red: 0.83, green: 0.22, blue: 0.55),
                 Color(red: 0.94, green: 0.34, blue: 0.43)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let urgentTimerGradient = LinearGradient(
        colors: [Color(red: 0.84, green: 0.06, blue: 0.25),
                 Color(red: 1.00, green: 0.34, blue: 0.17),
                 Color(red: 1.00, green: 0.66, blue: 0.18)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static func color(for tint: Int) -> Color {
        switch (tint % 6 + 6) % 6 {
        case 0: return Color(red: 0.96, green: 0.26, blue: 0.38) // berry red
        case 1: return Color(red: 0.97, green: 0.56, blue: 0.66) // frosting pink
        case 2: return Color(red: 0.52, green: 0.74, blue: 0.35) // leaf green
        case 3: return Color(red: 0.66, green: 0.47, blue: 0.84) // blueberry violet
        case 4: return Color(red: 1.00, green: 0.72, blue: 0.32) // sunny citrus
        default: return Color(red: 0.38, green: 0.76, blue: 0.75) // mint
        }
    }
}

struct BerryTile: View {
    let tint: Int
    var preview = false
    var mode: BerryMode = .endless
    var strawberryUnlocked = false
    /// Preview a boutique skin without changing the player's actual selection.
    var skinOverride: String? = nil
    @AppStorage("berryblockblast.shop.equippedBlockSkin.v056b2") private var blockSkin = "default"
    @AppStorage("berryblockblast.shop.equippedSparkle.v056b2") private var sparkles = "default"
    @AppStorage("berryberryblast.trophies.strawberry-red-on.v0512") private var strawberryRewardOn = true

    private var skin: String { skinOverride ?? blockSkin }
    /// Restored original 0.5.8 square candy blocks for the default style.
    /// Sculpted fruit shapes are kept only for the optional Boutique skin.
    private var fruitImage: String? {
        guard skin == "strawberry-fruit" else { return nil }
        switch (tint % 6 + 6) % 6 {
        case 0: return "BerryFruitStrawberry"
        case 1: return "BerryFruitRaspberry"
        case 2: return "BerryFruitMint"
        case 3: return "BerryFruitBlueberry"
        case 4: return "BerryFruitLemon"
        default: return "BerryFruitMint"
        }
    }
    private var rewardArt: String? {
        BerryTrophyCatalog.enabledArt(skin: skin, tint: tint,
                                      legacyStrawberry: strawberryUnlocked,
                                      strawberryEnabled: strawberryRewardOn)
    }
    private var decorated: Bool {
        strawberryUnlocked && strawberryRewardOn && (tint % 6 + 6) % 6 == 0 &&
        skin == "default" && (rewardArt == nil || UIImage(named: rewardArt!) == nil)
    }
    /// Prepared 0.5.8 art catalog: each square remains an exact grid cell.
    private var artName: String? {
        switch skin {
        case "default", "strawberry-fruit": return nil
        case "raspberry-blocks": return "RaspberryRubyBlock"
        case "lemon-blocks": return "LemonGlazeBlock"
        case "chocolate-blocks": return "ChocolateTruffleBlock"
        case "mint-blocks": return "MintFrostBlock"
        case "blackberry-blocks": return "BlackberryJamBlock"
        default: return nil
        }
    }
    private var palette: Color {
        let index = (tint % 6 + 6) % 6
        if skin == "blueberry-blocks" {
            return [Color(red: 0.20, green: 0.25, blue: 0.72),
                    Color(red: 0.34, green: 0.20, blue: 0.67),
                    Color(red: 0.17, green: 0.39, blue: 0.73),
                    Color(red: 0.44, green: 0.23, blue: 0.77),
                    Color(red: 0.21, green: 0.32, blue: 0.62),
                    Color(red: 0.28, green: 0.17, blue: 0.61)][index]
        }
        if skin == "vanilla-blocks" {
            return [Color(red: 0.92, green: 0.64, blue: 0.27),
                    Color(red: 0.95, green: 0.76, blue: 0.45),
                    Color(red: 0.79, green: 0.47, blue: 0.23),
                    Color(red: 0.95, green: 0.70, blue: 0.37),
                    Color(red: 0.83, green: 0.56, blue: 0.24),
                    Color(red: 0.88, green: 0.66, blue: 0.41)][index]
        }
        if skin == "raspberry-blocks" { return Color(red: 0.82, green: 0.07, blue: 0.28) }
        if skin == "lemon-blocks" { return Color(red: 0.97, green: 0.72, blue: 0.10) }
        if skin == "chocolate-blocks" { return Color(red: 0.44, green: 0.18, blue: 0.12) }
        if skin == "mint-blocks" { return Color(red: 0.18, green: 0.77, blue: 0.55) }
        if skin == "blackberry-blocks" { return Color(red: 0.35, green: 0.06, blue: 0.44) }
        switch mode {
        case .endless, .classic: return BerryStyle.color(for: tint)
        case .story: return [Color(red: 0.92, green: 0.31, blue: 0.57), .purple, .orange, .pink, .mint, .indigo][index]
        case .daily: return [Color(red: 0.92, green: 0.30, blue: 0.29), .yellow, .orange, .green, .red, .brown][index]
        case .cozy: return [Color(red: 0.76, green: 0.58, blue: 0.44), Color(red: 0.83, green: 0.67, blue: 0.52), .mint, Color(red: 0.68, green: 0.77, blue: 0.52), .orange, .teal][index]
        case .challenge: return [.red, .orange, .yellow, .pink, .purple, .cyan][index]
        case .superHard: return [Color(red: 0.62, green: 0.12, blue: 0.29), .purple, .indigo, .red, .orange, .pink][index]
        }
    }
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let radius = max(3, side * 0.19)
            if let art = rewardArt, UIImage(named: art) != nil {
                // Cosmetic replaces ONLY the matching tinted square, never its
                // hitbox, engine value or accessibility position. Remaining
                // colors keep their classic appearance for legibility.
                Image(art)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: side, height: side)
                    .shadow(color: palette.opacity(0.20), radius: max(0.5, side * 0.06), y: 1)
                    .accessibilityLabel("Unlocked special candy block")
            } else if let art = fruitImage, UIImage(named: art) != nil {
                // Transparent fruit silhouettes, while square grid cells
                // remain unchanged for drag/drop placement and scoring.
                Image(art)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: side, height: side)
                    .shadow(color: palette.opacity(preview ? 0.10 : 0.22),
                            radius: max(0.5, side * 0.06), y: 1)
                    .accessibilityLabel("Sculpted \(art.replacingOccurrences(of: "BerryFruit", with: "")) puzzle block")
            } else if skin == "strawberry-fruit" {
                // Legacy fruit cosmetic remains available only by choice.
                // Default blocks must use the full original square tile.
                Image("BerryRealStrawberry")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: side, height: side)
                    .shadow(color: Color(red: 0.66, green: 0.1, blue: 0.22).opacity(0.26),
                            radius: max(1, side * 0.08), y: 1)
                    .accessibilityLabel("Three-dimensional strawberry fruit block")
            } else if skin == "default" && (mode == .classic || mode == .endless) &&
                        (tint % 6 + 6) % 6 == 1 {
                // Approved deeper-raspberry image replaces the original pink
                // square on gameplay, in-hand pieces and tray previews.
                // The touch geometry, other colors and boutique skins remain unchanged.
                Image("Tile_Pink")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: side, height: side)
                    .shadow(color: Color(red: 0.51, green: 0.02, blue: 0.20)
                                .opacity(preview ? 0.10 : 0.20),
                            radius: max(0.5, side * 0.04), y: 1)
                    .accessibilityLabel("Deep raspberry pink candy block")
            } else {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(LinearGradient(colors: [palette.opacity(0.78), palette, palette.opacity(0.98)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(palette.opacity(0.74), lineWidth: max(1, side * 0.065))
                }
                .overlay(alignment: .topLeading) {
                    Capsule()
                        .fill(.white.opacity(skin == "blueberry-blocks" ? 0.75 : 0.65))
                        .frame(width: side * 0.46, height: max(2, side * 0.13))
                        .padding(.top, side * 0.13).padding(.leading, side * 0.12)
                }
                .overlay {
                    if side > 23 {
                        if decorated {
                            Text("🍓").font(.system(size: side * 0.50))
                                .minimumScaleFactor(0.3)
                        } else if skin == "blueberry-blocks" {
                            Image(systemName: "sparkle")
                                .font(.system(size: side * 0.37, weight: .medium))
                                .foregroundStyle(Color(red: 0.89, green: 0.82, blue: 1))
                                .shadow(color: .white, radius: 2)
                        } else if skin == "vanilla-blocks" {
                            Image(systemName: "circle.hexagongrid.fill")
                                .font(.system(size: side * 0.34, weight: .regular))
                                .foregroundStyle(.white.opacity(0.72))
                        } else if sparkles == "berry-sparkle" {
                            Image(systemName: "sparkles")
                                .font(.system(size: side * 0.38))
                                .foregroundStyle(.white.opacity(0.95))
                        } else {
                            HStack(spacing: max(2, side * 0.12)) {
                                Capsule().fill(.white.opacity(0.55)).frame(width: 3, height: side * 0.11)
                                Capsule().fill(.white.opacity(0.42)).frame(width: 3, height: side * 0.11)
                            }.rotationEffect(.degrees(24)).offset(y: side * 0.13)
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(.white.opacity(0.12))
                        .frame(height: side * 0.13)
                        .padding(.horizontal, max(2, side * 0.08))
                        .padding(.bottom, max(2, side * 0.08))
                }
                .shadow(color: palette.opacity(preview ? 0.10 : 0.24), radius: 2, y: 2)
                .overlay {
                    if let asset = artName {
                        Image(asset)
                            .resizable()
                            .interpolation(.medium)
                            .scaledToFill()
                            .frame(width: side, height: side)
                            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .opacity(preview ? 0.80 : 1)
    }
}

struct BerryPieceGlyph: View {
    let piece: BerryPiece
    let unit: CGFloat
    var mode: BerryMode = .endless
    var strawberryUnlocked = false

    var body: some View {
        let tileSide = max(3, unit - 2)
        let fill = BerryStyle.color(for: piece.tint)

        // Deterministic actual-grid layout: no offsets, no .position, and no
        // expanding ZStacks. A three-slot tray is only as reliable as every
        // child being measured at its *real* width and height.
        VStack(alignment: .leading, spacing: 2) {
            ForEach(0..<piece.height, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<piece.width, id: \.self) { col in
                        if piece.points.contains(where: { $0.row == row && $0.col == col }) {
                            BerryTile(tint: piece.tint, mode: mode,
                                      strawberryUnlocked: strawberryUnlocked)
                                .frame(width: tileSide, height: tileSide)
                                // A solid colored square remains visible if
                                // an optional cosmetic has transparent pixels
                                // or SwiftUI fails to resolve an asset.
                                .background(
                                    RoundedRectangle(cornerRadius: max(2, unit * 0.17))
                                        .fill(fill)
                                )
                                .accessibilityHidden(true)
                        } else {
                            Color.clear
                                .frame(width: tileSide, height: tileSide)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .frame(height: tileSide, alignment: .leading)
            }
        }
        .frame(width: CGFloat(piece.width) * unit - 2,
               height: CGFloat(piece.height) * unit - 2,
               alignment: .topLeading)
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityLabel("Visible \(piece.points.count)-square berry piece")
    }
}


/// Shared readable gradient for Score, Best, Lines, Moves, Combo, records and
/// chapter counters. Does not alter the scoring engine or saved preferences.
struct BerryCandyNumber: View {
    let value: String
    var size: CGFloat = 20
    var label: String? = nil

    var body: some View {
        Text(value)
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundStyle(BerryStyle.candyNumberGradient)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .accessibilityLabel(label.map { $0 + ": " + value } ?? value)
    }
}

/// Consistent vertical result tile used on Game Over / Chapter Complete.
struct BerryCandyResultCounter: View {
    let title: String
    let value: Int
    var body: some View {
        VStack(spacing: 3) {
            BerryCandyNumber(value: value.formatted(), size: 24, label: title)
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.78))
        }
        .frame(maxWidth: .infinity)
    }
}
