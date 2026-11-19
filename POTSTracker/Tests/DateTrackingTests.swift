import XCTest
import CoreData
@testable import POTSTracker

final class DateTrackingTests: XCTestCase {
    func testLastSevenDaysIncludesReferenceDay() {
        let calendar = Calendar(identifier: .gregorian)
        let reference = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: 14))!
        let days = DateTracking.lastSevenDays(reference: reference, calendar: calendar)
        XCTAssertEqual(days.count, 7)
        XCTAssertTrue(calendar.isDate(days.last!, inSameDayAs: reference))
        XCTAssertEqual(calendar.dateComponents([.day], from: days.first!, to: days.last!).day, 6)
    }

    func testLeapDayExistsWhenInSevenDayRange() {
        let calendar = Calendar(identifier: .gregorian)
        let reference = calendar.date(from: DateComponents(year: 2028, month: 3, day: 2, hour: 10))!
        let days = DateTracking.lastSevenDays(reference: reference, calendar: calendar)
        XCTAssertTrue(days.contains { calendar.component(.month, from: $0) == 2 && calendar.component(.day, from: $0) == 29 })
    }

    func testMultipleEntriesStayIndependent() throws {
        let container = NSPersistentContainer(name: "POTSData", managedObjectModel: POTSData.model())
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        var storeError: Error?
        container.loadPersistentStores { _, error in storeError = error }
        XCTAssertNil(storeError)
        let context = container.viewContext
        for (number, category) in [("First", "symptom"), ("Second", "heartRate")] {
            let entry = POTSLogEntry(context: context)
            entry.id = UUID()
            entry.recordedAt = Date()
            entry.category = category
            entry.title = number
            entry.severity = -1
            entry.firstValue = 0
            entry.secondValue = 0
            entry.notes = ""
            entry.posture = ""
            entry.source = "manual"
            entry.timezoneID = TimeZone.current.identifier
        }
        try POTSData.save(context)
        let fetch = NSFetchRequest<POTSLogEntry>(entityName: "POTSLogEntry")
        let found = try context.fetch(fetch)
        XCTAssertEqual(found.count, 2)
        XCTAssertEqual(Set(found.map(\.title)), Set(["First", "Second"]))
    }
}
