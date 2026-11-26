import XCTest
@testable import LastSeen

@MainActor final class Build32IntegrationAuditTests: XCTestCase {
    func testBannerQueueOrdersAndSkipsDismissedActivity() throws {
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        w.recordTimerActivity(end: 100)
        w.recordTimerActivity(end: 200)
        w.recordTimerActivity(end: 300)
        let notices = LumaActivityCatalog.newEntries(w.state, previous: [])
        XCTAssertEqual(notices.count, 3)
        var queue = LumaActivityBannerQueue()
        queue.enqueue(notices, showing: nil)
        queue.enqueue(notices, showing: nil)
        XCTAssertEqual(queue.ids.count, 3)
        w.dismissActivity(notices[0].id)
        XCTAssertEqual(queue.next(in: w.state)?.id, notices[1].id)
        XCTAssertEqual(queue.next(in: w.state)?.id, notices[2].id)
        XCTAssertNil(queue.next(in: w.state))
        queue.enqueue(notices, showing: notices[1].id)
        queue.clear()
        XCTAssertTrue(queue.ids.isEmpty)
    }
    func testActivityPresentationRevalidatesAfterPreemptionAndDismissal() throws {
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        w.recordTimerActivity(end: 100)
        let notice = try XCTUnwrap(LumaActivityCatalog.visible(w.state).first { $0.kind == .timer })
        XCTAssertEqual(LumaActivityCatalog.presentedID(notice, in: w.state, unobstructed: true), notice.id)
        XCTAssertNil(LumaActivityCatalog.presentedID(notice, in: w.state, unobstructed: false))
        XCTAssertEqual(LumaActivityCatalog.presentedID(notice, in: w.state, unobstructed: true), notice.id)
        w.dismissActivity(notice.id)
        XCTAssertNil(LumaActivityCatalog.presentedID(notice, in: w.state, unobstructed: true))
        XCTAssertNil(LumaActivityCatalog.presentedID(nil, in: w.state, unobstructed: true))
    }
    func testTimerCompletionAndCheckpointDeadlinePolicy() {
        XCTAssertFalse(LumaTimerCompletion.due(end: 100, delivered: 0, now: 99))
        XCTAssertTrue(LumaTimerCompletion.due(end: 100, delivered: 0, now: 100))
        XCTAssertFalse(LumaTimerCompletion.due(end: 100, delivered: 100, now: 101))
        XCTAssertFalse(LumaTimerCompletion.due(end: 0, delivered: 0, now: 101))
        XCTAssertFalse(LumaTimerCompletion.due(end: .infinity, delivered: 0, now: 101))
        XCTAssertEqual(LumaTimerCompletion.restoredDeadline(100, savedAt: 110, now: 500), 100)
        XCTAssertEqual(LumaTimerCompletion.restoredDeadline(130, savedAt: 110, now: 500), 520)
    }

    func testCheckpointRebasesPendingHavenEventsWithoutChangingDeliveredHistory() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite="haven-checkpoint-"+UUID().uuidString
        let defaults=try XCTUnwrap(UserDefaults(suiteName:suite))
        defer {defaults.removePersistentDomain(forName:suite);try? FileManager.default.removeItem(at:root)}
        let saved=Date(timeIntervalSince1970:1800000000)
        let later=saved.addingTimeInterval(1000)
        let pending=HavenWatchEvent(id:HavenWatchEvents.followupID,due:saved.addingTimeInterval(25))
        let delivered=HavenWatchEvent(id:HavenWatchEvents.archiveID,due:saved.addingTimeInterval(-10),delivered:true)
        var state=RestoredPhoneBackup.snapshot(now:saved)
        var connected=state.connectedWorld ?? LumaConnectedState()
        connected.havenEvent=delivered;connected.havenFollowupEvent=pending
        state.connectedWorld=connected
        let w=PhoneWorldStore(initial:state,persistToDisk:false)
        let saves=LumaSaveStore(root:root,defaults:defaults)
        XCTAssertTrue(saves.write("manual-1",world:w.state,now:saved))
        XCTAssertTrue(saves.restore("manual-1",into:w,now:later))
        XCTAssertEqual(w.connected.havenEvent,delivered)
        XCTAssertEqual(w.connected.havenFollowupEvent?.due,later.addingTimeInterval(25))
        XCTAssertEqual(w.connected.havenFollowupEvent?.delivered,false)
        XCTAssertNil(LumaSaveStore.rebasedEvent(nil,by:1000))
        XCTAssertEqual(LumaSaveStore.rebasedEvent(pending,by:-10)?.due,saved.addingTimeInterval(15))
    }

    func testCheckpointPreservesCompletedTimerIdentityAndRunningRemainingTime() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "timer-checkpoint-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: root) }
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        let saves = LumaSaveStore(root: root, defaults: defaults)
        let saved = Date(timeIntervalSince1970: 1000)
        let later = Date(timeIntervalSince1970: 2000)
        let endKey = "lastseen.lab.timerEnd", deliveredKey = "lastseen.lab.timerFeedbackDelivered"
        defaults.set(990.0, forKey: endKey)
        w.recordTimerActivity(end: 990)
        w.dismissActivity("timer-" + String(990.0))
        XCTAssertTrue(saves.write("manual-1", world: w.state, now: saved))
        defaults.set(1040.0, forKey: endKey)
        XCTAssertTrue(saves.write("manual-2", world: w.state, now: saved))
        defaults.set(1040.0, forKey: deliveredKey)
        XCTAssertTrue(saves.restore("manual-1", into: w, now: later))
        XCTAssertEqual(defaults.double(forKey: endKey), 990)
        XCTAssertEqual(defaults.double(forKey: deliveredKey), 990)
        XCTAssertTrue(LumaActivityCatalog.visible(w.state).isEmpty)
        XCTAssertTrue(saves.restore("manual-2", into: w, now: later))
        XCTAssertEqual(defaults.double(forKey: endKey), 2040)
        XCTAssertEqual(defaults.double(forKey: deliveredKey), 0)
    }

    func testReviewRequiresVisitedSourceAndActiveRecovery() throws {
        let asset=try XCTUnwrap(LumaWebCatalog.page("archive-records")?.images.first)
        var flags:Set<String>=["phone-tutorial-finished","web.visited.studio","web.visited.archive","web.visited.archive-review","web.visited.studio-news","web.inspected."+asset]
        XCTAssertFalse(LumaWebCatalog.isReviewReady(flags))
        flags.insert("web.visited.archive-records")
        XCTAssertTrue(LumaWebCatalog.isReviewReady(flags))
        for missing in ["phone-tutorial-finished","web.visited.studio","web.visited.archive","web.visited.archive-records","web.visited.archive-review","web.visited.studio-news","web.inspected."+asset] {
            XCTAssertFalse(LumaWebCatalog.isReviewReady(flags.subtracting([missing])),missing)
        }
    }

    func testLatePageRejectsMissingPrerequisite() {
        var flags: Set<String> = ["phone-tutorial-finished","web.visited.studio","investigation.chapter2.reviewed","web.visited.archive-ledger","investigation.chapter2.ledgerAcknowledged",InvestigationReview.requested,InvestigationReview.read,InvestigationReview.finished,"web.visited."+InvestigationReview.pageID,"web.visited."+InvestigationResolution.indexID,"web.visited."+InvestigationResolution.noteID,InvestigationResolution.requested,InvestigationResolution.read]
        XCTAssertTrue(LumaWebCatalog.visible(flags).contains { $0.id == InvestigationResolution.conclusionID })
        flags.remove("phone-tutorial-finished")
        XCTAssertFalse(LumaWebCatalog.visible(flags).contains { $0.id == InvestigationResolution.conclusionID || $0.id == InvestigationReview.pageID })
        flags.insert("phone-tutorial-finished")
        flags.remove(InvestigationResolution.read)
        XCTAssertFalse(LumaWebCatalog.visible(flags).contains { $0.id == InvestigationResolution.conclusionID })
    }
}
