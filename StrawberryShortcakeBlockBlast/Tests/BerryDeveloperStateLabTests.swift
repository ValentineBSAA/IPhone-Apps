import Foundation
import XCTest
@testable import BerryBlockBlast

#if BERRY_INTERNAL_QA
/// D0b proves mock policy boundaries and that the lab never uses live storage.
/// These are not production checkout, daily-reward or purchase-flow tests.
final class BerryDeveloperStateLabTests: XCTestCase {
    private func canonical(_ engine: BerryEngine) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(engine)
    }

    func testAllSixScenariosRunAndReportSpecificResults() {
        var lab = BerryDeveloperStateLab()
        XCTAssertEqual(BerryQAStateScenario.allCases.count, 6)
        for scenario in BerryQAStateScenario.allCases {
            lab.prepare(scenario)
            let result = lab.run()
            XCTAssertEqual(result.scenario, scenario)
            XCTAssertTrue(result.passed, "\(scenario.rawValue): \(result.actual)")
            XCTAssertEqual(result.expected, scenario.expected)
        }
    }

    func testExactPriceUndoDoesNotProduceFreeCurrency() {
        var lab = BerryDeveloperStateLab()
        let result = lab.run()
        XCTAssertTrue(result.passed, result.actual)
        XCTAssertEqual(lab.wallet.balance, 0)
        XCTAssertEqual(lab.wallet.chargeCount(for: .undo), 1)
        XCTAssertEqual(BerryQAIsolatedTool.undo.price, BerryEconomy.undoPrice)
    }

    func testOneBerryShortRejectsShuffleWithoutMutation() {
        var lab = BerryDeveloperStateLab()
        lab.prepare(.oneBerryShort)
        XCTAssertEqual(lab.wallet.balance, BerryEconomy.shufflePrice - 1)
        let receipt = lab.run()
        XCTAssertTrue(receipt.passed, receipt.actual)
        XCTAssertEqual(lab.wallet.balance, BerryEconomy.shufflePrice - 1)
        XCTAssertEqual(lab.wallet.chargeCount(for: .shuffle), 0)
    }

    func testZeroChargeHintRejectedAndCannotGoNegative() {
        var lab = BerryDeveloperStateLab()
        lab.prepare(.zeroToolCharge)
        XCTAssertTrue(lab.run().passed)
        XCTAssertEqual(lab.wallet.chargeCount(for: .hint), 0)
        var isolatedCopy = lab.wallet
        XCTAssertFalse(isolatedCopy.use(.hint))
        XCTAssertEqual(isolatedCopy.chargeCount(for: .hint), 0)
    }

    func testSandboxChargePurchaseUseAndNoDoubleSpend() {
        var wallet = BerryQAIsolatedWallet(balance: BerryEconomy.undoPrice)
        XCTAssertTrue(wallet.buy(.undo))
        XCTAssertFalse(wallet.buy(.undo))
        XCTAssertTrue(wallet.use(.undo))
        XCTAssertFalse(wallet.use(.undo))
        XCTAssertEqual(wallet.balance, 0)
        XCTAssertEqual(wallet.chargeCount(for: .undo), 0)
    }

    func testChargeOverflowRejectsPurchaseWithoutSpending() {
        var wallet = BerryQAIsolatedWallet(
            balance: BerryEconomy.hintPrice,
            charges: [.hint: Int.max])
        XCTAssertFalse(wallet.buy(.hint))
        XCTAssertEqual(wallet.balance, BerryEconomy.hintPrice)
        XCTAssertEqual(wallet.chargeCount(for: .hint), Int.max)
    }

    func testInMemorySaveRoundTripForAllSupportedBoardSizes() throws {
        var storage = BerryQAMemorySaveStore()
        for side in [8, 12, 24] {
            let engine = BerryEngine(side: side, seed: UInt64(20261120 + side))
            let key = "test-\(side)"
            try storage.save(engine, key: key)
            let loaded = try XCTUnwrap(storage.restore(key: key))
            XCTAssertEqual(try canonical(loaded), try canonical(engine))
            XCTAssertGreaterThan(storage.byteCount(key: key), 100)
        }
        XCTAssertNil(try storage.restore(key: "missing"))
    }

    func testCorruptedSlotCannotDamageValidIndependentSnapshot() throws {
        var storage = BerryQAMemorySaveStore()
        let original = BerryEngine(side: 12, seed: 12345)
        try storage.save(original, key: "valid")
        storage.setCorruptedBytes(Data("{bad".utf8), key: "bad")
        XCTAssertThrowsError(try storage.restore(key: "bad"))
        let restored = try XCTUnwrap(storage.restore(key: "valid"))
        XCTAssertEqual(try canonical(restored), try canonical(original))
    }

    func testVirtualTimerPauseAndResumeUsesProductionTimingPolicy() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        var virtual = BerryQAVirtualClock(now: start)
        let deadline = start.addingTimeInterval(3)
        virtual.advance(by: 1)
        let pausedAt = virtual.now
        XCTAssertEqual(BerryTimedLifecycle.pausedSeconds(
            deadline: deadline, pausedAt: pausedAt, fallback: 0), 2)
        virtual.advance(by: 10)
        let resumed = BerryTimedLifecycle.restoredDeadline(
            deadline, pausedAt: pausedAt, resumedAt: virtual.now)
        XCTAssertEqual(resumed, deadline.addingTimeInterval(10))
        XCTAssertEqual(BerryCountdownMath.seconds(
            deadline: resumed, now: virtual.now,
            pausedAt: nil, fallback: 0), 2)
        XCTAssertTrue(BerryTimedLifecycle.canPlay(
            now: virtual.now, deadline: resumed,
            running: true, foreground: true, pausedAt: nil))
        virtual.advance(by: 2)
        XCTAssertFalse(BerryTimedLifecycle.canPlay(
            now: virtual.now, deadline: resumed,
            running: true, foreground: true, pausedAt: nil))
    }

    func testRepeatAndDiscardUseFreshMockStateNotPriorTransaction() {
        var lab = BerryDeveloperStateLab()
        let first = lab.run()
        XCTAssertTrue(first.passed)
        XCTAssertEqual(lab.wallet.balance, 0)
        let second = lab.run()
        XCTAssertEqual(first, second)
        XCTAssertEqual(lab.wallet.chargeCount(for: .undo), 1)
        lab.prepare(.virtualTimer)
        XCTAssertTrue(lab.run().passed)
        lab.discard()
        XCTAssertEqual(lab.scenario, .exactPriceUndo)
        XCTAssertEqual(lab.wallet.balance, BerryEconomy.undoPrice)
        XCTAssertNil(lab.latest)
    }

    func testAllStateLabFixturesLeaveActualSavedKeysAndRealEngineUntouched() throws {
        let keys = [
            "berryblockblast.inventory.v3",
            "berryblockblast.endless.saved-8.v056b2",
            "berryblockblast.endless.saved-12.v056b2",
            "berryblockblast.endless.saved-24.v056b2",
            "berryblockblast.rewards.v1",
            "berryblockblast.shop.owned.v056b2",
            "berryberryblast.premium.charges.v059",
            "berryblockblast.daily.history.v1"
        ]
        let before = keys.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        let realEngine = BerryEngine(seed: 20261120)
        let original = try canonical(realEngine)
        var lab = BerryDeveloperStateLab()
        for option in BerryQAStateScenario.allCases {
            lab.prepare(option)
            XCTAssertTrue(lab.run().passed, option.rawValue)
        }
        lab.discard()
        XCTAssertEqual(try canonical(realEngine), original)
        let after = keys.map { UserDefaults.standard.object(forKey: $0) as? NSObject }
        for idx in keys.indices {
            XCTAssertEqual(before[idx], after[idx], "Mutated normal player key \(keys[idx])")
        }
    }
}
#endif
