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
            // A rejected selection or an expanded stage can move the desired
            // control above the current viewport. Search both directions.
            if !button.isHittable {
                for _ in 0..<10 {
                    if button.isHittable {break}
                    app.swipeDown()
                }
            }
            if !button.isHittable {
                for _ in 0..<10 {
                    if button.isHittable {break}
                    app.swipeUp()
                }
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
        XCTAssertTrue(app.staticTexts["That hook is legitimate. Review the trace and try another."].exists)
        XCTAssertFalse(app.staticTexts["Extension quarantined"].exists)
        tapReachable("echo.trace.Clock echo")
        tapReachable("echo.trace.Grid echo")
        tapReachable("echo.trace.Badge echo")
        tapReachable("echo.repair.Verify")
        tapReachable("echo.repair.Isolate")
        tapReachable("echo.repair.Restore")
        tapReachable("echo.commit")
        XCTAssertTrue(app.staticTexts["Service order is not verified. Recheck the dependency hints."].exists)
        XCTAssertFalse(app.staticTexts["echo.containment.result"].exists)
        XCTAssertFalse(app.buttons["echo.commit"].isEnabled)
        // A rejected repair order clears only its stage. The helper can find
        // the earlier choices again even after scrolling to the final button.
        tapReachable("echo.repair.Isolate")
        tapReachable("echo.repair.Verify")
        tapReachable("echo.repair.Restore")
        tapReachable("echo.commit")
        XCTAssertTrue(app.staticTexts["echo.containment.result"].waitForExistence(timeout:8))
    }
}
