import XCTest

/// Deliberately tests the same Release config as the private real-device
/// Developer Garden build. Checks cheats exist without actually granting coins.
final class BerryDeveloperGardenPhysicalQAUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLongPressPINAndIsolatedDeveloperLabsAreActuallyAccessible() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-berryblockblast.music", "NO",
            "-berryblockblast.sound", "NO"
        ]
        app.launch()

        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 30))
        settings.tap()

        let version = app.staticTexts["berry.settings.version.developer"]
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        for _ in 0..<8 {
            if version.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(version.isHittable, "Actual Settings version label must be reachable")
        XCTAssertEqual(version.label, "Berry Berry Blast v0.5.16 • Build 48 • I6 QA")
        version.press(forDuration: 2.1)

        let pin = app.secureTextFields["Four digit developer PIN"]
        XCTAssertTrue(pin.waitForExistence(timeout: 10),
                      "Holding Settings version must open the PIN-protected Developer Garden in physical QA")
        pin.tap()
        pin.typeText("1476")
        let unlock = app.buttons["Unlock"]
        XCTAssertTrue(unlock.isEnabled)
        unlock.tap()

        XCTAssertTrue(app.staticTexts["HIDDEN DEVELOPER GARDEN • Tests are isolated; cheats change saves only when confirmed"]
                      .waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["berry.developer.tool.Diagnostics"].exists)
        XCTAssertTrue(app.buttons["berry.developer.tool.Save Inspector"].exists)

        // This is deliberately a permanent, opt-in CHEAT tool in installable
        // Release builds. Never use a player's real wallet in simulator tests.
        let cheat = app.buttons["berry.developer.tool.Cheat Strawberries"]
        XCTAssertTrue(cheat.isHittable, "Owner's voluntary cheat control cannot disappear from Release")
        cheat.tap()
        XCTAssertTrue(app.staticTexts["OPTIONAL CHEAT • ADDS TO YOUR REAL SAVED WALLET"]
                      .waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Review strawberry grant"].exists,
                      "A cheat must require an explicit confirmation before changing saves")
        let closeTool = app.buttons["berry.developer.tool.done"]
        XCTAssertTrue(closeTool.waitForExistence(timeout: 10),
                      "Cheat sheet must have its own unambiguous Done control")
        closeTool.tap()

        let more = app.buttons["More diagnostics and build information"]
        XCTAssertTrue(more.waitForExistence(timeout: 10))
        more.tap()

        let lab = app.buttons["berry.developer.tool.Commerce Lab"]
        let devScroll = app.scrollViews["berry.developer.scroll"]
        XCTAssertTrue(devScroll.waitForExistence(timeout: 10),
                      "Developer Garden must expose the actual scrolling card grid")
        for _ in 0..<10 {
            if lab.isHittable { break }
            devScroll.swipeUp()
        }
        XCTAssertTrue(lab.isHittable, "Isolated Commerce Lab must be accessible in private device QA")
        lab.tap()
        XCTAssertTrue(app.staticTexts["REAL CHECKOUT • DISPOSABLE TEST WALLET"]
                      .waitForExistence(timeout: 10),
                      "Physical QA must expose actual isolated purchase handlers, not a placeholder")

        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "Physical I6 QA: PIN developer menu and isolated Commerce Lab"
        capture.lifetime = .keepAlways
        add(capture)
    }
}
