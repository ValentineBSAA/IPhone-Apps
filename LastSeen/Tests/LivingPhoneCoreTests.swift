import XCTest
@testable import LastSeen

@MainActor
final class LivingPhoneCoreTests: XCTestCase {
    func testTutorialIsPersistentIdempotentAndActionDriven() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("world.json")
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        try RestoredPhoneBackup.restore(to: url, now: now)
        let world = PhoneWorldStore(storageURL: url)
        world.startPhoneTutorial(now: now)
        world.startPhoneTutorial(now: now)
        XCTAssertTrue(world.tutorialStarted)
        XCTAssertEqual(world.messages(.maya).filter { $0.id == "phone-tutorial-contact" }.count, 1)
        XCTAssertEqual(world.state.notes.filter { $0.id == PhoneWorldStore.tutorialNoteID }.count, 1)
        world.removeNote(PhoneWorldStore.tutorialNoteID)
        world.updateNote(PhoneWorldStore.tutorialNoteID, title: "Deleted", body: "")
        XCTAssertEqual(world.state.notes.first { $0.id == PhoneWorldStore.tutorialNoteID }?.title, PhoneWorldStore.tutorialNoteTitle)
        XCTAssertFalse(world.reply(to: .maya, text: "unrecognized reply", now: now))
        XCTAssertTrue(world.reply(to: .maya, text: world.tutorialChoices[0], now: now))
        XCTAssertTrue(world.messages(.maya).contains { $0.id == "phone-tutorial-notes" })
        XCTAssertFalse(world.messages(.maya).contains { $0.id == "phone-tutorial-files" })
        world.recordTutorialVisit("reservation", now: now)
        world.recordTutorialVisit("note", now: now)
        XCTAssertTrue(world.messages(.maya).contains { $0.id == "phone-tutorial-files" })
        XCTAssertFalse(world.messages(.maya).contains { $0.id == "phone-tutorial-journal" })
        world.recordTutorialVisit("desk", now: now)
        XCTAssertTrue(world.messages(.maya).contains { $0.id == "phone-tutorial-journal" })
        XCTAssertFalse(world.tutorialFinished)
        let reopened = PhoneWorldStore(storageURL: url)
        reopened.startPhoneTutorial(now: now)
        reopened.recordTutorialVisit("journal", now: now)
        reopened.recordTutorialVisit("journal", now: now)
        XCTAssertTrue(reopened.tutorialFinished)
        XCTAssertEqual(reopened.messages(.maya).filter { $0.id == "phone-tutorial-finish" }.count, 1)
        XCTAssertTrue(reopened.choices(.maya).isEmpty)
        XCTAssertEqual(reopened.state.events.count, world.state.events.count)
        XCTAssertTrue(PhoneWorldStore(storageURL: url).tutorialFinished)
    }

    func testNotificationsExcludeOutgoingAndRespectReadState() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let world = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        world.startPhoneTutorial(now: now)
        let alerts = PhoneAlertCatalog.alerts(in: world.state, unreadOnly: true)
        XCTAssertEqual(alerts.first?.message.id, "phone-tutorial-contact")
        XCTAssertTrue(alerts.allSatisfy { !$0.message.fromPlayer && !$0.message.read })
        world.markRead(.maya)
        XCTAssertFalse(PhoneAlertCatalog.alerts(in: world.state, unreadOnly: true).contains { $0.neighbor == .maya })
        XCTAssertTrue(PhoneAlertCatalog.alerts(in: world.state, unreadOnly: false).contains { $0.neighbor == .maya })
        XCTAssertTrue(world.reply(to: .maya, text: world.tutorialChoices[0], now: now))
        XCTAssertEqual(PhoneAlertCatalog.alerts(in: world.state, unreadOnly: true).first?.message.id, "phone-tutorial-notes")
    }

    func testPublicSearchDoesNotExposeProtectedRecordsOrCode() {
        let world = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        world.startPhoneTutorial()
        func search(_ q: String) -> [PhoneSearchResult] {
            PhonePublicSearch.results(query: q, world: world.state, documents: PhonePublicFiles.documents)
        }
        XCTAssertTrue(search("Maya").contains { $0.destination == "Contacts" })
        XCTAssertTrue(search("Before I forget").contains { $0.detail == PhoneWorldStore.tutorialNoteID })
        XCTAssertTrue(search("reservation").contains { $0.destination == "Files" && $0.detail == "Book reservation" })
        XCTAssertTrue(search("coffee").contains { $0.destination == "Calendar" })
        XCTAssertTrue(search(OwnerSecurityPolicy.fixtureCode).isEmpty)
        XCTAssertTrue(search("Personal journal").isEmpty)
        XCTAssertTrue(search("   ").isEmpty)
    }
}
