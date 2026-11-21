import Foundation
import XCTest
@testable import BerryBlockBlast

/// D3b: real History and Session's once-only reward methods against
/// disposable UserDefaults, actual BerryEconomyLedger and virtual local dates.
@MainActor
final class BerryDailyRewardIsolationTests: XCTestCase {
    private let completedKey = BerryDailyHistory.key
    private let inventoryKey = "berryblockblast.inventory.v3"

    private func suite() throws -> (name: String, store: UserDefaults) {
        let name = "com.valentinebsaa.berry.d3b.\(UUID().uuidString)"
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }
    private func day(_ number: Int = 20) throws -> Date {
        try XCTUnwrap(Calendar.current.date(from:
            DateComponents(year: 2026, month: 11, day: number, hour: 12)))
    }
    private func shifted(_ date: Date, _ offset: Int) throws -> Date {
        try XCTUnwrap(Calendar.current.date(byAdding: .day, value: offset, to: date))
    }
    private func open(_ store: UserDefaults, on date: Date,
                      mode: BerryMode? = .daily) -> BerryGameSession {
        let game = BerryGameSession(
            checkoutDefaults: store,
            checkoutLedger: BerryEconomyLedger(defaults: store),
            now: { date })
        if let mode { game.selectMode(mode) }
        return game
    }
    private func finish(_ store: UserDefaults, on date: Date) {
        XCTAssertTrue(BerryDailyHistory.beginToday(defaults: store, now: date))
        BerryDailyHistory.markCompleteToday(defaults: store, now: date)
        XCTAssertEqual(BerryDailyHistory.outcome(on: date, defaults: store), .won)
    }

    func testActualDailyCompletionIsOnceOnlyAndPreventsSameDayReentry() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let today = try day()
        let game = open(store, on: today)
        XCTAssertFalse(game.gameOver)
        BerryDailyHistory.markCompleteToday(defaults: store, now: today)
        XCTAssertEqual(BerryDailyHistory.outcome(on: today, defaults: store), .won)
        XCTAssertTrue(BerryDailyHistory.completedDays(defaults: store)
                      .contains(BerryDailyHistory.dateKey(for: today)))
        let snapshot = try XCTUnwrap(store.stringArray(forKey: completedKey))
        BerryDailyHistory.markCompleteToday(defaults: store, now: today)
        XCTAssertEqual(store.stringArray(forKey: completedKey), snapshot)
        let denied = open(store, on: today)
        XCTAssertTrue(denied.gameOver)
        XCTAssertFalse(BerryDailyHistory.beginToday(defaults: store, now: today))
    }

    func testSevenConsecutiveDailyCompletionsUseOriginal10To50RewardLadder() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let seventh = try day()
        for step in 1...6 {
            let date = try shifted(seventh, step - 7)
            XCTAssertEqual(BerryDailyHistory.nextStreakDay(on: date, defaults: store),
                           step)
            XCTAssertEqual(BerryDailyHistory.rewardToday(on: date, defaults: store),
                           BerryDailyHistory.rewardLadder[step-1])
            finish(store, on: date)
        }
        XCTAssertEqual(BerryDailyHistory.nextStreakDay(on: seventh, defaults: store), 7)
        XCTAssertEqual(BerryDailyHistory.rewardToday(on: seventh, defaults: store), 50)
        finish(store, on: seventh)
        XCTAssertEqual(BerryDailyHistory.streak(on: seventh, defaults: store), 7)
        XCTAssertEqual(BerryDailyHistory.rewardToday(on: seventh, defaults: store), 0)
    }

    func testInterruptedStreakRestartsAtDayOneWithoutRewritingOldHistory() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let date = try day()
        finish(store, on: try shifted(date, -3))
        finish(store, on: try shifted(date, -2))
        let oldHistory = store.stringArray(forKey: completedKey)
        XCTAssertEqual(BerryDailyHistory.nextStreakDay(on: date, defaults: store), 1)
        XCTAssertEqual(BerryDailyHistory.rewardToday(on: date, defaults: store), 10)
        XCTAssertEqual(BerryDailyHistory.streak(on: date, defaults: store), 0)
        XCTAssertEqual(store.stringArray(forKey: completedKey), oldHistory)
    }

    func testDailyTenBerryPayoutHasOneReceiptAndCannotPayTwiceAfterReopen() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let today = try day()
        let game = open(store, on: today)
        game.rewardDaily()
        XCTAssertEqual(game.berries, 10)
        XCTAssertEqual(game.totalEarnedBerries, 10)
        let receipt = store.stringArray(forKey: "berryblockblast.rewards.v1") ?? []
        XCTAssertEqual(receipt.count, 1)
        XCTAssertTrue(receipt[0].contains("Daily Harvest"))
        game.rewardDaily()
        XCTAssertEqual(game.berries, 10)
        let reopened = open(store, on: today)
        reopened.rewardDaily()
        XCTAssertEqual(reopened.berries, 10)
        XCTAssertEqual(store.stringArray(forKey: "berryblockblast.rewards.v1"), receipt)
        let awardKey = "berryblockblast.award.daily-" +
                       BerryDailyHistory.dateKey(for: today)
        XCTAssertTrue(store.bool(forKey: awardKey))
    }

    func testSeventhDayFiftyBerryPayoutUsesDisposableLedgerAndExactOriginalPrice() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let seventh = try day()
        for offset in (-6)...(-1) {
            finish(store, on: try shifted(seventh, offset))
        }
        let game = open(store, on: seventh)
        game.rewardDaily()
        XCTAssertEqual(game.berries, 50)
        XCTAssertEqual(game.totalEarnedBerries, 50)
        XCTAssertEqual(store.stringArray(forKey: "berryblockblast.rewards.v1")?.count, 1)
        game.rewardDaily()
        XCTAssertEqual(game.berries, 50)
        let reopened = open(store, on: seventh)
        XCTAssertEqual(reopened.berries, 50)
        BerryDailyHistory.markCompleteToday(defaults: store, now: seventh)
        reopened.rewardDaily()
        XCTAssertEqual(reopened.berries, 50)
        XCTAssertEqual(BerryDailyHistory.streak(on: seventh, defaults: store), 7)
    }

    func testLegacyAlreadyCompletedDateCannotBePaidAgain() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let today = try day()
        let dateKey = BerryDailyHistory.dateKey(for: today)
        store.set(dateKey, forKey: "berryblockblast.daily.completed")
        let game = open(store, on: today, mode: nil)
        game.rewardDaily()
        XCTAssertEqual(game.berries, 0)
        XCTAssertEqual(game.totalEarnedBerries, 0)
        XCTAssertNil(store.stringArray(forKey: "berryblockblast.rewards.v1"))
        XCTAssertEqual(BerryDailyHistory.outcome(on: today, defaults: store), .won)
    }

    func testLostDailyCannotClaimBerriesOrCarryStreakToday() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let today = try day()
        let game = open(store, on: today)
        BerryDailyHistory.markLostToday(defaults: store, now: today)
        XCTAssertEqual(BerryDailyHistory.rewardToday(on: today, defaults: store), 0)
        XCTAssertEqual(BerryDailyHistory.nextStreakDay(on: today, defaults: store), 1)
        game.rewardDaily()
        XCTAssertEqual(game.berries, 0)
        XCTAssertNil(store.stringArray(forKey: "berryblockblast.rewards.v1"))
    }

    func testStoryRewardOnceAndDailyRewardsDoNotLeakIntoPlayerOrQuestKeys() throws {
        let day = try day()
        let watched = [
            inventoryKey,
            completedKey,
            "berryblockblast.daily.completed",
            "berryberryblast.daily.attempt.v0510",
            "berryberryblast.daily.outcomes.v0510",
            "berryblockblast.rewards.v1",
            "berryblockblast.award.chapter-2",
            "berryblockblast.award.daily-" + BerryDailyHistory.dateKey(for: day),
            "berryblockblast.story.level",
            "berryberryblast.progression.v059." +
                BerryDailyHistory.dateKey(for: day) + ".chapters"
        ]
        let before = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let session = open(store, on: day, mode: nil)
        session.rewardStory(2)
        XCTAssertEqual(session.berries, 25)
        session.rewardStory(2)
        XCTAssertEqual(session.berries, 25)
        XCTAssertTrue(store.bool(forKey: "berryblockblast.award.chapter-2"))
        let daily = open(store, on: day)
        daily.rewardDaily()
        XCTAssertEqual(daily.berries, 35)
        XCTAssertEqual(store.stringArray(forKey: "berryblockblast.rewards.v1")?.count, 2)
        let after = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        XCTAssertEqual(before, after)
    }

}
