import XCTest
import UIKit
@testable import LastSeen

final class RelaySupportKnowledgeTests: XCTestCase {
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
