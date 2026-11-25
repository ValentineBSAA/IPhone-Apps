import XCTest
@testable import LastSeen
@MainActor final class NoraEverydayArchiveTests: XCTestCase {
    func testMigrationIsAdditiveAndIdempotent() throws {
        var w = RestoredPhoneBackup.snapshot()
        XCTAssertEqual(Neighbor.visible(in:w).count,7)
        XCTAssertEqual(w.everydayArchiveRevision,1)
        XCTAssertTrue(w.flags.isEmpty)
        for n in Neighbor.allCases where !Neighbor.original.contains(n) && n != .unknown {
            XCTAssertEqual(w.threads[n.id]?.count,5)
            XCTAssertTrue(w.threads[n.id]?.allSatisfy(\.read) == true)
        }
        w.notes.removeAll { $0.id == "b27-sunday" }
        let before = w.threads
        NoraEverydayArchive.expand(&w)
        XCTAssertEqual(w.threads,before)
        XCTAssertFalse(w.notes.contains { $0.id == "b27-sunday" })
        let decoded = try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w))
        XCTAssertEqual(decoded.everydayArchiveRevision,1)
        XCTAssertEqual(decoded.threads,before)
        XCTAssertEqual(PhonePublicFiles.available(in:decoded).count,PhonePublicFiles.documents.count+4)
    }
    func testLegacyWorldAndNewReplies() {
        let old = PhoneWorldStore(persistToDisk:false)
        XCTAssertEqual(Neighbor.visible(in:old.state),Neighbor.original)
        XCTAssertFalse(old.sendReactive(to:.helen,text:"Hello"))
        let w = PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        XCTAssertTrue(w.sendReactive(to:.helen,text:"I repaired the phone"))
        w.advancePendingReplies(now:Date().addingTimeInterval(20))
        XCTAssertTrue(w.state.flags.isEmpty)
        XCTAssertEqual(w.messages(.helen).count,7)
    }
    func testAllExpansionArtResolves() {
        for name in ["FieldNotes","ClipGlass","LumaPlus","AfterglowStudio","PulseTerminal","RootExplorer","PocketClipboard","QuickPulse","PowerDeck","Relay","Patchline","TweakHub"] { XCTAssertNotNil(PortraitImages.load("Jailbreak_"+name),name) }
        for i in 1...10 { XCTAssertNotNil(PortraitImages.load(String(format:"Contact_B27_%02d",i))) }
    }
}
