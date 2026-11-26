import XCTest
@testable import LastSeen

@MainActor final class EntityEchoTests:XCTestCase {
    func testContainmentRequiresBothStagesAndPreservesWorld() throws {
        var snapshot=RestoredPhoneBackup.snapshot()
        let early=PhoneWorldStore(initial:snapshot,persistToDisk:false)
        early.triggerEntityEcho()
        XCTAssertFalse(EntityEcho.active(early.state.flags))
        snapshot.flags.insert(EntityEcho.installed)
        let store=PhoneWorldStore(initial:snapshot,persistToDisk:false)
        let epoch=store.checkpointEpoch
        for id in EntityEcho.overrides {
            XCTAssertTrue(EntityEcho.overridesTweak(id,flags:store.state.flags,safeMode:false))
            XCTAssertFalse(EntityEcho.overridesTweak(id,flags:store.state.flags,safeMode:true))
        }
        XCTAssertFalse(store.removeEntityEcho(answers:EntityEcho.solution,repair:[],epoch:epoch))
        XCTAssertFalse(store.removeEntityEcho(answers:["Wallpaper"],repair:EntityEcho.repairOrder,epoch:epoch))
        XCTAssertFalse(store.removeEntityEcho(answers:EntityEcho.solution,repair:EntityEcho.repairOrder,epoch:UUID()))
        let encoded=try JSONEncoder().encode(store.state)
        let restored=try JSONDecoder().decode(PhoneWorld.self,from:encoded)
        let reload=PhoneWorldStore(initial:restored,persistToDisk:false)
        XCTAssertTrue(EntityEcho.active(reload.state.flags))
        XCTAssertTrue(reload.removeEntityEcho(answers:EntityEcho.solution,repair:EntityEcho.repairOrder,epoch:reload.checkpointEpoch))
        XCTAssertFalse(EntityEcho.active(reload.state.flags))
        reload.triggerEntityEcho()
        XCTAssertFalse(EntityEcho.active(reload.state.flags))
        XCTAssertEqual(reload.state.flags.subtracting([EntityEcho.installed,EntityEcho.removed]),store.state.flags.subtracting([EntityEcho.installed,EntityEcho.removed]))
        XCTAssertEqual(reload.state.threads.keys.sorted(),store.state.threads.keys.sorted())
        XCTAssertTrue(RelayCatalog.tweakActive("seconds",installed:"seconds",safeMode:false,flags:reload.state.flags))
    }
    func testHelpUsesCurrentEncounterStateAndNoSolutionKey() {
        var snapshot=RestoredPhoneBackup.snapshot()
        func context()->LumaAssistantContext {
            .init(world:snapshot,availableApps:[.patchline,.assistant],wifi:false,sound:false,haptics:false,safeMode:true,installedCount:0,timerEnd:0,now:Date())
        }
        XCTAssertNotEqual(LumaAssistantConversation.reply("help with virus",context:context()).answer.app,.patchline)
        snapshot.flags.insert(EntityEcho.installed)
        let answer=LumaAssistantConversation.reply("help with virus",context:context()).answer
        XCTAssertEqual(answer.app,.patchline)
        XCTAssertFalse(answer.text.contains(EntityEcho.repairOrder.joined(separator:" ")))
        let alex=RelaySupportLocalProvider().reply(question:"help with virus",recent:[],flags:snapshot.flags,sources:"",installed:"")
        XCTAssertEqual(alex.text,EntityEcho.assistance(technical:true))
        snapshot.flags.insert(EntityEcho.removed)
        XCTAssertNotEqual(LumaAssistantConversation.reply("help with virus",context:context()).answer.app,.patchline)
    }
}
