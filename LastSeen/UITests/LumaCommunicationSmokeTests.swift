import XCTest

final class LumaCommunicationSmokeTests: XCTestCase {
    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    // Locate actual home icons through the new page dots, never a vertical list.
    private func homeIcon(_ name:String,in app:XCUIApplication)->XCUIElement {
        let icon=app.buttons["luma.app."+name]
        if icon.isHittable{return icon}
        for index in 0..<8 {
            let dot=app.buttons["luma.home.page.\(index)"]
            guard dot.exists else{break}
            dot.tap()
            let ready=XCTNSPredicateExpectation(predicate:NSPredicate(format:"hittable == true"),object:icon)
            if XCTWaiter.wait(for:[ready],timeout:2) == .completed{return icon}
        }
        XCTAssertTrue(icon.isHittable,"Home icon not reachable: "+name)
        return icon
    }
    func testPagedLauncherFoldersAndFixedDock() {
        continueAfterFailure=false
        let app=XCUIApplication()
        app.launchArguments=["--luma-ui-test","--luma-relay-clean-test"]
        app.launch()
        let page0=app.buttons["luma.home.page.0"]
        XCTAssertTrue(page0.waitForExistence(timeout:12))
        page0.tap()
        let photos=app.buttons["luma.app.Photos"]
        let dockPhone=app.buttons["luma.app.Phone"]
        XCTAssertTrue(photos.isHittable)
        XCTAssertTrue(dockPhone.isHittable)
        let photoFrame=photos.frame
        let dockFrame=dockPhone.frame
        let from=app.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.63))
        let to=app.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.39))
        from.press(forDuration:0.08,thenDragTo:to)
        XCTAssertTrue(photos.isHittable)
        XCTAssertEqual(photos.frame.minY,photoFrame.minY,accuracy:3)
        XCTAssertEqual(dockPhone.frame.minY,dockFrame.minY,accuracy:3)
        screenshot("Home page one, fixed grid")
        let folder=app.buttons["luma.folder.studio"]
        XCTAssertTrue(folder.isHittable)
        folder.tap()
        let files=app.buttons["luma.app.Files"]
        XCTAssertTrue(files.waitForExistence(timeout:8))
        XCTAssertTrue(files.isHittable)
        XCTAssertTrue(app.buttons["luma.app.Connective"].isHittable)
        screenshot("Blue Hour folder")
        files.tap()
        XCTAssertTrue(app.navigationBars["Files"].waitForExistence(timeout:8))
        app.buttons["luma.home"].firstMatch.tap()
        XCTAssertTrue(page0.waitForExistence(timeout:8))
        page0.tap()
        let page1=app.buttons["luma.home.page.1"]
        XCTAssertTrue(page1.exists)
        app.coordinate(withNormalizedOffset:CGVector(dx:0.83,dy:0.48)).press(forDuration:0.08,thenDragTo:app.coordinate(withNormalizedOffset:CGVector(dx:0.17,dy:0.48)))
        let relay=app.buttons["luma.app.Relay"]
        let ready=XCTNSPredicateExpectation(predicate:NSPredicate(format:"hittable == true"),object:relay)
        XCTAssertEqual(XCTWaiter.wait(for:[ready],timeout:8),.completed)
        XCTAssertTrue(dockPhone.isHittable)
        XCTAssertEqual(dockPhone.frame.minY,dockFrame.minY,accuracy:3)
        screenshot("Home page two, persistent dock")
    }
    func testRecoveryCircuitEarnsPackageAndInstallsFieldNotes() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--luma-ui-test", "--luma-relay-clean-test"]
        app.launch()
        XCTAssertTrue(app.buttons["luma.home.page.0"].waitForExistence(timeout:12))
        homeIcon("Patchline",in:app).tap()
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
        func waitHittable(_ element: XCUIElement, timeout: TimeInterval = 20) {
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: element)
            XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: timeout), .completed)
        }
        func openRelay() {
            let relay = homeIcon("Relay",in:app)
            waitHittable(relay); relay.tap()
            XCTAssertTrue(app.navigationBars["Relay"].waitForExistence(timeout: 8))
        }
        func findFieldNotes() {
            let searchTab = app.buttons["relay.tab.Search"]
            waitHittable(searchTab); searchTab.tap()
            let row = app.buttons["relay.package.fieldnotes"]
            let search = app.textFields.firstMatch
            if search.waitForExistence(timeout: 3) {
                if (search.value as? String) != "Field Notes" {
                    search.tap()
                    if let existing = search.value as? String, !existing.isEmpty, existing != search.placeholderValue {
                        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
                    }
                    search.typeText("Field Notes")
                }
                if app.keyboards.buttons["Search"].exists { app.keyboards.buttons["Search"].tap() }
            }
            for _ in 0..<6 where !row.isHittable { app.swipeUp() }
            waitHittable(row); row.tap()
        }
        func confirmQueue() {
            let queue = app.buttons["relay.queue"]
            waitHittable(queue); queue.tap()
            let confirm = app.buttons["relay.queue.confirm"]
            waitHittable(confirm); confirm.tap()
        }
        func finishRestart() {
            let restart = app.buttons["relay.transaction.restart"]
            // Do not use the skip button: verify automatic log completion.
            waitHittable(restart, timeout: 20); restart.tap()
            let unlock = app.buttons["luma.lock.unlock"]
            waitHittable(unlock, timeout: 30); unlock.tap()
        }
        // Recovery Circuit is a nested NavigationLink, not a top-level app.
        let back = app.navigationBars["Recovery Circuit"].buttons.firstMatch
        waitHittable(back); back.tap()
        let relayLink = app.buttons.containing(.staticText, identifier: "Open Relay").firstMatch
        for _ in 0..<4 where !relayLink.isHittable { app.swipeUp() }
        waitHittable(relayLink); relayLink.tap()
        XCTAssertTrue(app.navigationBars["Relay"].waitForExistence(timeout: 8))
        findFieldNotes()
        app.buttons["Queue Install"].tap()
        confirmQueue(); finishRestart()
        let notes = homeIcon("Field Notes",in:app)
        XCTAssertTrue(notes.isHittable)
        screenshot("Field Notes installed after respring")
        openRelay(); findFieldNotes()
        app.buttons["Queue Removal"].tap()
        confirmQueue()
        let cancel = app.buttons["relay.transaction.cancel"]
        waitHittable(cancel); cancel.tap()
        // A cancelled removal remains uncommitted, and the package stays installed.
        findFieldNotes()
        XCTAssertTrue(app.buttons["Queue Removal"].waitForExistence(timeout: 8))
        app.buttons["Done"].tap()
        confirmQueue(); finishRestart()
        _ = homeIcon("Relay",in:app)
        XCTAssertFalse(app.buttons["luma.app.Field Notes"].exists)
        screenshot("Field Notes removed after respring")
    }
    func testCommunicationAndCheckpointNavigation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--luma-ui-test"]
        app.launch()
        func open(_ name: String) {
            XCTAssertTrue(app.buttons["luma.home.page.0"].waitForExistence(timeout:12),name)
            homeIcon(name,in:app).tap()
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
