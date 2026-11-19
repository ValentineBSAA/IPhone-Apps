import XCTest
import CoreData
@testable import POTSTracker

final class CheckInFormatTests: XCTestCase {
    func testPreviousBuildCheckInsKeepTheirFeelingWithoutDataMigration() {
        for feeling in CheckInFormat.feelings {
            XCTAssertEqual(CheckInFormat.feeling(title: feeling, posture: ""), feeling)
            XCTAssertEqual(CheckInFormat.shortDetail(feeling: feeling, notes: ""), "Check-in · \(feeling)")
        }
    }

    func testCustomHeadingKeepsSelectedFeelingSeparate() {
        XCTAssertEqual(CheckInFormat.feeling(title: "A difficult afternoon", posture: "Worse"), "Worse")
        XCTAssertEqual(CheckInFormat.shortDetail(feeling: "Worse", notes: "  After standing in the kitchen  "),
                       "Worse · After standing in the kitchen")
        XCTAssertFalse(CheckInFormat.titleWasSuggested("A difficult afternoon"))
    }

    func testSuggestedTitleCanChangeButCustomTitleIsNotOverwritten() {
        XCTAssertEqual(CheckInFormat.defaultTitle(for: "Better"), "Feeling better")
        XCTAssertEqual(CheckInFormat.defaultTitle(for: "Not sure"), "Not sure how I feel")
        XCTAssertTrue(CheckInFormat.titleWasSuggested("Feeling better"))
        XCTAssertTrue(CheckInFormat.titleWasSuggested("Worse"))
        XCTAssertFalse(CheckInFormat.titleWasSuggested("My own title"))
        XCTAssertNil(CheckInFormat.feeling(title: "My own title", posture: ""))
    }

    func testSavedCheckInWithTitleNotesAndTimeRendersInHistory() throws {
        let container = NSPersistentContainer(name: "POTSData", managedObjectModel: POTSData.model())
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        var openError: Error?
        container.loadPersistentStores { _, error in openError = error }
        if let openError { throw openError }

        let context = container.viewContext
        let record = POTSLogEntry(context: context)
        record.id = UUID()
        record.recordedAt = Date()
        record.category = LogCategory.checkIn.rawValue
        record.title = "After lunch"
        record.posture = "Usual"
        record.notes = "Had to sit down."
        record.severity = -1
        record.firstValue = 0
        record.secondValue = 0
        record.timezoneID = TimeZone.current.identifier
        record.source = "manual"
        try POTSData.save(context)

        let result = RecordSnapshot(record)
        XCTAssertEqual(result.title, "After lunch")
        XCTAssertEqual(result.categoryLabel, "Check-ins")
        XCTAssertEqual(result.detail, "Usual · Had to sit down.")
        XCTAssertEqual(CheckInFormat.feeling(title: result.title, posture: result.posture), "Usual")
    }
}