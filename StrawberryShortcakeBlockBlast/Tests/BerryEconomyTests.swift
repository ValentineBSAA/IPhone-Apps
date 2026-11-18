import XCTest
@testable import BerryBlockBlast

final class BerryEconomyTests: XCTestCase {
    func testHelperCostsAreConsistentAndDistinct() {
        XCTAssertEqual(BerryEconomy.undoPrice, 40)
        XCTAssertEqual(BerryEconomy.shufflePrice, 50)
        XCTAssertEqual(BerryEconomy.hintPrice, 35)
        XCTAssertTrue(BerryEconomy.hintPrice > 0)
        XCTAssertLessThan(BerryEconomy.shufflePrice, BerryGameSession.goldenStrawberryCost)
    }

    func testGoldenStrawberryRescueRemains250() {
        XCTAssertEqual(BerryGameSession.goldenStrawberryCost, 250)
    }

    func testCottageUnlocksBecomeLongTermGoals() {
        XCTAssertEqual(BerryEconomy.cottagePrices, [60, 90, 130, 180, 240, 300])
        XCTAssertEqual(BerryEconomy.cottagePrices.reduce(0, +), 1000)
        for owned in 0..<6 {
            XCTAssertEqual(BerryEconomy.nextCottagePrice(owned: owned),
                           BerryEconomy.cottagePrices[owned])
        }
        XCTAssertNil(BerryEconomy.nextCottagePrice(owned: 6))
        XCTAssertNil(BerryEconomy.nextCottagePrice(owned: -1))
    }

    func testPreviouslyOwnedDecorationsDoNotRequireRepurchase() {
        XCTAssertEqual(BerryEconomy.nextCottagePrice(owned: 1), 90)
        XCTAssertEqual(BerryEconomy.nextCottagePrice(owned: 5), 300)
        XCTAssertNil(BerryEconomy.nextCottagePrice(owned: 7))
    }
}
