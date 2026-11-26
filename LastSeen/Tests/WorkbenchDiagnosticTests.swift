import XCTest
@testable import LastSeen

@MainActor final class WorkbenchDiagnosticTests: XCTestCase {
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
