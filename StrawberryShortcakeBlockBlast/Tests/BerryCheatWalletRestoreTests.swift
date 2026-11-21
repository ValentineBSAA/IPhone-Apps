import Foundation
import XCTest
@testable import BerryBlockBlast

/// Real production cheat + restore code, exercised only in disposable local
/// UserDefaults suites. NEVER awards or restores the physical owner's balance.
@MainActor
final class BerryCheatWalletRestoreTests: XCTestCase {
    private struct TestInventory: Codable, Equatable {
        var berries: Int
        var undos: Int
        var shuffles: Int
        var totalEarnedBerries: Int
        var hints: Int
    }

    private let inventoryKey = "berryblockblast.inventory.v3"

    private func store(_ berries: Int = 123) -> (String, UserDefaults) {
        let name = "berry.cheat.restore.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.set(try! JSONEncoder().encode(TestInventory(
            berries: berries, undos: 7, shuffles: 8, totalEarnedBerries: 432, hints: 3
        )), forKey: inventoryKey)
        return (name, defaults)
    }

    private func balance(_ store: UserDefaults) -> TestInventory {
        try! JSONDecoder().decode(TestInventory.self,
                                  from: store.data(forKey: inventoryKey)!)
    }

    func testFirstCheatRecordsExactPreCheatBalanceAndSurvivesReopen() {
        let (name, defaults) = store(123)
        defer { defaults.removePersistentDomain(forName: name) }

        XCTAssertEqual(BerryGameSession.grantQAStrawberries(250, defaults: defaults), 373)
        let reopened = UserDefaults(suiteName: name)!
        let snapshot = BerryGameSession.qaCheatRestorePoint(defaults: reopened)
        XCTAssertEqual(snapshot?.preCheatBalance, 123)
        XCTAssertEqual(snapshot?.lastCheatBalance, 373)
        XCTAssertEqual(snapshot?.cheatCount, 1)
        XCTAssertEqual(balance(reopened).berries, 373)
        XCTAssertFalse(snapshot?.capturedAt.isEmpty ?? true)
    }

    func testMultipleCheatsDoNotOverwriteTheOriginalStartingAmount() {
        let (name, defaults) = store(19)
        defer { defaults.removePersistentDomain(forName: name) }

        XCTAssertEqual(BerryGameSession.grantQAStrawberries(20, defaults: defaults), 39)
        XCTAssertEqual(BerryGameSession.grantQAStrawberries(90, defaults: defaults), 129)
        XCTAssertEqual(BerryGameSession.grantQAStrawberries(1, defaults: defaults), 130)
        let snapshot = BerryGameSession.qaCheatRestorePoint(defaults: defaults)
        XCTAssertEqual(snapshot?.preCheatBalance, 19)
        XCTAssertEqual(snapshot?.lastCheatBalance, 130)
        XCTAssertEqual(snapshot?.cheatCount, 3)
    }

    func testRestoreExactAmountWithoutResettingToolsOrNaturalEarnings() {
        let (name, defaults) = store(88)
        defer { defaults.removePersistentDomain(forName: name) }
        let unchanged = balance(defaults)

        XCTAssertEqual(BerryGameSession.grantQAStrawberries(250, defaults: defaults), 338)
        XCTAssertEqual(BerryGameSession.restorePreCheatStrawberries(defaults: defaults), 88)
        XCTAssertEqual(balance(defaults), unchanged,
                       "Undoing the cheat must preserve the original undos, shuffles, hints and total earned")
        XCTAssertNil(BerryGameSession.qaCheatRestorePoint(defaults: defaults))
        XCTAssertNil(BerryGameSession.restorePreCheatStrawberries(defaults: defaults),
                     "One restoration is never charged or applied twice")
        XCTAssertTrue(BerryGameSession.qaGrantHistory(defaults: defaults).first?
                          .contains("CHEAT RESTORED") ?? false)
    }

    func testRestoreOriginalEvenWhenOrdinaryGameplayChangedBalanceLater() {
        let (name, defaults) = store(71)
        defer { defaults.removePersistentDomain(forName: name) }

        XCTAssertEqual(BerryGameSession.grantQAStrawberries(55, defaults: defaults), 126)
        // Mimic an actual purchase/earn event after the cheat, but preserve all
        // real tool/earned inventory counters, as the production wallet does.
        var current = balance(defaults)
        current.berries = 42
        current.undos = 13
        current.totalEarnedBerries = 901
        defaults.set(try! JSONEncoder().encode(current), forKey: inventoryKey)

        XCTAssertEqual(BerryGameSession.restorePreCheatStrawberries(defaults: defaults), 71)
        let restored = balance(defaults)
        XCTAssertEqual(restored.berries, 71)
        XCTAssertEqual(restored.undos, 13)
        XCTAssertEqual(restored.totalEarnedBerries, 901)
    }

    func testInvalidGrantsMissingInventoryAndMissingSnapshotNeverChangeWallet() {
        let (name, defaults) = store(123)
        defer { defaults.removePersistentDomain(forName: name) }
        let before = defaults.data(forKey: inventoryKey)

        XCTAssertNil(BerryGameSession.grantQAStrawberries(0, defaults: defaults))
        XCTAssertNil(BerryGameSession.grantQAStrawberries(-1, defaults: defaults))
        XCTAssertNil(BerryGameSession.grantQAStrawberries(Int.max, defaults: defaults))
        XCTAssertNil(BerryGameSession.restorePreCheatStrawberries(defaults: defaults))
        XCTAssertEqual(defaults.data(forKey: inventoryKey), before)
        XCTAssertNil(BerryGameSession.qaCheatRestorePoint(defaults: defaults))

        defaults.removeObject(forKey: inventoryKey)
        XCTAssertNil(BerryGameSession.grantQAStrawberries(50, defaults: defaults))
        XCTAssertNil(BerryGameSession.qaCheatRestorePoint(defaults: defaults))
    }

    func testCorruptedExistingRestorePointBlocksCheatRatherThanLoseOriginal() {
        let (name, defaults) = store(56)
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(Data([0x00, 0xff, 0x04]), forKey: BerryGameSession.qaCheatRestoreKey)
        let prior = defaults.data(forKey: inventoryKey)

        XCTAssertNil(BerryGameSession.grantQAStrawberries(500, defaults: defaults))
        XCTAssertEqual(defaults.data(forKey: inventoryKey), prior)
    }

    func testRestoreClearsOldBaselineAndNextCheatCapturesNewOriginal() {
        let (name, defaults) = store(200)
        defer { defaults.removePersistentDomain(forName: name) }

        XCTAssertEqual(BerryGameSession.grantQAStrawberries(7, defaults: defaults), 207)
        XCTAssertEqual(BerryGameSession.restorePreCheatStrawberries(defaults: defaults), 200)
        var inventory = balance(defaults)
        inventory.berries = 240
        defaults.set(try! JSONEncoder().encode(inventory), forKey: inventoryKey)
        XCTAssertEqual(BerryGameSession.grantQAStrawberries(15, defaults: defaults), 255)
        XCTAssertEqual(BerryGameSession.qaCheatRestorePoint(defaults: defaults)?.preCheatBalance, 240)
        XCTAssertEqual(BerryGameSession.restorePreCheatStrawberries(defaults: defaults), 240)
    }

    func testCheatAndRestoreOnlyAffectInjectedPreferencesSuite() {
        let (nameA, a) = store(30)
        let (nameB, b) = store(900)
        defer {
            a.removePersistentDomain(forName: nameA)
            b.removePersistentDomain(forName: nameB)
        }
        let untouched = b.data(forKey: inventoryKey)
        XCTAssertEqual(BerryGameSession.grantQAStrawberries(100, defaults: a), 130)
        XCTAssertEqual(BerryGameSession.restorePreCheatStrawberries(defaults: a), 30)
        XCTAssertEqual(b.data(forKey: inventoryKey), untouched)
        XCTAssertNil(BerryGameSession.qaCheatRestorePoint(defaults: b))
    }
}
