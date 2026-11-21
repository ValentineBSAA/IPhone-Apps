import XCTest
@testable import BerryBlockBlast

#if BERRY_INTERNAL_QA
/// D0: exercising real board mechanics through disposable value fixtures.
/// No test starts BerryGameSession or invokes persistent wallet mutations.
final class BerryDeveloperSandboxTests: XCTestCase {
    private func engineBytes(_ engine: BerryEngine) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(engine)
    }

    func testOneMoveLineClearRunsActualEngineWithExactScoreAndNoBonus() throws {
        var sandbox = BerryDeveloperSandbox()
        XCTAssertEqual(sandbox.engine.side, 8)
        XCTAssertEqual(sandbox.engine.board[3].compactMap { $0 }.count, 7)
        XCTAssertNil(sandbox.engine.board[3][7])
        XCTAssertEqual(sandbox.engine.board[7][7], 2)
        let receipt = sandbox.run()
        XCTAssertTrue(receipt.passed, receipt.actual)
        XCTAssertEqual(receipt.clearedLines, 1)
        XCTAssertEqual(receipt.scoreDelta, 11)
        XCTAssertEqual(sandbox.engine.moves, 1)
        XCTAssertEqual(sandbox.engine.totalLines, 1)
        XCTAssertEqual(sandbox.engine.score, 11)
        XCTAssertTrue(sandbox.engine.board[3].allSatisfy { $0 == nil })
        XCTAssertEqual(sandbox.engine.board[7][7], 2)
    }

    func testInvalidPlacementRejectsWithoutAnyEngineMutation() throws {
        var sandbox = BerryDeveloperSandbox()
        sandbox.prepare(.blockedPlacement)
        XCTAssertEqual(sandbox.engine.board[2][2], 2)
        let before = try engineBytes(sandbox.engine)
        let receipt = sandbox.run()
        XCTAssertTrue(receipt.passed, receipt.actual)
        XCTAssertEqual(receipt.scoreDelta, 0)
        XCTAssertEqual(receipt.clearedLines, 0)
        XCTAssertEqual(try engineBytes(sandbox.engine), before)
    }

    func testRepeatRunAlwaysRestartsExactlyTheSameFixture() throws {
        var sandbox = BerryDeveloperSandbox()
        let first = sandbox.run()
        let firstEngine = try engineBytes(sandbox.engine)
        let second = sandbox.run()
        XCTAssertEqual(first, second)
        XCTAssertEqual(try engineBytes(sandbox.engine), firstEngine)
        sandbox.prepare(.blockedPlacement)
        let blocked = sandbox.run()
        XCTAssertTrue(blocked.passed)
        XCTAssertNotEqual(first.scenario, blocked.scenario)
    }

    func testDiscardErasesSandboxResultAndRestoresUnplayedFixture() throws {
        var sandbox = BerryDeveloperSandbox()
        sandbox.prepare(.blockedPlacement)
        _ = sandbox.run()
        XCTAssertNotNil(sandbox.latestResult)
        sandbox.discard()
        XCTAssertNil(sandbox.latestResult)
        XCTAssertEqual(sandbox.scenario, .oneMoveLineClear)
        XCTAssertEqual(sandbox.engine.moves, 0)
        XCTAssertEqual(sandbox.engine.score, 0)
        XCTAssertEqual(sandbox.engine.board[3].compactMap { $0 }.count, 7)
        XCTAssertNil(sandbox.engine.board[3][7])
    }

    func testSandboxDoesNotTouchRealPersistentSaveOrWallet() throws {
        // Snapshot real application keys as found, do not seed/change them.
        // The sandbox deliberately cannot be passed a UserDefaults instance.
        let keys = [
            "berryblockblast.inventory.v3",
            "berryblockblast.endless.saved-8.v056b2",
            "berryblockblast.endless.saved-12.v056b2",
            "berryblockblast.endless.saved-24.v056b2",
            "berryblockblast.rewards.v1",
            "berryblockblast.shop.owned.v056b2",
            "berryberryblast.premium.charges.v059",
            "berryberryblast.birthday.month.v0511"
        ]
        let before = keys.map { UserDefaults.standard.object(forKey: $0) as Any? }
        let productionEngine = BerryEngine(seed: 20261120)
        let originalEngine = try engineBytes(productionEngine)
        var sandbox = BerryDeveloperSandbox()
        XCTAssertTrue(sandbox.run().passed)
        sandbox.prepare(.blockedPlacement)
        XCTAssertTrue(sandbox.run().passed)
        sandbox.discard()
        XCTAssertEqual(try engineBytes(productionEngine), originalEngine)
        let after = keys.map { UserDefaults.standard.object(forKey: $0) as Any? }
        for i in keys.indices {
            let oldValue = before[i] as? NSObject
            let newValue = after[i] as? NSObject
            XCTAssertEqual(oldValue, newValue, "QA sandbox modified live game key: \(keys[i])")
        }
    }

    func testFixtureIDsAreStableAndNoRandomRefillWasTriggered() throws {
        var sandbox = BerryDeveloperSandbox()
        let initialIDs = sandbox.engine.tray.compactMap { $0?.id }
        XCTAssertEqual(initialIDs.count, 3)
        _ = sandbox.run()
        XCTAssertEqual(sandbox.engine.tray.compactMap { $0?.id }.count, 2)
        sandbox.discard()
        XCTAssertEqual(sandbox.engine.tray.compactMap { $0?.id }, initialIDs)
    }
}
#endif
