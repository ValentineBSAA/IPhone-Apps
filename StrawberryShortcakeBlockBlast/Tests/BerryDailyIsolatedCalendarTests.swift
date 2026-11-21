import Foundation
import XCTest
@testable import BerryBlockBlast

/// D3a: true DailyGameSession with injected local calendar time and disposable
/// UserDefaults. No phone clock changes, no owner's Daily streak or reward use.
@MainActor
final class BerryDailyIsolatedCalendarTests: XCTestCase {
    private let attemptKey = "berryberryblast.daily.attempt.v0510"
    private let outcomesKey = "berryberryblast.daily.outcomes.v0510"

    private func testDate() throws -> Date {
        try XCTUnwrap(Calendar.current.date(from:
            DateComponents(year: 2026, month: 11, day: 20, hour: 12)))
    }

    private func suite() throws -> (name: String, store: UserDefaults) {
        let name = "com.valentinebsaa.berry.d3a.\(UUID().uuidString)"
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }

    private func open(_ store: UserDefaults, on date: Date) -> BerryGameSession {
        let game = BerryGameSession(
            checkoutDefaults: store,
            checkoutLedger: BerryEconomyLedger(defaults: store),
            now: { date })
        game.selectMode(.daily)
        return game
    }

    private func canonical(_ game: BerryGameSession) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(game.engine)
    }

    func testFirstEntryConsumesExactlyOneActualDailyAttemptBeforeAnyMoves() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let today = try testDate()
        XCTAssertNil(BerryDailyHistory.outcome(on: today, defaults: store))
        let game = open(store, on: today)
        XCTAssertFalse(game.gameOver)
        XCTAssertEqual(game.engine.moves, 0)
        XCTAssertEqual(BerryDailyHistory.outcome(on: today, defaults: store), .active)
        XCTAssertNotNil(store.data(forKey: attemptKey))
        XCTAssertNotNil(BerryDailyHistory.activeEngine(defaults: store, now: today))
        XCTAssertTrue(BerryDailyHistory.beginToday(defaults: store, now: today))
        XCTAssertEqual(BerryDailyHistory.outcome(on: today, defaults: store), .active)
    }

    func testSameDaySecondSessionResumesExactDailyBoardWithoutNewAttempt() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let today = try testDate()
        let first = open(store, on: today)
        let original = try canonical(first)
        let restored = open(store, on: today)
        XCTAssertEqual(try canonical(restored), original)
        XCTAssertFalse(restored.gameOver)
        XCTAssertEqual(BerryDailyHistory.outcome(on: today, defaults: store), .active)
        XCTAssertEqual((store.dictionary(forKey: outcomesKey) as? [String: String])?[
            BerryDailyHistory.dateKey(for: today)], "active")
    }

    func testRealDailyPlacementSavesReopensAndDoesNotUseOwnerQuestProgress() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let today = try testDate()
        let watched = [
            "berryblockblast.daily.best-score.v055",
            "berryblockblast.daily.completed",
            "berryblockblast.daily.history.v057",
            "berryberryblast.daily.attempt.v0510",
            "berryberryblast.daily.outcomes.v0510",
            "berryblockblast.inventory.v3",
            "berryberryblast.progression.v059." +
                BerryDailyHistory.dateKey(for: today) + ".moves"
        ]
        let realBefore = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        let game = open(store, on: today)
        let hint = try XCTUnwrap(game.engine.suggestedMove())
        XCTAssertTrue(game.drop(slot: hint.slot, row: hint.row, col: hint.col))
        XCTAssertEqual(game.engine.moves, 1)
        XCTAssertFalse(game.gameOver)
        let saved = BerryDailyHistory.activeEngine(defaults: store, now: today)
        XCTAssertEqual(saved?.moves, 1)
        XCTAssertEqual(saved?.score, game.engine.score)
        let reopened = open(store, on: today)
        XCTAssertEqual(try canonical(reopened), try canonical(game))
        XCTAssertEqual(reopened.bestScore, game.bestScore)
        XCTAssertEqual(reopened.engine.moves, 1)
        let realAfter = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        XCTAssertEqual(realBefore, realAfter)
    }

    func testLostDailyAttemptCannotBeRestartedOrRepaidSameDate() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let today = try testDate()
        _ = open(store, on: today)
        BerryDailyHistory.markLostToday(defaults: store, now: today)
        XCTAssertEqual(BerryDailyHistory.outcome(on: today, defaults: store), .lost)
        let lossSnapshot = try XCTUnwrap(store.data(forKey: attemptKey))
        let denied = open(store, on: today)
        XCTAssertTrue(denied.gameOver)
        XCTAssertTrue(denied.lastMessage?.contains("finished") == true)
        XCTAssertEqual(store.data(forKey: attemptKey), lossSnapshot)
        XCTAssertFalse(BerryDailyHistory.beginToday(defaults: store, now: today))
    }

    func testLocalMidnightExpiresYesterdayAndAllowsNextDailyOnce() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let day1 = try testDate()
        let day2 = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: day1))
        _ = open(store, on: day1)
        XCTAssertEqual(BerryDailyHistory.outcome(on: day1, defaults: store), .active)
        let next = open(store, on: day2)
        XCTAssertFalse(next.gameOver)
        XCTAssertEqual(BerryDailyHistory.outcome(on: day1, defaults: store), .lost)
        XCTAssertEqual(BerryDailyHistory.outcome(on: day2, defaults: store), .active)
        let outcomes = try XCTUnwrap(store.dictionary(forKey: outcomesKey) as? [String:String])
        XCTAssertEqual(outcomes[BerryDailyHistory.dateKey(for: day1)], "lost")
        XCTAssertEqual(outcomes[BerryDailyHistory.dateKey(for: day2)], "active")
        XCTAssertTrue(BerryDailyHistory.beginToday(defaults: store, now: day2))
    }

    func testLegacyCompletedDailyBlocksNewAttemptWithoutDeletingLegacy() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let today = try testDate()
        let old = BerryDailyHistory.dateKey(for: today)
        store.set(old, forKey: "berryblockblast.daily.completed")
        XCTAssertEqual(BerryDailyHistory.outcome(on: today, defaults: store), .won)
        let game = open(store, on: today)
        XCTAssertTrue(game.gameOver)
        XCTAssertEqual(store.string(forKey: "berryblockblast.daily.completed"), old)
        XCTAssertNil(store.data(forKey: attemptKey))
        XCTAssertFalse(BerryDailyHistory.beginToday(defaults: store, now: today))
    }

    func testCorruptedActiveAttemptDoesNotIssueAnotherDailyHand() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let today = try testDate()
        let day = BerryDailyHistory.dateKey(for: today)
        let corrupt = Data([0xF0, 0xE2, 0x00])
        store.set(corrupt, forKey: attemptKey)
        store.set([day: "active"], forKey: outcomesKey)
        XCTAssertFalse(BerryDailyHistory.beginToday(defaults: store, now: today))
        let game = open(store, on: today)
        XCTAssertTrue(game.gameOver)
        XCTAssertEqual(store.data(forKey: attemptKey), corrupt)
        XCTAssertEqual((store.dictionary(forKey: outcomesKey) as? [String:String])?[day],
                       "active")
        XCTAssertNil(BerryDailyHistory.activeEngine(defaults: store, now: today))
    }

    func testTwoTemporarySuitesHaveIndependentDailyAttemptsAndLeaveOwnerUntouched() throws {
        let (an, a) = try suite()
        let (bn, b) = try suite()
        defer { a.removePersistentDomain(forName: an);
                b.removePersistentDomain(forName: bn) }
        let today = try testDate()
        let watched = [attemptKey, outcomesKey,
                       "berryblockblast.daily.completed",
                       "berryblockblast.daily.history.v057",
                       "berryblockblast.daily.best-score.v055"]
        let before = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        _ = open(a, on: today)
        BerryDailyHistory.markLostToday(defaults: a, now: today)
        let bGame = open(b, on: today)
        XCTAssertFalse(bGame.gameOver)
        XCTAssertEqual(BerryDailyHistory.outcome(on: today, defaults: a), .lost)
        XCTAssertEqual(BerryDailyHistory.outcome(on: today, defaults: b), .active)
        XCTAssertNotEqual(a.data(forKey: attemptKey), b.data(forKey: attemptKey))
        let after = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        XCTAssertEqual(before, after)
    }
}
