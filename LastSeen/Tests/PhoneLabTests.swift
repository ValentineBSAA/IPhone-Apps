import XCTest
@testable import LastSeen

final class PhoneLabTests: XCTestCase {
    func testNotesAndCalendarBrowsingBoundaries() {
        var state=RestoredPhoneBackup.snapshot()
        let date=Date(timeIntervalSince1970:1_800_000_000)
        state.notes=[
            .init(id:"b",title:"Coffee",body:"Later",modifiedAt:date,pinned:false),
            .init(id:"a",title:"Reminder",body:"Coffee",modifiedAt:date,pinned:true),
            .init(id:"c",title:"Other",body:"",modifiedAt:date,pinned:false)]
        XCTAssertEqual(PhoneRecordBrowsing.notes(state,query:" COFFEE ").map(\.id),["a","b"])
        XCTAssertEqual(PhoneRecordBrowsing.notes(state,pinnedOnly:true).map(\.id),["a"])
        XCTAssertEqual(PhoneRecordBrowsing.notes(state).map(\.id),["a","b","c"])
        XCTAssertTrue(PhoneRecordBrowsing.notes(state,query:"no-match-83").isEmpty)
        var calendar=Calendar(identifier:.gregorian)
        calendar.timeZone=TimeZone(secondsFromGMT:0)!
        let start=calendar.startOfDay(for:date)
        let end=calendar.date(byAdding:.day,value:1,to:start)!
        state.events=[
            .init(id:"cross",title:"Crossing",detail:"",startsAt:start.addingTimeInterval(-600),endsAt:start.addingTimeInterval(600)),
            .init(id:"previous",title:"Previous",detail:"",startsAt:start.addingTimeInterval(-1000),endsAt:start),
            .init(id:"next",title:"Next",detail:"",startsAt:end,endsAt:end.addingTimeInterval(600)),
            .init(id:"instant",title:"Instant",detail:"",startsAt:start,endsAt:start),
            .init(id:"invalid",title:"Invalid",detail:"",startsAt:start.addingTimeInterval(60),endsAt:start)]
        XCTAssertEqual(PhoneRecordBrowsing.events(state,on:start,calendar:calendar).map(\.id),["cross","instant"])
        XCTAssertEqual(PhoneRecordBrowsing.events(state,on:end,calendar:calendar).map(\.id),["next"])
        XCTAssertEqual(PhoneRecordBrowsing.upcoming(state,now:start.addingTimeInterval(1)).map(\.id),["cross","next"])
        XCTAssertTrue(PhoneRecordBrowsing.upcoming(state,now:end.addingTimeInterval(601)).isEmpty)
    }

    func testSettingsEffectivePreviewAndDimming() {
        for preference in [false,true] {
            for biometrics in [false,true] {
                for shield in [false,true] {
                    XCTAssertEqual(LumaSettingsPolicy.hidesMessagePreviews(preference:preference,biometrics:biometrics,shield:shield),preference || biometrics || shield)
                }
            }
        }
        XCTAssertEqual(LumaSettingsPolicy.clampedBrightness(-1),0.35)
        XCTAssertEqual(LumaSettingsPolicy.clampedBrightness(2),1)
        XCTAssertEqual(LumaSettingsPolicy.clampedBrightness(.nan),0.9)
        XCTAssertEqual(LumaSettingsPolicy.displayDimming(1),0)
        XCTAssertEqual(LumaSettingsPolicy.displayDimming(0.35),0.4875,accuracy:0.0001)
    }
    @MainActor func testSettingsCheckpointScope() {
        XCTAssertTrue(LumaSaveStore.keys.contains("lastseen.recovery.effects"))
        XCTAssertTrue(LumaSaveStore.keys.contains("lastseen.lab.hideLockPreviews"))
        XCTAssertFalse(LumaSaveStore.keys.contains("lastseen.lab.nativeAlerts"))
        XCTAssertFalse(LumaSaveStore.keys.contains("lastseen.permissions.biometricPrepared"))
        XCTAssertFalse(LumaSaveStore.keys.contains("lastseen.security.appearanceEnrolled"))
    }

    @MainActor
    func testIndependentWorldFilesAndPersistence() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let labURL = root.appendingPathComponent("lab.json")
        let storyURL = root.appendingPathComponent("legacy.json")
        let legacy = PhoneWorldStore(storageURL: storyURL)
        let original = try Data(contentsOf: storyURL)
        let lab = PhoneWorldStore(storageURL: labURL)
        let id = lab.addNote(title: "Lab test", body: "Only in lab")
        lab.markRead(.maya)
        XCTAssertTrue(lab.reply(to: .maya, text: "Coffee sounds good!"))
        let restored = PhoneWorldStore(storageURL: labURL)
        XCTAssertEqual(restored.state.notes.first(where: { $0.id == id })?.body, "Only in lab")
        XCTAssertEqual(restored.state.progress["maya"], 1)
        XCTAssertFalse(legacy.state.notes.contains { $0.id == id })
        XCTAssertEqual(try Data(contentsOf: storyURL), original)
        XCTAssertTrue(restored.state.flags.isEmpty)
    }
}
