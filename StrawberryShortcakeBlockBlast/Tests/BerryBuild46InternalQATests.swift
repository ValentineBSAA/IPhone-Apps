import XCTest
@testable import BerryBlockBlast

#if BERRY_INTERNAL_QA
@MainActor
final class BerryBuild46InternalQATests: XCTestCase {
    private func freshDefaults() -> (UserDefaults, String) {
        let name = "berry46.qa." + UUID().uuidString
        return (UserDefaults(suiteName: name)!, name)
    }
    private func record(_ berries: Int) -> Data {
        let x: [String: Int] = ["berries": berries, "undos": 1, "shuffles": 2,
                                "hints": 1, "totalEarnedBerries": 38]
        return try! JSONSerialization.data(withJSONObject: x)
    }
    func testSingle1200GrantPersistsWithoutChangingEarnedOrBoard() throws {
        let (defaults, domain) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: domain) }
        defaults.set(record(4), forKey: "berryblockblast.inventory.v3")
        let board = Data("saved 12x12 board".utf8)
        defaults.set(board, forKey: "berryblockblast.endless.saved-12.v056b2")
        XCTAssertEqual(BerryGameSession.grantQAStrawberries(1200, defaults: defaults), 1204)
        let bytes = try XCTUnwrap(defaults.data(forKey: "berryblockblast.inventory.v3"))
        let saved = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Int])
        XCTAssertEqual(saved["berries"], 1204)
        XCTAssertEqual(saved["undos"], 1)
        XCTAssertEqual(saved["shuffles"], 2)
        XCTAssertEqual(saved["hints"], 1)
        XCTAssertEqual(saved["totalEarnedBerries"], 38)
        XCTAssertEqual(defaults.data(forKey: "berryblockblast.endless.saved-12.v056b2"), board)
        XCTAssertEqual(BerryGameSession.qaGrantHistory(defaults: defaults).count, 1)
    }
    func testInvalidAndOverflowGrantsLeaveWalletUnchanged() {
        let (defaults, domain) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: domain) }
        XCTAssertNil(BerryGameSession.grantQAStrawberries(1200, defaults: defaults),
                     "Cannot create a new inventory over a potentially old wallet")
        defaults.set(record(44), forKey: "berryblockblast.inventory.v3")
        XCTAssertNil(BerryGameSession.grantQAStrawberries(0, defaults: defaults))
        XCTAssertNil(BerryGameSession.grantQAStrawberries(-1, defaults: defaults))
        XCTAssertNil(BerryGameSession.grantQAStrawberries(Int.max, defaults: defaults))
        XCTAssertEqual(BerryGameSession.qaWalletBalance(defaults: defaults), 44)
        XCTAssertTrue(BerryGameSession.qaGrantHistory(defaults: defaults).isEmpty)
    }
    func testSingleLargeGrantAndRecordedDiagnosticHistory() {
        let (defaults, domain) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: domain) }
        defaults.set(record(4), forKey: "berryblockblast.inventory.v3")
        XCTAssertEqual(BerryGameSession.grantQAStrawberries(250000, defaults: defaults), 250004)
        XCTAssertTrue(BerryGameSession.qaGrantHistory(defaults: defaults)[0].contains("QA +250000"))
    }
}
#endif
