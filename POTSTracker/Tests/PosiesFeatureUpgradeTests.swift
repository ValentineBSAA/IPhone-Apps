import XCTest
import CoreData
@testable import POTSTracker

final class PosiesFeatureUpgradeTests: XCTestCase {
    private func container() throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "POTSData", managedObjectModel: POTSData.model())
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        var failure: Error?
        container.loadPersistentStores { _, error in failure = error }
        if let failure { throw failure }
        return container
    }

    @discardableResult
    private func insert(_ context: NSManagedObjectContext, type: LogCategory,
                        id: UUID = UUID(), title: String = "Example",
                        date: Date = Date()) throws -> POTSLogEntry {
        let record = POTSLogEntry(context: context)
        record.id = id
        record.recordedAt = date
        record.category = type.rawValue
        record.title = title
        record.severity = -1
        record.firstValue = type == .hydration ? 250 : 0
        record.secondValue = type == .hydration ? 100 : 0
        record.posture = type == .medications ? "Skipped" : ""
        record.notes = "A test note, with comma and \"quotes\""
        record.timezoneID = "America/Phoenix"
        record.source = PosiesEntryExtras(dose: type == .medications ? "as labeled" : "").stored()
        try POTSData.save(context)
        return record
    }

    private func all(_ context: NSManagedObjectContext) throws -> [POTSLogEntry] {
        try context.fetch(NSFetchRequest<POTSLogEntry>(entityName: POTSData.entityName))
    }

    func testAllTwelveApprovedFeaturesNowHaveAccessibleRoutes() {
        for id in ["hydration", "medications", "sleep", "posture", "calendar", "reports", "reminders"] {
            let feature = TrackerFeature.all.first { $0.id == id }
            XCTAssertNotNil(feature)
            XCTAssertEqual(feature?.build, 1, "\(id) should no longer be shown as planned")
        }
        XCTAssertEqual(TrackerFeature.all.count, 12)
    }

    func testExtendedCategoriesPreserveCoreDataModelAndSavedDetail() throws {
        let context = try container().viewContext
        _ = try insert(context, type: .hydration, title: "Water")
        _ = try insert(context, type: .medications, title: "Sample prescription")
        XCTAssertEqual(try all(context).count, 2)
        let snap = RecordSnapshot.snapshots(of: try all(context))
        XCTAssertTrue(snap.contains { $0.category == "hydration" && $0.detail.contains("250 mL") })
        XCTAssertTrue(snap.contains { $0.category == "medications" && $0.detail.contains("Skipped") })
        XCTAssertTrue(Set(LogCategory.allCases.map(\.rawValue)).contains("posture"))
    }

    func testMetadataRoundTripPreservesDoseAndContext() {
        let extras = PosiesEntryExtras(dose: "as written on label",
                                       context: "Observed after lunch",
                                       quality: "Interrupted", recordSource: "manual")
        XCTAssertEqual(PosiesEntryExtras.read(extras.stored()), extras)
        XCTAssertEqual(PosiesEntryExtras.read("manual"), PosiesEntryExtras())
    }

    func testJSONBackupRoundTripPreservesIDsTimestampNotesAndUnits() throws {
        let context = try container().viewContext
        let fixed = Date(timeIntervalSince1970: 1795230788.123456)
        let record = try insert(context, type: .hydration, title: "Electrolyte drink", date: fixed)
        record.notes = "Sodium was explicitly 100 mg"
        try POTSData.save(context)
        let original = PosiesPortableRecord(record)
        let raw = try PosiesDataTransfer.encodeBackup([original])
        let preview = try PosiesDataTransfer.inspect(raw, existingIDs: [], journalUnlocked: true)
        XCTAssertEqual(preview.additions, 1)
        let rebuilt = try XCTUnwrap(preview.archive.records.first)
        XCTAssertEqual(rebuilt.id, original.id)
        XCTAssertEqual(rebuilt.firstValue, 250)
        XCTAssertEqual(rebuilt.secondValue, 100)
        XCTAssertEqual(rebuilt.notes, record.notes)
        XCTAssertEqual(rebuilt.timezoneID, "America/Phoenix")
        XCTAssertEqual(rebuilt.recordedAt.timeIntervalSince1970,
                       original.recordedAt.timeIntervalSince1970, accuracy: 0.001)
    }

    func testImportPreviewRejectsDuplicateIDsAndUnknownCategories() throws {
        let id = UUID()
        let context = try container().viewContext
        let record = PosiesPortableRecord(try insert(context, type: .sleep, id: id))
        let duplicateArchive = try PosiesDataTransfer.encodeBackup([record, record])
        XCTAssertThrowsError(try PosiesDataTransfer.inspect(
            duplicateArchive, existingIDs: [], journalUnlocked: true
        ))
        var corrupt = record
        corrupt.category = "unrecognized"
        let bad = try PosiesDataTransfer.encodeBackup([corrupt])
        XCTAssertThrowsError(try PosiesDataTransfer.inspect(bad, existingIDs: [], journalUnlocked: true))
    }

    func testRestoreSkipsExistingIDsAndNeverOverwritesUserData() throws {
        let context = try container().viewContext
        let existing = try insert(context, type: .symptom, title: "Original")
        let imported = PosiesPortableRecord(existing)
        var new = imported
        new.id = UUID()
        new.title = "Second record"
        let raw = try PosiesDataTransfer.encodeBackup([imported, new])
        let preview = try PosiesDataTransfer.inspect(raw, existingIDs: [existing.id],
                                                      journalUnlocked: true)
        XCTAssertEqual(preview.existing, 1)
        XCTAssertEqual(preview.additions, 1)
        XCTAssertEqual(try PosiesDataTransfer.restore(preview, context: context), 1)
        XCTAssertEqual(try all(context).count, 2)
        XCTAssertEqual(existing.title, "Original")
        XCTAssertEqual(try PosiesDataTransfer.restore(preview, context: context), 0)
    }

    func testLockedJournalArchiveRequiresAuthenticationForImport() throws {
        let context = try container().viewContext
        let journal = PosiesPortableRecord(try insert(context, type: .journal))
        let raw = try PosiesDataTransfer.encodeBackup([journal])
        XCTAssertThrowsError(try PosiesDataTransfer.inspect(
            raw, existingIDs: [], journalUnlocked: false
        ))
    }

    func testCSVQuotesAndSpreadsheetFormulaSanitization() throws {
        let context = try container().viewContext
        let record = try insert(context, type: .symptom, title: "=Injected", date: Date())
        let csv = PosiesDataTransfer.csv([PosiesPortableRecord(record)], includeNotes: true)
        XCTAssertTrue(csv.contains("\"'=Injected\""))
        XCTAssertTrue(csv.contains("\"\"quotes\"\""))
        XCTAssertTrue(csv.contains("America/Phoenix"))
        XCTAssertTrue(csv.contains("severity_0_to_10"))
    }

    func testPDFCreatesOfflineBytesWithRealRecords() throws {
        let context = try container().viewContext
        let record = try insert(context, type: .heartRate)
        record.firstValue = 78
        let bytes = PosiesDataTransfer.pdf([PosiesPortableRecord(record)], includeNotes: true)
        XCTAssertGreaterThan(bytes.count, 500)
        XCTAssertTrue(bytes.starts(with: Data("%PDF".utf8)))
    }

    func test365DayRangeAndLeapYearUseCalendarDays() {
        let cal = Calendar(identifier: .gregorian)
        let ref = cal.date(from: DateComponents(year: 2028, month: 3, day: 1, hour: 12))!
        let leap = cal.date(from: DateComponents(year: 2028, month: 2, day: 29, hour: 12))!
        let earlier = cal.date(byAdding: .day, value: -364, to: ref)!
        let tooEarly = cal.date(byAdding: .day, value: -366, to: ref)!
        XCTAssertTrue(PosiesDateRange.year.includes(leap, reference: ref, calendar: cal))
        XCTAssertTrue(PosiesDateRange.year.includes(earlier, reference: ref, calendar: cal))
        XCTAssertFalse(PosiesDateRange.year.includes(tooEarly, reference: ref, calendar: cal))
    }

    func testQuietHoursOvernightAndNoQuietHours() {
        XCTAssertTrue(PosiesReminder.withinQuietHours(hour: 23, start: 22, end: 8))
        XCTAssertTrue(PosiesReminder.withinQuietHours(hour: 6, start: 22, end: 8))
        XCTAssertFalse(PosiesReminder.withinQuietHours(hour: 10, start: 22, end: 8))
        XCTAssertFalse(PosiesReminder.withinQuietHours(hour: 23, start: 8, end: 8))
        XCTAssertTrue(PosiesReminder.withinQuietHours(hour: 13, start: 12, end: 15))
    }
}
