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

    private var decorated: Bool { strawberryUnlocked && tint % 6 == 0 }
    private var palette: Color {
        switch mode {
        case .endless: BerryStyle.color(for: tint)
        case .story: [Color(red: 0.92, green: 0.38, blue: 0.64), .purple, .orange, .pink, .mint, .indigo][(tint % 6 + 6) % 6]
        case .daily: [Color(red: 0.94, green: 0.43, blue: 0.35), .yellow, .orange, .green, .red, .brown][(tint % 6 + 6) % 6]
        case .cozy: [Color(red: 0.76, green: 0.58, blue: 0.44), Color(red: 0.83, green: 0.67, blue: 0.52), .mint, Color(red: 0.68, green: 0.77, blue: 0.52), .orange, .teal][(tint % 6 + 6) % 6]
        case .challenge: [.red, .orange, .yellow, .pink, .purple, .cyan][(tint % 6 + 6) % 6]
        }
    }
    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(LinearGradient(colors: [palette.opacity(0.82), palette],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(0.30))
                    .frame(width: 11, height: 5)
                    .padding(5)
            }
            .overlay {
                if decorated {
                    Text("🍓").font(.system(size: 21)).minimumScaleFactor(0.5).shadow(color: .white.opacity(0.6), radius: 1)
                } else if mode == .cozy {
                    Image(systemName: "leaf.fill").font(.system(size: 11)).foregroundStyle(.white.opacity(0.75))
                } else if mode == .story {
                    Image(systemName: "sparkle").font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
                } else if mode == .daily {
                    Image(systemName: "sun.max.fill").font(.system(size: 10)).foregroundStyle(.white.opacity(0.65))
                } else if mode == .challenge {
                    Image(systemName: "bolt.fill").font(.system(size: 11)).foregroundStyle(.white.opacity(0.75))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 7).strokeBorder(.white.opacity(0.43), lineWidth: 1.2)
            }
            .shadow(color: palette.opacity(preview ? 0.12 : 0.22), radius: 3, y: 2)
            .opacity(preview ? 0.67 : 1)
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
