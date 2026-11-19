import XCTest
import Foundation
@testable import BerryBlockBlast

@MainActor
final class BerryBuild44BoutiqueToolsTests: XCTestCase {
    func testOnlyTwoHardwareApprovedBoardLooksAreOffered() {
        XCTAssertTrue(BerryBoardAppearancePolicy.isApproved("original"))
        XCTAssertTrue(BerryBoardAppearancePolicy.isApproved("blossom-glass"))
        for rejected in ["surface-glass", "surface-picnic", "concept-01", "seasonal-frame"] {
            XCTAssertFalse(BerryBoardAppearancePolicy.isApproved(rejected))
        }
    }

    func testBoardSurfaceUsesEstablishedSaveKey() {
        XCTAssertEqual(BerryBoardAppearancePolicy.storageKey,
                       "berryberryblast.board.surface.v059")
        // Isolated defaults: selecting an appearance never touches the
        // independent inventory/wallet payload or previous block style.
        let domain = "com.valentinebsaa.berryboard.qa." + UUID().uuidString
        guard let defaults = UserDefaults(suiteName: domain) else {
            XCTFail("Could not create isolated test preferences")
            return
        }
        defer { defaults.removePersistentDomain(forName: domain) }
        let existingInventory = Data([1, 2, 3, 4])
        defaults.set(existingInventory, forKey: "berryblockblast.inventory.v3")
        defaults.set("blueberry-blocks",
                     forKey: "berryblockblast.shop.equippedBlockSkin.v056b2")
        defaults.set(BerryBoardAppearancePolicy.blossomGlass,
                     forKey: BerryBoardAppearancePolicy.storageKey)
        XCTAssertEqual(defaults.data(forKey: "berryblockblast.inventory.v3"),
                       existingInventory)
        XCTAssertEqual(defaults.string(forKey: "berryblockblast.shop.equippedBlockSkin.v056b2"),
                       "blueberry-blocks")
        XCTAssertEqual(defaults.string(forKey: BerryBoardAppearancePolicy.storageKey),
                       BerryBoardAppearancePolicy.blossomGlass)
        defaults.set(BerryBoardAppearancePolicy.original,
                     forKey: BerryBoardAppearancePolicy.storageKey)
        XCTAssertEqual(defaults.string(forKey: BerryBoardAppearancePolicy.storageKey),
                       BerryBoardAppearancePolicy.original)
        XCTAssertEqual(defaults.data(forKey: "berryblockblast.inventory.v3"),
                       existingInventory)
    }

    func testOutOfStockToolsAreUnusableAndReadable() {
        for tool in BerrySpecialToolsSheet.Tool.allCases where tool != .pantry {
            XCTAssertFalse(BerrySpecialToolAvailability.canUse(
                tool, charges: [:], pantryOwned: false,
                selectedPiece: true, canContinue: true))
            XCTAssertEqual(BerrySpecialToolAvailability.label(
                tool, charges: [:], pantryOwned: false,
                selectedPiece: true, canContinue: true), "0 left")
        }
    }

    func testSelectedTrayPieceIsRequiredForTwisterAndPantry() {
        let charges = ["twister": 3]
        XCTAssertFalse(BerrySpecialToolAvailability.canUse(
            .twister, charges: charges, pantryOwned: true,
            selectedPiece: false, canContinue: false))
        XCTAssertEqual(BerrySpecialToolAvailability.label(
            .twister, charges: charges, pantryOwned: true,
            selectedPiece: false, canContinue: false), "Select a piece")
        XCTAssertTrue(BerrySpecialToolAvailability.canUse(
            .twister, charges: charges, pantryOwned: true,
            selectedPiece: true, canContinue: false))
        XCTAssertEqual(BerrySpecialToolAvailability.label(
            .twister, charges: charges, pantryOwned: true,
            selectedPiece: true, canContinue: false), "3 left")
        XCTAssertFalse(BerrySpecialToolAvailability.canUse(
            .pantry, charges: [:], pantryOwned: false,
            selectedPiece: true, canContinue: false))
        XCTAssertEqual(BerrySpecialToolAvailability.label(
            .pantry, charges: [:], pantryOwned: false,
            selectedPiece: true, canContinue: false), "Locked")
        XCTAssertEqual(BerrySpecialToolAvailability.label(
            .pantry, charges: [:], pantryOwned: true,
            selectedPiece: false, canContinue: false), "Select a piece")
        XCTAssertTrue(BerrySpecialToolAvailability.canUse(
            .pantry, charges: [:], pantryOwned: true,
            selectedPiece: true, canContinue: false))
    }

    func testGoldenStrawberryIsAvailableOnlyForRealRescue() {
        let charges = ["golden-strawberry": 1]
        XCTAssertFalse(BerrySpecialToolAvailability.canUse(
            .golden, charges: charges, pantryOwned: false,
            selectedPiece: false, canContinue: false))
        XCTAssertEqual(BerrySpecialToolAvailability.label(
            .golden, charges: charges, pantryOwned: false,
            selectedPiece: false, canContinue: false), "Available when stuck")
        XCTAssertTrue(BerrySpecialToolAvailability.canUse(
            .golden, charges: charges, pantryOwned: false,
            selectedPiece: false, canContinue: true))
    }

    func testExistingHelperPricesAreUnchanged() {
        XCTAssertEqual(BerryEconomy.undoPrice, 40)
        XCTAssertEqual(BerryEconomy.shufflePrice, 50)
        XCTAssertEqual(BerryEconomy.hintPrice, 35)
    }
}
