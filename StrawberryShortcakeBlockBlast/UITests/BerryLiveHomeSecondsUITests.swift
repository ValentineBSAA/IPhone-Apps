import XCTest

/// Real Release-configuration Home UI check for the owner's second-accurate
/// 12-hour time and Moonlight/Sunrise countdown (not a fake static label).
final class BerryLiveHomeSecondsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeTimeAndCountdownShowSecondsAndAdvanceInRealTime() {
        let app = XCUIApplication()
        app.launchArguments += ["-berryblockblast.music", "NO",
                                "-berryblockblast.sound", "NO"]
        app.launch()

        let time = app.staticTexts["berry.home.clock.time"]
        let countdown = app.staticTexts["berry.home.clock.countdown"]
        XCTAssertTrue(time.waitForExistence(timeout: 30), "Home clock time is missing")
        XCTAssertTrue(countdown.waitForExistence(timeout: 15), "Home countdown is missing")

        XCTAssertNotNil(time.label.range(
            of: #"^\d{1,2}:\d{2}:\d{2} (AM|PM)$"#,
            options: .regularExpression),
            "iPhone Home clock must show hours, minutes, SECONDS and AM/PM: \(time.label)")
        XCTAssertNotNil(countdown.label.range(
            of: #"^(Moonlight|Sunrise) in \d{2}:\d{2}:\d{2}$"#,
            options: .regularExpression),
            "6 AM/6 PM countdown must show HH:MM:SS, not old '4h 1m': \(countdown.label)")

        let originalTime = time.label
        let change = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", originalTime),
            object: time
        )
        XCTAssertEqual(XCTWaiter.wait(for: [change], timeout: 5), .completed,
                       "The Home clock must visibly tick while the app is open")

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Build50 Home: live local 12-hour seconds and Moonlight/Sunrise countdown"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
