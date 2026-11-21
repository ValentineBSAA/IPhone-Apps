import Foundation
import XCTest
@testable import BerryBlockBlast

/// Production birthday validation and real once-only GameSession rewards
/// against disposable UserDefaults, not a fake wallet or phone clock.
@MainActor
final class BerryBirthdayPolicyIsolationTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "America/Phoenix")!
        return value
    }

    private func date(_ year: Int, _ month: Int, _ day: Int,
                      hour: Int = 12, minute: Int = 0) throws -> Date {
        try XCTUnwrap(calendar.date(from:
            DateComponents(year: year, month: month, day: day,
                           hour: hour, minute: minute)))
    }

    private func suite() throws -> (name: String, defaults: UserDefaults) {
        let name = "com.valentinebsaa.berry.d3e.\(UUID().uuidString)"
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }

    private func session(_ defaults: UserDefaults) -> BerryGameSession {
        BerryGameSession(checkoutDefaults: defaults,
                         checkoutLedger: BerryEconomyLedger(defaults: defaults))
    }

    private func claim(_ month: Int, _ day: Int, _ date: Date,
                       game: BerryGameSession,
                       store: UserDefaults) -> Bool {
        BerryBirthdayPolicy.claim(month: month, day: day, on: date,
                                  session: game, defaults: store,
                                  calendar: calendar)
    }

    func testDayPickerUsesCorrectMonthLengthsAndDoesNotDiscardLeapDay() {
        XCTAssertEqual(BerryBirthdayPolicy.maximumDay(month: 1), 31)
        XCTAssertEqual(BerryBirthdayPolicy.maximumDay(month: 2), 29)
        XCTAssertEqual(BerryBirthdayPolicy.maximumDay(month: 4), 30)
        XCTAssertEqual(BerryBirthdayPolicy.maximumDay(month: 11), 30)
        XCTAssertEqual(BerryBirthdayPolicy.maximumDay(month: 12), 31)
        XCTAssertTrue(BerryBirthdayPolicy.isValid(month: 2, day: 29))
        XCTAssertFalse(BerryBirthdayPolicy.isValid(month: 2, day: 30))
        XCTAssertFalse(BerryBirthdayPolicy.isValid(month: 4, day: 31))
        XCTAssertFalse(BerryBirthdayPolicy.isValid(month: 13, day: 1))
        XCTAssertFalse(BerryBirthdayPolicy.isValid(month: 0, day: 20))
        XCTAssertFalse(BerryBirthdayPolicy.isValid(month: 11, day: 0))
    }

    func testUnsetBirthdayNeverShowsGiftOrChangesWallet() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let now = try date(2026, 11, 20)
        let game = session(store)
        XCTAssertFalse(BerryBirthdayPolicy.isBirthday(month: 0, day: 20,
                                                       on: now, calendar: calendar))
        XCTAssertFalse(claim(0, 20, now, game: game, store: store))
        XCTAssertFalse(claim(11, 0, now, game: game, store: store))
        XCTAssertEqual(game.berries, 0)
        XCTAssertNil(store.stringArray(forKey: "berryblockblast.rewards.v1"))
        XCTAssertFalse(store.bool(forKey: BerryBirthdayPolicy.awardKey(
            on: now, calendar: calendar)))
    }

    func testImpossibleSavedDatesCannotTriggerAnnualGift() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let now = try date(2026, 4, 30)
        let game = session(store)
        store.set(4, forKey: BerryBirthdayPolicy.monthKey)
        store.set(31, forKey: BerryBirthdayPolicy.dayKey)
        XCTAssertFalse(claim(4, 31, now, game: game, store: store))
        XCTAssertFalse(claim(2, 30, now, game: game, store: store))
        XCTAssertEqual(store.integer(forKey: BerryBirthdayPolicy.monthKey), 4)
        XCTAssertEqual(store.integer(forKey: BerryBirthdayPolicy.dayKey), 31)
        XCTAssertEqual(game.berries, 0)
        XCTAssertNil(store.stringArray(forKey: "berryblockblast.rewards.v1"))
    }

    func testOriginalHundredBerryGiftPaysExactlyOnceAndReopens() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let now = try date(2026, 11, 20)
        let game = session(store)
        XCTAssertTrue(claim(11, 20, now, game: game, store: store))
        XCTAssertEqual(game.berries, 100)
        XCTAssertEqual(game.totalEarnedBerries, 100)
        XCTAssertTrue(BerryBirthdayPolicy.hasClaimed(on: now, defaults: store,
                                                     calendar: calendar))
        XCTAssertEqual(store.stringArray(forKey: "berryblockblast.rewards.v1")?.count, 1)
        XCTAssertTrue(store.stringArray(forKey: "berryblockblast.rewards.v1")?.first?
                      .contains("Birthday Berry Bash") == true)
        let reopened = session(store)
        XCTAssertEqual(reopened.berries, 100)
        XCTAssertFalse(claim(11, 20, now, game: reopened, store: store))
        XCTAssertEqual(reopened.berries, 100)
        XCTAssertEqual(store.stringArray(forKey: "berryblockblast.rewards.v1")?.count, 1)
    }

    func testOnlyExactBirthdayCanClaimEvenIfStoredBirthdayWasChanged() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let dayBefore = try date(2026, 11, 19, hour: 23, minute: 59)
        let giftDay = try date(2026, 11, 20, hour: 0)
        let dayAfter = try date(2026, 11, 21, hour: 0)
        let game = session(store)
        XCTAssertFalse(claim(11, 20, dayBefore, game: game, store: store))
        XCTAssertFalse(claim(11, 20, dayAfter, game: game, store: store))
        XCTAssertTrue(claim(11, 20, giftDay, game: game, store: store))
        XCTAssertEqual(game.berries, 100)
        XCTAssertFalse(claim(10, 20, giftDay, game: game, store: store))
        XCTAssertFalse(claim(11, 20, giftDay, game: game, store: store))
        XCTAssertEqual(game.berries, 100)
    }

    func testNextCalendarYearUsesOriginalDistinctAnnualAwardKey() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let thisYear = try date(2026, 11, 20)
        let nextYear = try date(2027, 11, 20)
        let first = session(store)
        XCTAssertTrue(claim(11, 20, thisYear, game: first, store: store))
        let second = session(store)
        XCTAssertTrue(claim(11, 20, nextYear, game: second, store: store))
        XCTAssertEqual(second.berries, 200)
        XCTAssertEqual(second.totalEarnedBerries, 200)
        XCTAssertNotEqual(BerryBirthdayPolicy.awardKey(on: thisYear, calendar: calendar),
                          BerryBirthdayPolicy.awardKey(on: nextYear, calendar: calendar))
        XCTAssertTrue(BerryBirthdayPolicy.hasClaimed(on: thisYear, defaults: store,
                                                     calendar: calendar))
        XCTAssertTrue(BerryBirthdayPolicy.hasClaimed(on: nextYear, defaults: store,
                                                     calendar: calendar))
        XCTAssertEqual(store.stringArray(forKey: "berryblockblast.rewards.v1")?.count, 2)
    }

    func testFebruaryTwentyNinthCelebratesOnlyInExistingLeapYear() throws {
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        let nonLeapFeb28 = try date(2027, 2, 28)
        let nonLeapMar1 = try date(2027, 3, 1)
        let leapDay = try date(2028, 2, 29)
        XCTAssertFalse(BerryBirthdayPolicy.isBirthday(month: 2, day: 29,
                         on: nonLeapFeb28, calendar: calendar))
        XCTAssertFalse(BerryBirthdayPolicy.isBirthday(month: 2, day: 29,
                         on: nonLeapMar1, calendar: calendar))
        XCTAssertTrue(BerryBirthdayPolicy.isBirthday(month: 2, day: 29,
                        on: leapDay, calendar: calendar))
        let game = session(store)
        XCTAssertFalse(claim(2, 29, nonLeapFeb28, game: game, store: store))
        XCTAssertFalse(claim(2, 29, nonLeapMar1, game: game, store: store))
        XCTAssertTrue(claim(2, 29, leapDay, game: game, store: store))
        XCTAssertEqual(game.berries, 100)
    }

    func testWrongPreferencesWalletCannotReceiveBirthdayReward() throws {
        let (leftName, left) = try suite()
        let (rightName, right) = try suite()
        defer { left.removePersistentDomain(forName: leftName)
                right.removePersistentDomain(forName: rightName) }
        let today = try date(2026, 11, 20)
        let differentWallet = session(right)
        XCTAssertFalse(claim(11, 20, today, game: differentWallet, store: left))
        XCTAssertEqual(differentWallet.berries, 0)
        XCTAssertFalse(left.bool(forKey: BerryBirthdayPolicy.awardKey(
            on: today, calendar: calendar)))
        let matching = session(left)
        XCTAssertTrue(claim(11, 20, today, game: matching, store: left))
        XCTAssertEqual(matching.berries, 100)
        XCTAssertEqual(differentWallet.berries, 0)
        XCTAssertNil(right.stringArray(forKey: "berryblockblast.rewards.v1"))
    }

    func testTemporaryBirthdayRewardsDoNotModifyActualPlayerPreferences() throws {
        let watched = [
            BerryBirthdayPolicy.monthKey,
            BerryBirthdayPolicy.dayKey,
            "berryblockblast.inventory.v3",
            "berryblockblast.rewards.v1",
            "berryblockblast.story.level",
            "berryblockblast.award.birthday-2026",
            "berryblockblast.award.birthday-2027",
            "berryblockblast.award.birthday-2028"
        ] + [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        let before = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        let (name, store) = try suite()
        defer { store.removePersistentDomain(forName: name) }
        store.set(11, forKey: BerryBirthdayPolicy.monthKey)
        store.set(20, forKey: BerryBirthdayPolicy.dayKey)
        let today = try date(2026, 11, 20)
        let game = session(store)
        XCTAssertTrue(claim(11, 20, today, game: game, store: store))
        XCTAssertEqual(store.integer(forKey: BerryBirthdayPolicy.monthKey), 11)
        XCTAssertEqual(store.integer(forKey: BerryBirthdayPolicy.dayKey), 20)
        _ = session(store)
        let after = watched.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        XCTAssertEqual(before, after)
    }
}
