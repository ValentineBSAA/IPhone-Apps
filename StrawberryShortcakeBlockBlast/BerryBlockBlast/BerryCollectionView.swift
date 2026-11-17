import SwiftUI

/// This is an offline personal scoreboard, never a fabricated online ranking.
struct BerryCollectionView: View {
    @ObservedObject var session: BerryGameSession
    let lifetimeLines: Int
    let onOpenBoutique: () -> Void
    @State private var section = 0
    @AppStorage("berryblockblast.shop.equippedBlockSkin.v056b2") private var blockSkin = "default"
    @AppStorage("berryblockblast.shop.equippedBorder.v056b2") private var borderSkin = "default"
    @AppStorage("berryblockblast.shop.equippedSparkle.v056b2") private var sparkleSkin = "default"
    @AppStorage("berryblockblast.strawberry-unlocked") private var strawberryUnlocked = false

    private struct Skin: Identifiable {
        let id: String
        let title: String
        let category: String
        let detail: String
    }
    private let skins = [
        Skin(id: "default", title: "Strawberry Candy", category: "blocks", detail: "Your classic berry pieces"),
        Skin(id: "strawberry-fruit", title: "True Strawberry", category: "blocks", detail: "Real strawberry-shaped fruit blocks • Free"),
        Skin(id: "blueberry-blocks", title: "Blueberry Velvet", category: "blocks", detail: "Deep blue and violet jewels · 🍓 90"),
        Skin(id: "vanilla-blocks", title: "Vanilla Cream", category: "blocks", detail: "Golden honey and whipped cream · 🍓 90"),
        Skin(id: "raspberry-blocks", title: "Raspberry Ruby", category: "blocks", detail: "Raspberry candy jewels · 🍓 110"),
        Skin(id: "lemon-blocks", title: "Lemon Glaze", category: "blocks", detail: "Sunny citrus candy · 🍓 110"),
        Skin(id: "chocolate-blocks", title: "Chocolate Truffle", category: "blocks", detail: "Rich chocolate drizzle · 🍓 120"),
        Skin(id: "mint-blocks", title: "Mint Frost", category: "blocks", detail: "Glassy mint candies · 🍓 110"),
        Skin(id: "blackberry-blocks", title: "Blackberry Jam", category: "blocks", detail: "Dark-purple berry shine · 🍓 130"),
        Skin(id: "rose-border", title: "Rose Petal Frame", category: "frames", detail: "Raspberry-pink board edging · 🍓 75"),
        Skin(id: "mint-border", title: "Mint Garden Frame", category: "frames", detail: "Fresh mint-green board edging · 🍓 75"),
        Skin(id: "berry-sparkle", title: "Berry Sparkle", category: "sparkles", detail: "Sparkle effects on your blocks · 🍓 100")
    ]
    private var records: [(String, String, Int)] {
        let defaults = UserDefaults.standard
        return [
            ("Berry Classic", "BerryClassic", defaults.integer(forKey: "berryblockblast.classic.best-score.v055")),
            ("Sweet Endless 8 × 8", "SweetEndless", defaults.integer(forKey: BerryGameSession.endlessScoreKey(side: 8))),
            ("Sweet Endless 12 × 12", "SweetEndless", defaults.integer(forKey: BerryGameSession.endlessScoreKey(side: 12))),
            ("Sweet Endless 24 × 24", "SweetEndless", defaults.integer(forKey: BerryGameSession.endlessScoreKey(side: 24))),
            ("Berry Story", "BerryStory", defaults.integer(forKey: "berryblockblast.story.best-score.v055")),
            ("Daily Harvest", "DailyHarvest", defaults.integer(forKey: "berryblockblast.daily.best-score.v055")),
            ("Cozy Cottage", "CottageDecorations", defaults.integer(forKey: "berryblockblast.cozy.best-score.v055")),
            ("Strawberry Nightmare", "BerryClassic", defaults.integer(forKey: "berryblockblast.nightmare.best-score.v1")),
            ("Berry Blitz: Quick Jam", "Milestone", defaults.integer(forKey: BerryBlitzVariant.quick60.bestScoreKey)),
            ("Berry Blitz: Berry Rush", "Milestone", defaults.integer(forKey: BerryBlitzVariant.rush120.bestScoreKey)),
            ("Berry Blitz: Garden Sprint", "Milestone", defaults.integer(forKey: BerryBlitzVariant.garden300.bestScoreKey)),
            ("Berry Blitz: Berry Marathon", "Milestone", defaults.integer(forKey: BerryBlitzVariant.marathon600.bestScoreKey))
        ].sorted { $0.2 > $1.2 }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                BerryIcon(name: "BerryCollection", size: 88)
                Text("Your Berry Collection")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
                    .multilineTextAlignment(.center)
                BerryWalletPill(berries: session.berries)
                Picker("Collection sections", selection: $section) {
                    Text("Collection").tag(0)
                    Text("Inventory").tag(1)
                    Text("Awards").tag(2)
                    Text("Records").tag(3)
                }
                .pickerStyle(.segmented)
                if section == 0 { collectionContent }
                if section == 1 { inventoryContent }
                if section == 2 { awardsContent }
                if section == 3 { recordsContent }
                Button { onOpenBoutique() } label: {
                    HStack {
                        BerryIcon(name: "ShopBasket", size: 33)
                        Text("Visit the Berry Boutique").font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }.foregroundStyle(BerryStyle.chocolate)
                        .padding(12)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
        }
        .background(BerryStyle.cream.ignoresSafeArea())
        .onAppear { session.refreshEconomyFromDisk() }
    }
    private var collectionContent: some View {
        VStack(spacing: 13) {
            card("Lifetime Harvest", icon: "HarvestReward") {
                Text("🍓 \(BerryNumbers.compact(session.totalEarnedBerries)) earned")
                    .font(.title3.bold())
                Text("\(lifetimeLines) total lines cleared")
                ProgressView(value: Double(min(lifetimeLines, 100)), total: 100)
                    .tint(BerryStyle.strawberry)
                Text("Next collection milestones: 10, 25, 50 and 100 lines")
                    .font(.caption).foregroundStyle(.secondary)
            }
            card("Strawberry Blocks", icon: "CollectionBadge") {
                Text(strawberryUnlocked ? "✓ Unlocked by clearing 10 lines" :
                        "🔒 Clear 10 lines to unlock strawberry decorations")
                ProgressView(value: Double(min(lifetimeLines, 10)), total: 10)
                    .tint(BerryStyle.leaf)
            }
            card("Your Sweet Cottage", icon: "CottageDecorations") {
                Text("\(min(session.cottageDecorations, 6)) of 6 decorations owned")
                Text("Build your garden in My Strawberry Cottage on the home screen.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    private var inventoryContent: some View {
        VStack(spacing: 12) {
            card("Garden Helpers", icon: "UndoHelper") {
                HStack {
                    BerryIcon(name: "UndoIcon", size: 35)
                    Text("Undo")
                    Spacer()
                    Text("×\(session.undos)").bold().foregroundStyle(BerryStyle.strawberry)
                }
                HStack {
                    BerryIcon(name: "ShuffleIcon", size: 35)
                    Text("Shuffle")
                    Spacer()
                    Text("×\(session.shuffles)").bold().foregroundStyle(BerryStyle.strawberry)
                }
                HStack {
                    BerryIcon(name: "BerryHint", size: 35)
                    Text("Berry Hint")
                    Spacer()
                    Text("×\(session.hints)").bold().foregroundStyle(BerryStyle.strawberry)
                }
                Text("Use these from the game toolbar. Berry Classic and timed challenges do not allow helpers.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(skins) { skin in
                let owned = skin.id == "default" || session.ownedCosmetics.contains(skin.id)
                let equipped = active(skin)
                HStack(spacing: 12) {
                    if skin.category == "blocks" {
                        BerryTile(tint: skin.id == "blueberry-blocks" ? 3 : 0,
                                  mode: .classic, skinOverride: skin.id)
                            .frame(width: 54, height: 54)
                    } else {
                        BerryIcon(name: skin.category == "frames" ? "CottageDecorations" : "Milestone", size: 54)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(skin.title).font(.system(size: 14, weight: .heavy, design: .rounded))
                        Text(skin.detail).font(.caption2)
                            .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        if equipped { Text("✓ Currently equipped").font(.caption2).foregroundStyle(BerryStyle.strawberry) }
                    }
                    Spacer(minLength: 2)
                    if owned {
                        Button(equipped ? "Unequip" : "Equip") { setEquipped(skin, enabled: !equipped) }
                            .font(.caption.bold()).buttonStyle(.borderedProminent)
                            .tint(equipped ? BerryStyle.leaf : BerryStyle.strawberry)
                    } else {
                        Label(skin.id == "strawberry-fruit" ? "Free in Boutique" : "Boutique • \(shopPrice(skin.id)) 🍓", systemImage: "lock.fill")
                            .font(.caption2).foregroundStyle(BerryStyle.strawberry)
                    }
                }
                .foregroundStyle(BerryStyle.chocolate)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }
    private var awardsContent: some View {
        VStack(spacing: 12) {
            ForEach([10, 25, 50, 100], id: \.self) { target in
                HStack(spacing: 13) {
                    BerryIcon(name: lifetimeLines >= target ? "Champion" : "Milestone", size: 60)
                        .opacity(lifetimeLines >= target ? 1 : 0.5)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(target)-Line Harvest").font(.headline)
                        Text(lifetimeLines >= target ? "Achievement unlocked!" : "\(max(0, target-lifetimeLines)) more lines to go")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if lifetimeLines >= target { Image(systemName: "checkmark.seal.fill").foregroundStyle(BerryStyle.leaf) }
                }
                .padding(12).background(.white, in: RoundedRectangle(cornerRadius: 18))
            }
            Text("Awards reflect your actual offline progress. Your earned berries and best scores are preserved.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private var recordsContent: some View {
        VStack(spacing: 12) {
            Text("🏆 Personal Best Leaderboard")
                .font(.headline).foregroundStyle(BerryStyle.strawberry)
            Text("These are your own local records, not online players.")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(0..<records.count, id: \.self) { position in
                let record = records[position]
                HStack(spacing: 9) {
                    Text("\(position + 1)").font(.headline).frame(width: 22)
                    BerryIcon(name: record.1, size: 34)
                    Text(record.0).font(.system(size: 12, weight: .bold, design: .rounded))
                    Spacer(minLength: 4)
                    Text(BerryNumbers.compact(record.2)).font(.system(size: 14, weight: .black, design: .rounded))
                }
                .foregroundStyle(BerryStyle.chocolate)
                .padding(10)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    private func shopPrice(_ id: String) -> Int {
        switch id {
        case "blueberry-blocks", "vanilla-blocks": return 90
        case "raspberry-blocks", "lemon-blocks", "mint-blocks": return 110
        case "chocolate-blocks": return 120
        case "blackberry-blocks": return 130
        case "rose-border", "mint-border": return 75
        case "berry-sparkle": return 100
        default: return 0
        }
    }

    private func active(_ skin: Skin) -> Bool {
        switch skin.category {
        case "blocks": return blockSkin == skin.id
        case "frames": return borderSkin == skin.id
        default: return sparkleSkin == skin.id
        }
    }
    private func setEquipped(_ skin: Skin, enabled: Bool) {
        guard skin.id == "default" || session.ownedCosmetics.contains(skin.id) else { return }
        let id = enabled ? skin.id : "default"
        switch skin.category {
        case "blocks": blockSkin = id
        case "frames": borderSkin = id
        default: sparkleSkin = id
        }
    }
    private func card<Content: View>(_ title: String, icon: String,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                BerryIcon(name: icon, size: 47)
                Text(title).font(.headline)
            }
            content()
        }
        .foregroundStyle(BerryStyle.chocolate)
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}
