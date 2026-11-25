import XCTest
@testable import LastSeen

final class WelcomeBriefingTests: XCTestCase {
    func testApprovedSectionsAndStoryPremise() {
        let sections = WelcomeBriefing.sections
        XCTAssertEqual(sections.map(\.id), Array(1...10))
        XCTAssertEqual(sections.map(\.title), [
            "How it all began", "Your role", "Navigating your phone", "The world inside",
            "Patchline", "Relay Package Manager", "Protected information",
            "Understanding the experience", "Community acknowledgments", "Privacy and immersion"
        ])
        XCTAssertTrue(sections[0].paragraphs.contains { $0.contains("Someone brought you a phone") })
        XCTAssertTrue(sections[0].paragraphs.contains { $0.contains("backup is waiting to be restored") })
        XCTAssertEqual(sections[2].bullets.count, 7)
        XCTAssertEqual(sections[4].bullets.count, 6)
        XCTAssertTrue(sections[5].paragraphs.contains("All available packages are free."))
        XCTAssertTrue(sections[6].paragraphs.contains { $0.contains("passcode has been verified") })
        XCTAssertTrue(sections[7].paragraphs.contains { $0.contains("slow-burn psychological horror") })
        XCTAssertTrue(sections[8].paragraphs.contains { $0.contains("Installer, Cydia") && $0.contains("SnowBoard") })
        XCTAssertTrue(sections[9].paragraphs.contains { $0.contains("No real jailbreak") })
        XCTAssertEqual(WelcomeBriefing.closingLine, "Every phone holds a story. Some are better left unseen.")
        for section in sections {
            XCTAssertFalse(section.paragraphs.isEmpty)
            XCTAssertFalse((section.paragraphs + section.bullets + section.ending).contains { $0.isEmpty })
        }
    }

    func testWelcomeUpgradePreservesOpeningAndSetupRouting() {
        XCTAssertEqual(WelcomeRevision.current, 7)
        XCTAssertEqual(WelcomeRevision.destination(previousRevision: 0, stage: 0), 0)
        XCTAssertEqual(WelcomeRevision.destination(previousRevision: 5, stage: 6), 0)
        for stage in 0...5 {
            XCTAssertEqual(WelcomeRevision.destination(previousRevision: 6, stage: stage), stage)
        }
        XCTAssertEqual(WelcomeRevision.destination(previousRevision: 6, stage: 6), 5)
        XCTAssertEqual(WelcomeRevision.destination(previousRevision: 7, stage: 6), 6)
    }
}
