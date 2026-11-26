import XCTest
@testable import LastSeen

final class LumaArchiveAtmosphereTests: XCTestCase {
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
