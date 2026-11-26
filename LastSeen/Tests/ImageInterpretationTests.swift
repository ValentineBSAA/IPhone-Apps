import XCTest
@testable import LastSeen

@MainActor final class ImageInterpretationTests:XCTestCase {
    func testDisplayPolicyAndAdditionalFinding() {
        var state=RestoredPhoneBackup.snapshot()
        let asset="Nora_Archive_09"
        state.flags.formUnion(["phone-tutorial-finished","investigation.contact.received","web.visited.archive",VeilArchive.discovery])
        let w=PhoneWorldStore(initial:state,persistToDisk:false)
        w.recordVeilObservation(asset)
        XCTAssertTrue(w.completeRecoveredImageAnalysis(asset,source:2,limit:0))
        XCTAssertEqual(ImageInterpretation.displayMode(.echo,asset:asset,in:w.state,horrorEnabled:true,compareOriginal:false),.echo)
        XCTAssertEqual(ImageInterpretation.displayMode(.echo,asset:asset,in:w.state,horrorEnabled:false,compareOriginal:false),.original)
        XCTAssertEqual(ImageInterpretation.displayMode(.channels,asset:asset,in:w.state,horrorEnabled:false,compareOriginal:false),.channels)
        XCTAssertEqual(ImageInterpretation.displayMode(.echo,asset:asset,in:w.state,horrorEnabled:true,compareOriginal:true),.original)
        XCTAssertFalse(w.recordImageInterpretation(asset,mode:.echo,region:0))
        XCTAssertTrue(w.recordImageInterpretation(asset,mode:.echo,region:6))
        XCTAssertEqual(ImageInterpretation.recorded(w.state).count,1)
        XCTAssertEqual(ImageInterpretation.displayMode(.echo,asset:"not-recovered",in:w.state,horrorEnabled:true,compareOriginal:false),.original)
    }
    func testLayerProgressAndRecordedFindings() throws {
        var state=RestoredPhoneBackup.snapshot()
        let asset="Nora_Archive_08"
        XCTAssertTrue(ImageInterpretation.modes(asset,in:state).isEmpty)
        state.flags.formUnion(["phone-tutorial-finished","investigation.contact.received","web.visited.archive",VeilArchive.discovery])
        let w=PhoneWorldStore(initial:state,persistToDisk:false)
        w.recordVeilObservation(asset)
        XCTAssertEqual(ImageInterpretation.modes(asset,in:w.state),[.original])
        XCTAssertFalse(w.recordImageInterpretation(asset,mode:.scanlines,region:4))
        XCTAssertTrue(w.completeRecoveredImageAnalysis(asset,source:2,limit:0))
        XCTAssertTrue(ImageInterpretation.modes(asset,in:w.state).contains(.scanlines))
        XCTAssertFalse(w.recordImageInterpretation(asset,mode:.scanlines,region:0))
        XCTAssertFalse(w.recordImageInterpretation(asset,mode:.echo,region:4))
        XCTAssertTrue(w.recordImageInterpretation(asset,mode:.scanlines,region:4))
        XCTAssertTrue(w.recordImageInterpretation(asset,mode:.scanlines,region:4))
        XCTAssertEqual(ImageInterpretation.recorded(w.state).count,1)
        let record=try XCTUnwrap(LumaAssistantEvidence.selected("image:"+asset,in:w.state))
        XCTAssertTrue(record.excerpts.joined().contains("Interpretive observation"))
        var restored=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        XCTAssertEqual(ImageInterpretation.recorded(restored).count,1)
        restored.flags.remove(VeilArchive.discovery)
        XCTAssertTrue(ImageInterpretation.recorded(restored).isEmpty)
        XCTAssertNil(LumaAssistantEvidence.selected("image:"+asset,in:restored))
    }
}
