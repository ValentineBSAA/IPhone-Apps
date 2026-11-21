import XCTest

/// Genuine production Daily/Story screen interactions on a disposable
/// iPhone 16e simulator. No injected money, fake reward, or owner save.
final class BerryDailyStoryJourneyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-berryblockblast.music", "NO",
            "-berryblockblast.sound", "NO"
        ]
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 25))
        addTeardownBlock {
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Actual Story or Daily Harvest iPhone screen"
            shot.lifetime = .keepAlways
            self.add(shot)
        }
        return app
    }

    private func openHomeCard(_ id: String, app: XCUIApplication) {
        let tile = app.buttons[id]
        let scroller = app.scrollViews.firstMatch
        XCTAssertTrue(scroller.waitForExistence(timeout: 8))
        // Return to the top after an earlier sheet, then locate below fold.
        for _ in 0..<8 {
            if tile.isHittable { break }
            scroller.swipeDown()
        }
        for _ in 0..<12 {
            if tile.isHittable { break }
            scroller.swipeUp()
        }
        XCTAssertTrue(tile.isHittable, "The original card was not reachable: \(id)")
        tile.tap()
    }

    private func closeWelcomeIfNeeded(in app: XCUIApplication) {
        let welcome = app.buttons["Let's Grow!"]
        if welcome.waitForExistence(timeout: 4) { welcome.tap() }
    }

    private func pauseAndReturn(in app: XCUIApplication) {
        let pause = app.buttons["Pause game"]
        XCTAssertTrue(pause.waitForExistence(timeout: 12))
        pause.tap()
        XCTAssertTrue(app.staticTexts["A Little Berry Break"].waitForExistence(timeout: 8))
        app.buttons["berry.game.pause.return"].tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 12))
    }

    func testActualHarvestAlmanacAndStoryDialogueOpenAndReturn() {
        let app = launch()
        openHomeCard("berry.home.dailyCalendar", app: app)
        XCTAssertTrue(app.staticTexts["Harvest Garden"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["TODAY'S BERRY QUEST"].exists)
        XCTAssertTrue(app.buttons["berry.dailyCalendar.done"].exists)
        app.buttons["berry.dailyCalendar.done"].tap()

        openHomeCard("berry.home.mode.Berry Story", app: app)
        closeWelcomeIfNeeded(in: app)
        let dialogue = app.buttons["berry.story.dialogue"]
        XCTAssertTrue(dialogue.waitForExistence(timeout: 10),
                      "The player must see Story dialogue above the board")
        dialogue.tap()
        XCTAssertTrue(app.alerts["Berry Story"].waitForExistence(timeout: 10))
        app.alerts["Berry Story"].buttons["Back to the Garden"].tap()
        pauseAndReturn(in: app)
        XCTAssertTrue(app.buttons["berry.home.mode.Berry Story"].exists)
    }

    func testActualDailyAttemptResumesRatherThanSilentlyStartingOver() {
        let app = launch()
        let dailyID = "berry.home.mode.Daily Harvest"
        openHomeCard(dailyID, app: app)
        closeWelcomeIfNeeded(in: app)
        pauseAndReturn(in: app)

        let tile = app.buttons[dailyID]
        XCTAssertTrue(tile.waitForExistence(timeout: 8))
        XCTAssertTrue(tile.label.contains("Resume Today"),
                      "An interrupted Daily must remain resumable, not reissued")

        openHomeCard(dailyID, app: app)
        closeWelcomeIfNeeded(in: app)
        pauseAndReturn(in: app)
        XCTAssertTrue(app.buttons[dailyID].label.contains("Resume Today"))

        openHomeCard("berry.home.dailyCalendar", app: app)
        XCTAssertTrue(app.staticTexts[
            "Your garden is still growing. Resume today's attempt."].waitForExistence(timeout: 8))
        app.buttons["berry.dailyCalendar.done"].tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 8))
    }
}
