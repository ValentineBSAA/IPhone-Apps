import XCTest
@testable import BerryBlockBlast

final class BerryBoardPersonalityTests: XCTestCase {
    func testBotanicalCellsAreSparseAndPredictable() {
        for side in [8, 12] {
            let leaves = (0..<side).flatMap { row in
                (0..<side).filter {
                    BerryBoardPersonality.showsLeaf(row: row, column: $0, side: side)
                }
            }
            XCTAssertGreaterThan(leaves.count, 0)
            XCTAssertLessThan(leaves.count, side * side / 5)
        }
        XCTAssertFalse(BerryBoardPersonality.showsLeaf(row: 0, column: 0, side: 24))
    }
}
