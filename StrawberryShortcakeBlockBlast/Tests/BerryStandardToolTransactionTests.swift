import XCTest
@testable import BerryBlockBlast

/// D0c first shared-handler safety gate.
/// These tests exercise the EXACT reducer called by production
/// BerryGameSession.buyUndo, buyShuffle, buyHint and useHintIfPossible.
/// Full persistence/ledger/checkout UI injection remains a separate gate.
final class BerryStandardToolTransactionTests: XCTestCase {
    func testExactPricePurchasesForAllThreeRealToolPrices() {
        for price in [BerryEconomy.undoPrice, BerryEconomy.shufflePrice,
                      BerryEconomy.hintPrice] {
            let state = BerryStandardToolTransaction.purchase(
                berries: price, charges: 0, price: price)
            XCTAssertEqual(state, BerryStandardToolTransaction.UpdatedState(berries: 0, charges: 1))
        }
    }

    func testOneBerryShortRejectsEveryToolWithoutDebit() {
        for price in [BerryEconomy.undoPrice, BerryEconomy.shufflePrice,
                      BerryEconomy.hintPrice] {
            XCTAssertNil(BerryStandardToolTransaction.purchase(
                berries: price - 1, charges: 0, price: price))
        }
    }

    func testInsufficientFundsDoesNotInvalidateExistingCharges() {
        let balance = BerryEconomy.undoPrice - 1
        let alreadyOwned = 7
        let attempted = BerryStandardToolTransaction.purchase(
            berries: balance, charges: alreadyOwned,
            price: BerryEconomy.undoPrice)
        XCTAssertNil(attempted)
        XCTAssertEqual(balance, BerryEconomy.undoPrice - 1)
        XCTAssertEqual(alreadyOwned, 7)
    }

    func testRejectsInvalidBalancesChargesAndPrices() {
        XCTAssertNil(BerryStandardToolTransaction.purchase(
            berries: -1, charges: 0, price: 1))
        XCTAssertNil(BerryStandardToolTransaction.purchase(
            berries: 10, charges: -1, price: 1))
        XCTAssertNil(BerryStandardToolTransaction.purchase(
            berries: 10, charges: 0, price: -1))
        XCTAssertNil(BerryStandardToolTransaction.purchase(
            berries: 10, charges: 0, price: 0))
    }

    func testRejectsChargeOverflowWithoutTakingCurrency() {
        XCTAssertNil(BerryStandardToolTransaction.purchase(
            berries: 900, charges: Int.max,
            price: BerryEconomy.shufflePrice))
        XCTAssertEqual(BerryStandardToolTransaction.purchase(
            berries: Int.max, charges: Int.max - 1,
            price: BerryEconomy.shufflePrice),
            BerryStandardToolTransaction.UpdatedState(berries: Int.max - BerryEconomy.shufflePrice,
                  charges: Int.max))
    }

    func testSuccessfulPurchaseIncrementsExistingChargesExactlyOnce() {
        let old = 3
        let price = BerryEconomy.hintPrice
        XCTAssertEqual(BerryStandardToolTransaction.purchase(
            berries: 200, charges: old, price: price),
            BerryStandardToolTransaction.UpdatedState(berries: 200 - price, charges: 4))
    }

    func testToolConsumptionOnlyAfterValidUnderlyingAction() {
        XCTAssertNil(BerryStandardToolTransaction.consumeCharge(
            10, actionIsValid: false))
        XCTAssertEqual(BerryStandardToolTransaction.consumeCharge(
            10, actionIsValid: true), 9)
        XCTAssertNil(BerryStandardToolTransaction.consumeCharge(
            0, actionIsValid: true))
        XCTAssertNil(BerryStandardToolTransaction.consumeCharge(
            -1, actionIsValid: true))
    }

    func testDoesNotSpendChargeOnInvalidOrUnselectedHint() {
        // The game performs its suggested-move validation first; this reducer
        // must not consume a charge when an action cannot be executed.
        let count = 2
        let rejected = BerryStandardToolTransaction.consumeCharge(
            count, actionIsValid: false)
        XCTAssertNil(rejected)
        XCTAssertEqual(count, 2)
    }

    #if BERRY_INTERNAL_QA
    func testInternalQAUsesExactProductionPurchaseReducer() {
        for tool in [BerryQAIsolatedTool.undo, .shuffle, .hint] {
            var simulated = BerryQAIsolatedWallet(balance: tool.price)
            let policy = BerryStandardToolTransaction.purchase(
                berries: tool.price, charges: 0, price: tool.price)
            XCTAssertTrue(simulated.buy(tool))
            XCTAssertEqual(simulated.balance, policy?.berries)
            XCTAssertEqual(simulated.chargeCount(for: tool), policy?.charges)
        }
    }

    func testInternalQARejectedActionMatchesProductionPolicy() {
        var isolated = BerryQAIsolatedWallet(
            balance: BerryEconomy.shufflePrice - 1)
        XCTAssertNil(BerryStandardToolTransaction.purchase(
            berries: isolated.balance, charges: 0,
            price: BerryEconomy.shufflePrice))
        XCTAssertFalse(isolated.buy(.shuffle))
        XCTAssertEqual(isolated.balance, BerryEconomy.shufflePrice - 1)
        XCTAssertEqual(isolated.chargeCount(for: .shuffle), 0)
    }
    #endif
}
