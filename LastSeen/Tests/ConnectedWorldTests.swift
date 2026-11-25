import XCTest
@testable import LastSeen

@MainActor final class ConnectedWorldTests:XCTestCase {
    func testMailDraftSendDeliveryAndRestore() throws {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let now=Date(timeIntervalSince1970:1800000000)
        XCTAssertFalse(w.sendConnectedMail(draftID:nil,peer:.unknown,subject:"Question",body:"Hello",now:now))
        let draft=try XCTUnwrap(w.saveMailDraft(id:nil,peer:.adrian,subject:"Review",body:"Could you clarify the checklist?",now:now))
        XCTAssertTrue(w.sendConnectedMail(draftID:draft,peer:.adrian,subject:"Review",body:"Could you clarify the checklist?",now:now))
        XCTAssertEqual(w.connected.mail.count,1)
        XCTAssertEqual(w.connected.pendingMail.count,1)
        w.advanceConnectedMail(now:now.addingTimeInterval(29))
        XCTAssertEqual(w.connected.mail.count,1)
        w.advanceConnectedMail(now:now.addingTimeInterval(31))
        w.advanceConnectedMail(now:now.addingTimeInterval(100))
        XCTAssertEqual(w.connected.mail.count,2)
        XCTAssertTrue(w.connected.pendingMail.isEmpty)
        let id=w.connected.mail[0].id
        w.moveConnectedMail(id,folder:"archive")
        XCTAssertEqual(w.connected.mailFolders[id],"archive")
        w.moveConnectedMail(id,folder:"original")
        XCTAssertNil(w.connected.mailFolders[id])
        let decoded=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        XCTAssertEqual(decoded.connectedWorld,w.state.connectedWorld)
    }
    func testSocialStateAndLocalAuthor() throws{
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        let first=try XCTUnwrap(LumaSocialCatalog.visible(.afterframe,world:w.state).first)
        w.toggleSocial(.like,postID:first.id,channel:.connective)
        XCTAssertTrue(w.connected.likes.isEmpty)
        w.toggleSocial(.like,postID:first.id,channel:.afterframe)
        XCTAssertTrue(w.connected.likes.contains(first.id))
        w.toggleSocial(.save,postID:first.id,channel:.afterframe)
        XCTAssertTrue(w.connected.savedPosts.contains(first.id))
        XCTAssertTrue(w.commentSocial(postID:first.id,channel:.afterframe,text:"Thank you"))
        XCTAssertTrue(w.publishSocial(channel:.commonGround,text:"Local repair desk update"))
        XCTAssertEqual(w.connected.posts.first?.author,"Repair desk")
        XCTAssertFalse(w.commentSocial(postID:"missing",channel:.afterframe,text:"Hi"))
        let decoded=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        XCTAssertEqual(decoded.connectedWorld,w.state.connectedWorld)
    }
    func testWorkbenchRequiresConnectionAndValidSelection() {
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        w.setWorkbenchSelection(Array(WorkbenchChallenge.routing.options.prefix(2)),for:.routing)
        XCTAssertFalse(w.verifyWorkbench(.routing))
        w.setWorkbenchConnection(true)
        w.setWorkbenchSelection([WorkbenchChallenge.routing.options[2],WorkbenchChallenge.routing.options[3]],for:.routing)
        XCTAssertFalse(w.verifyWorkbench(.routing))
        w.setWorkbenchSelection(Array(WorkbenchChallenge.routing.options.prefix(2)),for:.routing)
        XCTAssertTrue(w.verifyWorkbench(.routing))
        XCTAssertTrue(w.verifyWorkbench(.routing))
        XCTAssertEqual(w.connected.workbenchVerified.count,1)
        w.setWorkbenchConnection(false)
        XCTAssertFalse(w.verifyWorkbench(.routing))
    }
}
