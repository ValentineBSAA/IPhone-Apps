import XCTest
@testable import POTSTracker

final class PosiesFeatureVisualsTests: XCTestCase {
    func testAllApprovedIconAssetsAreMapped() {
        let expected = [
            "heartRate":"01_Heart_Rate","bloodPressure":"02_Blood_Pressure",
            "symptom":"03_Symptoms","hydration":"04_Hydration",
            "medications":"05_Medications","sleep":"06_Sleep",
            "calendar":"07_Calendar","reports":"08_Reports",
            "journal":"09_Journal","posture":"10_Posture",
            "reminders":"11_Reminders","settings":"12_Settings"
        ]
        XCTAssertEqual(Set(PosiesFeatureVisuals.approvedIDs), Set(expected.keys))
        XCTAssertEqual(Set(expected.values).count, 12)
        for (key,file) in expected {
            XCTAssertEqual(PosiesFeatureVisuals.artworkFile(for:key), file)
        }
    }
    func testRestSharesApprovedSleepImage() {
        XCTAssertEqual(PosiesFeatureVisuals.artworkFile(for:"Rest"),"06_Sleep")
        XCTAssertEqual(PosiesFeatureVisuals.artworkFile(for:"sleep & rest"),"06_Sleep")
        XCTAssertEqual(PosiesFeatureVisuals.artworkFile(for:"medication"),"05_Medications")
    }
    func testNoInventedCheckinImage() {
        XCTAssertNil(PosiesFeatureVisuals.artworkFile(for:"checkIn"))
    }
    func testMenuChoiceCanBeDeselectByTappingAgain() {
        XCTAssertEqual(PosiesChoiceBehavior.toggle("Rest",tapped:"Rest"),"")
        XCTAssertEqual(PosiesChoiceBehavior.toggle("",tapped:"Sleep"),"Sleep")
    }
}
