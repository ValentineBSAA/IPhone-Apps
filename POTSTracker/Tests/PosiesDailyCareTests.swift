import XCTest
@testable import POTSTracker

final class PosiesDailyCareTests: XCTestCase {
    func testOriginalHydrationAndRestPresetsArePreserved() {
        XCTAssertEqual(PosiesQuickPresets.values("", fallback: [125,250,350,500], range: 1...10000),
                       [125,250,350,500])
        XCTAssertEqual(PosiesQuickPresets.values("", fallback: [15,30,60,90], range: 1...2880),
                       [15,30,60,90])
    }

    func testPersonalAmountsAreFourUniqueWholeNumbers() {
        let custom = [100,225,440,600]
        let text = PosiesQuickPresets.encode(custom, range: 1...10000)
        XCTAssertEqual(text, "100,225,440,600")
        XCTAssertEqual(PosiesQuickPresets.values(text!, fallback: [125,250,350,500],
                                                range: 1...10000), custom)
    }

    func testBadStoredSettingsCannotCorruptQuickChoices() {
        let defaults = [125,250,350,500]
        for input in ["0,250,350,500", "250,250,350,500", "250,350,500",
                      "-1,250,350,500", "a,250,350,500", "250,350,500,10001"] {
            XCTAssertEqual(PosiesQuickPresets.values(input, fallback: defaults,
                                                    range: 1...10000), defaults)
        }
        XCTAssertNil(PosiesQuickPresets.encode([15,15,60,90], range: 1...2880))
        XCTAssertNil(PosiesQuickPresets.encode([0,30,60,90], range: 1...2880))
        XCTAssertNil(PosiesQuickPresets.encode([15,30,60], range: 1...2880))
    }

    func testExistingMedicationProfileArchiveIsStillReadable() throws {
        let item = PosiesMedicationProfile(name: "Test name")
        let data = try PosiesDataTransfer.encoder().encode([item])
        let read = try PosiesDataTransfer.decoder().decode([PosiesMedicationProfile].self, from: data)
        XCTAssertEqual(read, [item])
    }

    func testMedicationChoiceDoesNotAssumeAdherence() {
        XCTAssertEqual(PosiesChoiceBehavior.toggle("Taken", tapped: "Taken"), "")
        let draft = PosiesEntryExtras(dose: "As written on label")
        XCTAssertEqual(PosiesEntryExtras.read(draft.stored()).dose, "As written on label")
    }
}
