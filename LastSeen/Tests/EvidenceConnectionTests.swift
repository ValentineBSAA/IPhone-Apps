import XCTest
@testable import LastSeen

@MainActor final class EvidenceConnectionTests:XCTestCase {
    func testConnectionsOnlyUseOpenedRecordsAndRespectCheckpoint() throws {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let first="web:books",second="web:cafe"
        XCTAssertFalse(w.saveEvidenceConnection(first,second,relation:.wording))
        w.visitWebRecord("books")
        XCTAssertFalse(w.saveEvidenceConnection(first,second,relation:.wording))
        XCTAssertFalse(w.saveEvidenceConnection(first,first,relation:.source))
        w.visitWebRecord("cafe")
        XCTAssertTrue(w.saveEvidenceConnection(first,second,relation:.wording))
        XCTAssertTrue(w.saveEvidenceConnection(second,first,relation:.source))
        let entry=try XCTUnwrap(EvidenceConnection.visible(w.state).first)
        XCTAssertEqual(EvidenceConnection.visible(w.state).count,1)
        XCTAssertEqual(entry.relation,.source)
        XCTAssertEqual(entry.records(in:w.state).count,2)
        XCTAssertNotNil(entry.discussion(in:w.state))
        let data=try JSONEncoder().encode(w.state)
        var restored=try JSONDecoder().decode(PhoneWorld.self,from:data)
        XCTAssertEqual(EvidenceConnection.visible(restored),[entry])
        restored.flags.remove("web.visited.cafe")
        XCTAssertTrue(EvidenceConnection.visible(restored).isEmpty)
        XCTAssertNil(entry.discussion(in:restored))
        w.removeEvidenceConnection(entry.id)
        XCTAssertTrue(EvidenceConnection.visible(w.state).isEmpty)
    }
    func testImageAssociationRequiresBothOpenedSources() throws {
        var state=RestoredPhoneBackup.snapshot()
        state.flags.formUnion(["phone-tutorial-finished","web.visited.studio","investigation.contact.received","web.visited.archive",VeilArchive.discovery])
        let w=PhoneWorldStore(initial:state,persistToDisk:false)
        let image="image:Nora_Archive_08",conversation="veil:conversation"
        w.recordVeilObservation("Nora_Archive_08")
        XCTAssertFalse(w.saveEvidenceConnection(image,conversation,relation:.source))
        w.recordVeilCorrespondenceOpened()
        XCTAssertTrue(w.saveEvidenceConnection(image,conversation,relation:.source))
        let entry=try XCTUnwrap(EvidenceConnection.visible(w.state).first)
        XCTAssertTrue(entry.discussion(in:w.state)?.contains("includes this attachment") ?? false)
        state=w.state;state.flags.remove(VeilArchive.discovery)
        XCTAssertNil(entry.discussion(in:state))
    }
}
