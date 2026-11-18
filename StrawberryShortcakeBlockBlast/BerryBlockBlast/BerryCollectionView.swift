import SwiftUI

/// This is an offline personal scoreboard, never a fabricated online ranking.
struct BerryCollectionView: View {
    @ObservedObject var session: BerryGameSession
    let lifetimeLines: Int
    let onOpenBoutique: () -> Void
    @State private var section: Int? = nil
    @ObservedObject private var playtime = BerryPlaytimeTracker.shared
    @ObservedObject private var economy = BerryEconomyLedger.shared
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

    private let gridColumns = [GridItem(.flexible(), spacing: 11),
                               GridItem(.flexible(), spacing: 11)]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                BerryIcon(name: "BerryCollection", size: 76)
                Text("Your Berry Collection")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
                    .multilineTextAlignment(.center)
                BerryWalletPill(berries: session.berries)

                if let section {
                    HStack(spacing: 9) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                self.section = nil
                            }
                        } label: {
                            Label("Back to Collection", systemImage: "chevron.left")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .buttonStyle(.bordered)
                        .tint(BerryStyle.strawberry)
                        Spacer(minLength: 3)
                        Text(["Collection", "Inventory", "Awards", "Records", "Playtime", "Economy"][section])
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                    }
                    switch section {
                    case 0: collectionContent
                    case 1: inventoryContent
                    case 2: awardsContent
                    case 3: recordsContent
                    case 4: playtimeContent
                    default: economyContent
                    }
                } else {
                    Text("EXPLORE YOUR BERRY TREASURES")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(BerryStyle.strawberry)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        BerryGridNavigationTile(
                            title: "Collection", detail: "Harvest, unlocks and cottage progress",
                            art: "BerryCollection", caption: "My Progress") {
                                withAnimation { section = 0 }
                            }
                        BerryGridNavigationTile(
                            title: "Inventory", detail: "Helpers, power-ups and equipped skins",
                            art: "PremiumToolsCategory", caption: "Owned Items") {
                                withAnimation { section = 1 }
                            }
                        BerryGridNavigationTile(
                            title: "Awards", detail: "Your unlocked berry achievements",
                            art: "Champion", caption: "\(lifetimeLines) Lines") {
                                withAnimation { section = 2 }
                            }
                        BerryGridNavigationTile(
                            title: "Personal Records", detail: "Best scores in every game mode",
                            art: "Milestone", caption: "12 Modes") {
                                withAnimation { section = 3 }
                            }
                        BerryGridNavigationTile(
                            title: "Playtime & Sessions",
                            detail: "Mode timers, daily history and start/stop times",
                            art: "DailyHarvest",
                            caption: "⏱ My Playtime") {
                                withAnimation { section = 4 }
                            }
                        BerryGridNavigationTile(
                            title: "Berry Economy",
                            detail: "Real earnings, purchases and savings goals",
                            art: "HarvestReward", caption: "My Strawberry Wallet") {
                                withAnimation { section = 5 }
                            }
                        BerryGridNavigationTile(
                            title: "Berry Boutique", detail: "Shop for new garden treasures",
                            art: "ShopBasket", caption: "Visit Shop") {
                                onOpenBoutique()
                            }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .background(BerryStyle.cream.ignoresSafeArea())
        .onAppear {
            session.refreshEconomyFromDisk()
            playtime.checkpoint()
        }
    }

    private var collectionContent: some View {
        LazyVGrid(columns: gridColumns, spacing: 11) {
            BerryGridInfoTile(
                title: "Lifetime Harvest",
                detail: "\(lifetimeLines) total lines cleared",
                art: "HarvestReward",
                value: "🍓 \(BerryNumbers.compact(session.totalEarnedBerries))")
            BerryGridInfoTile(
                title: "Strawberry Blocks",
                detail: strawberryUnlocked ? "Unlocked after 10 lines" :
                    "\(max(0, 10 - lifetimeLines)) lines until unlock",
                art: "CollectionBadge",
                value: strawberryUnlocked ? "Unlocked" : "\(min(lifetimeLines, 10))/10",
                complete: strawberryUnlocked)
            BerryGridInfoTile(
                title: "Sweet Cottage",
                detail: "Arrange owned decorations in the Village",
                art: "CottageDecorations",
                value: "\(min(session.cottageDecorations, 6))/6")
            BerryGridInfoTile(
                title: "Next Milestone",
                detail: "Reach 10, 25, 50 and 100 lifetime lines",
                art: "Milestone",
                value: "\(lifetimeLines) Lines",
                complete: lifetimeLines >= 100)
        }
    }

    private var inventoryContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("GARDEN HELPERS")
            LazyVGrid(columns: gridColumns, spacing: 11) {
                BerryGridInfoTile(title: "Undo", detail: "Return to the last move",
                                 art: "UndoIcon", value: "×\(session.undos)")
                BerryGridInfoTile(title: "Shuffle", detail: "Refresh a blocked hand",
                                 art: "ShuffleIcon", value: "×\(session.shuffles)")
                BerryGridInfoTile(title: "Berry Hint", detail: "Find a legal placement",
                                 art: "BerryHint", value: "×\(session.hints)")
            }
            sectionHeader("SPECIAL TOOLS & UPGRADES")
            LazyVGrid(columns: gridColumns, spacing: 11) {
                BerryGridInfoTile(title: "Golden Strawberry", detail: "One continue per run",
                                 art: "GoldenStrawberry",
                                 value: "×\(session.premiumCharges["golden-strawberry", default: 0])")
                BerryGridInfoTile(title: "Golden Trowel", detail: "Remove a filled square",
                                 art: "GoldenTrowel",
                                 value: "×\(session.premiumCharges["trowel", default: 0])")
                BerryGridInfoTile(title: "Ribbon Twister", detail: "Rotate a tray piece",
                                 art: "RibbonTwister",
                                 value: "×\(session.premiumCharges["twister", default: 0])")
                BerryGridInfoTile(title: "Starberry Seed", detail: "Fill one empty square",
                                 art: "StarberrySeed",
                                 value: "×\(session.premiumCharges["seed", default: 0])")
                BerryGridInfoTile(title: "Picnic Pantry", detail: "Permanent piece storage",
                                 art: "PicnicPantry",
                                 value: session.premiumOwned.contains("pantry") ? "Owned" : "Locked",
                                 complete: session.premiumOwned.contains("pantry"))
                BerryGridInfoTile(title: "Berry Spyglass", detail: "See the next piece",
                                 art: "BerrySpyglass",
                                 value: session.premiumOwned.contains("spyglass") ? "Owned" : "Locked",
                                 complete: session.premiumOwned.contains("spyglass"))
            }
            Text("Helpers aren't available in Berry Classic or timed challenges.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.7))
            sectionHeader("MY BLOCKS, FRAMES & SPARKLES")
            LazyVGrid(columns: gridColumns, spacing: 11) {
                ForEach(skins) { skin in
                    cosmeticTile(skin)
                }
            }
        }
    }

    private func cosmeticTile(_ skin: Skin) -> some View {
        let owned = skin.id == "default" || session.ownedCosmetics.contains(skin.id)
        let equipped = active(skin)
        return VStack(spacing: 7) {
            if skin.category == "blocks" {
                BerryTile(tint: skin.id == "blueberry-blocks" ? 3 : 0,
                          mode: .classic, skinOverride: skin.id)
                    .frame(width: 58, height: 58)
            } else {
                BerryIcon(name: skin.category == "frames" ? "CottageDecorations" : "Milestone",
                          size: 58)
            }
            Text(skin.title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(skin.detail)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.73))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Spacer(minLength: 0)
            if owned {
                Button(equipped ? "✓ Equipped" : "Equip") {
                    setEquipped(skin, enabled: !equipped)
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .buttonStyle(.borderedProminent)
                .tint(equipped ? BerryStyle.leaf : BerryStyle.strawberry)
            } else {
                Text(skin.id == "strawberry-fruit" ? "Free in Boutique" :
                     "🔒 🍓 \(shopPrice(skin.id))")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 215)
        .background(.white, in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19)
            .strokeBorder(BerryStyle.strawberry.opacity(equipped ? 0.58 : 0.25),
                          lineWidth: equipped ? 2 : 1.2))
    }

    private var awardsContent: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeader("YOUR REAL OFFLINE ACHIEVEMENTS")
            LazyVGrid(columns: gridColumns, spacing: 11) {
                ForEach([10, 25, 50, 100], id: \.self) { target in
                    let unlocked = lifetimeLines >= target
                    VStack(spacing: 8) {
                        BerryIcon(name: unlocked ? "Champion" : "Milestone", size: 61)
                            .opacity(unlocked ? 1 : 0.6)
                        Text("\(target)-Line Harvest")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.chocolate)
                            .multilineTextAlignment(.center)
                        Text(unlocked ? "✓ Unlocked" : "\(max(0, target - lifetimeLines)) lines left")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(unlocked ? BerryStyle.leaf : BerryStyle.strawberry)
                        ProgressView(value: Double(min(lifetimeLines, target)), total: Double(target))
                            .tint(unlocked ? BerryStyle.leaf : BerryStyle.strawberry)
                    }
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 19))
                    .overlay(RoundedRectangle(cornerRadius: 19)
                        .strokeBorder(BerryStyle.strawberry.opacity(0.25)))
                }
            }
            Text("All awards reflect your actual offline gameplay. Scores and strawberries are unchanged.")
                .font(.caption)
                .foregroundStyle(BerryStyle.chocolate.opacity(0.7))
        }
    }

    private var recordsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("YOUR PERSONAL BEST SCORES")
            Text("These are your real local scores, not an online leaderboard.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
            LazyVGrid(columns: gridColumns, spacing: 11) {
                ForEach(0..<records.count, id: \.self) { index in
                    let record = records[index]
                    BerryGridInfoTile(
                        title: record.0,
                        detail: "#\(index + 1) Personal Best",
                        art: record.1,
                        value: record.2 > 0 ? BerryNumbers.compact(record.2) : "Not yet")
                }
            }
            sectionHeader("BERRY ECONOMY & PLAYTIME")
            BerryGridNavigationTile(
                title: "Berry Economy", detail: "Balance, income and recorded spending",
                art: "HarvestReward", caption: "My Wallet") {
                    withAnimation { section = 5 }
                }
            sectionHeader("YOUR PLAYTIME LEADERBOARD")
            BerryGridNavigationTile(
                title: "Playtime & Sessions",
                detail: "Per-mode timers, start and stop times, and daily history",
                art: "DailyHarvest",
                caption: BerryPlaytimeTracker.display(playtime.todaySeconds) + " today") {
                    withAnimation { section = 4 }
                }
        }
    }

    private var playtimeContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("YOUR STRAWBERRY PLAYTIME")
            Text("Tracked privately on this iPhone since 0.5.9. Background and lock-screen time isn't counted. Mode timers also stop during Pause, menus and result screens.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
            LazyVGrid(columns: gridColumns, spacing: 11) {
                BerryGridInfoTile(title: "Today",
                                 detail: "Time in Berry Berry Blast",
                                 art: "DailyHarvest",
                                 value: BerryPlaytimeTracker.display(playtime.todaySeconds))
                BerryGridInfoTile(title: "Current Visit",
                                 detail: "This foreground session",
                                 art: "Milestone",
                                 value: BerryPlaytimeTracker.display(playtime.sessionSeconds))
                BerryGridInfoTile(title: "Lifetime Playtime",
                                 detail: "All foreground app time since tracking began",
                                 art: "Champion",
                                 value: BerryPlaytimeTracker.display(playtime.lifetimeSeconds))
                BerryGridInfoTile(title: "Days Played",
                                 detail: "Days with recorded activity",
                                 art: "BerryCollection",
                                 value: "\(playtime.daysPlayed)")
            }
            sectionHeader("PLAYTIME BY GAME MODE")
            Text("Separate totals for every board size and Blitz duration. Last-played times follow your device's 12-hour clock.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
            LazyVGrid(columns: gridColumns, spacing: 11) {
                ForEach(BerryPlaytimeTracker.modeCatalog) { mode in
                    let latest = playtime.latestModeSession(for: mode.id)
                    let total = playtime.modeSeconds(for: mode.id)
                    let today = playtime.modeSecondsToday(for: mode.id)
                    BerryGridInfoTile(
                        title: mode.title,
                        detail: total > 0 ?
                            "Today \(BerryPlaytimeTracker.display(today)) · Last \(latest.map { BerryPlaytimeTracker.clock($0.startedAt) } ?? "—")" :
                            "Not played since tracking began",
                        art: mode.art,
                        value: total > 0 ? BerryPlaytimeTracker.display(total) : "Not yet")
                }
            }
            sectionHeader("RECENT GAME SESSIONS")
            Text("Actual start and stop times while playing. Pausing or leaving the app ends a timed session.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
            if playtime.recentSessions.isEmpty {
                BerryGridInfoTile(
                    title: "No sessions yet",
                    detail: "Play any game mode to start your private playtime journal.",
                    art: "DailyHarvest", value: "Ready")
            } else {
                LazyVGrid(columns: gridColumns, spacing: 11) {
                    ForEach(Array(playtime.recentSessions.prefix(20))) { visit in
                        BerryGridInfoTile(
                            title: visit.title,
                            detail: visit.dayLabel + " · " + visit.timeRange,
                            art: BerryPlaytimeTracker.modeCatalog.first(where: {
                                $0.id == visit.modeID
                            })?.art ?? "Milestone",
                            value: BerryPlaytimeTracker.display(visit.activeSeconds))
                    }
                }
            }
            sectionHeader("LAST SEVEN DAYS")
            LazyVGrid(columns: gridColumns, spacing: 11) {
                ForEach(playtime.lastSevenDays) { day in
                    BerryGridInfoTile(
                        title: day.label, detail: "Total app playtime",
                        art: "DailyHarvest",
                        value: BerryPlaytimeTracker.display(day.seconds))
                }
            }
        }
    }

    private var economyContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("YOUR STRAWBERRY ECONOMY")
            Text("Prices are unchanged. The balance and lifetime earnings are real; spending and mode breakdowns are recorded only from 0.5.10 onward, without inventing past purchases.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.76))
            LazyVGrid(columns: gridColumns, spacing: 11) {
                BerryGridInfoTile(title: "Berry Wallet",
                                 detail: "Available strawberries to spend",
                                 art: "HarvestReward",
                                 value: BerryNumbers.compact(session.berries))
                BerryGridInfoTile(title: "Lifetime Earned",
                                 detail: "Preserved from previous versions",
                                 art: "Champion",
                                 value: BerryNumbers.compact(session.totalEarnedBerries))
                BerryGridInfoTile(title: "Spent Since 0.5.10",
                                 detail: "Actual purchases tracked after this update",
                                 art: "ShopBasket",
                                 value: BerryNumbers.compact(economy.spent))
                BerryGridInfoTile(title: "Daily Rescue Budget",
                                 detail: "Golden Strawberry: 250; Shuffle: 50",
                                 art: "GoldenStrawberry",
                                 value: session.berries >= 250 ? "Rescue Ready" :
                                     "\(max(0, 250 - session.berries)) to Go")
            }
            sectionHeader("LINE EARNINGS BY MODE · FROM 0.5.10")
            LazyVGrid(columns: gridColumns, spacing: 11) {
                ForEach(BerryMode.allCases) { mode in
                    BerryGridInfoTile(title: mode.rawValue,
                                     detail: "Strawberries earned from cleared lines",
                                     art: mode == .story ? "BerryStory" :
                                          mode == .daily ? "DailyHarvest" :
                                          mode == .challenge ? "Milestone" : "SweetEndless",
                                     value: BerryNumbers.compact(
                                        economy.earnedByMode[mode.rawValue, default: 0]))
                }
            }
            sectionHeader("ACTUAL SPENDING BY ITEM")
            if economy.spentByItem.isEmpty {
                BerryGridInfoTile(title: "No purchases tracked yet",
                                 detail: "Your existing purchases are preserved; new spending will appear here.",
                                 art: "ShopBasket", value: "0 🍓")
            } else {
                LazyVGrid(columns: gridColumns, spacing: 11) {
                    ForEach(economy.spentByItem.keys.sorted(), id: \.self) { item in
                        BerryGridInfoTile(title: item,
                                         detail: "Strawberries spent since 0.5.10",
                                         art: "ShopBasket",
                                         value: BerryNumbers.compact(
                                            economy.spentByItem[item, default: 0]))
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(BerryStyle.strawberry)
            .frame(maxWidth: .infinity, alignment: .leading)
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
