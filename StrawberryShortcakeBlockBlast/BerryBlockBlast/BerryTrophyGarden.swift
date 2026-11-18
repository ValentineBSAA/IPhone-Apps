import SwiftUI

/// Source of truth for permanent, *cosmetic-only* collectible block awards.
/// No score, RNG, move legality or real-money transaction depends on a trophy.
enum BerryTrophyCatalog {
    struct Reward: Identifiable {
        let id: String
        let title: String
        let artwork: String
        let condition: String
        let tintIndex: Int
        let requiredLines: Int
    }

    static let rewards: [Reward] = [
        .init(id: "strawberry-red", title: "Strawberry Red", artwork: "BerryRewardStrawberryRed",
              condition: "Clear 10 lifetime lines. Original unlock carries over.", tintIndex: 0, requiredLines: 10),
        .init(id: "golden-honey", title: "Golden Honey", artwork: "BerryRewardGoldenHoney",
              condition: "Clear 100 lifetime lines.", tintIndex: 2, requiredLines: 100),
        .init(id: "blueberry-sparkle", title: "Blueberry Sparkle", artwork: "BerryRewardBlueberrySparkle",
              condition: "Clear 250 lifetime lines.", tintIndex: 3, requiredLines: 250),
        .init(id: "mint-leaf-jelly", title: "Mint Leaf Jelly", artwork: "BerryRewardMintLeafJelly",
              condition: "Clear 450 lifetime lines.", tintIndex: 5, requiredLines: 450),
        .init(id: "raspberry-bloom", title: "Raspberry Bloom", artwork: "BerryRewardRaspberryBloom",
              condition: "Clear 700 lifetime lines.", tintIndex: 0, requiredLines: 700),
        .init(id: "peach-fizz", title: "Peach Fizz", artwork: "BerryRewardPeachFizz",
              condition: "Clear 1,000 lifetime lines.", tintIndex: 2, requiredLines: 1000),
        .init(id: "lavender-dream", title: "Lavender Dream", artwork: "BerryRewardLavenderDream",
              condition: "Clear 1,400 lifetime lines.", tintIndex: 4, requiredLines: 1400),
        .init(id: "coconut-cream", title: "Coconut Cream", artwork: "BerryRewardCoconutCream",
              condition: "Clear 2,000 lifetime lines.", tintIndex: 1, requiredLines: 2000),
        .init(id: "royal-berry", title: "Royal Berry", artwork: "BerryRewardRoyalBerry",
              condition: "Clear 2,500 lifetime lines AND finish Berry Story Chapter 5.", tintIndex: 4, requiredLines: 2500),
        .init(id: "moonberry-nightmare", title: "Moonberry Nightmare", artwork: "BerryRewardMoonberryNightmare",
              condition: "Survive five 3-minute Nightmare runs AND clear 12 lines within a single run.", tintIndex: 4, requiredLines: 0)
    ]

    static let nightmareSurvivalsKey = "berryberryblast.trophies.nightmare-survivals.v0512"
    static let nightmareBestLinesKey = "berryberryblast.trophies.nightmare-best-lines.v0512"
    static let legacyStrawberryKey = "berryblockblast.strawberry-unlocked"
    static let lifetimeLinesKey = "berryblockblast.lifetime-lines"
    static let equippedSkinKey = "berryblockblast.shop.equippedBlockSkin.v056b2"
    static let strawberryEnabledKey = "berryberryblast.trophies.strawberry-red-on.v0512"

    static func unlocked(_ reward: Reward, lifetimeLines: Int, chapter: Int, survivals: Int, nightmareBest: Int, legacy: Bool) -> Bool {
        switch reward.id {
        case "strawberry-red":
            return legacy || lifetimeLines >= 10
        case "royal-berry":
            return lifetimeLines >= 2500 && chapter >= 6
        case "moonberry-nightmare":
            return survivals >= 5 && nightmareBest >= 12
        default:
            return lifetimeLines >= reward.requiredLines
        }
    }

    static func reward(for skin: String) -> Reward? {
        guard skin.hasPrefix("reward-") else { return nil }
        return rewards.first(where: { "reward-" + $0.id == skin })
    }

    static func earnedKey(_ id: String) -> String {
        "berryberryblast.trophies.earned." + id + ".v0512"
    }

    static func permanentlyEarned(_ reward: Reward) -> Bool {
        UserDefaults.standard.bool(forKey: earnedKey(reward.id)) ||
        (reward.id == "strawberry-red" &&
         UserDefaults.standard.bool(forKey: legacyStrawberryKey))
    }

    static func recordPermanentUnlock(_ reward: Reward) {
        // One-way entitlement: Undo never revokes a collectible and
        // repeating an already achieved challenge never earns a second one.
        UserDefaults.standard.set(true, forKey: earnedKey(reward.id))
    }

    static func migrateAlreadyEarned() {
        for reward in rewards where isEarned(reward) {
            recordPermanentUnlock(reward)
        }
    }

    static func isEarned(_ reward: Reward) -> Bool {
        if permanentlyEarned(reward) { return true }
        let data = UserDefaults.standard
        return unlocked(reward,
                        lifetimeLines: data.integer(forKey: lifetimeLinesKey),
                        chapter: max(1, data.integer(forKey: "berryblockblast.story.level")),
                        survivals: data.integer(forKey: nightmareSurvivalsKey),
                        nightmareBest: data.integer(forKey: nightmareBestLinesKey),
                        legacy: data.bool(forKey: legacyStrawberryKey))
    }

    static func enabledArt(skin: String, tint: Int, legacyStrawberry: Bool, strawberryEnabled: Bool) -> String? {
        let index = (tint % 6 + 6) % 6
        if skin == "default", legacyStrawberry, strawberryEnabled, index == 0 {
            return rewards[0].artwork
        }
        guard let reward = reward(for: skin), reward.tintIndex == index,
              isEarned(reward) else { return nil }
        return reward.artwork
    }
}

/// Collection > Strawberry Trophy Garden. Every page is an actual grid,
/// every locked condition is readable, and unlocks never interrupt a timed game.
struct BerryTrophyGardenView: View {
    @AppStorage(BerryTrophyCatalog.lifetimeLinesKey) private var lifetimeLines = 0
    @AppStorage(BerryTrophyCatalog.legacyStrawberryKey) private var legacyStrawberry = false
    @AppStorage(BerryTrophyCatalog.nightmareSurvivalsKey) private var nightmareSurvivals = 0
    @AppStorage(BerryTrophyCatalog.nightmareBestLinesKey) private var nightmareBestLines = 0
    @AppStorage("berryblockblast.story.level") private var storyChapter = 1
    @AppStorage(BerryTrophyCatalog.equippedSkinKey) private var blockSkin = "default"
    @AppStorage(BerryTrophyCatalog.strawberryEnabledKey) private var strawberryEnabled = true
    @State private var filter = 0

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    private var owned: Int {
        BerryTrophyCatalog.rewards.filter { isUnlocked($0) }.count
    }
    private func isUnlocked(_ reward: BerryTrophyCatalog.Reward) -> Bool {
        BerryTrophyCatalog.permanentlyEarned(reward) ||
        BerryTrophyCatalog.unlocked(reward, lifetimeLines: lifetimeLines, chapter: storyChapter,
                                    survivals: nightmareSurvivals, nightmareBest: nightmareBestLines,
                                    legacy: legacyStrawberry)
    }
    private func isEquipped(_ reward: BerryTrophyCatalog.Reward) -> Bool {
        reward.id == "strawberry-red"
            ? blockSkin == "default" && strawberryEnabled
            : blockSkin == "reward-" + reward.id
    }
    private func toggle(_ reward: BerryTrophyCatalog.Reward) {
        guard isUnlocked(reward) else { return }
        if reward.id == "strawberry-red" {
            let wasEquipped = isEquipped(reward)
            blockSkin = "default"
            strawberryEnabled = !wasEquipped
        } else {
            blockSkin = isEquipped(reward) ? "default" : "reward-" + reward.id
            if blockSkin == "default" { strawberryEnabled = false }
        }
    }

    var body: some View {
        VStack(spacing: 11) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 25))
                    .foregroundStyle(BerryStyle.strawberry)
                VStack(alignment: .leading) {
                    Text("Strawberry Trophy Garden")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                    Text("\(owned) / \(BerryTrophyCatalog.rewards.count) permanent block rewards")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(BerryStyle.chocolate)
            .padding(13)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))

            Text("Collect special candy block styles by playing. Unlocked rewards work across every mode. They never change your score or puzzle rules.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate)
                .multilineTextAlignment(.center)
            Picker("Trophies", selection: $filter) {
                Text("All").tag(0)
                Text("Unlocked").tag(1)
                Text("Locked").tag(2)
            }
            .pickerStyle(.segmented)

            LazyVGrid(columns: columns, spacing: 11) {
                ForEach(BerryTrophyCatalog.rewards.filter {
                    filter == 0 || (filter == 1 ? isUnlocked($0) : !isUnlocked($0))
                }) { reward in
                    card(reward)
                }
            }
            if filter != 0 && BerryTrophyCatalog.rewards.allSatisfy({ isUnlocked($0) == (filter == 2) }) {
                Text("No trophies in this category yet.")
                    .font(.footnote)
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.7))
            }
        }
        .accessibilityIdentifier("berry-trophy-garden")
        .onAppear { BerryTrophyCatalog.migrateAlreadyEarned() }
    }

    private func card(_ reward: BerryTrophyCatalog.Reward) -> some View {
        let earned = isUnlocked(reward)
        let equipped = isEquipped(reward)
        return VStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(BerryStyle.softPink)
                if UIImage(named: reward.artwork) != nil {
                    Image(reward.artwork)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(height: 90)
                        .opacity(earned ? 1 : 0.5)
                        .saturation(earned ? 1 : 0.2)
                } else {
                    Image(systemName: earned ? "seal.fill" : "lock.fill")
                        .font(.system(size: 43))
                        .foregroundStyle(BerryStyle.strawberry)
                }
                if !earned {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .black))
                        .padding(7)
                        .foregroundStyle(.white)
                        .background(BerryStyle.chocolate.opacity(0.9), in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }
            .frame(height: 105)
            Text(reward.title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text(reward.condition)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.78))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if reward.id == "moonberry-nightmare" {
                ProgressView(value: Double(min(5, nightmareSurvivals)), total: 5)
                    .tint(BerryStyle.strawberry)
                Text("Survived \(min(5, nightmareSurvivals))/5 · Best \(min(12,nightmareBestLines))/12 lines")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
            } else {
                ProgressView(value: Double(min(lifetimeLines, reward.requiredLines)),
                             total: Double(max(1, reward.requiredLines)))
                    .tint(BerryStyle.strawberry)
                Text("\(min(max(lifetimeLines, (legacyStrawberry && reward.id == "strawberry-red") ? 10 : 0), reward.requiredLines)) / \(reward.requiredLines) lines")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                if reward.id == "royal-berry" {
                    Text(storyChapter >= 6 ? "✓ Chapter 5 finished" : "🔒 Complete Story Chapter 5")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                }
            }
            Spacer(minLength: 0)
            if earned {
                Button(equipped ? "Unequip" : "Equip") { toggle(reward) }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .buttonStyle(.borderedProminent)
                    .tint(equipped ? BerryStyle.leaf : BerryStyle.strawberry)
            } else {
                Label("Locked", systemImage: "lock.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.68))
                    .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 297)
        .padding(9)
        .background(.white, in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19)
                    .strokeBorder(equipped ? BerryStyle.leaf : BerryStyle.strawberry.opacity(0.25),
                                  lineWidth: equipped ? 2 : 1))
        .accessibilityElement(children: .contain)
    }
}
