import XCTest

final class LumaCommunicationSmokeTests: XCTestCase {
    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    func testRecoveryCircuitEarnsPackage() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--luma-ui-test"]
        app.launch()
        let icon = app.buttons["luma.app.Patchline"]
        XCTAssertTrue(icon.waitForExistence(timeout: 12))
        if !icon.isHittable { app.swipeUp() }
        icon.tap()
        let challenge = app.buttons.containing(.staticText, identifier: "Recovery Circuit").firstMatch
        XCTAssertTrue(challenge.waitForExistence(timeout: 10))
        challenge.tap()
        let verify = app.buttons["Verify sequence"]
        for stage in [["Index","Verify","Mount"],["Scan","Repair","Reload"],["Prepare","Link","Activate"]] {
            for name in stage {
                let choice = app.buttons["circuit.choice." + name]
                XCTAssertTrue(choice.waitForExistence(timeout: 8))
                if !choice.isHittable { app.swipeUp() }
                choice.tap()
            }
            if !verify.isHittable { app.swipeUp() }
            XCTAssertTrue(verify.isEnabled)
            verify.tap()
        }
        XCTAssertTrue(app.staticTexts["Service verified"].firstMatch.waitForExistence(timeout: 10))
        screenshot("Recovery Circuit completion")
    }
    func testCommunicationAndCheckpointNavigation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--luma-ui-test"]
        app.launch()
        func open(_ name: String) {
            let icon = app.buttons["luma.app." + name]
            XCTAssertTrue(icon.waitForExistence(timeout: 12), name)
            if !icon.isHittable { app.swipeUp() }
            icon.tap()
            XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 8), name)
            screenshot(name)
        }
        func home() {
            let handle = app.buttons["luma.home"].firstMatch
            XCTAssertTrue(handle.waitForExistence(timeout: 8))
            handle.tap()
        }
        open("Messages")
        XCTAssertTrue(app.buttons["New message"].exists)
        home()
        open("Contacts")
        XCTAssertTrue(app.staticTexts["My Card"].exists)
        home()
        open("Phone")
        let contacts = app.buttons["luma.phone.tab.Contacts"]
        XCTAssertTrue(contacts.waitForExistence(timeout: 8))
        contacts.tap()
        XCTAssertTrue(app.staticTexts["Maya Brooks"].exists)
        app.staticTexts["Maya Brooks"].tap()
        let call = app.buttons["luma.phone.call"]
        XCTAssertTrue(call.waitForExistence(timeout: 8))
        screenshot("Fictional call")
        call.tap()
        XCTAssertTrue(app.staticTexts["No answer"].waitForExistence(timeout: 12))
        home()
        open("Settings")
        XCTAssertTrue(app.staticTexts["Game Saves"].exists)
        home()
        open("Game Saves")
        let save = app.buttons["luma.save.manual-1"]
        XCTAssertTrue(save.waitForExistence(timeout: 8))
        save.tap()
        let load = app.buttons["luma.load.manual-1"]
        XCTAssertTrue(load.waitForExistence(timeout: 8))
        XCTAssertFalse(save.isEnabled)
        screenshot("Game Saves")
        load.tap()
        let confirm = app.buttons.matching(NSPredicate(format: "label == %@", "Load")).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 8))
        confirm.tap()
        let unlock = app.buttons["luma.lock.unlock"]
        XCTAssertTrue(unlock.waitForExistence(timeout: 30))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: unlock)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 35), .completed)
        screenshot("Restored lock screen")
    }
}
