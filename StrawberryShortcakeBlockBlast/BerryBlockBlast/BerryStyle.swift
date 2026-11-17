import SwiftUI

enum BerryStyle {
    static let chocolate = Color(red: 0.38, green: 0.20, blue: 0.24)
    static let strawberry = Color(red: 0.91, green: 0.21, blue: 0.37)
    static let cream = Color(red: 1.00, green: 0.97, blue: 0.92)
    static let softPink = Color(red: 1.00, green: 0.87, blue: 0.90)
    static let leaf = Color(red: 0.34, green: 0.63, blue: 0.36)

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

    private var skin: String { skinOverride ?? blockSkin }
    private var decorated: Bool { strawberryUnlocked && tint % 6 == 0 }
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
        ZStack(alignment: .topLeading) {
            ForEach(piece.points, id: \.self) { cell in
                BerryTile(tint: piece.tint, mode: mode, strawberryUnlocked: strawberryUnlocked)
                    .frame(width: unit - 2, height: unit - 2)
                    .offset(x: CGFloat(cell.col) * unit, y: CGFloat(cell.row) * unit)
            }
        }
        .frame(width: CGFloat(piece.width) * unit, height: CGFloat(piece.height) * unit, alignment: .topLeading)
    }
}
