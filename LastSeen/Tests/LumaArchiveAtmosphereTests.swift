import XCTest
@testable import LastSeen

final class LumaArchiveAtmosphereTests: XCTestCase {
    func testVEILPresentationRequiresActiveAuthorizedSession() {
        var world = RestoredPhoneBackup.snapshot()
        world.flags.formUnion(["phone-tutorial-finished", "web.visited.archive", VeilArchive.discovery])
        func treatment(_ page: String = "records", security: String = "Standard",
                       intensity: LumaArchiveAtmosphere.Intensity = .standard,
                       enabled: Bool = true, reduceMotion: Bool = false,
                       connected: Bool = true, active: Bool = true, wifi: Bool = true,
                       packages: String = "veil", safeMode: Bool = false) -> LumaArchiveAtmosphere.Treatment? {
            LumaArchiveAtmosphere.veilTreatment(pageID: page, world: world, installed: packages,
                safeMode: safeMode, connected: connected, active: active, wifi: wifi,
                security: security, intensity: intensity, enabled: enabled, reduceMotion: reduceMotion)
        }
        let normal = treatment()
        XCTAssertNotNil(normal)
        XCTAssertNil(normal?.cue)
        XCTAssertGreaterThan(treatment("media")?.edgeOpacity ?? 0, normal?.edgeOpacity ?? 1)
        XCTAssertLessThan(treatment(security: "Safer")?.edgeOpacity ?? 1, normal?.edgeOpacity ?? 0)
        XCTAssertLessThan(treatment(intensity: .restrained)?.edgeOpacity ?? 1, normal?.edgeOpacity ?? 0)
        XCTAssertNil(treatment("directory"))
        XCTAssertNil(treatment("boards"))
        XCTAssertNil(treatment("fragment-04"))
        XCTAssertNil(treatment(security: "Safest"))
        XCTAssertNil(treatment(security: "invalid"))
        XCTAssertNil(treatment(intensity: .off))
        XCTAssertNil(treatment(enabled: false))
        XCTAssertNil(treatment(reduceMotion: true))
        XCTAssertNil(treatment(connected: false))
        XCTAssertNil(treatment(active: false))
        XCTAssertNil(treatment(wifi: false))
        XCTAssertNil(treatment(packages: ""))
        XCTAssertNil(treatment(safeMode: true))
        world.flags.insert(InvestigationResolution.completed)
        XCTAssertNil(treatment())
        world.flags.remove(InvestigationResolution.completed)
        world.flags.remove(VeilArchive.discovery)
        XCTAssertNil(treatment())
    }

    func testIndexRecordingCueIsDisposableAndNeverRepeats() {
        let treatment = LumaArchiveAtmosphere.Treatment(edgeOpacity:0.19,cue:nil)
        func cue(_ previous:Bool=false,_ recorded:Bool=true,
                 _ surface:LumaArchiveAtmosphere.Treatment?=nil,
                 intensity:LumaArchiveAtmosphere.Intensity = .standard,
                 security:String = "Standard")->PhoneCue? {
            LumaArchiveAtmosphere.indexRecordingCue(previouslyRecorded:previous,recorded:recorded,
                treatment:surface,intensity:intensity,security:security)
        }
        XCTAssertEqual(cue(false,true,treatment),.suspense)
        XCTAssertNil(cue(true,true,treatment))
        XCTAssertNil(cue(false,false,treatment))
        XCTAssertNil(cue())
        XCTAssertNil(cue(false,true,treatment,intensity:.restrained))
        XCTAssertNil(cue(false,true,treatment,intensity:.off))
        XCTAssertNil(cue(false,true,treatment,security:"Safer"))
        XCTAssertNil(cue(false,true,treatment,security:"Safest"))
        XCTAssertNil(LumaArchiveAtmosphere.friendTreatment(world:RestoredPhoneBackup.snapshot(),
            active:true,enabled:true,intensity:.standard,reduceMotion:false,security:"Standard"))
    }

    func testAuthorizedFirstEntryAndIntensity() {
        let flags: Set<String> = ["phone-tutorial-finished", "web.visited.studio", "investigation.contact.received",
                                  "web.visited.archive", "web.visited.archive-records"]
        let standard = LumaArchiveAtmosphere.treatment(pageID: "archive-records", flags: flags, intensity: .standard, enabled: true, reduceMotion: false)
        XCTAssertEqual(standard?.cue, .suspense)
        XCTAssertEqual(LumaArchiveAtmosphere.entryCue(pageID: "archive-records", previouslyVisited: false, active: true, treatment: standard), .suspense)
        XCTAssertNil(LumaArchiveAtmosphere.entryCue(pageID: "archive-records", previouslyVisited: true, active: true, treatment: standard))
        XCTAssertNil(LumaArchiveAtmosphere.entryCue(pageID: "archive-records", previouslyVisited: false, active: false, treatment: standard))
        let restrained = LumaArchiveAtmosphere.treatment(pageID: "archive-records", flags: flags, intensity: .restrained, enabled: true, reduceMotion: false)
        XCTAssertNil(restrained?.cue)
        XCTAssertLessThan(restrained?.edgeOpacity ?? 1, standard?.edgeOpacity ?? 0)
        XCTAssertNil(LumaArchiveAtmosphere.treatment(pageID: "archive-records", flags: flags, intensity: .standard, enabled: true, reduceMotion: true)?.cue)
        XCTAssertNil(LumaArchiveAtmosphere.treatment(pageID: "archive-records", flags: flags, intensity: .off, enabled: true, reduceMotion: false))
        XCTAssertNil(LumaArchiveAtmosphere.treatment(pageID: "archive-records", flags: flags, intensity: .standard, enabled: false, reduceMotion: false))
        XCTAssertNil(LumaArchiveAtmosphere.treatment(pageID: "archive-records", flags: [], intensity: .standard, enabled: true, reduceMotion: false))
        XCTAssertNil(LumaArchiveAtmosphere.treatment(pageID: "studio", flags: flags, intensity: .standard, enabled: true, reduceMotion: false))
        XCTAssertNil(LumaArchiveAtmosphere.treatment(pageID: "archive-records", flags: flags.union([InvestigationResolution.completed]), intensity: .standard, enabled: true, reduceMotion: false))
    }
}
