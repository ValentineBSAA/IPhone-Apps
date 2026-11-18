import SwiftUI
import UIKit

/// Cosmetic-only frame layer. The existing board surface, cell spacing,
/// hit testing and block skin continue to use their original save keys.
enum BerryFrameCatalog {
    struct Theme: Identifiable {
        let id: String
        let title: String
        let detail: String
        let image: String
        let symbol: String
        let color: Color
    }
    static let choices: [Theme] = [
        .init(id: "original", title: "Original Board", detail: "Clean classic border",
              image: "", symbol: "square.grid.3x3", color: BerryStyle.strawberry),
        .init(id: "christmas", title: "Christmas Berry Cottage",
              detail: "Candy canes, holly and snowy ribbons",
              image: "BBBFrameChristmas", symbol: "snowflake",
              color: Color(red: 0.62, green: 0.18, blue: 0.25)),
        .init(id: "birthday", title: "Birthday Berry Bash",
              detail: "Birthday cake, candles and satin bows",
              image: "BBBFrameBirthday", symbol: "birthday.cake.fill",
              color: Color(red: 0.96, green: 0.42, blue: 0.65)),
        .init(id: "spring", title: "Spring Blossom Garden",
              detail: "Blooming flowers and strawberry vines",
              image: "BBBFrameSpring", symbol: "leaf.fill",
              color: Color(red: 0.39, green: 0.60, blue: 0.30)),
        .init(id: "midnight", title: "Midnight Berry",
              detail: "Blackberry moonlight and tiny stars",
              image: "BBBFrameMidnight", symbol: "moon.stars.fill",
              color: Color(red: 0.46, green: 0.26, blue: 0.65)),
        .init(id: "picnic", title: "Berry Picnic",
              detail: "Blush ribbons and garden-lace trim",
              image: "BBBFramePicnic", symbol: "basket.fill",
              color: BerryStyle.strawberry)
    ]
    static func theme(_ id: String) -> Theme {
        choices.first(where: { $0.id == id }) ?? choices[0]
    }
}

struct BerryApprovedArtwork: View {
    let name: String
    let fallback: String
    var size: CGFloat = 54

    var body: some View {
        Group {
            if let art = UIImage(named: name) {
                Image(uiImage: art)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: fallback)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(BerryStyle.strawberry)
                    .padding(size * 0.19)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// The decorative image sits on top of the existing pink board frame.
/// Its center is transparent, and all gesture traffic passes through it.
struct BerryDecorativeBoardFrame: View {
    @AppStorage("berryberryblast.frame.overlay.v0511") private var frameID = "original"
    let boardSize: CGFloat
    var body: some View {
        let theme = BerryFrameCatalog.theme(frameID)
        Group {
            if frameID != "original" {
                if let art = UIImage(named: theme.image) {
                    Image(uiImage: art)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                        .frame(width: boardSize + 24, height: boardSize + 24)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 19)
                        .strokeBorder(theme.color.opacity(0.75), lineWidth: 5)
                        .frame(width: boardSize + 15, height: boardSize + 15)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct BerryDecorativeFrameCard: View {
    let theme: BerryFrameCatalog.Theme
    @AppStorage("berryberryblast.frame.overlay.v0511") private var selected = "original"
    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(BerryStyle.softPink)
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.95))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(BerryStyle.strawberry.opacity(0.52), lineWidth: 1.5))
                    .padding(12)
                if theme.id != "original" {
                    BerryApprovedArtwork(name: theme.image, fallback: theme.symbol, size: 91)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 98)
            Text(theme.title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(theme.detail)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 31)
            Text(selected == theme.id ? "✓ EQUIPPED" : "INCLUDED")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.leaf)
            Button(selected == theme.id ? "✓ Selected" : "Use Frame") {
                selected = theme.id
            }
            .buttonStyle(.borderedProminent)
            .tint(BerryStyle.leaf)
            .disabled(selected == theme.id)
        }
        .foregroundStyle(BerryStyle.chocolate)
        .padding(9)
        .frame(maxWidth: .infinity, minHeight: 227)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18)
            .strokeBorder(selected == theme.id ? BerryStyle.leaf : BerryStyle.strawberry.opacity(0.24),
                          lineWidth: selected == theme.id ? 2.0 : 1.0))
    }
}

struct BerryBoardFrameGrid: View {
    var seasonalOnly = false
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    var body: some View {
        VStack(spacing: 10) {
            Text("Frames decorate outside the original board. They never alter block skins, empty squares, placement, saves or scores.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.78))
                .multilineTextAlignment(.center)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(BerryFrameCatalog.choices) { theme in
                    if !seasonalOnly || ["christmas", "birthday", "spring", "midnight"].contains(theme.id) {
                        BerryDecorativeFrameCard(theme: theme)
                    }
                }
            }
        }
    }
}


/// The ten originally approved portrait board concepts are shown as their own
/// grid. Selecting one changes only the empty-square art, using a cropped
/// texture derived from that concept. Never stretch the entire portrait
/// mockup over the live 8x8/12x12 board or paint over occupied game squares.
struct BerryBoardConceptGrid: View {
    @AppStorage("berryberryblast.board.surface.v059") private var selected = "original"
    private struct Concept: Identifiable {
        let id: String
        let title: String
        let image: String
    }
    private let themes: [Concept] = [
        .init(id: "concept-01", title: "Strawberry Cream", image: "BBBBoardConcept01"),
        .init(id: "concept-02", title: "Picnic Basket", image: "BBBBoardConcept02"),
        .init(id: "concept-03", title: "Garden Meadow", image: "BBBBoardConcept03"),
        .init(id: "concept-04", title: "Candy Glass", image: "BBBBoardConcept04"),
        .init(id: "concept-05", title: "Seed Mosaic", image: "BBBBoardConcept05"),
        .init(id: "concept-06", title: "Royal Berry", image: "BBBBoardConcept06"),
        .init(id: "concept-07", title: "Berry Garden", image: "BBBBoardConcept07"),
        .init(id: "concept-08", title: "Strawberry Jam", image: "BBBBoardConcept08"),
        .init(id: "concept-09", title: "Berry Sunset", image: "BBBBoardConcept09"),
        .init(id: "concept-10", title: "Blackberry Night", image: "BBBBoardConcept10")
    ]
    private let cols = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    var body: some View {
        VStack(spacing: 10) {
            Text("10 COLLECTIBLE BOARD SURFACES")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            Text("These themes decorate the empty squares only. Your board remains the exact same puzzle grid.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(themes) { theme in
                    Button {
                        selected = theme.id
                    } label: {
                        VStack(spacing: 6) {
                            if UIImage(named: theme.image) != nil {
                                Image(theme.image)
                                    .resizable()
                                    .interpolation(.high)
                                    .scaledToFit()
                                    .frame(height: 155)
                            } else {
                                Image(systemName: "square.grid.3x3.fill")
                                    .font(.system(size: 44))
                                    .frame(height: 155)
                            }
                            Text(theme.title)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(BerryStyle.chocolate)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Text(selected == theme.id ? "✓ EQUIPPED" : "USE BOARD")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(selected == theme.id ? BerryStyle.leaf : BerryStyle.strawberry)
                        }
                        .frame(maxWidth: .infinity, minHeight: 225)
                        .padding(7)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(selected == theme.id ? BerryStyle.leaf : BerryStyle.strawberry.opacity(0.25),
                                          lineWidth: selected == theme.id ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
