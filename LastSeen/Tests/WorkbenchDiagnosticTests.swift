import XCTest
@testable import LastSeen

@MainActor final class WorkbenchDiagnosticTests: XCTestCase {
    func testVerifiedLegacyExercisesAreImmutableAndRequireCurrentAccess() {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let challenge=WorkbenchChallenge.routing
        let correct=Array(challenge.options.prefix(2))
        w.setWorkbenchSelection(correct,for:challenge)
        XCTAssertFalse(w.verifyWorkbench(challenge))
        w.setWorkbenchConnection(true)
        w.setWorkbenchSelection([correct[0],correct[0],"invalid",correct[1]],for:challenge)
        XCTAssertEqual(w.connected.workbenchSelections[challenge.rawValue],correct)
        XCTAssertTrue(w.verifyWorkbench(challenge))
        w.setWorkbenchSelection([],for:challenge)
        XCTAssertEqual(w.connected.workbenchSelections[challenge.rawValue],correct)
        XCTAssertTrue(w.verifyWorkbench(challenge))
        w.setWorkbenchConnection(false)
        XCTAssertFalse(w.verifyWorkbench(challenge))
        w.setWorkbenchConnection(true)
        var revoked=w.state
        revoked.everydayArchiveRevision=nil
        let stale=PhoneWorldStore(initial:revoked,persistToDisk:false)
        XCTAssertFalse(stale.verifyWorkbench(challenge))
        XCTAssertTrue(WorkbenchDiagnosticCatalog.available(stale.state).isEmpty)
    }
    func testPersonalNotebookSearchAndStableOrdering() {
        let date=Date(timeIntervalSince1970:1800000000)
        var a=FieldEntry()
        a.title="Review";a.source="VEIL";a.text="Compare sources";a.pinned=true;a.updated=date
        var b=FieldEntry()
        b.title="Question";b.text="Review later";b.status="Follow up";b.updated=date.addingTimeInterval(10)
        var c=FieldEntry()
        c.title="Other";c.text="Check later";c.status="Resolved";c.updated=date
        let entries=[b,c,a]
        XCTAssertEqual(FieldNotebookBrowsing.visible(entries,query:"  REVIEW ").map(\.id),[a.id,b.id])
        XCTAssertEqual(FieldNotebookBrowsing.visible(entries,pinnedOnly:true).map(\.id),[a.id])
        XCTAssertEqual(FieldNotebookBrowsing.visible(entries,status:"Resolved").map(\.id),[c.id])
        XCTAssertEqual(FieldNotebookBrowsing.visible(entries,query:"veil").map(\.id),[a.id])
        XCTAssertTrue(FieldNotebookBrowsing.visible(entries,query:"not present").isEmpty)
    }

    func testAvailabilityAndSaveRoundTrip() throws {
        let base = PhoneWorldStore(persistToDisk: false)
        base.setWorkbenchConnection(true)
        XCTAssertTrue(WorkbenchDiagnosticCatalog.available(base.state).isEmpty)
        base.updateDiagnostic(.signal, values: [3,2,0])
        XCTAssertNil(base.connected.diagnostics)
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        XCTAssertTrue(WorkbenchDiagnosticCatalog.available(w.state).isEmpty)
        w.setWorkbenchConnection(true)
        XCTAssertEqual(WorkbenchDiagnosticCatalog.available(w.state).count, 3)
        w.updateDiagnostic(.signal, values: [3,4,1])
        w.revealDiagnosticHint(.signal)
        XCTAssertFalse(w.verifyDiagnostic(.signal))
        w.updateDiagnostic(.signal, values: [999])
        XCTAssertEqual(WorkbenchDiagnosticCatalog.progress(.signal,in:w.state).values,[3,4,1])
        let restored = try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        let resumed = PhoneWorldStore(initial:restored,persistToDisk:false)
        XCTAssertEqual(WorkbenchDiagnosticCatalog.progress(.signal,in:resumed.state).hintLevel,1)
        XCTAssertEqual(WorkbenchDiagnosticCatalog.progress(.signal,in:resumed.state).values,[3,4,1])
        resumed.resetDiagnostic(.signal)
        XCTAssertEqual(WorkbenchDiagnosticCatalog.progress(.signal,in:resumed.state).values,WorkbenchDiagnostic.signal.initial)
        XCTAssertEqual(WorkbenchDiagnosticCatalog.progress(.signal,in:resumed.state).hintLevel,1)
        resumed.updateDiagnostic(.signal,values:[3,2,0])
        XCTAssertTrue(resumed.verifyDiagnostic(.signal))
        XCTAssertTrue(resumed.verifyDiagnostic(.signal))
        resumed.resetDiagnostic(.signal)
        XCTAssertEqual(WorkbenchDiagnosticCatalog.verifiedCount(resumed.state),1)
        XCTAssertTrue(resumed.state.flags.isEmpty)
        resumed.setWorkbenchConnection(false)
        XCTAssertFalse(resumed.verifyDiagnostic(.signal))
        XCTAssertEqual(WorkbenchDiagnosticCatalog.verifiedCount(resumed.state),1)
    }
    func testAppliedReviewRequiresVisitedSourceAndVerifiedExercise() throws {
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false)
        XCTAssertTrue(WorkbenchAppliedReview.visible(w.state).isEmpty)
        w.setWorkbenchConnection(true)
        w.updateDiagnostic(.configuration, values: [0,1,0])
        XCTAssertTrue(w.verifyDiagnostic(.configuration))
        XCTAssertFalse(w.completeAppliedReview(.configuration, choice: 1))
        w.visitWebRecord("studio-news")
        XCTAssertTrue(WorkbenchAppliedReview.visible(w.state).contains(.configuration))
        XCTAssertFalse(WorkbenchAppliedReview.visible(w.state).contains(.sequence))
        let flags = w.state.flags
        XCTAssertFalse(w.completeAppliedReview(.configuration, choice: 0))
        XCTAssertTrue(w.completeAppliedReview(.configuration, choice: 1))
        XCTAssertTrue(w.completeAppliedReview(.configuration, choice: 1))
        XCTAssertEqual(w.connected.workbenchAppliedReviews, Set(["configuration"]))
        XCTAssertEqual(w.state.flags, flags)
        let restored = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(w.state))
        let resumed = PhoneWorldStore(initial: restored, persistToDisk: false)
        XCTAssertTrue(WorkbenchAppliedReview.configuration.completed(in: resumed.state))
        resumed.setWorkbenchConnection(false)
        XCTAssertTrue(WorkbenchAppliedReview.visible(resumed.state).isEmpty)
        XCTAssertFalse(resumed.completeAppliedReview(.configuration, choice: 1))
        XCTAssertTrue(WorkbenchAppliedReview.configuration.completed(in: resumed.state))
    }

    func testValidatorsAndMultipleValidOrders() {
        XCTAssertTrue(WorkbenchDiagnostic.configuration.valid([0,1,0]))
        XCTAssertFalse(WorkbenchDiagnostic.configuration.valid([1,1,0]))
        XCTAssertTrue(WorkbenchDiagnostic.chronology.valid([0,1,2,3]))
        XCTAssertTrue(WorkbenchDiagnostic.chronology.valid([0,2,1,3]))
        XCTAssertFalse(WorkbenchDiagnostic.chronology.valid([1,0,2,3]))
        XCTAssertFalse(WorkbenchDiagnostic.chronology.valid([0,1,1,3]))
        XCTAssertFalse(WorkbenchDiagnostic.signal.valid([3,2,1]))
        for challenge in WorkbenchDiagnostic.allCases {
            XCTAssertTrue(challenge.accepts(challenge.initial))
            XCTAssertFalse(challenge.valid(challenge.initial))
        }
    }
}
