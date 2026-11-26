import XCTest
@testable import LastSeen

@MainActor final class ContextualConversationTests: XCTestCase {
    func testStatusKnowledgeAndMailDeliveryRemainConsistent() throws {
        let now=Date(timeIntervalSince1970:1_800_000_000)
        let initial=RestoredPhoneBackup.snapshot(now:now)
        let question="Is Nora safe?"
        let w=PhoneWorldStore(initial:initial,persistToDisk:false)
        XCTAssertTrue(w.sendReactive(to:.maya,text:question,now:now))
        XCTAssertTrue(w.sendConnectedMail(draftID:nil,peer:.maya,subject:"Checking in",body:question,now:now))
        let pending=try XCTUnwrap(w.state.pendingReplies?.first)
        let queued=try XCTUnwrap(w.connected.pendingMail.first)
        var restored=w.state
        restored.flags.insert(InvestigationResolution.read)
        let status=try XCTUnwrap(PhoneReplyPolicy.mayaStatusReply(question,flags:restored.flags))
        XCTAssertNotEqual(pending.text,status)
        XCTAssertNotEqual(queued.record.body,status+"\n\nMaya")
        let resume=PhoneWorldStore(initial:restored,persistToDisk:false)
        let delivery=max(pending.dueAt,queued.dueAt).addingTimeInterval(10)
        resume.advancePendingReplies(now:delivery)
        let message=try XCTUnwrap(resume.messages(.maya).first(where:{$0.id==pending.id}))
        let reply=try XCTUnwrap(resume.connected.mail.first(where:{$0.id==queued.record.id}))
        XCTAssertEqual(message.text,status)
        XCTAssertEqual(reply.body,status+"\n\nMaya")
        XCTAssertEqual(message.at,delivery)
        XCTAssertEqual(reply.date,delivery)
        resume.advancePendingReplies(now:delivery.addingTimeInterval(30))
        XCTAssertEqual(resume.connected.mail.filter{$0.id==reply.id}.count,1)
        XCTAssertEqual(resume.messages(.maya).filter{$0.id==message.id}.count,1)
        XCTAssertNil(PhoneReplyPolicy.mayaStatusReply("Nora's passcode",flags:restored.flags))
        XCTAssertNil(PhoneReplyPolicy.mayaStatusReply(question,flags:initial.flags))
        XCTAssertFalse(LumaMailCatalog.response(to:.denise,subject:"Checking in",body:question,flags:restored.flags).contains(status))
    }

    func testFictionalCallOutcomesAndContactAvailability() throws {
        var initial=RestoredPhoneBackup.snapshot()
        initial.threads.removeValue(forKey:Neighbor.unknown.id)
        initial.threads.removeValue(forKey:Neighbor.lily.id)
        let w=PhoneWorldStore(initial:initial,persistToDisk:false)
        XCTAssertNil(w.recordCallAttempt(.unknown))
        XCTAssertNil(w.recordCallAttempt(.lily))
        w.toggleFavoriteContact(.unknown)
        XCTAssertFalse((w.state.favoriteContacts ?? []).contains(Neighbor.unknown.id))
        let now=Date(timeIntervalSince1970:1_800_000_000)
        let id=try XCTUnwrap(w.recordCallAttempt(.maya,now:now))
        w.finishCallAttempt(id,outcome:.noAnswer)
        w.finishCallAttempt(id,outcome:.ended)
        XCTAssertEqual(LumaPhoneDirectoryPolicy.recents(w.state).first?.outcome,.noAnswer)
        XCTAssertTrue(LumaPhoneDirectoryPolicy.recents(w.state,query:"no-match-7").isEmpty)
        XCTAssertEqual(LumaPhoneDirectoryPolicy.recents(w.state,query:" Maya ").first?.id,id)
        w.toggleFavoriteContact(.maya)
        XCTAssertTrue(LumaPhoneDirectoryPolicy.contacts(w.state,favoritesOnly:true).contains(.maya))
        var restored=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(w.state))
        XCTAssertEqual(LumaPhoneDirectoryPolicy.recents(restored).first?.outcome,.noAnswer)
        restored.callHistory?.append(.init(id:UUID(),contact:.lily,date:now))
        XCTAssertFalse(LumaPhoneDirectoryPolicy.recents(restored).contains{$0.contact == .lily})
        let legacy=LumaCallRecord(id:UUID(),contact:.maya,date:now)
        XCTAssertEqual(legacy.outcomeTitle,"Outgoing attempt")
        XCTAssertNil(try JSONDecoder().decode(LumaCallRecord.self,from:JSONEncoder().encode(legacy)).outcome)
    }

    func testDirectorySearchUsesMatchingMessageAndProtectsUnopenedArchive() {
        var state=RestoredPhoneBackup.snapshot()
        let now=Date(timeIntervalSince1970:1_800_000_000)
        state.threads[Neighbor.maya.id]=[
            .init(id:"older",thread:Neighbor.maya.id,text:"A unique coffee reminder",fromPlayer:false,at:now.addingTimeInterval(-600),read:true),
            .init(id:"latest",thread:Neighbor.maya.id,text:"See you later",fromPlayer:true,at:now,read:false)]
        let rows=LumaMessageDirectorySearch.rows(state,search:"  UNIQUE COFFEE  ")
        XCTAssertEqual(rows.first?.message.id,"older")
        XCTAssertEqual(rows.first?.preview,"A unique coffee reminder")
        XCTAssertEqual(rows.first?.matchedMessage,true)
        XCTAssertEqual(rows.first?.unread,0)
        XCTAssertEqual(LumaMessageDirectorySearch.rows(state,search:"Maya").first?.message.id,"latest")
        XCTAssertFalse(LumaMessageDirectorySearch.rows(state,unreadOnly:true).contains{$0.person == .maya})
        XCTAssertFalse(LumaMessageDirectorySearch.rows(state,search:"not-a-match-891").contains{$0.person == .maya})
        state.flags.formUnion(["phone-tutorial-finished","investigation.contact.received","web.visited.archive",VeilArchive.discovery])
        let phrase="A copy for your collection"
        XCTAssertTrue(LumaMessageDirectorySearch.recoveredSenderMatches(state,search:"",unreadOnly:false))
        XCTAssertFalse(LumaMessageDirectorySearch.recoveredSenderMatches(state,search:phrase,unreadOnly:false))
        state.flags.insert("veil.correspondence.opened")
        XCTAssertTrue(LumaMessageDirectorySearch.recoveredSenderMatches(state,search:phrase,unreadOnly:false))
        XCTAssertFalse(LumaMessageDirectorySearch.recoveredSenderMatches(state,search:phrase,unreadOnly:true))
        state.flags.remove(VeilArchive.discovery)
        XCTAssertFalse(LumaMessageDirectorySearch.recoveredSenderMatches(state,search:phrase,unreadOnly:false))
    }

    func testContextualFollowupsAreContactLocalAndDoNotGrantAccess() {
        func plan(_ who: Neighbor, _ text: String, previous: String? = nil, recent: [String] = []) -> PhoneReplyPlan {
            PhoneReplyPolicy.plan(for: who, text: text, flags: [], tutorialStarted: false, tutorialFinished: false, previousReply: previous, recentReplies: recent)
        }
        let first = plan(.adrian, "How do you promote the studio?")
        let second = plan(.adrian, "Tell me more", previous: first.text, recent: [first.text])
        let third = plan(.adrian, "Why?", previous: second.text, recent: [first.text,second.text])
        XCTAssertEqual(Set([first.text,second.text,third.text]).count, 3)
        let unrelated = plan(.lily, "Tell me more", previous: first.text)
        XCTAssertNotEqual(unrelated.text, second.text)
        let privateRequest = plan(.adrian, "Tell me more about the passcode", previous: second.text)
        XCTAssertTrue(privateRequest.text.contains("private access"))
        XCTAssertFalse(privateRequest.startsTutorial)
        XCTAssertFalse(third.startsTutorial)
    }
    func testIndependentTopicsAndRevisitsRemainAuthored() {
        func reply(_ text: String, previous: String? = nil, recent: [String] = []) -> String? {
            PhoneEverydayConversation.reply(neighbor: .lily, text: text, previousMessage: nil, previousReply: previous, recentReplies: recent)
        }
        let combined = reply("What music do you like and what films do you watch?")
        XCTAssertEqual(combined?.components(separatedBy: "\n\n").count, 2)
        XCTAssertTrue(combined?.contains("playlists") == true)
        XCTAssertTrue(combined?.contains("film") == true)
        XCTAssertEqual(reply("Tell me more", previous: combined), "Which part did you want to talk about a little more?")
        XCTAssertNil(reply("What music do you like and what is the passcode?"))
        let first = reply("Any music recommendations?")
        let other = reply("Do you watch films?", previous: first)
        let revisit = reply("What about music?", previous: other, recent: [first ?? "", other ?? ""])
        XCTAssertNotEqual(first, revisit)
        XCTAssertNotNil(revisit)
    }

    func testCheckpointRetainsSeparateTypingTimestamp() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "typing-restore-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: root) }
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        XCTAssertTrue(w.sendReactive(to: .adrian, text: "What about documentation?", now: now))
        let pending = try XCTUnwrap(w.state.pendingReplies?.first)
        let typingAt = try XCTUnwrap(pending.typingAt)
        let saves = LumaSaveStore(root: root, defaults: defaults)
        XCTAssertTrue(saves.write("manual-1", world: w.state, now: now))
        XCTAssertTrue(saves.restore("manual-1", into: w, now: now.addingTimeInterval(60)))
        let restored = try XCTUnwrap(w.state.pendingReplies?.first)
        XCTAssertEqual(restored.typingAt, typingAt.addingTimeInterval(60))
        XCTAssertFalse(w.isTyping(.adrian, now: restored.readAt))
        XCTAssertTrue(w.isTyping(.adrian, now: typingAt.addingTimeInterval(60)))
    }

    func testAvailabilityIsBoundedAndDoesNotDelayProgressReplies() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let noon = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: 12)))
        let night = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: 2)))
        let weekend = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 28, hour: 12)))
        XCTAssertEqual(PhoneReplyTiming.availabilityDelay(neighbor: .denise, now: noon, calendar: calendar), 0)
        XCTAssertEqual(PhoneReplyTiming.availabilityDelay(neighbor: .denise, now: weekend, calendar: calendar), 10)
        for neighbor in Neighbor.allCases {
            let ordinary = PhoneReplyTiming.window(neighbor: neighbor, text: "An ordinary answer.", introductory: false, everyday: true, now: night, calendar: calendar)
            XCTAssertLessThan(ordinary.read, ordinary.typing)
            XCTAssertLessThan(ordinary.typing, ordinary.due)
            XCTAssertLessThanOrEqual(ordinary.due, 22)
            let progressDay = PhoneReplyTiming.window(neighbor: neighbor, text: "A progress answer.", introductory: false, now: noon, calendar: calendar)
            let progressNight = PhoneReplyTiming.window(neighbor: neighbor, text: "A progress answer.", introductory: false, now: night, calendar: calendar)
            XCTAssertEqual(progressDay.due, progressNight.due)
            let tutorial = PhoneReplyTiming.window(neighbor: neighbor, text: "A tutorial answer.", introductory: true, everyday: true, now: night, calendar: calendar)
            XCTAssertLessThan(tutorial.due, 6)
        }
        let slow = PhoneReplyTiming.window(neighbor: .helen, text: "Hello.", introductory: false, everyday: true, now: night, calendar: calendar)
        let engaged = PhoneReplyTiming.window(neighbor: .helen, text: "Hello.", introductory: false, everyday: true, now: night, recentExchange: true, calendar: calendar)
        let queued = PhoneReplyTiming.window(neighbor: .helen, text: "Hello.", introductory: false, everyday: true, now: night, alreadyWaiting: true, calendar: calendar)
        XCTAssertLessThan(engaged.read, queued.read)
        XCTAssertLessThan(queued.read, slow.read)
        XCTAssertTrue(PhoneReplyPolicy.plan(for: .lily, text: "What music do you like?", flags: [], tutorialStarted: false, tutorialFinished: false).everyday)
        XCTAssertFalse(PhoneReplyPolicy.plan(for: .lily, text: "What is the passcode?", flags: [], tutorialStarted: false, tutorialFinished: false).everyday)
    }

    func testNegatedOrQuotedRepairReportDoesNotAdvanceTutorial() {
        for text in ["I didn't repair the phone", "Is the phone working?", "Someone said \"I repaired the phone\"", "I am not a technician"] {
            XCTAssertFalse(PhoneReplyPolicy.plan(for: .maya, text: text, flags: [], tutorialStarted: true, tutorialFinished: false).startsTutorial)
        }
        XCTAssertTrue(PhoneReplyPolicy.plan(for: .maya, text: "I repaired the phone", flags: [], tutorialStarted: true, tutorialFinished: false).startsTutorial)
    }
    func testReadTypingDeliveryAndRestore() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let w = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        XCTAssertTrue(w.sendReactive(to: .adrian, text: "How do you promote the studio?", now: now))
        let pending = try XCTUnwrap(w.state.pendingReplies?.first)
        let typingAt = try XCTUnwrap(pending.typingAt)
        XCTAssertLessThan(pending.readAt, typingAt)
        XCTAssertLessThan(typingAt, pending.dueAt)
        w.advancePendingReplies(now: pending.readAt)
        XCTAssertFalse(w.isTyping(.adrian, now: pending.readAt))
        XCTAssertEqual(w.messages(.adrian).last?.recipientReadAt, pending.readAt)
        XCTAssertTrue(w.isTyping(.adrian, now: typingAt))
        let saved = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(w.state))
        let restored = PhoneWorldStore(initial: saved, persistToDisk: false)
        restored.advancePendingReplies(now: pending.dueAt.addingTimeInterval(10))
        XCTAssertEqual(restored.messages(.adrian).last?.at, pending.dueAt)
        XCTAssertEqual(restored.messages(.adrian).last?.text, pending.text)
        let count = restored.messages(.adrian).count
        restored.advancePendingReplies(now: pending.dueAt.addingTimeInterval(20))
        XCTAssertEqual(restored.messages(.adrian).count, count)
        XCTAssertTrue(restored.state.flags.isEmpty)
    }
    func testPendingReplyRequiresParentAndRetainsChronologyAfterClockRollback() throws {
        let now=Date(timeIntervalSince1970:1800000000)
        let original=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(now:now),persistToDisk:false)
        XCTAssertTrue(original.sendReactive(to:.adrian,text:"Hello",now:now))
        let queued=try XCTUnwrap(original.state.pendingReplies?.first)
        var snapshot=original.state
        let earlier=now.addingTimeInterval(-60)
        snapshot.pendingReplies=[
            .init(id:queued.id,outgoingID:queued.outgoingID,neighbor:.adrian,text:queued.text,
                  readAt:earlier,dueAt:earlier.addingTimeInterval(5),startsTutorial:false,typingAt:earlier.addingTimeInterval(2)),
            .init(id:"orphan",outgoingID:"missing-parent",neighbor:.adrian,text:"Orphan reply",
                  readAt:earlier,dueAt:earlier.addingTimeInterval(5),startsTutorial:false)
        ]
        let restored=PhoneWorldStore(initial:snapshot,persistToDisk:false)
        restored.advancePendingReplies(now:earlier.addingTimeInterval(10))
        let outgoing=try XCTUnwrap(restored.messages(.adrian).first{$0.id==queued.outgoingID})
        let incoming=try XCTUnwrap(restored.messages(.adrian).first{$0.id==queued.id})
        XCTAssertEqual(outgoing.recipientReadAt,now)
        XCTAssertEqual(incoming.at,now)
        XCTAssertFalse(restored.messages(.adrian).contains{$0.id=="orphan"})
        XCTAssertFalse(restored.hasPendingReply(.adrian))
        restored.advancePendingReplies(now:now.addingTimeInterval(10))
        XCTAssertEqual(restored.messages(.adrian).filter{$0.id==queued.id}.count,1)
    }

    func testTutorialDeliveryDoesNotPrecedeParentAfterClockRollback() throws {
        let now=Date(timeIntervalSince1970:1800000000)
        let original=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(now:now),persistToDisk:false)
        original.startPhoneTutorial(now:now)
        XCTAssertTrue(original.sendReactive(to:.maya,text:"I repaired the phone",now:now.addingTimeInterval(20)))
        let queued=try XCTUnwrap(original.state.pendingReplies?.first)
        XCTAssertTrue(queued.startsTutorial)
        let parent=try XCTUnwrap(original.messages(.maya).first{$0.id==queued.outgoingID})
        var snapshot=original.state
        let earlier=now.addingTimeInterval(-3600)
        snapshot.pendingReplies=[PhonePendingReply(id:queued.id,outgoingID:queued.outgoingID,neighbor:.maya,text:queued.text,
            readAt:earlier,dueAt:earlier.addingTimeInterval(5),startsTutorial:true,typingAt:earlier.addingTimeInterval(2))]
        let restored=PhoneWorldStore(initial:snapshot,persistToDisk:false)
        restored.advancePendingReplies(now:earlier.addingTimeInterval(10))
        let delivered=try XCTUnwrap(restored.messages(.maya).first{$0.id=="phone-tutorial-notes"})
        XCTAssertGreaterThanOrEqual(delivered.at,parent.at)
        XCTAssertTrue(restored.state.flags.contains("phone-tutorial-replied"))
        XCTAssertFalse(restored.hasPendingReply(.maya))
    }
    func testTutorialStartIsIdempotentAcrossCheckpointAndGuideUpdates() throws {
        let now=Date(timeIntervalSince1970:1800000000)
        let store=PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(now:now),persistToDisk:false)
        store.startPhoneTutorial(now:now)
        let first=store.messages(.maya).map(\.id)
        store.startPhoneTutorial(now:now.addingTimeInterval(5))
        XCTAssertEqual(store.messages(.maya).map(\.id),first)
        let saved=try JSONDecoder().decode(PhoneWorld.self,from:JSONEncoder().encode(store.state))
        let restored=PhoneWorldStore(initial:saved,persistToDisk:false)
        restored.startPhoneTutorial(now:now.addingTimeInterval(20))
        XCTAssertEqual(restored.messages(.maya).map(\.id),first)
        XCTAssertEqual(restored.state.notes.filter{$0.id==PhoneWorldStore.tutorialNoteID}.count,1)
        XCTAssertTrue(restored.tutorialStarted)
    }
    func testLegacyPendingReplyDecodesWithoutTypingTime() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let original = PhonePendingReply(id: "old", outgoingID: "old-out", neighbor: .adrian, text: "Hi", readAt: now, dueAt: now.addingTimeInterval(5), startsTutorial: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PhonePendingReply.self, from: data)
        XCTAssertNil(decoded.typingAt)
        XCTAssertEqual(decoded, original)
    }
}
