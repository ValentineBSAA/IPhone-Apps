import XCTest
@testable import BerryBlockBlast

final class BerryDailyAttemptTests: XCTestCase {
    private func isolatedDefaults() -> UserDefaults {
        let suite = "BerryDailyAttemptTests." + UUID().uuidString
        return UserDefaults(suiteName: suite)!
    }

    func testDailyAttemptBeginsOnlyOnceAndIsResumable() throws {
        let store = isolatedDefaults()
        XCTAssertNil(BerryDailyHistory.outcome(defaults: store))
        XCTAssertTrue(BerryDailyHistory.beginToday(defaults: store))
        XCTAssertEqual(BerryDailyHistory.outcome(defaults: store), .active)
        XCTAssertTrue(BerryDailyHistory.beginToday(defaults: store),
                      "Re-entering an active attempt should resume, not reset it")
        let engine = BerryEngine(seed: 123456)
        BerryDailyHistory.saveActiveEngine(engine, defaults: store)
        let saved = try XCTUnwrap(BerryDailyHistory.activeEngine(defaults: store))
        XCTAssertEqual(saved.board, engine.board)
        XCTAssertEqual(saved.score, engine.score)
    }

    func testLossLocksRestOfDayEvenAfterAnotherStart() {
        let store = isolatedDefaults()
        XCTAssertTrue(BerryDailyHistory.beginToday(defaults: store))
        BerryDailyHistory.markLostToday(defaults: store)
        XCTAssertEqual(BerryDailyHistory.outcome(defaults: store), .lost)
        XCTAssertFalse(BerryDailyHistory.beginToday(defaults: store))
        XCTAssertNil(BerryDailyHistory.activeEngine(defaults: store))
        BerryDailyHistory.markLostToday(defaults: store)
        XCTAssertEqual(BerryDailyHistory.outcome(defaults: store), .lost)
    }

    func testLegacyCompletedDailyCannotBeReplayed() {
        let store = isolatedDefaults()
        store.set(BerryDailyHistory.dateKey(for: Date()),
                  forKey: "berryblockblast.daily.completed")
        XCTAssertEqual(BerryDailyHistory.outcome(defaults: store), .won)
        XCTAssertFalse(BerryDailyHistory.beginToday(defaults: store))
    }

    func testNoSecondTryEvenIfSnapshotWasCorrupted() {
        let store = isolatedDefaults()
        XCTAssertTrue(BerryDailyHistory.beginToday(defaults: store))
        BerryDailyHistory.markLostToday(defaults: store)
        store.removeObject(forKey: "berryberryblast.daily.attempt.v0510")
        XCTAssertEqual(BerryDailyHistory.outcome(defaults: store), .lost)
        XCTAssertFalse(BerryDailyHistory.beginToday(defaults: store))
    }

    func testNewDayDoesNotInheritPreviousDayLoss() throws {
        let store = isolatedDefaults()
        let yesterday = try XCTUnwrap(Calendar.current.date(
            byAdding: .day, value: -1, to: Date()))
        var results = [String: String]()
        results[BerryDailyHistory.dateKey(for: yesterday)] = "lost"
        store.set(results, forKey: "berryberryblast.daily.outcomes.v0510")
        XCTAssertNil(BerryDailyHistory.outcome(defaults: store))
        XCTAssertTrue(BerryDailyHistory.beginToday(defaults: store))
    }
}
