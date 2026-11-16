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

    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(LinearGradient(colors: [BerryStyle.color(for: tint).opacity(0.82), BerryStyle.color(for: tint)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(0.30))
                    .frame(width: 11, height: 5)
                    .padding(5)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 7).strokeBorder(.white.opacity(0.43), lineWidth: 1.2)
            }
            .shadow(color: BerryStyle.color(for: tint).opacity(preview ? 0.12 : 0.22), radius: 3, y: 2)
            .opacity(preview ? 0.67 : 1)
    }
}

struct BerryPieceGlyph: View {
    let piece: BerryPiece
    let unit: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(piece.points, id: \.self) { cell in
                BerryTile(tint: piece.tint)
                    .frame(width: unit - 2, height: unit - 2)
                    .offset(x: CGFloat(cell.col) * unit, y: CGFloat(cell.row) * unit)
            }
        }
        .frame(width: CGFloat(piece.width) * unit, height: CGFloat(piece.height) * unit, alignment: .topLeading)
    }
}
