import SwiftUI

/// Strawberry Jam Garden: visual-only palette, never gameplay rules.
enum BerryBoardPersonality {
    static func gardenBed(for mode: BerryMode) -> LinearGradient {
        let dark = mode == .superHard
        return LinearGradient(
            colors: dark ? [Color(red: 0.56, green: 0.31, blue: 0.57),
                           Color(red: 0.37, green: 0.23, blue: 0.51)] :
                           [Color(red: 0.98, green: 0.72, blue: 0.78),
                            Color(red: 0.82, green: 0.43, blue: 0.57)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static func rim(for mode: BerryMode) -> Color {
        mode == .superHard ? Color(red: 0.42, green: 0.20, blue: 0.47) :
            Color(red: 0.69, green: 0.29, blue: 0.42)
    }
    static func emptyCell(for mode: BerryMode) -> LinearGradient {
        let dark = mode == .superHard
        return LinearGradient(
            colors: dark ? [Color(red: 0.99, green: 0.97, blue: 1.00),
                           Color(red: 0.96, green: 0.92, blue: 0.99)] :
                           [Color(red: 1.00, green: 0.99, blue: 0.97),
                            Color(red: 1.00, green: 0.94, blue: 0.95)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static func cellOutline(for mode: BerryMode) -> Color {
        mode == .superHard ? Color(red: 0.47, green: 0.28, blue: 0.56).opacity(0.78) :
            Color(red: 0.65, green: 0.30, blue: 0.44).opacity(0.78)
    }
    static func leaf(for mode: BerryMode) -> Color {
        mode == .superHard ? Color(red: 0.51, green: 0.39, blue: 0.69) :
            Color(red: 0.38, green: 0.64, blue: 0.43)
    }
    static func showsLeaf(row: Int, column: Int, side: Int) -> Bool {
        guard side <= 12 else { return false }
        return (row * 7 + column * 11 + side) % (side > 8 ? 23 : 17) == 0
    }
}
