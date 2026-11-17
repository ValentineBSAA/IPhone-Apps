import SwiftUI
import UIKit

/// An offline, placeable six-item cottage garden. Existing ownership keys
/// are reused, so v0.5.7 purchases and earned berries are never lost.
struct BerryCottageGardenView: View {
    @ObservedObject var session: BerryGameSession
    @Environment(\.dismiss) private var dismiss
    @State private var positions: [String: Spot] = [:]
    @State private var gestureStarts: [String: Spot] = [:]
    @State private var selectedIndex: Int? = nil

    private struct Spot: Codable {
        var x: Double
        var y: Double
    }

    private struct Decoration {
        let id: String
        let title: String
        let image: String
        let fallback: String
    }

    private let decorations = [
        Decoration(id: "flowerbed", title: "Berry Flowerbed", image: "BerryFlowerbed", fallback: "🌸"),
        Decoration(id: "gate", title: "Strawberry Garden Gate", image: "StrawberryGardenGate", fallback: "🚪"),
        Decoration(id: "stall", title: "Jam Market Stall", image: "JamMarketStall", fallback: "🧺"),
        Decoration(id: "fountain", title: "Village Fountain", image: "VillageFountain", fallback: "⛲"),
        Decoration(id: "trellis", title: "Rose Trellis", image: "RoseTrellis", fallback: "🌹"),
        Decoration(id: "bakery", title: "Cottage Bakery", image: "CottageBakery", fallback: "🍰")
    ]

    private let layoutKey = "berryblockblast.cottage.layout.v058"
    private let suggested: [Spot] = [
        Spot(x: 0.22, y: 0.68), Spot(x: 0.76, y: 0.74),
        Spot(x: 0.24, y: 0.34), Spot(x: 0.78, y: 0.34),
        Spot(x: 0.55, y: 0.24), Spot(x: 0.72, y: 0.53)
    ]

    private func spot(_ index: Int) -> Spot {
        positions[decorations[index].id] ?? suggested[index]
    }

    private func image(_ name: String, fallback: String) -> some View {
        Group {
            if UIImage(named: name) != nil {
                Image(name).resizable().scaledToFit()
            } else {
                Text(fallback).font(.system(size: 46))
            }
        }
        .accessibilityHidden(true)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    Text("My Strawberry Cottage")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Text("Place your decorations wherever you like. Every change saves automatically.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(BerryStyle.chocolate)
                        .multilineTextAlignment(.center)
                    GeometryReader { geometry in
                        let w = geometry.size.width
                        let h = geometry.size.height
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(LinearGradient(colors: [
                                    Color(red: 0.89, green: 0.97, blue: 0.83),
                                    Color(red: 1.00, green: 0.91, blue: 0.91)],
                                    startPoint: .top, endPoint: .bottom))
                            if UIImage(named: "CottageGardenBackground") != nil {
                                Image("CottageGardenBackground")
                                    .resizable().scaledToFill()
                                    .frame(width: w, height: h).clipped()
                            }
                            image("StrawberryCottage", fallback: "🏡")
                                .frame(width: w * 0.43, height: h * 0.46)
                                .position(x: w * 0.47, y: h * 0.54)
                            ForEach(0..<min(session.cottageDecorations, decorations.count), id: \.self) { index in
                                let decoration = decorations[index]
                                let p = spot(index)
                                image(decoration.image, fallback: decoration.fallback)
                                    .frame(width: w * 0.30, height: h * 0.26)
                                    .overlay {
                                        if selectedIndex == index {
                                            RoundedRectangle(cornerRadius: 15)
                                                .strokeBorder(BerryStyle.strawberry, lineWidth: 2)
                                                .padding(4)
                                        }
                                    }
                                    .position(x: w * p.x, y: h * p.y)
                                    .onTapGesture { selectedIndex = index }
                                    .gesture(DragGesture(minimumDistance: 4)
                                        .onChanged { value in
                                            selectedIndex = index
                                            if gestureStarts[decoration.id] == nil {
                                                gestureStarts[decoration.id] = spot(index)
                                            }
                                            let origin = gestureStarts[decoration.id] ?? suggested[index]
                                            let nx = min(0.86, max(0.14, origin.x + Double(value.translation.width / w)))
                                            let ny = min(0.88, max(0.12, origin.y + Double(value.translation.height / h)))
                                            positions[decoration.id] = Spot(x: nx, y: ny)
                                        }
                                        .onEnded { _ in
                                            gestureStarts.removeValue(forKey: decoration.id)
                                            savePositions()
                                        })
                                    .accessibilityLabel(decoration.title + ", moveable garden decoration")
                            }
                        }
                        .frame(width: w, height: h)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(BerryStyle.strawberry.opacity(0.36), lineWidth: 2))
                    }
                    .frame(height: 340)
                    Text("🍓 \(min(session.cottageDecorations, 6)) of 6 cottage decorations collected")
                        .font(.headline).foregroundStyle(BerryStyle.strawberry)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(0..<decorations.count, id: \.self) { index in
                            let deco = decorations[index]
                            HStack(spacing: 6) {
                                image(deco.image, fallback: deco.fallback)
                                    .frame(width: 42, height: 42)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(deco.title).font(.system(size: 11, weight: .heavy, design: .rounded))
                                    Text(index < session.cottageDecorations ? "Owned · drag to place" : "Locked · buy at the Boutique")
                                        .font(.system(size: 9, weight: .semibold))
                                }
                                Spacer(minLength: 0)
                            }
                            .foregroundStyle(index < session.cottageDecorations ? BerryStyle.strawberry : .gray)
                            .padding(8)
                            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 15))
                        }
                    }
                    if session.cottageDecorations < 6 {
                        Button("🍓 Get the Next Cottage Decoration · 50") {
                            session.buyCottageDecoration()
                            savePositions()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(BerryStyle.strawberry)
                        .disabled(session.berries < 50)
                    }
                    Text("Your basket: 🍓 \(session.berries). All decorations are earned through play.")
                        .font(.caption.bold())
                        .foregroundStyle(BerryStyle.chocolate)
                }
                .padding(17)
            }
            .background(BerryStyle.cream.ignoresSafeArea())
            .navigationTitle("Cozy Cottage")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.large])
        .onAppear {
            session.refreshEconomyFromDisk()
            if let data = UserDefaults.standard.data(forKey: layoutKey),
               let saved = try? JSONDecoder().decode([String: Spot].self, from: data) {
                positions = saved
            }
        }
    }

    private func savePositions() {
        if let data = try? JSONEncoder().encode(positions) {
            UserDefaults.standard.set(data, forKey: layoutKey)
        }
    }
}
