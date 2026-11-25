import XCTest
@testable import LastSeen
@MainActor final class UtilityProgressTests: XCTestCase {
    func testSequentialGatesAndSafeCatalog() {
        let w = PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        XCTAssertNil(LumaUtility.next(in:w.state.flags))
        XCTAssertFalse(w.earnUtility(.pocketclipboard,answer:LumaUtility.pocketclipboard.correct))
        XCTAssertTrue(w.completeRecoveryCircuit(verified:RecoveryCircuit.stages))
        for tool in LumaUtility.allCases {
            XCTAssertEqual(LumaUtility.next(in:w.state.flags),tool)
            XCTAssertFalse(RelayCatalog.available(tool.rawValue,flags:w.state.flags))
            XCTAssertFalse(w.earnUtility(tool,answer:"invalid"))
            XCTAssertTrue(w.earnUtility(tool,answer:tool.correct))
            XCTAssertTrue(RelayCatalog.available(tool.rawValue,flags:w.state.flags))
            XCTAssertFalse(w.earnUtility(tool,answer:tool.correct))
        }
        XCTAssertNil(LumaUtility.next(in:w.state.flags))
    }
    func testSelectionsAreLocalAndBoundToPublicRecords() {
        let w = PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let invalid = LumaSnippet(id:"hidden",title:"Hidden",source:"Files",text:"not public")
        w.storeSnippet(invalid)
        XCTAssertTrue((w.state.utilitySnippets ?? []).isEmpty)
        let record = LumaRecords.publicRecords(w.state).first!
        w.storeSnippet(record); w.pinSnippet(record.id)
        XCTAssertEqual(LumaRecords.visibleSaved(w.state),[record])
        XCTAssertEqual(w.state.pinnedSnippet,record.id)
        w.removeSnippet(record.id)
        XCTAssertNil(w.state.pinnedSnippet)
    }
}
