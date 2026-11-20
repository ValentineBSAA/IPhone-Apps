import XCTest
@testable import POTSTracker

final class PosiesBackupAndTrackerPolishTests: XCTestCase {
    func testSaveBackupNoLongerSilentlyDisablesWhenJournalLocked() {
        XCTAssertEqual(PosiesManualBackupAccess.evaluate(
            recordCount: 3, lockEnabled: true, unlocked: false), .needsUnlock)
        XCTAssertEqual(PosiesManualBackupAccess.evaluate(
            recordCount: 3, lockEnabled: true, unlocked: true), .ready)
        XCTAssertEqual(PosiesManualBackupAccess.evaluate(
            recordCount: 3, lockEnabled: false, unlocked: false), .ready)
    }

    func testEmptyBackupHasFriendlyStateIndependentOfICloud() {
        XCTAssertEqual(PosiesManualBackupAccess.evaluate(
            recordCount: 0, lockEnabled: false, unlocked: false), .noEntries)
        XCTAssertEqual(PosiesManualBackupAccess.evaluate(
            recordCount: 0, lockEnabled: true, unlocked: false), .noEntries)
    }

    func testLegacyEncodedExtraFieldsAreStillReadable() {
        let oldJSON = #"{"dose":"5 mg from label","context":"After breakfast","quality":"Okay","recordSource":"manual"}"#
        let source = PosiesEntryExtras.marker + Data(oldJSON.utf8).base64EncodedString()
        let extras = PosiesEntryExtras.read(source)
        XCTAssertEqual(extras.dose, "5 mg from label")
        XCTAssertEqual(extras.context, "After breakfast")
        XCTAssertEqual(extras.quality, "Okay")
        XCTAssertEqual(extras.recordSource, "manual")
        XCTAssertNil(extras.tags)
        XCTAssertNil(extras.recovery)
        XCTAssertNil(extras.startAt)
        XCTAssertNil(extras.endAt)
    }

    func testPremiumTagsAndSleepDatesRoundTripWithoutSchemaMigration() {
        var extras = PosiesEntryExtras(
            dose: "", context: "Quiet room", quality: "Interrupted", recordSource: "manual")
        extras.tags = ["Fatigued", "Palpitations"]
        extras.recovery = "Still tired"
        extras.startAt = Date(timeIntervalSince1970: 1795253400)
        extras.endAt = Date(timeIntervalSince1970: 1795273200)
        let source = extras.stored()
        XCTAssertTrue(source.hasPrefix(PosiesEntryExtras.marker))
        XCTAssertEqual(PosiesEntryExtras.read(source), extras)
    }

    func testOlderPortableBackupSchemaIsUnchanged() throws {
        let oldJSON = #"{"format":"pots-posies-local-backup","schemaVersion":1,"createdAt":1795253400,"records":[]}"#
        let preview = try PosiesDataTransfer.inspect(
            Data(oldJSON.utf8), existingIDs: [], journalUnlocked: true)
        XCTAssertEqual(preview.archive.schemaVersion, 1)
        XCTAssertTrue(preview.archive.records.isEmpty)
    }

    func testNewMetadataUsesOptionalFieldsNotNewCoreDataAttributes() {
        let keys = Set(POTSData.model().entitiesByName["POTSLogEntry"]?.attributesByName.keys.map { $0 } ?? [])
        XCTAssertTrue(keys.contains("source"))
        XCTAssertFalse(keys.contains("tags"))
        XCTAssertFalse(keys.contains("startAt"))
        XCTAssertFalse(keys.contains("endAt"))
    }
}
