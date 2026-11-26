import XCTest
@testable import LastSeen

@MainActor final class EntityEchoTests:XCTestCase {
    func testOptionalInstallAndQuarantinePreserveExistingWorld() throws {
        var snapshot=RestoredPhoneBackup.snapshot()
        let w=PhoneWorldStore(initial:snapshot,persistToDisk:false)
        XCTAssertFalse(w.installEntityEcho(packages:"veil",safeMode:false,epoch:w.checkpointEpoch))
        snapshot.flags.formUnion(["phone-tutorial-finished","web.visited.archive",VeilArchive.discovery])
        let store=PhoneWorldStore(initial:snapshot,persistToDisk:false)
        let epoch=store.checkpointEpoch
        XCTAssertFalse(store.installEntityEcho(packages:"",safeMode:false,epoch:epoch))
        XCTAssertFalse(store.installEntityEcho(packages:"veil",safeMode:true,epoch:epoch))
        XCTAssertFalse(store.installEntityEcho(packages:"veil",safeMode:false,epoch:UUID()))
        XCTAssertTrue(store.installEntityEcho(packages:"veil",safeMode:false,epoch:epoch))
        XCTAssertFalse(store.installEntityEcho(packages:"veil",safeMode:false,epoch:epoch))
        for id in EntityEcho.overrides {
            XCTAssertTrue(EntityEcho.overridesTweak(id,flags:store.state.flags,safeMode:false))
            XCTAssertFalse(EntityEcho.overridesTweak(id,flags:store.state.flags,safeMode:true))
        }
        XCTAssertFalse(EntityEcho.overridesTweak("veil",flags:store.state.flags,safeMode:false))
        XCTAssertFalse(store.removeEntityEcho(answers:["Wallpaper"],epoch:epoch))
        XCTAssertFalse(store.removeEntityEcho(answers:EntityEcho.solution,epoch:UUID()))
        let encoded=try JSONEncoder().encode(store.state)
        let restored=try JSONDecoder().decode(PhoneWorld.self,from:encoded)
        let reload=PhoneWorldStore(initial:restored,persistToDisk:false)
        XCTAssertTrue(EntityEcho.active(reload.state.flags))
        XCTAssertTrue(reload.removeEntityEcho(answers:EntityEcho.solution,epoch:reload.checkpointEpoch))
        XCTAssertFalse(EntityEcho.active(reload.state.flags))
        XCTAssertFalse(reload.installEntityEcho(packages:"veil",safeMode:false,epoch:reload.checkpointEpoch))
        XCTAssertFalse(reload.removeEntityEcho(answers:EntityEcho.solution,epoch:reload.checkpointEpoch))
        XCTAssertEqual(reload.state.flags.subtracting([EntityEcho.installed,EntityEcho.removed]),store.state.flags.subtracting([EntityEcho.installed,EntityEcho.removed]))
        XCTAssertEqual(reload.state.threads.keys.sorted(),store.state.threads.keys.sorted())
        XCTAssertTrue(RelayCatalog.tweakActive("seconds",installed:"seconds",safeMode:false,flags:reload.state.flags))
    }
}
