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
    @AppStorage("berryberryblast.board.surface.v059") private var boardSurface = "cream"
    @AppStorage("berryblockblast.shop.equippedSparkle.v056b2") private var sparkleSkin = "default"
    @AppStorage("berryblockblast.sound") private var sound = true
    @State private var selectedCategory: Category?

    private enum Category: String, CaseIterable, Identifiable {
        case blocks, frames, helpers, special, cottage, inventory
        var id: String { rawValue }
        var title: String {
            switch self {
            case .blocks: return "Block Styles"
            case .frames: return "Frames & Sparkles"
            case .helpers: return "Garden Helpers"
            case .special: return "Special Tools & Upgrades"
            case .cottage: return "Cottage Decor"
            case .inventory: return "My Items"
            }
        }
        var subtitle: String {
            switch self {
            case .blocks: return "Make every berry block yours"
            case .frames: return "Illustrated boards, borders and effects"
            case .helpers: return "Undo, Shuffle and Berry Hint"
            case .special: return "Powerful one-use tools and permanent abilities"
            case .cottage: return "Build your strawberry garden"
            case .inventory: return "Owned cosmetics and supplies"
            }
        }
        var symbol: String {
            switch self {
            case .blocks: return "square.grid.3x3.fill"
            case .frames: return "sparkles"
            case .helpers: return "wand.and.stars"
            case .special: return "crown.fill"
            case .cottage: return "house.fill"
            case .inventory: return "shippingbox.fill"
            }
        }
    }


    private let items = [
        BerryBoutiqueItem(id: "strawberry-fruit", name: "True Strawberry",
                          detail: "Actual strawberry-shaped fruit blocks, not square tiles", emoji: "🍓", price: 0, type: "blocks"),
        BerryBoutiqueItem(id: "blueberry-blocks", name: "Blueberry Velvet",
                          detail: "Deep violet and blue game pieces", emoji: "🫐", price: 90, type: "blocks"),
        BerryBoutiqueItem(id: "vanilla-blocks", name: "Vanilla Cream",
                          detail: "Warm honey and cream game pieces", emoji: "🍦", price: 90, type: "blocks"),
        BerryBoutiqueItem(id: "raspberry-blocks", name: "Raspberry Ruby",
                          detail: "Glossy raspberry jewels", emoji: "🍒", price: 110, type: "blocks"),
        BerryBoutiqueItem(id: "lemon-blocks", name: "Lemon Glaze",
                          detail: "Juicy golden citrus candy", emoji: "🍋", price: 110, type: "blocks"),
        BerryBoutiqueItem(id: "chocolate-blocks", name: "Chocolate Truffle",
                          detail: "Rich cocoa and chocolate drizzle", emoji: "🍫", price: 120, type: "blocks"),
        BerryBoutiqueItem(id: "mint-blocks", name: "Mint Frost",
                          detail: "Cool mint leaves and candy glass", emoji: "🍃", price: 110, type: "blocks"),
        BerryBoutiqueItem(id: "blackberry-blocks", name: "Blackberry Jam",
                          detail: "Deep-purple jam and blackberry shine", emoji: "🫐", price: 130, type: "blocks"),
        // All five visual surfaces are included, not newly monetized.
        // Reuse the same selection key already saved by Berry Settings.
        BerryBoutiqueItem(id: "surface-cream", name: "Strawberry Cream",
                          detail: "Soft pink berry cream", emoji: "🍓", price: 0, type: "surfaces"),
        BerryBoutiqueItem(id: "surface-glass", name: "Frosted Candy Glass",
                          detail: "Glossy strawberry jelly", emoji: "💎", price: 0, type: "surfaces"),
        BerryBoutiqueItem(id: "surface-picnic", name: "Berry Picnic",
                          detail: "Pastel picnic-cloth tiles", emoji: "🧺", price: 0, type: "surfaces"),
        BerryBoutiqueItem(id: "surface-garden", name: "Garden Patch",
                          detail: "Earth and leaf growing squares", emoji: "🌱", price: 0, type: "surfaces"),
        BerryBoutiqueItem(id: "surface-seed", name: "Seed Mosaic",
                          detail: "Sparkling seed-imprint tiles", emoji: "✨", price: 0, type: "surfaces"),
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
        case "surfaces": return boardSurface == String(item.id.dropFirst("surface-".count))
        default: return sparkleSkin == item.id
        }
    }

    private func equip(_ item: BerryBoutiqueItem) {
        switch item.type {
        case "blocks": blockSkin = item.id
        case "frames": borderSkin = item.id
        case "surfaces": boardSurface = String(item.id.dropFirst("surface-".count))
        default: sparkleSkin = item.id
        }
        if sound { BerryAudio.shared.play(.menuSelect) }
    }


    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                BerryIcon(name: "ShopBasket", size: 57)
                VStack(alignment: .leading, spacing: 3) {
                    Text("The Berry Boutique")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Text("Little treasures for your strawberry village")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(BerryStyle.chocolate)
                }
                Spacer(minLength: 0)
            }
            HStack {
                Label("Berry Wallet", systemImage: "basket.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                Text("🍓 \(BerryNumbers.compact(session.berries))")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
            }
            .foregroundStyle(BerryStyle.chocolate)
            .padding(13)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .strokeBorder(BerryStyle.strawberry.opacity(0.30), lineWidth: 1))

            if let selectedCategory {
                HStack(spacing: 9) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            self.selectedCategory = nil
                        }
                    } label: {
                        Label("Back to Boutique", systemImage: "chevron.left")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .buttonStyle(.bordered)
                    .tint(BerryStyle.strawberry)
                    Spacer()
                    Text(selectedCategory.title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                }
                section(selectedCategory)
            } else {
                Text("CHOOSE YOUR BERRY TREASURE")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(BerryStyle.strawberry)
                    .frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Category.allCases) { category in
                        categoryTile(category)
                    }
                }
                Text("Purchases stay yours. Tap a category to browse and preview items.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
        }
        .padding(.vertical, 8)
    }

    private func categoryTile(_ category: Category) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: 8) {
                Group {
                    switch category {
                    case .blocks: BerryIcon(name: "BerryClassic", size: 73)
                    case .frames: BerryIcon(name: "Milestone", size: 73)
                    case .helpers: BerryIcon(name: "BerryHint", size: 73)
                    case .special: Image("PremiumToolsCategory").resizable().scaledToFit()
                    case .cottage: BerryIcon(name: "CottageDecorations", size: 73)
                    case .inventory: BerryIcon(name: "BerryCollection", size: 73)
                    }
                }
                .frame(width: 73, height: 73)
                .background(BerryStyle.softPink.opacity(0.8),
                            in: RoundedRectangle(cornerRadius: 17))
                Text(category.title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .multilineTextAlignment(.center)
                Text(category.subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.72))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .padding(.horizontal, 8)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20)
                .strokeBorder(BerryStyle.strawberry.opacity(0.28), lineWidth: 1.3))
            .shadow(color: BerryStyle.strawberry.opacity(0.09), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func section(_ category: Category) -> some View {
        switch category {
        case .blocks:
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(items.filter { $0.type == "blocks" }) { item in itemCard(item) }
            }
        case .frames:
            Text("ILLUSTRATED BOARD SURFACES")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            Text("All five new board surfaces are included. Your existing frames and sparkles are preserved.")
                .font(.caption).foregroundStyle(BerryStyle.chocolate)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(items.filter { $0.type == "surfaces" }) { item in itemCard(item) }
            }
            Text("FRAMES & SPARKLES")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(items.filter { $0.type == "frames" || $0.type == "sparkles" }) {
                    item in itemCard(item)
                }
            }
        case .helpers:
            VStack(alignment: .leading, spacing: 13) {
                Text("Helpers are unavailable in Berry Classic and timed modes.")
                    .font(.caption.bold())
                    .foregroundStyle(BerryStyle.chocolate)
                helperRow("Extra Undo", icon: "UndoIcon", count: session.undos, cost: BerryEconomy.undoPrice) {
                    session.buyUndo()
                }
                helperRow("Extra Shuffle", icon: "ShuffleIcon", count: session.shuffles, cost: BerryEconomy.shufflePrice) {
                    session.buyShuffle()
                }
                helperRow("Berry Hint", icon: "BerryHint", count: session.hints, cost: BerryEconomy.hintPrice) {
                    session.buyHint()
                }
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
        case .special:
            VStack(spacing: 11) {
                Text("Premium powers for Endless, Berry Story and Cozy Cottage. Classic and timed challenges stay fair.")
                    .font(.caption.bold())
                    .foregroundStyle(BerryStyle.chocolate)
                    .multilineTextAlignment(.center)
                premiumOffer(id: "trowel", title: "Golden Trowel", detail: "Remove an occupied square · one use", icon: "GoldenTrowel", fallback: "shovel.fill", cost: 150)
                premiumOffer(id: "twister", title: "Ribbon Twister", detail: "Rotate a tray piece · three uses", icon: "RibbonTwister", fallback: "arrow.triangle.2.circlepath", cost: 200)
                premiumOffer(id: "seed", title: "Starberry Seed", detail: "Plant one square, potentially clear a line", icon: "StarberrySeed", fallback: "leaf.circle.fill", cost: 230)
                premiumOffer(id: "golden-strawberry", title: "Golden Strawberry", detail: "Continue a failed run · clear the board · one use per run · no bonus points", icon: "GoldenStrawberry", fallback: "star.circle.fill", cost: BerryGameSession.goldenStrawberryCost)
                premiumOffer(id: "pantry", title: "Picnic Pantry", detail: "Permanent piece storage slot", icon: "PicnicPantry", fallback: "basket.fill", cost: 600)
                premiumOffer(id: "spyglass", title: "Berry Spyglass", detail: "Permanent preview of an upcoming piece", icon: "BerrySpyglass", fallback: "scope", cost: 900)
            }
        case .cottage:
            VStack(spacing: 11) {
                BerryIcon(name: "CottageDecorations", size: 87)
                Text("Your Strawberry Cottage")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
                Text("Owned: \(min(session.cottageDecorations, 6)) of 6 decorations")
                    .font(.subheadline.bold())
                    .foregroundStyle(BerryStyle.chocolate)
                Text("Decorate your garden by opening My Strawberry Cottage in the village. Every purchased item is saved.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BerryStyle.chocolate)
                Button(session.cottageDecorations >= 6 ? "Collection Complete" : "Buy Next Decoration • 🍓 \(session.nextCottageDecorationPrice ?? 0)") {
                    session.buyCottageDecoration()
                    if sound { BerryAudio.shared.play(.reward) }
                }
                .buttonStyle(.borderedProminent)
                .tint(BerryStyle.strawberry)
                .disabled(session.nextCottageDecorationPrice.map { session.berries < $0 } ?? true)
            }
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
        case .inventory:
            VStack(alignment: .leading, spacing: 12) {
                Label("Garden Supplies", systemImage: "shippingbox.fill")
                    .font(.headline)
                    .foregroundStyle(BerryStyle.strawberry)
                Text("Undo ×\(session.undos)   •   Shuffle ×\(session.shuffles)   •   Hint ×\(session.hints)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
                Text("Cottage decorations: \(min(session.cottageDecorations, 6)) / 6")
                Text("Premium: Trowel ×\(session.premiumCharges["trowel", default: 0]) • Twister ×\(session.premiumCharges["twister", default: 0]) • Seed ×\(session.premiumCharges["seed", default: 0])")
                    .font(.caption.bold()).foregroundStyle(BerryStyle.strawberry)
                Text("Golden Strawberry ×\(session.premiumCharges["golden-strawberry", default: 0])")
                    .font(.caption.bold()).foregroundStyle(BerryStyle.strawberry)
                Text("Pantry: \(session.premiumOwned.contains("pantry") ? "Owned" : "Locked")  •  Spyglass: \(session.premiumOwned.contains("spyglass") ? "Owned" : "Locked")")
                    .font(.caption.bold()).foregroundStyle(BerryStyle.leaf)
                    .foregroundStyle(BerryStyle.chocolate)
                if items.allSatisfy({ !session.ownedCosmetics.contains($0.id) }) {
                    Text("Your permanent cosmetic collection is waiting. Browse the Boutique to unlock your first style!")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
            ForEach(items.filter { session.ownedCosmetics.contains($0.id) }) { item in
                itemCard(item)
            }
        }
    }

    private func premiumOffer(id: String, title: String, detail: String,
                              icon: String, fallback: String, cost: Int) -> some View {
        let permanent = id == "pantry" || id == "spyglass"
        let owned = session.premiumOwned.contains(id)
        let charges = session.premiumCharges[id, default: 0]
        return HStack(spacing: 12) {
            Group {
                if UIImage(named: icon) != nil {
                    Image(icon).resizable().scaledToFit()
                } else {
                    Image(systemName: fallback)
                        .font(.system(size: 27, weight: .medium))
                        .foregroundStyle(BerryStyle.strawberry)
                }
            }
            .frame(width: 56, height: 56)
            .background(BerryStyle.softPink, in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .black, design: .rounded))
                Text(detail).font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Text(permanent ? (owned ? "✓ Permanently owned" : "Lifetime upgrade") :
                     "\(charges) charges remaining")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(BerryStyle.leaf)
            }
            Spacer(minLength: 2)
            Button(owned ? "Owned" : "🍓 \(cost)") {
                if session.buyPremium(id) && sound { BerryAudio.shared.play(.reward) }
            }
            .buttonStyle(.borderedProminent)
            .tint(owned ? BerryStyle.leaf : BerryStyle.strawberry)
            .disabled(owned || session.berries < cost)
        }
        .foregroundStyle(BerryStyle.chocolate)
        .padding(11)
        .background(.white, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17)
            .strokeBorder(BerryStyle.strawberry.opacity(0.18)))
    }

    private func helperRow(_ name: String, icon: String, count: Int, cost: Int, purchase: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            BerryIcon(name: icon, size: 37)
            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(.system(size: 14, weight: .bold, design: .rounded))
                Text("Owned ×\(count)")
                    .font(.caption.bold()).foregroundStyle(BerryStyle.strawberry)
            }
            Spacer()
            Button("🍓 \(cost)") {
                purchase()
                if sound { BerryAudio.shared.play(.reward) }
            }
            .buttonStyle(.borderedProminent)
            .tint(BerryStyle.strawberry)
            .disabled(session.berries < cost)
        }
        .foregroundStyle(BerryStyle.chocolate)
    }

    private func surfaceArt(for id: String) -> String {
        switch id {
        case "surface-glass": return "BerryBoardCandyGlassCell"
        case "surface-picnic": return "BerryBoardPicnicCell"
        case "surface-garden": return "BerryBoardGardenCell"
        case "surface-seed": return "BerryBoardSeedMosaicCell"
        default: return "BerryBoardCreamCell"
        }
    }

    private func itemCard(_ item: BerryBoutiqueItem) -> some View {
        let included = item.type == "surfaces"
        let owned = included || session.ownedCosmetics.contains(item.id)
        return VStack(spacing: 7) {
            Group {
                if item.type == "blocks" {
                    BerryTile(tint: item.id == "blueberry-blocks" ? 3 : 0,
                              mode: .classic, strawberryUnlocked: true,
                              skinOverride: item.id)
                        .padding(6)
                } else if included {
                    Image(surfaceArt(for: item.id))
                        .resizable()
                        .scaledToFit()
                } else {
                    BerryIcon(name: item.type == "frames" ? "CottageDecorations" : "Milestone",
                              size: 62)
                }
            }
            .frame(width: 70, height: 70)
            .background(item.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
            Text(item.name)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
            Text(item.detail)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if owned {
                Text(active(item) ? "✓ EQUIPPED" : included ? "INCLUDED" : "✓ OWNED")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.leaf)
            }
            Spacer(minLength: 0)
            Button {
                if owned {
                    if active(item) {
                        switch item.type {
                        case "blocks": blockSkin = "default"
                        case "frames": borderSkin = "default"
                        case "surfaces": boardSurface = "cream"
                        default: sparkleSkin = "default"
                        }
                    } else {
                        equip(item)
                    }
                } else if session.buyCosmetic(id: item.id, cost: item.price) {
                    equip(item)
                    if sound { BerryAudio.shared.play(.reward) }
                }
            } label: {
                Text(included ? (active(item) ? "✓ Selected" : "Use Board") :
                     owned ? (active(item) ? "Unequip" : "Equip") : "🍓 \(item.price)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(owned ? BerryStyle.leaf : BerryStyle.strawberry)
            .disabled((!owned && session.berries < item.price) ||
                      (included && active(item)))
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 218)
        .background(.white, in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19)
            .strokeBorder(active(item) ? BerryStyle.leaf.opacity(0.65) :
                          item.accent.opacity(0.28),
                          lineWidth: active(item) ? 2 : 1.2))
    }
}
