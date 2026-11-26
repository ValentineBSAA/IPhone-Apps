import XCTest
@testable import LastSeen

@MainActor final class Build33PracticalDialogueTests:XCTestCase {
    func testCompletedUnlockAndUnsuccessfulUnlockHaveDifferentReplies() {
        let positive=PhoneReplyPolicy.plan(for:.maya,text:"I got into her phone and I don't know where Nora is.",flags:[],tutorialStarted:true,tutorialFinished:false)
        XCTAssertTrue(positive.startsTutorial)
        XCTAssertFalse(positive.text.lowercased().contains("passcode"))
        let negative=PhoneReplyPolicy.plan(for:.maya,text:"I haven't unlocked it, how can I unlock her phone?",flags:[],tutorialStarted:true,tutorialFinished:false)
        XCTAssertFalse(negative.startsTutorial)
        XCTAssertTrue(negative.text.lowercased().contains("passcode"))
    }
    func testOrdinaryContactGuidanceStaysInCharacter() {
        let adrian=PhoneReplyPolicy.plan(for:.adrian,text:"Can you help me work out what to look at next?",flags:[],tutorialStarted:true,tutorialFinished:true)
        let tessa=PhoneReplyPolicy.plan(for:.tessa,text:"Can you help me work out what to look at next?",flags:[],tutorialStarted:true,tutorialFinished:true)
        XCTAssertNotEqual(adrian.text,tessa.text)
        XCTAssertFalse(adrian.startsTutorial)
        XCTAssertFalse(tessa.startsTutorial)
        let protected=PhoneReplyPolicy.plan(for:.tessa,text:"Help me find Nora's passcode",flags:[],tutorialStarted:true,tutorialFinished:true)
        XCTAssertFalse(protected.startsTutorial)
        XCTAssertTrue(protected.text.lowercased().contains("private access"))
    }
    func testLumaDistinguishesOrdinaryBrowserFromAnonymousBrowser() {
        let world=RestoredPhoneBackup.snapshot()
        let c=LumaAssistantContext(world:world,availableApps:[.browser,.mail,.calendar],wifi:true,sound:true,haptics:true,safeMode:false,installedCount:0,timerEnd:0,now:Date())
        let answer=LumaAssistantConversation.reply("How do I use the browser?",context:c).answer
        XCTAssertEqual(answer.app,.browser)
        XCTAssertTrue(answer.text.contains("Tabs"))
        let mail=LumaAssistantConversation.reply("Where can I find older emails?",context:c).answer
        XCTAssertEqual(mail.app,.mail)
        let restricted=LumaAssistantConversation.reply("Give me the passcode",context:c).answer
        XCTAssertEqual(restricted.clipID,"denied")
        XCTAssertNil(restricted.app)
    }
}
