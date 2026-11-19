import XCTest
import CoreData
@testable import POTSTracker

final class RecordHistoryTests: XCTestCase {
    private func memoryContainer() throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "POTSData", managedObjectModel: POTSData.model())
        let store = NSPersistentStoreDescription()
        store.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [store]
        var failure: Error?
        container.loadPersistentStores { _, error in failure = error }
        if let failure { throw failure }
        return container
    }

    private func add(_ context: NSManagedObjectContext, type: String = "checkIn",
                     title: String = "Better", date: Date = Date()) throws -> POTSLogEntry {
        let entry = POTSLogEntry(context: context)
        entry.id = UUID()
        entry.category = type
        entry.recordedAt = date
        entry.title = title
        entry.severity = -1
        entry.firstValue = 0
        entry.secondValue = 0
        entry.posture = ""
        entry.notes = ""
        entry.timezoneID = TimeZone.current.identifier
        entry.source = "manual"
        try POTSData.save(context)
        return entry
    }

    private func all(_ context: NSManagedObjectContext) throws -> [POTSLogEntry] {
        let request = NSFetchRequest<POTSLogEntry>(entityName: "POTSLogEntry")
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        return try context.fetch(request)
    }

    func testDeleteLastEntryLeavesEmptyHistoryAndRetainedSnapshotSafe() throws {
        let context = try memoryContainer().viewContext
        let saved = try add(context, title: "Better")
        let id = saved.objectID
        let frozen = RecordSnapshot(saved)

        XCTAssertEqual(RecordDayGroup.group(RecordSnapshot.snapshots(of: try all(context))).count, 1)
        XCTAssertTrue(try RecordStore.delete(id, in: context))
        XCTAssertTrue(try all(context).isEmpty)
        XCTAssertEqual(RecordDayGroup.group(RecordSnapshot.snapshots(of: try all(context))).count, 0)

        // This immutable snapshot can still render after Core Data invalidates the object.
        XCTAssertEqual(frozen.title, "Better")
        XCTAssertEqual(frozen.categoryLabel, "Check-ins")
        XCTAssertEqual(frozen.detail, "Check-in · Better")
    }

    func testFourCheckInsCollapseIntoOneDayAndCategoryWithoutLosingEntries() throws {
        let context = try memoryContainer().viewContext
        let fixed = Date(timeIntervalSince1970: 1_795_107_600)
        for value in ["Better", "Better", "Usual", "Worse"] {
            _ = try add(context, title: value, date: fixed)
        }
        let tree = RecordDayGroup.group(RecordSnapshot.snapshots(of: try all(context)))
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].records.count, 4)
        XCTAssertEqual(tree[0].categories.count, 1)
        XCTAssertEqual(tree[0].categories[0].label, "Check-ins")
        XCTAssertEqual(tree[0].categories[0].records.count, 4)

        let ids = try all(context).map(\.objectID)
        for (index, id) in ids.enumerated() {
            XCTAssertTrue(try RecordStore.delete(id, in: context))
            XCTAssertEqual(try all(context).count, ids.count - index - 1)
        }
        XCTAssertTrue(RecordDayGroup.group(RecordSnapshot.snapshots(of: try all(context))).isEmpty)
    }

    func testDifferentDaysAndCategoriesBecomeSeparateExpandableBranches() throws {
        let context = try memoryContainer().viewContext
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: 9))!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        _ = try add(context, type: "checkIn", title: "Better", date: today)
        _ = try add(context, type: "heartRate", title: "Heart Rate", date: today)
        _ = try add(context, type: "journal", title: "Note", date: yesterday)

        let days = RecordDayGroup.group(RecordSnapshot.snapshots(of: try all(context)), calendar: calendar)
        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days[0].categories.count, 2)
        XCTAssertEqual(days[0].records.count, 2)
        XCTAssertEqual(days[1].categories.count, 1)
        XCTAssertEqual(days[1].records.count, 1)
    }

    func testDeleteWholeDateKeepsAnotherDate() throws {
        let context = try memoryContainer().viewContext
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let previous = calendar.date(byAdding: .day, value: -1, to: today)!
        for title in ["Better", "Worse", "Usual"] {
            _ = try add(context, title: title, date: today.addingTimeInterval(3600))
        }
        _ = try add(context, title: "Yesterday", date: previous.addingTimeInterval(3600))

        let groups = RecordDayGroup.group(RecordSnapshot.snapshots(of: try all(context)))
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].records.count, 3)
        let deleted = try RecordStore.delete(groups[0].records.map(\.id), in: context)
        XCTAssertEqual(deleted, 3)
        let remaining = try all(context)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].title, "Yesterday")
    }

    func testDeleteOneCategoryKeepsOtherCategoryAndDay() throws {
        let context = try memoryContainer().viewContext
        let now = Date()
        for _ in 0..<4 {
            _ = try add(context, type: "checkIn", title: "Feeling", date: now)
        }
        _ = try add(context, type: "heartRate", title: "Heart Rate", date: now)

        let day = try XCTUnwrap(RecordDayGroup.group(RecordSnapshot.snapshots(of: all(context))).first)
        let group = try XCTUnwrap(day.categories.first(where: { $0.category == "checkIn" }))
        let removed = try RecordStore.delete(group.records.map(\.id), in: context)
        XCTAssertEqual(removed, 4)
        let remaining = try all(context)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].category, "heartRate")
    }

    func testClearAllHistoryRemovesAllEntriesAcrossDatesAndCategories() throws {
        let context = try memoryContainer().viewContext
        let old = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        _ = try add(context, type: "checkIn", title: "Better", date: Date())
        _ = try add(context, type: "journal", title: "Old note", date: old)
        _ = try add(context, type: "symptom", title: "Dizziness", date: Date())
        let ids = try all(context).map(\.objectID)
        XCTAssertEqual(try RecordStore.delete(ids, in: context), 3)
        XCTAssertTrue(try all(context).isEmpty)
        XCTAssertEqual(try RecordStore.delete(ids, in: context), 0)
        XCTAssertTrue(RecordDayGroup.group(RecordSnapshot.snapshots(of: try all(context))).isEmpty)
    }

    func testBulkDeleteOnlyDeletesEachIDOnce() throws {
        let context = try memoryContainer().viewContext
        let entry = try add(context, title: "Once")
        XCTAssertEqual(try RecordStore.delete([entry.objectID, entry.objectID], in: context), 1)
        XCTAssertTrue(try all(context).isEmpty)
    }

}