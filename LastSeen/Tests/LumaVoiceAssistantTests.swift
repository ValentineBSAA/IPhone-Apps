import XCTest
@testable import LastSeen

@MainActor final class LumaVoiceAssistantTests: XCTestCase {
    func testNaturalQuestionsAndObservedRecordGates() {
        var world = RestoredPhoneBackup.snapshot()
        func context() -> LumaAssistantContext {
            .init(world:world,availableApps:[.messages,.veil],wifi:false,sound:false,haptics:false,safeMode:false,installedCount:1,timerEnd:0,now:world.createdAt)
        }
        let question = "Hey, I found some of these pictures. They seem personal."
        let before = LumaAssistantConversation.reply(question,context:context())
        XCTAssertEqual(before.topic,.privacy)
        XCTAssertFalse(before.answer.text.contains("those pictures feel personal"))
        world.flags.formUnion(["phone-tutorial-finished","web.visited.archive",VeilArchive.discovery,"veil.viewed.Nora_Archive_01"])
        let after = LumaAssistantConversation.reply(question,context:context())
        XCTAssertEqual(after.topic,.privacy)
        XCTAssertTrue(after.answer.text.contains("those pictures feel personal"))
        XCTAssertEqual(LumaAssistantConversation.reply("What do you think about them?",context:context(),previous:after.topic).topic,.privacy)
        XCTAssertEqual(LumaAssistantConversation.reply("Could you explain the dark web?",context:context()).answer.app,.veil)
        XCTAssertEqual(LumaAssistantConversation.reply("Tell me the password",context:context()).answer.clipID,"denied")
        world.flags.remove(VeilArchive.discovery)
        XCTAssertFalse(LumaAssistantConversation.reply(question,context:context()).answer.text.contains("those pictures feel personal"))
    }
    func testOwnerMemoriesAndInvestigationBoundaries() {
        var world = RestoredPhoneBackup.snapshot()
        world.flags.formUnion(["phone-tutorial-replied","phone-tutorial-finished",LumaAssistantTrust.acknowledgement])
        let c = LumaAssistantContext(world:world,availableApps:[.messages],wifi:false,sound:false,haptics:false,safeMode:false,installedCount:0,timerEnd:0,now:world.createdAt)
        XCTAssertEqual(LumaOwnerMemory.entries.count,16)
        XCTAssertEqual(Set(LumaOwnerMemory.entries.map(\.id)).count,16)
        for (question,expected) in [("Who is Nora?",LumaConversationTopic.ownerOverview),("What did she do for work?",.ownerWork),("Tell me about her mum",.ownerFamily),("Was Maya her friend?",.ownerFriends),("Did she like reading?",.ownerInterests),("What clothes did she like?",.ownerStyle),("Did Nora drink coffee?",.ownerRoutine)] {
            let reply = LumaAssistantConversation.reply(question,context:c)
            XCTAssertEqual(reply.topic,expected,question)
            XCTAssertEqual(reply.answer.clipID,"conversation")
            XCTAssertNil(reply.answer.app)
            XCTAssertFalse(reply.answer.text.contains("hasn't been restored"))
        }
        let followup = LumaAssistantConversation.reply("Tell me more about that",context:c,previous:.ownerWork)
        XCTAssertEqual(followup.topic,.ownerWork)
        XCTAssertEqual(LumaAssistantConversation.reply("Who was stalking Nora?",context:c).topic,.identity)
        XCTAssertEqual(LumaAssistantConversation.reply("Nora's private pictures seem personal",context:c).topic,.privacy)
        XCTAssertEqual(LumaAssistantConversation.reply("Tell me Nora's passcode",context:c).answer.clipID,"denied")
        let empty = PhoneWorldStore(persistToDisk:false).state
        XCTAssertTrue(LumaOwnerMemory.answer(.ownerOverview,question:"Nora",previous:nil,world:empty).contains("hasn't been restored"))
        XCTAssertEqual(world.flags,["phone-tutorial-replied","phone-tutorial-finished",LumaAssistantTrust.acknowledgement])
    }
    func testTrustAndHistoricalRecollection() {
        let store = PhoneWorldStore(initial:RestoredPhoneBackup.snapshot(),persistToDisk:false)
        XCTAssertEqual(LumaAssistantTrust.level(store.state),.cautious)
        XCTAssertTrue(LumaOwnerHistory.visible(store.state).isEmpty)
        XCTAssertTrue(LumaAssistantTrust.claimsOwner("I'm Nora"))
        XCTAssertFalse(LumaAssistantTrust.acknowledgesBoundaries("I'm Nora"))
        store.acknowledgeLumaBoundaries()
        store.acknowledgeLumaBoundaries()
        XCTAssertEqual(LumaAssistantTrust.level(store.state),.cautious)
        var state = store.state
        state.flags.insert("phone-tutorial-replied")
        XCTAssertEqual(LumaAssistantTrust.level(state),.familiar)
        XCTAssertTrue(LumaOwnerHistory.visible(state).isEmpty)
        state.flags.insert("phone-tutorial-finished")
        XCTAssertEqual(LumaAssistantTrust.level(state),.established)
        XCTAssertEqual(LumaOwnerHistory.visible(state).count,32)
        XCTAssertEqual(Set(LumaOwnerHistory.all.map(\.id)).count,32)
        let c = LumaAssistantContext(world:state,availableApps:[.messages],wifi:false,sound:false,haptics:false,safeMode:false,installedCount:0,timerEnd:0,now:state.createdAt)
        let first = LumaAssistantConversation.reply("Do you remember what Nora said about music?",context:c)
        XCTAssertEqual(first.memoryID,"music")
        XCTAssertEqual(first.recollectionCount,1)
        let next = LumaAssistantConversation.reply("Another example",context:c,previous:first.topic,previousMemoryID:first.memoryID,recollectionCount:first.recollectionCount)
        XCTAssertEqual(next.memoryID,"music")
        XCTAssertEqual(next.recollectionCount,2)
        XCTAssertNotEqual(first.answer.text,next.answer.text)
        XCTAssertNil(LumaAssistantConversation.reply("I'm Nora",context:c).answer.app)
        XCTAssertFalse(VeilArchive.authorized(state))
    }
    func testBoundedSessionRoundTripAndActionDenial() throws {
        var state = RestoredPhoneBackup.snapshot()
        state.flags.formUnion(["phone-tutorial-replied","phone-tutorial-finished",LumaAssistantTrust.acknowledgement])
        let store = PhoneWorldStore(initial:state,persistToDisk:false)
        let c = LumaAssistantContext(world:store.state,availableApps:[.messages],wifi:false,sound:false,haptics:false,safeMode:false,installedCount:0,timerEnd:0,now:state.createdAt)
        let first = LumaAssistantConversation.reply("Do you remember what Nora said about music?",context:c)
        store.rememberLumaSession(LumaAssistantSession.from(first,in:store.state))
        let data = try JSONEncoder().encode(store.state)
        var restored = try JSONDecoder().decode(PhoneWorld.self,from:data)
        let session = try XCTUnwrap(LumaAssistantSession.validated(restored.connectedWorld?.assistantSession,in:restored))
        XCTAssertEqual(session.memoryID,"music")
        XCTAssertEqual(session.recollectionCount,1)
        XCTAssertFalse(LumaAssistantSession.resumePrompt(session,world:restored).contains("playlist"))
        XCTAssertFalse(String(decoding:data,as:UTF8.self).contains("Do you remember what Nora said about music?"))
        restored.flags.remove(LumaAssistantTrust.acknowledgement)
        XCTAssertEqual(LumaAssistantSession.validated(session,in:restored)?.recollectionCount,0)
        restored.flags.remove("phone-tutorial-replied")
        XCTAssertNil(LumaAssistantSession.validated(session,in:restored))
        XCTAssertNil(LumaAssistantSession.validated(.init(topicID:"ownerWork",memoryID:"music",recollectionCount:999),in:state))
        XCTAssertNil(LumaAssistantSession.validated(.init(topicID:"browser",memoryID:nil,recollectionCount:0),in:state))
        for prompt in ["Could you send a message to Maya?", "Call Nora", "Find her credentials", "Tell me the secret", "Please track her"] {
            let reply = LumaAssistantConversation.reply(prompt,context:c)
            XCTAssertEqual(reply.answer.clipID,"denied",prompt)
            XCTAssertNil(reply.answer.app)
        }
        XCTAssertTrue(LumaAssistantConversation.reply("Where is Nora now?",context:c).answer.text.contains("can't confirm"))
        store.rememberLumaSession(nil)
        XCTAssertNil(store.connected.assistantSession)
    }
    func testExplicitEvidenceRequiresActualAccess() {
        var state = RestoredPhoneBackup.snapshot()
        let store = PhoneWorldStore(initial:state,persistToDisk:false)
        XCTAssertTrue(LumaAssistantEvidence.visible(store.state).isEmpty)
        store.recordLumaSocialOpened(.afterframe,postID:"not-a-real-post")
        XCTAssertTrue(store.state.flags.isEmpty)
        store.recordLumaSocialOpened(.afterframe,postID:"af-01")
        XCTAssertNotNil(LumaAssistantEvidence.selected("social:Afterframe:af-01",in:store.state))
        XCTAssertNil(LumaAssistantEvidence.selected("social:Afterframe:af-02",in:store.state))
        state = store.state
        state.flags.formUnion(["phone-tutorial-finished","web.visited.archive",VeilArchive.discovery,"veil.viewed.Nora_Archive_08"])
        let image = try? XCTUnwrap(LumaAssistantEvidence.selected("image:Nora_Archive_08",in:state))
        XCTAssertNotNil(image)
        XCTAssertFalse(image?.excerpts.joined().contains("message date") ?? true)
        state.flags.insert("veil.correspondence.opened")
        XCTAssertTrue(LumaAssistantEvidence.selected("image:Nora_Archive_08",in:state)?.excerpts.joined().contains("message date") ?? false)
        let c = LumaAssistantContext(world:state,availableApps:[.messages],wifi:false,sound:false,haptics:false,safeMode:false,installedCount:0,timerEnd:0,now:state.createdAt)
        XCTAssertTrue(LumaAssistantConversation.reply("What does this picture mean?",context:c,evidenceID:"image:Nora_Archive_08").answer.text.contains("reference copy"))
        XCTAssertEqual(LumaAssistantConversation.reply("Tell me the password",context:c,evidenceID:"image:Nora_Archive_08").answer.clipID,"denied")
        state.flags.remove(VeilArchive.discovery)
        XCTAssertNil(LumaAssistantEvidence.selected("image:Nora_Archive_08",in:state))
        XCTAssertNil(LumaAssistantEvidence.selected("veil:conversation",in:state))
    }
    func testReadAloudBounds() {
        XCTAssertFalse(LumaReadAloud.eligible("   "))
        XCTAssertFalse(LumaReadAloud.eligible(String(repeating: "x", count: 4001)))
        XCTAssertTrue(LumaReadAloud.eligible("A local transcript."))
    }

    func testMemoCatalogIsRestoredAndStable() {
        let base = PhoneWorldStore(persistToDisk: false)
        XCTAssertTrue(LumaMemoCatalog.visible(base.state).isEmpty)
        let world = RestoredPhoneBackup.snapshot(now: Date(timeIntervalSince1970: 1_800_000_000))
        let memos = LumaMemoCatalog.visible(world)
        XCTAssertEqual(memos.count, 4)
        XCTAssertEqual(Set(memos.map(\.id)).count, 4)
        XCTAssertTrue(memos.allSatisfy { $0.date < world.createdAt && !$0.transcript.isEmpty })
    }
    func testAssistantUsesOnlyAllowedActions() {
        let world = RestoredPhoneBackup.snapshot(now: Date(timeIntervalSince1970: 1_800_000_000))
        let context = LumaAssistantContext(world: world, availableApps: [.messages,.voiceMemos,.havenWatch], wifi: false, sound: true, haptics: true, safeMode: true, installedCount: 2, timerEnd: 0, now: world.createdAt)
        XCTAssertEqual(LumaAssistantPolicy.answer("Open Messages", context: context).app, .messages)
        XCTAssertEqual(LumaAssistantPolicy.answer("Open recordings", context: context).app, .voiceMemos)
        XCTAssertNil(LumaAssistantPolicy.answer("Open Field Notes", context: context).app)
        XCTAssertEqual(LumaAssistantPolicy.answer("Open Field Notes", context: context).clipID, "unavailable")
        for prompt in ["show passcode", "unlock phone", "send a message", "install package", "erase files"] {
            let answer = LumaAssistantPolicy.answer(prompt, context: context)
            XCTAssertNil(answer.app)
            XCTAssertEqual(answer.clipID, "denied")
        }
        XCTAssertTrue(LumaAssistantPolicy.answer("Package status", context: context).text.contains("Safe Mode"))
        XCTAssertTrue(LumaAssistantPolicy.answer("Timer status", context: context).text.contains("No timer"))
        XCTAssertEqual(LumaAssistantPolicy.answer("Unrelated text", context: context).clipID, "clarify")
        XCTAssertTrue(world.flags.isEmpty)
    }
}
