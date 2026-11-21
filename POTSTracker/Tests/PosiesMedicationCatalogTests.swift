import XCTest
@testable import POTSTracker

final class PosiesMedicationCatalogTests: XCTestCase {
    func testCatalogHasLargeCuratedSetAndNoDuplicateGenericNames() {
        XCTAssertGreaterThanOrEqual(PosiesMedicationCatalog.all.count, 150)
        XCTAssertGreaterThanOrEqual(PosiesMedicationCatalog.categories.count, 10)
        let keys = PosiesMedicationCatalog.all.map { $0.name.lowercased() }
        XCTAssertEqual(keys.count, Set(keys).count)
    }

    func testCommonGenericBrandLookupAndCaseInsensitiveSearch() {
        XCTAssertEqual(PosiesMedicationCatalog.find("ibuprofen")?.name, "Ibuprofen")
        XCTAssertEqual(PosiesMedicationCatalog.find("  ADVIL ")?.name, "Ibuprofen")
        XCTAssertEqual(PosiesMedicationCatalog.find("TYLENOL")?.name, "Acetaminophen")
        XCTAssertEqual(PosiesMedicationCatalog.find("CORLANOR")?.name, "Ivabradine")
        XCTAssertEqual(PosiesMedicationCatalog.find("not a medicine"), nil)
        XCTAssertTrue(PosiesMedicationCatalog.search("Aleve").contains { $0.name == "Naproxen" })
        XCTAssertTrue(PosiesMedicationCatalog.search("SYNTHROID").contains { $0.name == "Levothyroxine" })
    }

    func testCategoryFilterDoesNotSuggestTreatmentOrAlterNames() {
        let result = PosiesMedicationCatalog.search("", category: "Pain & fever")
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.category == "Pain & fever" })
        XCTAssertFalse(result.contains { $0.name == "Ivabradine" })
    }

    func testChoosingPresetCreatesOnlyAnUnscheduledUnlabeledDraft() throws {
        let item = try XCTUnwrap(PosiesMedicationCatalog.find("ibuprofen"))
        let draft = item.draftProfile
        XCTAssertEqual(draft.name, "Ibuprofen")
        XCTAssertEqual(draft.labelDose, "")
        XCTAssertEqual(draft.instructions, "")
        XCTAssertEqual(draft.schedule, "Not set")
        XCTAssertNil(draft.refillDate)
        XCTAssertNil(draft.remainingSupply)
        XCTAssertTrue(draft.safeToSave)
    }

    func testCautionsAreAvailableButExplicitlyNonExhaustive() {
        for entry in PosiesMedicationCatalog.all {
            XCTAssertFalse(entry.caution.isEmpty, "Missing caution for \(entry.name)")
            XCTAssertFalse(entry.detailURL.absoluteString.isEmpty)
            XCTAssertFalse(entry.name.isEmpty)
        }
        XCTAssertTrue(PosiesMedicationCatalog.find("acetaminophen")!.caution.localizedCaseInsensitiveContains("liver"))
        XCTAssertTrue(PosiesMedicationCatalog.find("midodrine")!.caution.localizedCaseInsensitiveContains("lying down"))
        XCTAssertTrue(PosiesMedicationCatalog.find("apixaban")!.caution.localizedCaseInsensitiveContains("bleeding"))
    }

    func testExistingProfilesDoNotNeedCatalogOrSchemaMigration() throws {
        let legacy = PosiesMedicationProfile(name: "Ibuprofen", labelDose: "400", instructions: "Personal label")
        let data = try PosiesDataTransfer.encoder().encode([legacy])
        let decoded = try PosiesDataTransfer.decoder().decode([PosiesMedicationProfile].self, from: data)
        XCTAssertEqual(decoded, [legacy])
        XCTAssertNotNil(PosiesMedicationCatalog.find(decoded[0].name))
        XCTAssertEqual(decoded[0].labelDose, "400")
        XCTAssertEqual(decoded[0].instructions, "Personal label")
    }
}
