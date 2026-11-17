import SwiftUI

private struct BerryBoutiqueItem: Identifiable {
    let id: String
    let name: String
    let detail: String
    let emoji: String
    let price: Int
    let type: String
    var accent: Color {
        switch type {
        case "blocks": BerryStyle.strawberry
        case "frames": BerryStyle.leaf
        default: Color(red: 0.63, green: 0.41, blue: 0.86)
        }
    }
}

struct BerryBoutiqueView: View {
    @ObservedObject var session: BerryGameSession
    @AppStorage("berryblockblast.shop.equippedBlockSkin.v056b2") private var blockSkin = "default"
    @AppStorage("berryblockblast.shop.equippedBorder.v056b2") private var borderSkin = "default"
    @AppStorage("berryblockblast.shop.equippedSparkle.v056b2") private var sparkleSkin = "default"
    @AppStorage("berryblockblast.sound") private var sound = true

    private let items = [
        BerryBoutiqueItem(id: "blueberry-blocks", name: "Blueberry Velvet",
                          detail: "Deep violet and blue game pieces", emoji: "🫐", price: 90, type: "blocks"),
        BerryBoutiqueItem(id: "vanilla-blocks", name: "Vanilla Cream",
                          detail: "Warm honey and cream game pieces", emoji: "🍦", price: 90, type: "blocks"),
        BerryBoutiqueItem(id: "rose-border", name: "Rose Petal Frame",
                          detail: "A beautiful raspberry board border", emoji: "🌺", price: 75, type: "frames"),
        BerryBoutiqueItem(id: "mint-border", name: "Mint Garden Frame",
                          detail: "Fresh green board-edge trim", emoji: "🍃", price: 75, type: "frames"),
        BerryBoutiqueItem(id: "berry-sparkle", name: "Berry Sparkle",
                          detail: "A little shimmer on every berry block", emoji: "✨", price: 100, type: "sparkles")
    ]

    private func active(_ item: BerryBoutiqueItem) -> Bool {
        switch item.type {
        case "blocks": return blockSkin == item.id
        case "frames": return borderSkin == item.id
        default: return sparkleSkin == item.id
        }
    }

    private func equip(_ item: BerryBoutiqueItem) {
        switch item.type {
        case "blocks": blockSkin = item.id
        case "frames": borderSkin = item.id
        default: sparkleSkin = item.id
        }
        if sound { BerryAudio.shared.play(.menuSelect) }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("🧺").font(.system(size: 42))
                    .frame(width: 61, height: 61)
                    .background(BerryStyle.softPink, in: RoundedRectangle(cornerRadius: 17))
                VStack(alignment: .leading, spacing: 4) {
                    Text("The Berry Boutique")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Text("Little treasures for your strawberry village")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(BerryStyle.chocolate.opacity(0.76))
                }
                Spacer()
            }
            HStack {
                Image(systemName: "basket.fill")
                    .foregroundStyle(BerryStyle.strawberry)
                Text("Your Berry Wallet").font(.headline)
                Spacer()
                Text("🍓 \(session.berries)")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .strokeBorder(BerryStyle.strawberry.opacity(0.30), lineWidth: 1.5))

            Text("🎀 PERMANENT COLLECTIBLES")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(BerryStyle.chocolate)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(items) { item in
                let owned = session.ownedCosmetics.contains(item.id)
                HStack(spacing: 12) {
                    Text(item.emoji).font(.system(size: 31))
                        .frame(width: 58, height: 58)
                        .background(item.accent.opacity(0.15),
                                    in: RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.name)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.chocolate)
                        Text(item.detail)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(BerryStyle.chocolate.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                        if owned {
                            Label("Permanently owned", systemImage: "checkmark.seal.fill")
                                .font(.caption2).foregroundStyle(BerryStyle.leaf)
                        }
                    }
                    Spacer(minLength: 3)
                    Button {
                        if owned {
                            if active(item) {
                                switch item.type {
                                case "blocks": blockSkin = "default"
                                case "frames": borderSkin = "default"
                                default: sparkleSkin = "default"
                                }
                            } else { equip(item) }
                        } else if session.buyCosmetic(id: item.id, cost: item.price) {
                            equip(item)
                            if sound { BerryAudio.shared.play(.reward) }
                        }
                    } label: {
                        Text(owned ? (active(item) ? "Remove" : "Equip") : "🍓 \(item.price)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .frame(minWidth: 64)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(owned ? BerryStyle.leaf : BerryStyle.strawberry)
                    .disabled(!owned && session.berries < item.price)
                }
                .padding(12)
                .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(item.accent.opacity(0.35), lineWidth: 1.2))
            }

            VStack(alignment: .leading, spacing: 11) {
                Text("🍰 GARDEN HELPERS").font(.headline).foregroundStyle(BerryStyle.strawberry)
                Text("Usable in relaxed modes. Berry Classic remains power-up free.")
                    .font(.caption).foregroundStyle(BerryStyle.chocolate.opacity(0.7))
                HStack {
                    Label("Extra Undo", systemImage: "arrow.uturn.backward")
                    Spacer()
                    Button("🍓 25") {
                        session.buyUndo()
                        if sound { BerryAudio.shared.play(.reward) }
                    }
                    .disabled(session.berries < 25)
                }
                HStack {
                    Label("Extra Shuffle", systemImage: "shuffle")
                    Spacer()
                    Button("🍓 25") {
                        session.buyShuffle()
                        if sound { BerryAudio.shared.play(.reward) }
                    }
                    .disabled(session.berries < 25)
                }
                HStack {
                    Label("Cottage Decoration", systemImage: "house.lodge.fill")
                    Spacer()
                    Text("Owned \(min(session.cottageDecorations, 6))/6").font(.caption)
                    Button(session.cottageDecorations >= 6 ? "Complete" : "🍓 50") {
                        session.buyCottageDecoration()
                        if sound { BerryAudio.shared.play(.reward) }
                    }
                    .disabled(session.berries < 50 || session.cottageDecorations >= 6)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(BerryStyle.leaf)
            .foregroundStyle(BerryStyle.chocolate)
            .padding(17)
            .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 22))

            Text("All berries are earned through play. Every collectible stays unlocked after app updates.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(BerryStyle.chocolate.opacity(0.67))
        }
        .padding(.vertical, 8)
    }
}
