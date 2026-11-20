import SwiftUI
import UIKit

/// Visual layer only. Must never change board hitbox, placement or touch mapping.
struct BerryDragState {
    var slot: Int
    var piece: BerryPiece
    var row: Int
    var col: Int
    var allowed: Bool
}

struct BerryBoard: View {
    let engine: BerryEngine
    let preview: BerryDragState?
    let size: CGFloat
    let selected: Int?
    let mode: BerryMode
    let strawberryUnlocked: Bool
    let previewStyle: String
    // Build 4.1 optional Blossom Glass is decoration only, never a hitbox change.
    // The hardware-tested original remains the default and instant rollback.
    private let gap: CGFloat = 3
    @AppStorage("berryberryblast.board.surface.v059") private var boardSurface = "original"
    @AppStorage(BerryDayNightAppearance.storageKey) private var isNight = false

    var body: some View {
        let side = engine.visibleSide
        let origin = engine.sectionOrigin
        let unit = (size - CGFloat(side - 1) * gap) / CGFloat(side)
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 15)
                .fill(BerryBoardPersonality.gardenBed(for: mode))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(BerryBoardPersonality.rim(for: mode),
                                      lineWidth: 1.4)
                }
                .shadow(color: BerryStyle.strawberry.opacity(0.14),
                        radius: 4, y: 1)
            ForEach(0..<(side * side), id: \.self) { i in
                let r = i / side
                let c = i % side
                ZStack {
                    RoundedRectangle(cornerRadius: side > 8 ? 4 : 7)
                        .fill(BerryBoardPersonality.emptyCell(for: mode))
                        .overlay {
                            if boardSurface == "blossom-glass" {
                                Image(isNight && UIImage(named: "Night_Tile_Empty") != nil ?
                                      "Night_Tile_Empty" : "Tile_Empty")
                                    .resizable()
                                    .interpolation(.high)
                                    .scaledToFill()
                                    .overlay {
                                        // Light catching on each empty square only.
                                        RoundedRectangle(cornerRadius: side > 8 ? 4 : 7)
                                            .fill(LinearGradient(colors: [
                                                Color.white.opacity(0.42),
                                                Color(red: 0.92, green: 0.45, blue: 0.67).opacity(0.10),
                                                Color(red: 0.77, green: 0.61, blue: 0.96).opacity(0.33)
                                            ], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: side > 8 ? 4 : 7)
                                            .strokeBorder(.white.opacity(0.80),
                                                          lineWidth: side > 8 ? 0.8 : 1.2)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: side > 8 ? 4 : 7))
                                    .allowsHitTesting(false)
                                    .accessibilityHidden(true)
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: side > 8 ? 4 : 7)
                                .strokeBorder(BerryBoardPersonality.cellOutline(for: mode),
                                              lineWidth: side > 8 ? 1 : 1.5)
                        }
                    // Sparse deterministic botanical details inside empty cells.
                    if engine.visibleCell(row: r, col: c) == nil,
                       BerryBoardPersonality.showsLeaf(row: r, column: c, side: side) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: max(6, unit * 0.23), weight: .light))
                            .rotationEffect(.degrees(-32))
                            .foregroundStyle(BerryBoardPersonality.leaf(for: mode).opacity(0.18))
                            .accessibilityHidden(true)
                            .allowsHitTesting(false)
                    }
                    if let tint = engine.visibleCell(row: r, col: c) {
                        let blocked = preview?.piece.points.contains(where: {
                            preview!.row + $0.row == r + origin.row &&
                            preview!.col + $0.col == c + origin.col
                        }) ?? false
                        BerryTile(tint: tint, mode: mode, strawberryUnlocked: strawberryUnlocked)
                            .opacity(blocked && !((preview?.allowed) ?? true) ? 0.24 : 1)
                    }
                }
                .frame(width: unit, height: unit)
                .offset(x: CGFloat(c) * (unit + gap), y: CGFloat(r) * (unit + gap))
            }
            if let preview, previewStyle != "mystery" {
                ForEach(preview.piece.points, id: \.self) { p in
                    let r = preview.row + p.row - origin.row
                    let c = preview.col + p.col - origin.col
                    if BerryBoardContainment.contains(row: r, col: c, side: side) {
                        let occupied = engine.visibleCell(row: r, col: c) != nil
                        ZStack {
                            if preview.allowed {
                                BerryTile(tint: preview.piece.tint, preview: true,
                                          mode: mode, strawberryUnlocked: strawberryUnlocked)
                                    .opacity(previewStyle == "outline" ? 0.33 : 0.80)
                            } else {
                                RoundedRectangle(cornerRadius: side > 8 ? 4 : 8)
                                    .fill(Color.red.opacity(occupied ? 0.28 : 0.12))
                                if !preview.allowed {
                                    Image(systemName: "xmark")
                                        .font(.system(size: max(8, unit * 0.30), weight: .black))
                                        .foregroundStyle(Color(red: 0.72, green: 0.07, blue: 0.22))
                                }
                            }
                        }
                            .overlay {
                                RoundedRectangle(cornerRadius: side > 8 ? 4 : 8)
                                    .strokeBorder(preview.allowed ?
                                        Color(red: 0.09, green: 0.68, blue: 0.33) :
                                        Color(red: 0.94, green: 0.13, blue: 0.28),
                                        lineWidth: preview.allowed ? 2.5 : 3.2)
                                    .shadow(color: preview.allowed ?
                                        Color.green.opacity(0.54) : Color.red.opacity(0.54),
                                        radius: 4)
                            }
                            .frame(width: unit, height: unit)
                            .offset(x: CGFloat(c) * (unit + gap), y: CGFloat(r) * (unit + gap))
                    }
                }
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
        .overlay {
            if let preview, !preview.allowed,
               preview.piece.points.contains(where: {
                   !(0..<engine.side).contains(preview.row + $0.row) ||
                   !(0..<engine.side).contains(preview.col + $0.col)
               }) {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(Color.red.opacity(0.82), lineWidth: 3)
                    .overlay(alignment: .top) {
                        Text("Outside the garden")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(.white, in: Capsule())
                            .foregroundStyle(Color.red)
                            .padding(.top, 5)
                    }
                    .allowsHitTesting(false)
            }
        }
        // Crop occupied cells, off-edge previews, glows, shadows, and the
        // warning at the exact same rounded silhouette, on every board mode.
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Berry garden, \(engine.side) by \(engine.side) puzzle board")
    }
}

