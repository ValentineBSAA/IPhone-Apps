import SwiftUI
import CoreGraphics

/// Pure containment math; the decorative frame is never part of hit testing.
enum BerryBoardContainment {
    static func fullFrameSide(playableSide: CGFloat) -> CGFloat {
        playableSide + 2 * (BerryGameplayLayout.boardTouchMargin +
                            BerryGameplayLayout.gardenFrameInset)
    }

    /// Only the input tracker's three-point rim is removed.
    static func playableRect(from tracked: CGRect) -> CGRect {
        tracked.insetBy(dx: BerryGameplayLayout.boardTouchMargin,
                        dy: BerryGameplayLayout.boardTouchMargin)
    }

    static func contains(row: Int, col: Int, side: Int) -> Bool {
        side > 0 && (0..<side).contains(row) && (0..<side).contains(col)
    }
}

/// An inert Strawberry Jam Garden border. Its eight-point perimeter stays
/// outside the playable grid; save data, scoring and gesture math are unchanged.
struct BerryGardenBorder: View {
    let mode: BerryMode

    private var grape: Bool { mode == .superHard }
    private var frameTop: Color {
        grape ? Color(red: 0.65, green: 0.43, blue: 0.76) :
                Color(red: 0.95, green: 0.55, blue: 0.68)
    }
    private var frameBottom: Color {
        grape ? Color(red: 0.38, green: 0.22, blue: 0.54) :
                Color(red: 0.69, green: 0.29, blue: 0.45)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 23, style: .continuous)
            .fill(LinearGradient(colors: [frameTop, frameBottom],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.90), lineWidth: 2)
                    .padding(1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .strokeBorder(Color(red: 1, green: 0.92, blue: 0.82).opacity(0.72),
                                  lineWidth: 1)
                    .padding(5)
            }
            .overlay(alignment: .topLeading) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 9, weight: .medium))
                    .rotationEffect(.degrees(-40))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.leading, 4)
                    .padding(.top, 4)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 9, weight: .medium))
                    .rotationEffect(.degrees(140))
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
