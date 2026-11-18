import SwiftUI
import UIKit

/// This is one atomic three-slot tray. Every card has an explicit, identical
/// width and height. A long horizontal piece can never request extra HStack
/// space, push a neighbor offscreen, or make the underlying tappable slot
/// smaller than its visible contents.
struct BerryThreePieceTray: View {
    let pieces: [BerryPiece?]
    let availableWidth: CGFloat
    let height: CGFloat
    let selectedSlot: Int?
    let draggingSlot: Int?
    let mode: BerryMode
    let strawberryUnlocked: Bool
    let canMakeMove: Bool
    let onTouch: (Int, BerryTouchEvent) -> Void
    let onAccessibilitySelect: (Int) -> Void

    static let spacing: CGFloat = 8

    static func slotWidth(for availableWidth: CGFloat) -> CGFloat {
        max(1, (availableWidth - spacing * 2) / 3)
    }

    static func tileUnit(piece: BerryPiece, slotWidth: CGFloat, slotHeight: CGFloat) -> CGFloat {
        let columns = CGFloat(max(1, piece.width))
        let rows = CGFloat(max(1, piece.height))
        // The shape, including any long row/column, must fit *inside* the
        // single slot. Do not use the overall screen width for its tile unit.
        return max(3, min(20, (slotWidth - 22) / columns, (slotHeight - 14) / rows))
    }

    var body: some View {
        let cardWidth = Self.slotWidth(for: availableWidth)
        HStack(spacing: Self.spacing) {
            ForEach(0..<3, id: \.self) { slot in
                BerryFixedTraySlot(
                    slot: slot,
                    piece: slot < pieces.count ? pieces[slot] : nil,
                    width: cardWidth,
                    height: height,
                    selected: selectedSlot == slot,
                    isDragging: draggingSlot == slot,
                    mode: mode,
                    strawberryUnlocked: strawberryUnlocked,
                    canMakeMove: canMakeMove,
                    onTouch: onTouch,
                    onAccessibilitySelect: onAccessibilitySelect
                )
                .frame(width: cardWidth, height: height)
            }
        }
        .frame(width: availableWidth, height: height, alignment: .leading)
        .accessibilityIdentifier("berry-three-piece-tray")
    }
}

private struct BerryFixedTraySlot: View {
    let slot: Int
    let piece: BerryPiece?
    let width: CGFloat
    let height: CGFloat
    let selected: Bool
    let isDragging: Bool
    let mode: BerryMode
    let strawberryUnlocked: Bool
    let canMakeMove: Bool
    let onTouch: (Int, BerryTouchEvent) -> Void
    let onAccessibilitySelect: (Int) -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 17)
            .fill(Color.white.opacity(0.94))
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .strokeBorder(selected ? BerryStyle.strawberry :
                                  BerryStyle.strawberry.opacity(0.22),
                                  lineWidth: selected ? 2.5 : 1.25)
            }
            .overlay {
                if let piece {
                    let unit = BerryThreePieceTray.tileUnit(piece: piece,
                                                           slotWidth: width,
                                                           slotHeight: height)
                    BerryPieceGlyph(piece: piece, unit: unit,
                                    mode: mode, strawberryUnlocked: strawberryUnlocked)
                        .id(piece.id)
                        .frame(width: CGFloat(piece.width) * unit,
                               height: CGFloat(piece.height) * unit)
                        .opacity(isDragging ? 0.80 : 1)
                        // No geometry may escape into neighboring cards.
                        .allowsHitTesting(false)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(BerryStyle.leaf.opacity(0.75))
                }
            }
            .overlay(alignment: .topTrailing) {
                if let piece {
                    Text(String(piece.points.count))
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(BerryStyle.strawberry, in: Capsule())
                        .padding(4)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 17))
            .contentShape(Rectangle())
            .overlay {
                BerryTrayTouchCapture(slot: slot, onTouch: onTouch)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(piece.map {
                "Berry piece \(slot + 1), \($0.points.count) squares"
            } ?? "Berry piece \(slot + 1), used")
            .accessibilityIdentifier("berry-tray-slot-\(slot)")
            .accessibilityAddTraits(piece == nil ? [] : .isButton)
            .accessibilityAction {
                if canMakeMove && piece != nil {
                    onAccessibilitySelect(slot)
                }
            }
    }
}
