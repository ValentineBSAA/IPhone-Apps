import XCTest
@testable import POTSTracker

final class PosiesMedicationCabinetPolishTests: XCTestCase {
    func testStrengthAndSupplyAmountRequireExplicitUnits() {
        XCTAssertTrue(PosiesMedicationMeasurements.validPair(
            amount: "0.5", unit: "mg",
            units: PosiesMedicationMeasurements.strengthUnits, max: 1000000))
        XCTAssertTrue(PosiesMedicationMeasurements.validPair(
            amount: "1.5", unit: "US fl oz",
            units: PosiesMedicationMeasurements.supplyUnits, max: 100000))
        XCTAssertFalse(PosiesMedicationMeasurements.validPair(
            amount: "400", unit: nil,
            units: PosiesMedicationMeasurements.strengthUnits, max: 1000000))
        XCTAssertFalse(PosiesMedicationMeasurements.validPair(
            amount: nil, unit: "mg",
            units: PosiesMedicationMeasurements.strengthUnits, max: 1000000))
        XCTAssertTrue(PosiesMedicationMeasurements.validPair(
            amount: nil, unit: nil,
            units: PosiesMedicationMeasurements.strengthUnits, max: 1000000))
    }

    func testUnsafeOrAmbiguousInputRejected() {
        for bad in ["0", "0.0", "-1", ".5", "1,000", "100 mg",
                    "1e3", "1.00001", "999999999", "two"] {
            XCTAssertFalse(PosiesMedicationMeasurements.validPositiveDecimal(bad, max: 1000000),
                           "Unexpectedly accepted \(bad)")
        }
        XCTAssertTrue(PosiesMedicationMeasurements.validPositiveDecimal("0.5", max: 1000000))
        XCTAssertTrue(PosiesMedicationMeasurements.validPositiveDecimal("400", max: 1000000))
    }

    func testLegacyProfileAndJSONStillReadWithoutAssumingMg() throws {
        let original = PosiesMedicationProfile(name: "Ibuprofen", labelDose: "400",
            instructions: "Personal note", remainingSupply: 12)
        let data = try PosiesDataTransfer.encoder().encode([original])
        let loaded = try PosiesDataTransfer.decoder().decode([PosiesMedicationProfile].self, from: data)
        XCTAssertEqual(loaded[0].labelDose, "400")
        XCTAssertEqual(loaded[0].displayStrength, "400")
        XCTAssertNil(loaded[0].strengthUnit)
        XCTAssertNil(loaded[0].strengthAmount)
        XCTAssertEqual(loaded[0].remainingSupply, 12)
        XCTAssertTrue(loaded[0].safeToSave)
    }

    func testNewStructuredProfileSurvivesBackupRoundTrip() throws {
        var item = PosiesMedicationProfile(name: "Test medicine", schedule: "Not set")
        item.strengthAmount = "0.5"
        item.strengthUnit = "mg"
        item.dosageForm = "Tablet"
        item.supplyAmount = "30"
        item.supplyUnit = "tablets"
        XCTAssertTrue(item.safeToSave)
        let data = try PosiesDataTransfer.encoder().encode([item])
        let copied = try PosiesDataTransfer.decoder().decode([PosiesMedicationProfile].self, from: data)
        XCTAssertEqual(copied, [item])
        XCTAssertEqual(copied[0].displayStrength, "0.5 mg")
        XCTAssertEqual(copied[0].displaySupply, "30 tablets on hand")
    }

    func testCatalogPresetStillDoesNotInferPrescription() throws {
        let ref = try XCTUnwrap(PosiesMedicationCatalog.find("Advil"))
        let profile = ref.draftProfile
        XCTAssertNil(profile.strengthAmount)
        XCTAssertNil(profile.strengthUnit)
        XCTAssertNil(profile.dosageForm)
        XCTAssertNil(profile.supplyAmount)
        XCTAssertNil(profile.supplyUnit)
        XCTAssertEqual(profile.schedule, "Not set")
    }
}
