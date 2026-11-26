import XCTest

/// Confidential UI acceptance. The seeded encounter is simulator/debug only;
/// the actual story trigger is covered by the main reachability unit fixture.
final class EntityEchoSmokeTests:XCTestCase {
    func testContainmentInterfaceRejectsAndRecovers() {
        continueAfterFailure=false
        let app=XCUIApplication()
        app.launchArguments=["--luma-ui-test","--luma-relay-clean-test","--luma-containment-test"]
        app.launch()
        func tapReachable(_ id:String) {
            let button=app.buttons[id].firstMatch
            for _ in 0..<10 {
                if button.exists && button.isHittable {break}
                app.swipeUp()
            }
            XCTAssertTrue(button.exists && button.isHittable,id)
            button.tap()
        }
        let warning=app.buttons["echo.containment.open"]
        XCTAssertTrue(warning.waitForExistence(timeout:12))
        warning.tap()
        XCTAssertTrue(app.navigationBars["Patchline"].waitForExistence(timeout:8))
        tapReachable("echo.containment.route")
        XCTAssertTrue(app.navigationBars["Echo containment"].waitForExistence(timeout:8))
        tapReachable("echo.trace.Wallpaper")
        XCTAssertFalse(app.staticTexts["Extension quarantined"].exists)
        tapReachable("echo.trace.Clock echo")
        tapReachable("echo.trace.Grid echo")
        tapReachable("echo.trace.Badge echo")
        tapReachable("echo.repair.Verify")
        tapReachable("echo.repair.Isolate")
        tapReachable("echo.repair.Restore")
        tapReachable("echo.commit")
        XCTAssertFalse(app.staticTexts["echo.containment.result"].exists)
        // The wrong order clears only the repair sequence. Scroll up to
        // return to its first choice, then complete the corrected attempt.
        app.swipeDown()
        tapReachable("echo.repair.Isolate")
        tapReachable("echo.repair.Verify")
        tapReachable("echo.repair.Restore")
        tapReachable("echo.commit")
        XCTAssertTrue(app.staticTexts["echo.containment.result"].waitForExistence(timeout:8))
    }
}
