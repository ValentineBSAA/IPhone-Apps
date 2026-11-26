import XCTest
import UIKit
@testable import LastSeen

final class RelaySupportKnowledgeTests: XCTestCase {
    @MainActor func testStandaloneSupportDoesNotAlterNoraThreads() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let world = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        let original = world.state.threads
        XCTAssertFalse(RelaySupportAccess.available(installed: "", flags: []))
        world.beginRelaySupport(installed: "", now: now)
        XCTAssertNil(world.state.relaySupport)
        world.beginRelaySupport(installed: "relay-support", now: now)
        world.beginRelaySupport(installed: "relay-support", now: now.addingTimeInterval(5))
        XCTAssertEqual(world.state.relaySupport?.messages.count, 1)
        XCTAssertEqual(world.state.threads, original)
        XCTAssertEqual(try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(world.state)).relaySupport, world.state.relaySupport)
        let package = try XCTUnwrap(RelayCatalog.package("relay-support"))
        XCTAssertEqual(PatchlinePackageHealth.status(package, installed: ["relay-support"], flags: [], safeMode: true), .active)
        XCTAssertTrue(LumaHomeLayout.pages(columns: 4, rows: 2, fieldNotes: false, support: true).flatMap { $0 }.flatMap { $0.apps }.contains(.relaySupport))
        XCTAssertFalse(LumaHomeLayout.pages(columns: 4, rows: 2, fieldNotes: false).flatMap { $0 }.flatMap { $0.apps }.contains(.relaySupport))
    }

    func testApprovedContentAndVisibility() throws {
        XCTAssertNotNil(UIImage(named: "Support_AlexMorgan"))
        XCTAssertNotNil(UIImage(named: "Icon_RelaySupport"))
        XCTAssertNotNil(RelaySupportKnowledge.packageHelp("compact", flags: []))
        XCTAssertNil(RelaySupportKnowledge.packageHelp("readerfocus", flags: []))
        XCTAssertNotNil(RelaySupportKnowledge.packageHelp("readerfocus", flags: ["web.visited.repo-folio"]))
        XCTAssertNil(RelaySupportKnowledge.packageHelp("invented-package", flags: []))
        XCTAssertEqual(RelaySupportKnowledge.generalGuides().count, 5)
        XCTAssertNil(RelaySupportKnowledge.generalGuide("packages-12"))
        for guide in RelaySupportKnowledge.generalGuides() {
            let name = (guide.filename as NSString).deletingPathExtension
            XCTAssertNotNil(Bundle.main.url(forResource: name, withExtension: "docx"))
            XCTAssertFalse(guide.sections.isEmpty)
        }
    }
}
