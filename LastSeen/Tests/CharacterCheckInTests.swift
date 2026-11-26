import XCTest
@testable import LastSeen

@MainActor final class CharacterCheckInTests:XCTestCase {
    func testCrossContactReplyAndUnreadTutorialTakePriority() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var state = RestoredPhoneBackup.snapshot(now: now)
        state.flags.insert("phone-tutorial-finished")
        state.threads[Neighbor.denise.id, default: []].append(.init(id: "denise-checkin-outgoing",
            thread: Neighbor.denise.id, text: "Thank you.", fromPlayer: true, at: now, read: true))
        let initial = PhoneWorldStore(initial: state, persistToDisk: false)
        initial.markRead(.maya)
        initial.markRead(.denise)
        initial.advanceCharacterCheckIns(now: now)
        let due = now.addingTimeInterval(190)
        state = initial.state
        state.threads[Neighbor.maya.id, default: []].append(.init(id: "priority-outgoing",
            thread: Neighbor.maya.id, text: "Thanks.", fromPlayer: true, at: now, read: true))
        state.pendingReplies = [.init(id: "priority-reply", outgoingID: "priority-outgoing",
            neighbor: .maya, text: "You're welcome.", readAt: due, dueAt: due, startsTutorial: false)]
        let store = PhoneWorldStore(initial: state, persistToDisk: false)
        XCTAssertTrue(CharacterCheckIns.foregroundPriority(in: store.state, now: due))
        store.advancePendingReplies(now: due)
        XCTAssertTrue(store.messages(.maya).contains { $0.id == "priority-reply" })
        XCTAssertFalse(store.messages(.denise).contains { $0.id == "b32-denise-check-in" })
        XCTAssertEqual(store.connected.characterCheckIns?.first(where: { $0.id == "b32-denise-check-in" })?.dueAt, due.addingTimeInterval(15))
        state = store.state
        state.threads[Neighbor.maya.id, default: []].append(.init(id: "phone-tutorial-priority-test",
            thread: Neighbor.maya.id, text: "Please read this first.", fromPlayer: false, at: due, read: false))
        let unread = PhoneWorldStore(initial: state, persistToDisk: false)
        unread.advanceCharacterCheckIns(now: due.addingTimeInterval(15))
        XCTAssertFalse(unread.messages(.denise).contains { $0.id == "b32-denise-check-in" })
        unread.markRead(.maya)
        unread.advanceCharacterCheckIns(now: due.addingTimeInterval(29))
        XCTAssertFalse(unread.messages(.denise).contains { $0.id == "b32-denise-check-in" })
        unread.advanceCharacterCheckIns(now: due.addingTimeInterval(30))
        XCTAssertEqual(unread.messages(.denise).filter { $0.id == "b32-denise-check-in" }.count, 1)
    }

    func testOverdueCheckInsAreStaggeredRatherThanDeliveredInABurst() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var state = RestoredPhoneBackup.snapshot(now: now)
        state.flags.insert("phone-tutorial-finished")
        for contact in [Neighbor.maya, Neighbor.denise] {
            state.threads[contact.id, default: []].append(.init(id: "checkin-outgoing-" + contact.id,
                thread: contact.id, text: "Thank you.", fromPlayer: true, at: now, read: true))
        }
        let store = PhoneWorldStore(initial: state, persistToDisk: false)
        store.markRead(.maya)
        store.markRead(.denise)
        store.advanceCharacterCheckIns(now: now)
        XCTAssertEqual(store.connected.characterCheckIns?.count, 2)
        let catchUp = now.addingTimeInterval(500)
        store.advanceCharacterCheckIns(now: catchUp)
        XCTAssertTrue(store.messages(.maya).contains { $0.id == "b32-maya-check-in" })
        XCTAssertFalse(store.messages(.denise).contains { $0.id == "b32-denise-check-in" })
        XCTAssertEqual(store.connected.characterCheckIns?.first?.dueAt, catchUp.addingTimeInterval(35))
        store.advanceCharacterCheckIns(now: catchUp.addingTimeInterval(34))
        XCTAssertFalse(store.messages(.denise).contains { $0.id == "b32-denise-check-in" })
        store.advanceCharacterCheckIns(now: catchUp.addingTimeInterval(35))
        XCTAssertTrue(store.messages(.denise).contains { $0.id == "b32-denise-check-in" })
        XCTAssertTrue((store.connected.characterCheckIns ?? []).isEmpty)
    }

    func testFiniteCheckInsAndCheckpointTiming() throws {
        let now=Date(timeIntervalSince1970:1_800_000_000)
        let w=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(now:now),persistToDisk:false)
        w.advanceCharacterCheckIns(now:now)
        XCTAssertTrue((w.connected.characterCheckIns ?? []).isEmpty)
        var state=w.state
        state.flags.insert("phone-tutorial-finished")
        state.threads[Neighbor.maya.id,default:[]].append(.init(id:"checkin-test-outgoing",thread:Neighbor.maya.id,text:"Thanks for your help.",fromPlayer:true,at:now,read:true))
        let store=PhoneWorldStore(initial:state,persistToDisk:false)
        store.markRead(.maya)
        store.advanceCharacterCheckIns(now:now)
        let pending=try XCTUnwrap(store.connected.characterCheckIns)
        XCTAssertEqual(pending.map(\.id),["b32-maya-check-in"])
        XCTAssertEqual(pending[0].dueAt,now.addingTimeInterval(105))
        store.advanceCharacterCheckIns(now:now.addingTimeInterval(104))
        XCTAssertFalse(store.messages(.maya).contains{$0.id=="b32-maya-check-in"})
        let encoded=try JSONEncoder().encode(store.state)
        var restored=try JSONDecoder().decode(PhoneWorld.self,from:encoded)
        restored.connectedWorld?.characterCheckIns=CharacterCheckIns.rebase(restored.connectedWorld?.characterCheckIns,by:500)
        let resume=PhoneWorldStore(initial:restored,persistToDisk:false)
        resume.advanceCharacterCheckIns(now:now.addingTimeInterval(604))
        XCTAssertFalse(resume.messages(.maya).contains{$0.id=="b32-maya-check-in"})
        resume.advanceCharacterCheckIns(now:now.addingTimeInterval(605))
        resume.advanceCharacterCheckIns(now:now.addingTimeInterval(900))
        XCTAssertEqual(resume.messages(.maya).filter{$0.id=="b32-maya-check-in"}.count,1)
        XCTAssertTrue((resume.connected.characterCheckIns ?? []).isEmpty)
        XCTAssertFalse(resume.messages(.denise).contains{$0.id=="b32-denise-check-in"})
        restored.flags.remove("phone-tutorial-finished")
        let revoked=PhoneWorldStore(initial:restored,persistToDisk:false)
        revoked.advanceCharacterCheckIns(now:now.addingTimeInterval(900))
        XCTAssertFalse(revoked.messages(.maya).contains{$0.id=="b32-maya-check-in"})
        XCTAssertTrue((revoked.connected.characterCheckIns ?? []).isEmpty)
    }
}
