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
