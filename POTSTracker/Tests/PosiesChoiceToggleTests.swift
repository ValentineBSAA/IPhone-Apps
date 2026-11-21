import XCTest
@testable import POTSTracker

final class PosiesChoiceToggleTests: XCTestCase {
    func testSingleChoiceSelectThenTapAgainClears() {
        for choice in ["Water", "Taken", "Sleep", "Sitting", "Better", "Dizziness", "Restful"] {
            let selected = PosiesChoiceBehavior.toggle("", tapped: choice)
            XCTAssertEqual(selected, choice)
            XCTAssertEqual(PosiesChoiceBehavior.toggle(selected, tapped: choice), "")
        }
    }

    func testSwitchingChoiceReplacesInsteadOfSavingTwoSelections() {
        XCTAssertEqual(PosiesChoiceBehavior.toggle("Taken", tapped: "Skipped"), "Skipped")
        XCTAssertEqual(PosiesChoiceBehavior.toggle("Rest", tapped: "Sleep"), "Sleep")
        XCTAssertEqual(PosiesChoiceBehavior.toggle("Blossom", tapped: "Midnight"), "Midnight")
    }

    func testOptionalSeverityAndPostureCanBeRemoved() {
        XCTAssertEqual(PosiesChoiceBehavior.toggleRating(-1, tapped: 7), 7)
        XCTAssertEqual(PosiesChoiceBehavior.toggleRating(7, tapped: 7), -1)
        XCTAssertEqual(PosiesChoiceBehavior.toggleRating(7, tapped: 0), 0)
        XCTAssertEqual(PosiesChoiceBehavior.toggle("Sitting", tapped: "Sitting", empty: "Not specified"), "Not specified")
    }

    func testQuickAmountAndSleepDurationCanBeCleared() {
        XCTAssertEqual(PosiesChoiceBehavior.toggleAmount("", tapped: 250), "250")
        XCTAssertEqual(PosiesChoiceBehavior.toggleAmount("250", tapped: 250), "")
        XCTAssertEqual(PosiesChoiceBehavior.toggleAmount("250", tapped: 500), "500")
        XCTAssertEqual(PosiesChoiceBehavior.toggleAmount("90", tapped: 90), "")
        XCTAssertEqual(PosiesChoiceBehavior.toggleAmount("15", tapped: 30), "30")
    }

    func testOptionalTagsCanBeToggledWithoutAffectingOthers() {
        var tags = Set(["With food", "Morning"])
        tags = PosiesChoiceBehavior.toggleInSet(tags, tapped: "With food")
        XCTAssertEqual(tags, Set(["Morning"]))
        tags = PosiesChoiceBehavior.toggleInSet(tags, tapped: "With food")
        XCTAssertEqual(tags, Set(["Morning", "With food"]))
        tags = PosiesChoiceBehavior.toggleInSet(tags, tapped: "Morning")
        tags = PosiesChoiceBehavior.toggleInSet(tags, tapped: "With food")
        XCTAssertTrue(tags.isEmpty)
    }

    func testRepeatedSelectionDoesNotCreateAnyRecordedEntry() throws {
        let chosen = PosiesChoiceBehavior.toggle("Usual", tapped: "Usual")
        XCTAssertTrue(chosen.isEmpty)
        let archive = try PosiesDataTransfer.encodeBackup([])
        let preview = try PosiesDataTransfer.inspect(archive, existingIDs: [], journalUnlocked: true)
        XCTAssertEqual(preview.archive.records.count, 0)
    }

    func testSafeFallbackIsAvailableForRequiredSettings() {
        XCTAssertEqual(PosiesChoiceBehavior.preference("dark", tapped: "dark", defaultValue: "system"), "system")
        XCTAssertEqual(PosiesChoiceBehavior.preference("comfortable", tapped: "comfortable", defaultValue: "compact"), "compact")
        XCTAssertEqual(PosiesChoiceBehavior.preference("system", tapped: "dark", defaultValue: "system"), "dark")
    }

    func testExistingBackupRecordsRemainCompatible() throws {
        let archive = try PosiesDataTransfer.encodeBackup([])
        let preview = try PosiesDataTransfer.inspect(archive, existingIDs: [], journalUnlocked: true)
        XCTAssertEqual(preview.archive.schemaVersion, 1)
        XCTAssertEqual(preview.archive.format, "pots-posies-local-backup")
    }
}
