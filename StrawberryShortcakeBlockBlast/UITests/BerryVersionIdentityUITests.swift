import XCTest

/// Regression for the old "Build 4.6 VISUAL LAB" hardcoded Home / Settings
/// labels surviving after the actual app version changed to v0.5.16 build 46.
final class BerryVersionIdentityUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRealHomeAndSettingsDisplayActualVersionNotLegacyBetaLabel() {
        let app = XCUIApplication()
        app.launchArguments += ["-berryblockblast.music", "NO",
                                "-berryblockblast.sound", "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 30))

        let home = app.staticTexts["🍓 v0.5.16 • B46 • I6 TEST"]
        XCTAssertTrue(home.waitForExistence(timeout: 15),
                      "Home must show the real Info.plist v0.5.16 and build 46, not the legacy B4.6 Visual Lab label")
        XCTAssertFalse(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "VISUAL LAB")).firstMatch.exists)

        app.buttons["Settings"].tap()
        let expected = app.staticTexts["Berry Berry Blast v0.5.16 • Build 46 • I6 Test"]
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        for _ in 0..<5 {
            if expected.exists { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(expected.waitForExistence(timeout: 10),
                      "Settings must show real bundle version/build, never old Build 4.6")
        XCTAssertFalse(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "VISUAL LAB")).firstMatch.exists)

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "I6 actual version and build after correcting old UI"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
