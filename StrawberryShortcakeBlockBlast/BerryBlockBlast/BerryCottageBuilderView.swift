import SwiftUI
import UIKit

/// Placement positions are saved locally, separately from purchased ownership.
/// Older cottage purchases remain available because their original count key is unchanged.
struct BerryCottageBuilderView: View {
    @ObservedObject var session: BerryGameSession
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDecoration = 0
    @State private var placements: [String: GardenPosition] = [:]
    private let placementsKey = "berryblockblast.cottage.layout.v058"

    private struct GardenPosition: Codable {
        var x: Double
        var y: Double
    }
    private struct Decoration: Identifiable {
        let id: Int
        let name: String
        let art: String
        let emoji: String
    }
    private let decorations: [Decoration] = [
        .init(id: 0, name: "Berry Flowerbed", art: "BerryFlowerbed", emoji: "🌸"),
        .init(id: 1, name: "Strawberry Garden Gate", art: "StrawberryGardenGate", emoji: "🚪"),
        .init(id: 2, name: "Jam Market Stall", art: "JamMarketStall", emoji: "🧺"),
        .init(id: 3, name: "Village Fountain", art: "VillageFountain", emoji: "⛲"),
        .init(id: 4, name: "Rose Trellis", art: "RoseTrellis", emoji: "🌹"),
        .init(id: 5, name: "Cottage Bakery", art: "CottageBakery", emoji: "🍰")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Build Your Strawberry Cottage")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                        .multilineTextAlignment(.center)
                    Text("Choose an owned decoration, then tap the garden where you'd like it to go.")
                        .font(.subheadline)
                        .foregroundStyle(BerryStyle.chocolate)
                        .multilineTextAlignment(.center)
                    gardenView
                    HStack {
                        Label("\(min(session.cottageDecorations, 6)) of 6 owned",
                              systemImage: "house.fill")
                        Spacer()
                        Text("🍓 \(session.berries)")
                    }
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 11) {
                        ForEach(decorations) { item in
                            let owned = item.id < session.cottageDecorations
                            Button {
                                if owned { selectedDecoration = item.id }
                            } label: {
                                VStack(spacing: 5) {
                                    decorationImage(item, size: 64)
                                    Text(item.name)
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                    Text(owned ? (selectedDecoration == item.id ? "Selected • Tap garden" : "Owned • Place it") : "🔒 Not yet owned")
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .foregroundStyle(owned ? BerryStyle.strawberry : .secondary)
                                }
                                .foregroundStyle(BerryStyle.chocolate)
                                .frame(maxWidth: .infinity, minHeight: 128)
                                .background(.white, in: RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(owned && selectedDecoration == item.id ?
                                        BerryStyle.strawberry : BerryStyle.softPink,
                                        lineWidth: owned && selectedDecoration == item.id ? 3 : 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(!owned)
                        }
                    }
                    if session.cottageDecorations < decorations.count {
                        Button {
                            session.buyCottageDecoration()
                            selectedDecoration = max(0, session.cottageDecorations - 1)
                        } label: {
                            Text("Buy Next Cottage Decoration • 🍓 50")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(15)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(BerryStyle.strawberry)
                        .disabled(session.berries < 50)
                    }
                    Button("Reset positions (keep all purchases)") {
                        placements.removeAll()
                        save()
                    }
                    .font(.caption.bold())
                    .foregroundStyle(BerryStyle.strawberry)
                }
                .padding(17)
            }
            .background(BerryStyle.cream.ignoresSafeArea())
            .navigationTitle("My Strawberry Cottage")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            session.refreshEconomyFromDisk()
            if let data = UserDefaults.standard.data(forKey: placementsKey),
               let previous = try? JSONDecoder().decode([String: GardenPosition].self, from: data) {
                placements = previous
            }
        }
    }

    private var gardenView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [Color(red: 0.80, green: 0.93, blue: 0.74),
                                                  Color(red: 0.95, green: 0.85, blue: 0.88)],
                                         startPoint: .top, endPoint: .bottom))
                if let image = UIImage(named: "CottageGardenBackground") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                } else {
                    Text("🏡")
                        .font(.system(size: 96))
                        .position(x: width * 0.5, y: height * 0.35)
                }
                ForEach(decorations) { item in
                    if item.id < session.cottageDecorations,
                       let saved = placements[String(item.id)] {
                        decorationImage(item, size: 66)
                            .position(x: CGFloat(saved.x) * width,
                                      y: CGFloat(saved.y) * height)
                            .shadow(color: BerryStyle.chocolate.opacity(0.2),
                                    radius: 5, y: 3)
                            .allowsHitTesting(false)
                    }
                }
                if session.cottageDecorations == 0 {
                    Text("Visit the Boutique to begin decorating")
                        .font(.caption.bold())
                        .padding(8)
                        .background(.white.opacity(0.92), in: Capsule())
                        .position(x: width / 2, y: height * 0.82)
                }
            }
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20)
                .strokeBorder(BerryStyle.strawberry.opacity(0.35), lineWidth: 2))
            .gesture(SpatialTapGesture().onEnded { touch in
                guard selectedDecoration < session.cottageDecorations else { return }
                let x = min(0.9, max(0.1, Double(touch.location.x / max(1, width))))
                let y = min(0.9, max(0.18, Double(touch.location.y / max(1, height))))
                placements[String(selectedDecoration)] = GardenPosition(x: x, y: y)
                save()
            })
        }
        .frame(height: 320)
        .accessibilityLabel("Interactive strawberry cottage garden. Select a decoration and tap a position.")
    }

    @ViewBuilder
    private func decorationImage(_ item: Decoration, size: CGFloat) -> some View {
        if let image = UIImage(named: item.art) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Text(item.emoji).font(.system(size: size * 0.6))
                .frame(width: size, height: size)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(placements) {
            UserDefaults.standard.set(data, forKey: placementsKey)
        }
    }
}
