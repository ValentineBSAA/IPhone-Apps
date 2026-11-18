import SwiftUI

/// Offline, local-only progression. All existing game/save/currency keys remain intact.
@MainActor
final class BerryProgression: ObservableObject {
    static let shared = BerryProgression()
    @Published private(set) var revision = 0
    @Published private(set) var celebrationText: String? = nil
    private var celebrationToken = 0
    func celebrate(_ message: String) {
        celebrationToken += 1
        let token = celebrationToken
        celebrationText = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
            guard let self = self, self.celebrationToken == token else { return }
            self.celebrationText = nil
        }
    }
    private let namespace = "berryberryblast.progression.v059."
    private init() {}

    struct Quest: Identifiable {
        let id: String
        let title: String
        let detail: String
        let symbol: String
        let target: Int
        let reward: Int
    }

    private var today: String { BerryDailyHistory.dateKey(for: Date()) }
    private func key(_ suffix: String) -> String { namespace + today + "." + suffix }
    private func count(_ name: String) -> Int { UserDefaults.standard.integer(forKey: key(name)) }
    private func add(_ name: String, amount: Int = 1) {
        let value = min(1000000, count(name) + max(0, amount))
        UserDefaults.standard.set(value, forKey: key(name))
        revision &+= 1
    }

    var quests: [Quest] {
        let base = [
            Quest(id: "lines", title: "Blooming Lines", detail: "Clear 12 complete lines", symbol: "square.grid.3x3.fill", target: 12, reward: 25),
            Quest(id: "modes", title: "Village Explorer", detail: "Place blocks in two different modes", symbol: "map.fill", target: 2, reward: 25),
            Quest(id: "moves", title: "Garden Gardener", detail: "Place 18 puzzle pieces", symbol: "hand.tap.fill", target: 18, reward: 20),
            Quest(id: "chapters", title: "Story Keeper", detail: "Finish a Berry Story chapter", symbol: "book.closed.fill", target: 1, reward: 35)
        ]
        let offset = (Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0) % base.count
        return (0..<3).map { base[(offset + $0) % base.count] }
    }

    func progress(for quest: Quest) -> Int { min(quest.target, count(quest.id)) }
    func isClaimed(_ quest: Quest) -> Bool { UserDefaults.standard.bool(forKey: key("claimed." + quest.id)) }
    var claimedToday: Int { quests.filter(isClaimed).count }
    var claimedTotal: Int { UserDefaults.standard.integer(forKey: namespace + "claimed.total") }

    func recordPlacement(mode: BerryMode, clearedLines: Int) {
        add("moves")
        if clearedLines > 0 { add("lines", amount: clearedLines) }
        let modeName = mode.rawValue
        var modes = UserDefaults.standard.stringArray(forKey: key("playedModes")) ?? []
        if !modes.contains(modeName) {
            modes.append(modeName)
            UserDefaults.standard.set(modes, forKey: key("playedModes"))
            add("modes")
        }
    }

    func recordStoryChapter(_ chapter: Int) {
        let name = "chapter." + String(chapter)
        if !UserDefaults.standard.bool(forKey: key(name)) {
            UserDefaults.standard.set(true, forKey: key(name))
            add("chapters")
        }
        celebrate("📖 Story chapter complete! The village is growing.")
        revision &+= 1
    }

    @discardableResult
    func claim(_ quest: Quest, into session: BerryGameSession) -> Bool {
        guard quests.contains(where: { $0.id == quest.id }),
              progress(for: quest) >= quest.target,
              !isClaimed(quest) else { return false }
        UserDefaults.standard.set(true, forKey: key("claimed." + quest.id))
        UserDefaults.standard.set(claimedTotal + 1, forKey: namespace + "claimed.total")
        // Historical payout keys are never re-used for new daily quests.
        session.awardOnce("quest-" + today + "-" + quest.id, amount: quest.reward, reason: "Berry Quest: " + quest.title)
        celebrate("🍓 " + quest.title + " · +" + String(quest.reward) + " strawberries!")
        revision &+= 1
        return true
    }

    var villageLevel: Int {
        let chapter = max(1, UserDefaults.standard.integer(forKey: "berryblockblast.story.level"))
        return min(5, 1 + (chapter - 1) / 2 + min(2, BerryDailyHistory.completed.count / 7))
    }
}

struct BerryQuestBoardView: View {
    @ObservedObject var session: BerryGameSession
    @ObservedObject private var progress = BerryProgression.shared
    @Environment(\.dismiss) private var dismiss
    private func questArt(for id: String) -> String {
        switch id {
        case "lines": return "HarvestReward"
        case "modes": return "BerryVillageMap"
        case "moves": return "CottageDecorations"
        case "chapters": return "BerryStory"
        default: return "Milestone"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Image("BerryQuestBoardArt").resizable().scaledToFit()
                        .frame(height: 125).accessibilityHidden(true)
                    Text("Berry Quest Board")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Text("Three little adventures each day. Earn berries by actually playing, not by opening menus.")
                        .multilineTextAlignment(.center).font(.subheadline)
                        .foregroundStyle(BerryStyle.chocolate)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                        GridItem(.flexible(), spacing: 11)], spacing: 11) {
                        ForEach(progress.quests) { quest in
                            VStack(spacing: 8) {
                                ZStack(alignment: .bottomTrailing) {
                                    BerryIcon(name: questArt(for: quest.id), size: 61)
                                        .frame(width: 64, height: 64)
                                        .background(BerryStyle.softPink,
                                                    in: RoundedRectangle(cornerRadius: 18))
                                        .overlay(RoundedRectangle(cornerRadius: 18)
                                            .strokeBorder(BerryStyle.strawberry.opacity(0.35),
                                                          lineWidth: 1.4))
                                    Image(systemName: quest.symbol)
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundStyle(.white)
                                        .padding(5)
                                        .background(BerryStyle.strawberry, in: Circle())
                                        .offset(x: 2, y: 2)
                                }
                                Text(quest.title)
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(BerryStyle.chocolate)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                Text(quest.detail)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(BerryStyle.chocolate.opacity(0.72))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                Spacer(minLength: 0)
                                ProgressView(value: Double(progress.progress(for: quest)),
                                             total: Double(quest.target))
                                    .tint(BerryStyle.strawberry)
                                BerryCandyNumber(value:
                                    "\(progress.progress(for: quest))/\(quest.target)",
                                    size: 15, label: "Quest Progress")
                                Button(progress.isClaimed(quest) ? "✓ Collected" :
                                       "🍓 \(quest.reward) · Claim") {
                                    _ = progress.claim(quest, into: session)
                                }
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .buttonStyle(.borderedProminent)
                                .tint(BerryStyle.strawberry)
                                .disabled(progress.isClaimed(quest) ||
                                          progress.progress(for: quest) < quest.target)
                            }
                            .frame(maxWidth: .infinity, minHeight: 240)
                            .padding(9)
                            .background(.white, in: RoundedRectangle(cornerRadius: 19))
                            .overlay(RoundedRectangle(cornerRadius: 19)
                                .strokeBorder(BerryStyle.strawberry.opacity(0.28)))
                        }
                    }
                    Text("Quests refresh at local midnight. Rewards are collected only once per completed quest.")
                        .font(.caption).multilineTextAlignment(.center)
                        .foregroundStyle(BerryStyle.chocolate)
                }
                .padding(17)
            }
            .background(BerryStyle.cream.ignoresSafeArea())
            .navigationTitle("Berry Quests")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

struct BerryVillageView: View {
    @ObservedObject var session: BerryGameSession
    @ObservedObject private var progress = BerryProgression.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCottage = false
    private struct VillagePlace: Identifiable {
        let name: String
        let symbol: String
        let detail: String
        let level: Int
        var id: String { name }
    }
    private let places: [VillagePlace] = [
        .init(name: "Strawberry Cottage", symbol: "house.fill", detail: "Your growing little home", level: 1),
        .init(name: "Blooming Path", symbol: "leaf.fill", detail: "Restore paths with Story chapters", level: 2),
        .init(name: "Jam Market", symbol: "basket.fill", detail: "Bring treats back to the village", level: 3),
        .init(name: "Berry Bakery", symbol: "birthday.cake.fill", detail: "Help the ovens come alive", level: 4),
        .init(name: "Festival Square", symbol: "sparkles", detail: "A cheerful village celebration", level: 5)
    ]
    private func villageArt(for level: Int) -> String {
        switch level {
        case 1: return "CottageDecorations"
        case 2: return "BerryVillageGate"
        case 3: return "ShopBasket"
        case 4: return "BerryStory"
        default: return "Champion"
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    Image("BerryVillageMap").resizable().scaledToFit()
                        .frame(maxWidth: 355).frame(height: 215)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(BerryStyle.strawberry.opacity(0.4), lineWidth: 2))
                        .accessibilityHidden(true)
                    Text("Strawberry Village")
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Text("Restore the village through Story chapters, daily harvests and garden adventures.")
                        .multilineTextAlignment(.center).font(.subheadline)
                        .foregroundStyle(BerryStyle.chocolate)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                        GridItem(.flexible(), spacing: 11)], spacing: 11) {
                        ForEach(places) { place in
                            let unlocked = progress.villageLevel >= place.level
                            if unlocked && place.level == 1 {
                                BerryGridNavigationTile(
                                    title: place.name, detail: place.detail,
                                    art: "CottageDecorations",
                                    caption: "Visit Cottage") {
                                    showCottage = true
                                }
                            } else {
                                BerryGridInfoTile(
                                    title: place.name,
                                    detail: unlocked ? place.detail :
                                        "Unlock at Village Level \(place.level)",
                                    art: villageArt(for: place.level),
                                    value: unlocked ? "✓ Restored" : "🔒 Level \(place.level)",
                                    complete: unlocked)
                            }
                        }
                    }
                    Text("VILLAGE LEVEL \(progress.villageLevel) / 5")
                        .font(.headline).foregroundStyle(BerryStyle.strawberry)
                }
                .padding(17)
            }
            .background(BerryStyle.cream.ignoresSafeArea())
            .navigationTitle("Berry Village")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showCottage) { BerryCottageGardenView(session: session) }
        }
    }
}

struct BerryJournalView: View {
    @ObservedObject var session: BerryGameSession
    @ObservedObject private var progress = BerryProgression.shared
    @AppStorage("berryblockblast.lifetime-lines") private var lifetimeLines = 0
    @AppStorage("berryblockblast.story.level") private var storyLevel = 1
    @Environment(\.dismiss) private var dismiss
    private var chapters: Int { max(0, storyLevel - 1) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 13) {
                    Image("BerryJournalArt").resizable().scaledToFit()
                        .frame(height: 118).accessibilityHidden(true)
                    Text("Berry Journal")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Text("A scrapbook of everything you've grown and earned.")
                        .font(.subheadline).foregroundStyle(BerryStyle.chocolate)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                        GridItem(.flexible(), spacing: 11)], spacing: 11) {
                        BerryGridInfoTile(title: "Story Chapters", detail: "Completed chapters",
                                         art: "BerryStory", value: "\(chapters)")
                        BerryGridInfoTile(title: "Strawberry Village",
                                         detail: "Five village locations",
                                         art: "BerryVillageMap",
                                         value: "Level \(progress.villageLevel)/5")
                        BerryGridInfoTile(title: "Sweet Harvest", detail: "Lifetime cleared lines",
                                         art: "HarvestReward", value: "\(lifetimeLines)")
                        BerryGridInfoTile(title: "Daily Harvest",
                                         detail: "Daily challenges completed",
                                         art: "DailyHarvest",
                                         value: "\(BerryDailyHistory.completed.count)")
                        BerryGridInfoTile(title: "Quest Rewards", detail: "Claimed berry quests",
                                         art: "BerryQuestBoardArt", value: "\(progress.claimedTotal)")
                        BerryGridInfoTile(title: "Berry Collection", detail: "Cosmetics owned",
                                         art: "BerryCollection", value: "\(session.ownedCosmetics.count)")
                        BerryGridInfoTile(title: "My Cottage", detail: "Decorations collected",
                                         art: "CottageDecorations",
                                         value: "\(session.cottageDecorations)/6")
                        BerryGridInfoTile(title: "Strawberries Earned",
                                         detail: "Lifetime harvest",
                                         art: "HarvestReward",
                                         value: BerryNumbers.compact(session.totalEarnedBerries))
                    }
                }
                .padding(17)
            }
            .background(BerryStyle.cream.ignoresSafeArea())
            .navigationTitle("Berry Journal")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
