import XCTest

/// Release-scheme iPhone tests for the exact owner-discovered number-pad
/// problem. These only type into fields; they never confirm a real cheat.
final class BerryNumericKeyboardAndNoticeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPINAndCheatNumberPadsHaveWorkingDoneAndNoticeStudioIsVisible() {
        let app = XCUIApplication()
        app.launchArguments += ["-berryblockblast.music", "NO",
                                "-berryblockblast.sound", "NO"]
        app.launch()
        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 30))
        settings.tap()

        let version = app.staticTexts["berry.settings.version.developer"]
        let settingsScroll = app.scrollViews.firstMatch
        for _ in 0..<8 {
            if version.isHittable { break }
            settingsScroll.swipeUp()
        }
        XCTAssertTrue(version.isHittable)
        version.press(forDuration: 2.1)

        let pin = app.secureTextFields["Four digit developer PIN"]
        XCTAssertTrue(pin.waitForExistence(timeout: 10))
        pin.tap()
        pin.typeText("1476")
        let keyboardDone = app.buttons["berry.numeric.keyboard.done"]
        XCTAssertTrue(keyboardDone.waitForExistence(timeout: 10),
                      "Number pad for PIN must supply a custom Done button")
        keyboardDone.tap()
        XCTAssertTrue(app.buttons["Unlock"].isEnabled)
        app.buttons["Unlock"].tap()

        let cheat = app.buttons["berry.developer.tool.Cheat Strawberries"]
        XCTAssertTrue(cheat.waitForExistence(timeout: 10))
        cheat.tap()
        let amount = app.textFields["berry.developer.cheat.amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 10))
        amount.tap()
        amount.typeText("200")
        XCTAssertTrue(keyboardDone.waitForExistence(timeout: 10),
                      "Number pad for Strawberry cheat must supply a custom Done button")
        keyboardDone.tap()
        XCTAssertEqual(amount.value as? String, "200",
                       "Dismissing the keyboard must not submit or erase the amount")
        XCTAssertTrue(app.buttons["Review strawberry grant"].exists)
        // Close without ever confirming the cheat or changing any real wallet.
        let close = app.buttons["berry.developer.tool.done"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        close.tap()

        let more = app.buttons["More diagnostics and build information"]
        XCTAssertTrue(more.waitForExistence(timeout: 10))
        more.tap()
        let devScroll = app.scrollViews["berry.developer.scroll"]
        XCTAssertTrue(devScroll.waitForExistence(timeout: 10))
        // The working Notification Test is intentionally first in advanced
        // cards. Scroll once to bring that row onto the screen instead of
        // querying isHittable on an offscreen LazyVGrid cell (XCUITest can
        // throw "Activation point invalid" before it can auto-scroll).
        devScroll.swipeUp()
        let notices = app.buttons["berry.developer.tool.Notification Test"]
        XCTAssertTrue(notices.waitForExistence(timeout: 10),
                      "Notification Test card should exist in the expanded grid")
        notices.tap()
        XCTAssertTrue(app.staticTexts["STRAWBERRY NOTICE STUDIO • SAFE PREVIEW"]
                      .waitForExistence(timeout: 10))
        let success = app.buttons["berry.developer.notice.success"]
        if !success.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(success.waitForExistence(timeout: 10))
        success.tap()
        XCTAssertTrue(app.otherElements["berry.developer.notice.preview"]
                      .waitForExistence(timeout: 5) ||
                      app.staticTexts["berry.developer.notice.preview"].exists,
                      "A real BerryNoticeBanner preview must be visible")

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Build50: number pad Done and Strawberry in-app notice studio"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
