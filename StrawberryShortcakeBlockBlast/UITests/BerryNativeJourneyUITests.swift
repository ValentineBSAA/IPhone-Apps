import XCTest

/// Actual iPhone taps through production Home, Quest, Village, Journal,
/// Settings and gameplay surfaces. These tests run in a disposable simulator
/// app installation and never launch on an owner's physical phone.
final class BerryNativeJourneyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openGame() -> XCUIApplication {
        let app = XCUIApplication()
        // No audio during automated screen travel. This does not change the
        // real player's stored settings or use an internal QA reward wallet.
        app.launchArguments += [
            "-berryblockblast.music", "NO",
            "-berryblockblast.sound", "NO"
        ]
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 30),
                      "The genuine Berry home toolbar did not appear")
        addTeardownBlock {
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Berry real iPhone UI at test completion"
            shot.lifetime = .keepAlways
            self.add(shot)
        }
        return app
    }

    private func tapHomeTile(_ identifier: String,
                             in app: XCUIApplication,
                             file: StaticString = #filePath,
                             line: UInt = #line) {
        let tile = app.buttons[identifier]
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 10), file: file, line: line)
        for _ in 0..<9 {
            if tile.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(tile.isHittable, "Home tile \(identifier) is not reachable",
                      file: file, line: line)
        tile.tap()
    }

    func testRealHomeQuestVillageJournalNavigationAndLockedClaims() {
        let app = openGame()

        tapHomeTile("berry.home.village", in: app)
        XCTAssertTrue(app.staticTexts["berry.village.title"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["VILLAGE LEVEL 1 / 5"].exists)
        app.buttons["berry.village.done"].tap()

        tapHomeTile("berry.home.quests", in: app)
        XCTAssertTrue(app.staticTexts["berry.quests.title"].waitForExistence(timeout: 10))
        let claims = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "berry.quests.claim."))
        XCTAssertEqual(claims.count, 3, "The native Quest Board must show three daily quests")
        for i in 0..<claims.count {
            XCTAssertFalse(claims.element(boundBy: i).isEnabled,
                           "An unearned quest was claimable without playing")
        }
        app.buttons["berry.quests.done"].tap()

        tapHomeTile("berry.home.journal", in: app)
        XCTAssertTrue(app.staticTexts["berry.journal.title"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Story Chapters"].exists)
        app.buttons["berry.journal.done"].tap()
        XCTAssertTrue(app.buttons["berry.home.journal"].waitForExistence(timeout: 10))
    }

    func testRealCelebrationsSettingsExposeLocalBirthdayPickers() {
        let app = openGame()
        XCTAssertFalse(app.buttons["berry.home.birthday.claim"].exists,
                       "No birthday gift should appear without a matching saved date")
        app.buttons["Settings"].tap()
        let celebrations = app.buttons["berry.settings.celebration"]
        XCTAssertTrue(celebrations.waitForExistence(timeout: 10))
        celebrations.tap()

        XCTAssertTrue(app.staticTexts["Birthday Month"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Birthday Day"].exists)
        XCTAssertTrue(app.descendants(matching: .any)[
            "berry.settings.birthday.month"].exists)
        XCTAssertTrue(app.descendants(matching: .any)[
            "berry.settings.birthday.day"].exists)
        XCTAssertTrue(app.staticTexts[
            "Your birthday stays on this iPhone. Only month and day are saved, not your birth year."].exists)
        app.buttons["All Settings"].tap()
        XCTAssertTrue(app.buttons["berry.settings.celebration"].exists)
    }

    func testRealClassicGameplayHelpPauseResumeAndHome() {
        let app = openGame()
        let classic = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Berry Classic.")).firstMatch
        XCTAssertTrue(classic.waitForExistence(timeout: 10))
        classic.tap()

        let welcome = app.buttons["Let's Grow!"]
        if welcome.waitForExistence(timeout: 5) { welcome.tap() }

        let help = app.buttons["How to Play"]
        XCTAssertTrue(help.waitForExistence(timeout: 15),
                      "Classic gameplay must expose its real Help control")
        help.tap()
        XCTAssertTrue(app.staticTexts["Drag or Tap"].waitForExistence(timeout: 10))
        app.buttons["Back to Playing"].tap()

        app.buttons["Pause game"].tap()
        XCTAssertTrue(app.staticTexts["A Little Berry Break"].waitForExistence(timeout: 10))
        app.buttons["Continue Gardening"].tap()
        XCTAssertTrue(app.buttons["How to Play"].waitForExistence(timeout: 10))

        app.buttons["Pause game"].tap()
        XCTAssertTrue(app.staticTexts["A Little Berry Break"].waitForExistence(timeout: 10))
        // This is the overlay's actual player-facing exit action.
        app.buttons["berry.game.pause.return"].tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10))
    }
}
