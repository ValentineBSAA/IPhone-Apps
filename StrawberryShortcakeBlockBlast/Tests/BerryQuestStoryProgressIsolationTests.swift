import Foundation
import XCTest
@testable import BerryBlockBlast

/// D3c uses the real progression, reward and claim handlers against injected
/// disposable preferences. It never grants real player strawberries.
@MainActor
final class BerryQuestStoryProgressIsolationTests: XCTestCase {
    private let namespace = "berryberryblast.progression.v059."

    private func suite() throws -> (name: String, store: UserDefaults) {
        let name = "com.valentinebsaa.berry.d3c.\(UUID().uuidString)"
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }

    private func testDate() throws -> Date {
        try XCTUnwrap(Calendar.current.date(from:
            DateComponents(year: 2026, month: 11, day: 20, hour: 12)))
    }

    private func shift(_ date: Date, by days: Int) throws -> Date {
        try XCTUnwrap(Calendar.current.date(byAdding: .day, value: days, to: date))
    }

    private func progress(_ store: UserDefaults, on date: Date) -> BerryProgression {
        BerryProgression(defaults: store, now: { date })
    }

    private func session(_ store: UserDefaults, on date: Date) -> BerryGameSession {
        BerryGameSession(checkoutDefaults: store,
                         checkoutLedger: BerryEconomyLedger(defaults: store),
                         now: { date })
    }

    /// Quest selection deliberately rotates only three of four every day.
    private func active(_ id: String, in store: UserDefaults)
        throws -> (date: Date, progress: BerryProgression, quest: BerryProgression.Quest) {
        let base = try testDate()
        for offset in 0..<4 {
            let date = try shift(base, by: offset)
            let tracker = progress(store, on: date)
            if let quest = tracker.quests.first(where: { $0.id == id }) {
                return (date, tracker, quest)
            }
        }
        XCTFail("No rotating daily quest \(id) found across four calendar days")
        throw NSError(domain: "BerryQuestStoryProgressIsolationTests",
                      code: 1, userInfo: nil)
    }

    func testRealQuestPlacementCountsMovesLinesAndDistinctModes() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let (date, tracker, _) = try active("modes", in: store)
        tracker.recordPlacement(mode: .endless, clearedLines: 2)
        tracker.recordPlacement(mode: .endless, clearedLines: 0)
        tracker.recordPlacement(mode: .story, clearedLines: 3)
        let key = namespace + BerryDailyHistory.dateKey(for: date) + "."
        XCTAssertEqual(store.integer(forKey: key + "moves"), 3)
        XCTAssertEqual(store.integer(forKey: key + "lines"), 5)
        XCTAssertEqual(store.integer(forKey: key + "modes"), 2)
        XCTAssertEqual(store.stringArray(forKey: key + "playedModes")?.count, 2)
        let quest = try XCTUnwrap(tracker.quests.first(where: { $0.id == "modes" }))
        XCTAssertEqual(tracker.progress(for: quest), quest.target)
        XCTAssertEqual(tracker.claimedTotal, 0)
    }

    func testRealQuestClaimRequiresFullProgressAndPaysOnlyOnceAcrossReopen() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let (date, tracker, quest) = try active("moves", in: store)
        let game = session(store, on: date)
        for _ in 0..<17 { tracker.recordPlacement(mode: .endless, clearedLines: 0) }
        XCTAssertEqual(tracker.progress(for: quest), 17)
        XCTAssertFalse(tracker.claim(quest, into: game))
        XCTAssertEqual(game.berries, 0)
        tracker.recordPlacement(mode: .endless, clearedLines: 0)
        XCTAssertEqual(tracker.progress(for: quest), 18)
        XCTAssertTrue(tracker.claim(quest, into: game))
        XCTAssertEqual(game.berries, 20)
        XCTAssertEqual(game.totalEarnedBerries, 20)
        XCTAssertEqual(tracker.claimedTotal, 1)
        XCTAssertTrue(tracker.isClaimed(quest))
        XCTAssertEqual(store.stringArray(forKey: "berryblockblast.rewards.v1")?.count, 1)
        XCTAssertFalse(tracker.claim(quest, into: game))
        let resumed = session(store, on: date)
        let resumedProgress = progress(store, on: date)
        let sameQuest = try XCTUnwrap(resumedProgress.quests.first(where: { $0.id == "moves" }))
        XCTAssertFalse(resumedProgress.claim(sameQuest, into: resumed))
        XCTAssertEqual(resumed.berries, 20)
        XCTAssertEqual(resumedProgress.claimedTotal, 1)
    }

    func testFourDayRotatingQuestSelectionIsDeterministicForVirtualDates() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let base = try testDate()
        var excluded = Set<String>()
        let available = Set(["moves", "lines", "modes", "chapters"])
        for offset in 0..<4 {
            let date = try shift(base, by: offset)
            let tracker = progress(store, on: date)
            let first = tracker.quests.map(\.id)
            let second = tracker.quests.map(\.id)
            XCTAssertEqual(first, second)
            XCTAssertEqual(Set(first).count, 3)
            XCTAssertTrue(Set(first).isSubset(of: available))
            excluded.formUnion(available.subtracting(first))
        }
        XCTAssertEqual(excluded, available)
    }

    func testStoryChapterProgressCountsEachCompletedChapterOnce() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let (date, tracker, quest) = try active("chapters", in: store)
        let key = namespace + BerryDailyHistory.dateKey(for: date) + "."
        tracker.recordStoryChapter(2)
        XCTAssertEqual(tracker.progress(for: quest), 1)
        tracker.recordStoryChapter(2)
        XCTAssertEqual(store.integer(forKey: key + "chapters"), 1)
        tracker.recordStoryChapter(3)
        XCTAssertEqual(store.integer(forKey: key + "chapters"), 2)
        XCTAssertTrue(store.bool(forKey: key + "chapter.2"))
        XCTAssertTrue(store.bool(forKey: key + "chapter.3"))
        let game = session(store, on: date)
        XCTAssertTrue(tracker.claim(quest, into: game))
        XCTAssertEqual(game.berries, 35)
        game.rewardStory(2)
        XCTAssertEqual(game.berries, 60)
        game.rewardStory(2)
        XCTAssertEqual(game.berries, 60)
        XCTAssertEqual(store.stringArray(forKey: "berryblockblast.rewards.v1")?.count, 2)
        XCTAssertEqual(store.integer(forKey: key + "chapters"), 2)
    }

    func testQuestCountsResetOnNewCalendarDayButLifetimeClaimCountPersists() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let (date, first, quest) = try active("moves", in: store)
        let game = session(store, on: date)
        for _ in 0..<quest.target { first.recordPlacement(mode: .endless, clearedLines: 0) }
        XCTAssertTrue(first.claim(quest, into: game))
        let next = try shift(date, by: 1)
        let second = progress(store, on: next)
        XCTAssertEqual(second.claimedTotal, 1)
        let nextKey = namespace + BerryDailyHistory.dateKey(for: next) + "."
        XCTAssertEqual(store.integer(forKey: nextKey + "moves"), 0)
        XCTAssertEqual(store.integer(forKey: nextKey + "lines"), 0)
        XCTAssertEqual(store.stringArray(forKey: nextKey + "playedModes"), nil)
        XCTAssertEqual(second.claimedToday, 0)
        XCTAssertEqual(first.claimedTotal, 1)
    }

    func testQuestPayoutRefusesSessionFromDifferentPreferenceStore() throws {
        let (aName, a) = try suite()
        let (bName, b) = try suite()
        defer { a.removePersistentDomain(forName: aName)
                b.removePersistentDomain(forName: bName) }
        let (date, tracker, quest) = try active("moves", in: a)
        for _ in 0..<quest.target {
            tracker.recordPlacement(mode: .endless, clearedLines: 0)
        }
        let unrelated = session(b, on: date)
        XCTAssertFalse(tracker.claim(quest, into: unrelated))
        XCTAssertEqual(unrelated.berries, 0)
        XCTAssertEqual(tracker.claimedTotal, 0)
        XCTAssertFalse(tracker.isClaimed(quest))
        let correct = session(a, on: date)
        XCTAssertTrue(tracker.claim(quest, into: correct))
        XCTAssertEqual(correct.berries, 20)
        XCTAssertEqual(unrelated.berries, 0)
        XCTAssertNil(b.stringArray(forKey: "berryblockblast.rewards.v1"))
    }

    func testVillageLevelReadsInjectedStoryAndDailyHistoryAndCapsAtFive() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let tracker = progress(store, on: try testDate())
        XCTAssertEqual(tracker.villageLevel, 1)
        store.set(3, forKey: "berryblockblast.story.level")
        XCTAssertEqual(tracker.villageLevel, 2)
        let completed = (1...14).map { String(format: "2026-11-%02d", $0) }
        store.set(completed, forKey: BerryDailyHistory.key)
        XCTAssertEqual(tracker.villageLevel, 4)
        store.set(7, forKey: "berryblockblast.story.level")
        XCTAssertEqual(tracker.villageLevel, 5)
        XCTAssertEqual(tracker.claimedTotal, 0)
    }

    func testIsolatedQuestAndStoryRewardsNeverWriteToOwnerPreferences() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let (date, tracker, quest) = try active("moves", in: store)
        let day = BerryDailyHistory.dateKey(for: date)
        let watched = [
            "berryblockblast.inventory.v3",
            "berryblockblast.rewards.v1",
            "berryblockblast.story.level",
            "berryblockblast.award.chapter-2",
            "berryblockblast.award.quest-" + day + "-moves",
            namespace + "claimed.total",
            namespace + day + ".moves",
            namespace + day + ".claimed.moves",
            namespace + day + ".chapters",
            "berryblockblast.daily.history.v057"
        ] + [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let before = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        let game = session(store, on: date)
        for _ in 0..<quest.target { tracker.recordPlacement(mode: .endless, clearedLines: 0) }
        XCTAssertTrue(tracker.claim(quest, into: game))
        tracker.recordStoryChapter(2)
        game.rewardStory(2)
        XCTAssertEqual(game.berries, 45)
        let after = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        XCTAssertEqual(before, after)
    }
}
