import Foundation

#if BERRY_INTERNAL_QA
/// D3d: tap-to-test real quest, Story and Village logic using disposable data.
/// It never receives or alters the owner's active GameSession.
enum BerryQAQuestStoryScenario: String, CaseIterable, Identifiable {
    case moves = "18-Move Quest"
    case chapters = "Story Chapter & Claim"
    case rotation = "Four-Day Quest Rotation"
    case village = "Village Unlock Levels"
    case wrongWallet = "Wrong Wallet Protection"

    var id: String { rawValue }
    var explanation: String {
        switch self {
        case .moves: return "Complete the real 18-move quest and reopen the saved reward."
        case .chapters: return "Complete a chapter and claim the original Story Keeper reward once."
        case .rotation: return "Preview each day's actual three-of-four quests without changing device time."
        case .village: return "Verify Village unlocks from simulated chapter and Daily history."
        case .wrongWallet: return "Ensure a temporary quest cannot award berries into a different wallet."
        }
    }
    var expected: String {
        switch self {
        case .moves: return "Exactly 20 test berries; one claim and one receipt after reopen."
        case .chapters: return "35 quest berries + 25 chapter berries; chapter counted once."
        case .rotation: return "Three distinct quests per day; all four rotate out in four days."
        case .village: return "Village levels 1 → 2 → 4 → 5 at original thresholds."
        case .wrongWallet: return "Wrong wallet rejected; only matching isolated session gets 20."
        }
    }
}

struct BerryQAQuestStoryReceipt: Equatable {
    let scenario: BerryQAQuestStoryScenario
    let passed: Bool
    let expected: String
    let actual: String
    let playerDataUnchanged: Bool
}

@MainActor
struct BerryDeveloperQuestStoryLab {
    private(set) var selected: BerryQAQuestStoryScenario = .moves
    private(set) var latest: BerryQAQuestStoryReceipt?

    mutating func prepare(_ choice: BerryQAQuestStoryScenario) {
        selected = choice
        latest = nil
    }
    mutating func reset() {
        selected = .moves
        latest = nil
    }

    private func quest(_ id: String, in store: UserDefaults)
        -> (date: Date, tracker: BerryProgression, quest: BerryProgression.Quest)? {
        guard let start = Calendar.current.date(from:
            DateComponents(year: 2026, month: 11, day: 20, hour: 12)) else { return nil }
        for offset in 0..<4 {
            guard let day = Calendar.current.date(byAdding: .day, value: offset,
                                                  to: start) else { continue }
            let tracker = BerryProgression(defaults: store, now: { day })
            if let match = tracker.quests.first(where: { $0.id == id }) {
                return (day, tracker, match)
            }
        }
        return nil
    }

    private func game(_ store: UserDefaults, date: Date) -> BerryGameSession {
        BerryGameSession(checkoutDefaults: store,
                         checkoutLedger: BerryEconomyLedger(defaults: store),
                         now: { date })
    }

    @discardableResult
    mutating func run() -> BerryQAQuestStoryReceipt {
        let choice = selected
        let startName = "com.valentinebsaa.berry.d3d.\(UUID().uuidString)"
        guard let store = UserDefaults(suiteName: startName) else {
            let failure = BerryQAQuestStoryReceipt(
                scenario: choice, passed: false, expected: choice.expected,
                actual: "Unable to create temporary test preferences.",
                playerDataUnchanged: true)
            latest = failure
            return failure
        }
        defer { store.removePersistentDomain(forName: startName) }

        let watched = [
            "berryblockblast.inventory.v3", "berryblockblast.rewards.v1",
            "berryblockblast.story.level", "berryblockblast.daily.history.v057",
            "berryblockblast.daily.completed",
            "berryberryblast.progression.v059.claimed.total",
            "berryblockblast.award.chapter-2",
            "berryblockblast.award.quest-2026-11-20-moves",
            "berryberryblast.progression.v059.2026-11-20.moves",
            "berryberryblast.progression.v059.2026-11-20.chapters"
        ] + [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let original = watched.map {
            UserDefaults.standard.object(forKey: $0) as? NSObject
        }
        var passed = false
        var actual = ""

        switch choice {
        case .moves:
            if let fixture = quest("moves", in: store) {
                let session = game(store, date: fixture.date)
                for _ in 0..<fixture.quest.target {
                    fixture.tracker.recordPlacement(mode: .endless, clearedLines: 0)
                }
                let first = fixture.tracker.claim(fixture.quest, into: session)
                let second = fixture.tracker.claim(fixture.quest, into: session)
                let reopened = game(store, date: fixture.date)
                let receiptCount = store.stringArray(
                    forKey: "berryblockblast.rewards.v1")?.count ?? 0
                passed = first && !second &&
                         reopened.berries == 20 &&
                         fixture.tracker.claimedTotal == 1 &&
                         receiptCount == 1
                actual = "First claim \(first); second refused \(!second); " +
                         "restart wallet \(reopened.berries); receipts \(receiptCount)."
            } else {
                actual = "No active Garden Gardener quest in four virtual days."
            }

        case .chapters:
            if let fixture = quest("chapters", in: store) {
                let session = game(store, date: fixture.date)
                fixture.tracker.recordStoryChapter(2)
                fixture.tracker.recordStoryChapter(2)
                let count = fixture.tracker.progress(for: fixture.quest)
                let questClaimed = fixture.tracker.claim(fixture.quest, into: session)
                session.rewardStory(2)
                session.rewardStory(2)
                let reopened = game(store, date: fixture.date)
                let receiptCount = store.stringArray(
                    forKey: "berryblockblast.rewards.v1")?.count ?? 0
                passed = count == 1 && questClaimed &&
                         reopened.berries == 60 &&
                         fixture.tracker.claimedTotal == 1 &&
                         receiptCount == 2
                actual = "Chapter progress \(count); quest \(questClaimed); " +
                         "restart wallet \(reopened.berries); receipts \(receiptCount)."
            } else {
                actual = "No active Story Keeper quest in four virtual days."
            }

        case .rotation:
            if let start = Calendar.current.date(from:
                DateComponents(year: 2026, month: 11, day: 20, hour: 12)) {
                let all = Set(["lines", "modes", "moves", "chapters"])
                var exclusions = Set<String>()
                var dailyValid = true
                for offset in 0..<4 {
                    guard let date = Calendar.current.date(
                        byAdding: .day, value: offset, to: start) else {
                        dailyValid = false
                        continue
                    }
                    let tracker = BerryProgression(defaults: store, now: { date })
                    let ids = Set(tracker.quests.map(\.id))
                    dailyValid = dailyValid && ids.count == 3 &&
                                 ids.isSubset(of: all)
                    exclusions.formUnion(all.subtracting(ids))
                }
                passed = dailyValid && exclusions == all
                actual = "Each day three unique \(dailyValid); " +
                         "all four excluded once \(exclusions == all)."
            } else {
                actual = "Unable to create virtual local date."
            }

        case .village:
            if let day = Calendar.current.date(from:
                DateComponents(year: 2026, month: 11, day: 20, hour: 12)) {
                let tracker = BerryProgression(defaults: store, now: { day })
                let first = tracker.villageLevel
                store.set(3, forKey: "berryblockblast.story.level")
                let second = tracker.villageLevel
                let wins = (1...14).map {
                    String(format: "2026-11-%02d", $0)
                }
                store.set(wins, forKey: BerryDailyHistory.key)
                let third = tracker.villageLevel
                store.set(7, forKey: "berryblockblast.story.level")
                let fourth = tracker.villageLevel
                passed = [first, second, third, fourth] == [1, 2, 4, 5]
                actual = "Village progression \(first) → \(second) → " +
                         "\(third) → \(fourth)."
            } else {
                actual = "Unable to create virtual local date."
            }

        case .wrongWallet:
            let foreignName = "com.valentinebsaa.berry.d3d.other.\(UUID().uuidString)"
            if let other = UserDefaults(suiteName: foreignName),
               let fixture = quest("moves", in: store) {
                defer { other.removePersistentDomain(forName: foreignName) }
                for _ in 0..<fixture.quest.target {
                    fixture.tracker.recordPlacement(mode: .endless, clearedLines: 0)
                }
                let wrongSession = game(other, date: fixture.date)
                let wrong = fixture.tracker.claim(fixture.quest,
                                                  into: wrongSession)
                let realTestSession = game(store, date: fixture.date)
                let correct = fixture.tracker.claim(fixture.quest,
                                                    into: realTestSession)
                passed = !wrong && correct &&
                         wrongSession.berries == 0 &&
                         realTestSession.berries == 20 &&
                         fixture.tracker.claimedTotal == 1 &&
                         other.stringArray(
                            forKey: "berryblockblast.rewards.v1") == nil
                actual = "Wrong wallet refused \(!wrong); matching paid " +
                         "\(correct); other wallet \(wrongSession.berries)."
            } else {
                actual = "Unable to create independent second test wallet."
            }
        }

        let current = watched.map {
            UserDefaults.standard.object(forKey: $0) as? NSObject
        }
        let playerSafe = original == current
        if !playerSafe {
            passed = false
            actual += " WARNING: live player preferences changed."
        }
        let receipt = BerryQAQuestStoryReceipt(
            scenario: choice, passed: passed, expected: choice.expected,
            actual: actual, playerDataUnchanged: playerSafe)
        latest = receipt
        return receipt
    }
}
#endif
