import XCTest

/// Native Board Studio / Settings persistence across real process relaunch.
/// Runs on a disposable iPhone simulator, never the owner's saved phone data.
final class BerryBoardAppearancePersistenceUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func startApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-berryblockblast.music", "NO",
            "-berryblockblast.sound", "NO"
        ]
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 25))
        addTeardownBlock {
            let picture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            picture.name = "Board Studio and Settings selected appearance on real simulator"
            picture.lifetime = .keepAlways
            self.add(picture)
        }
        return app
    }

    private func openBoardStudio(in app: XCUIApplication) {
        let boutique = app.buttons["Open Berry Boutique"]
        XCTAssertTrue(boutique.waitForExistence(timeout: 12))
        boutique.tap()
        let board = app.buttons["berry.boutique.category.boardStudio"]
        XCTAssertTrue(board.waitForExistence(timeout: 12),
                      "The actual Berry Boutique must expose Board Studio")
        board.tap()
        XCTAssertTrue(app.buttons["berry.boutique.board.original"]
                      .waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["berry.boutique.board.blossom-glass"].exists)
    }

    private func closeBoutique(in app: XCUIApplication) {
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10))
    }

    private func openAppearanceSettings(in app: XCUIApplication) {
        app.buttons["Settings"].tap()
        let card = app.buttons["berry.settings.appearance"]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        card.tap()
        XCTAssertTrue(app.buttons["berry.settings.board.original"]
                      .waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["berry.settings.board.blossom-glass"].exists)
    }

    private func closeAppearanceSettings(in app: XCUIApplication) {
        app.buttons["All Settings"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Open Berry Boutique"].waitForExistence(timeout: 10))
    }

    private func assertSelected(_ selected: String, other: String,
                                prefix: String, app: XCUIApplication,
                                file: StaticString = #filePath, line: UInt = #line) {
        let active = app.buttons[prefix + selected]
        let inactive = app.buttons[prefix + other]
        XCTAssertTrue(active.waitForExistence(timeout: 8), file: file, line: line)
        XCTAssertEqual(active.value as? String, "Selected", file: file, line: line)
        XCTAssertEqual(inactive.value as? String, "Not selected", file: file, line: line)
    }

    func testBoardStudioAndSettingsRemainInSyncThroughForceCloseAndReopen() {
        let app = startApp()
        let original = "original"
        let blossom = "blossom-glass"

        // Establish a known original baseline using the real Boutique tap.
        openBoardStudio(in: app)
        app.buttons["berry.boutique.board.original"].tap()
        assertSelected(original, other: blossom, prefix: "berry.boutique.board.", app: app)

        // Change to the original approved Blossom Glass visual surface.
        app.buttons["berry.boutique.board.blossom-glass"].tap()
        assertSelected(blossom, other: original, prefix: "berry.boutique.board.", app: app)
        closeBoutique(in: app)

        // Same saved preference must be reflected in the original Settings grid.
        openAppearanceSettings(in: app)
        assertSelected(blossom, other: original, prefix: "berry.settings.board.", app: app)
        closeAppearanceSettings(in: app)

        // Real process termination, not just re-opening a SwiftUI sheet.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 20))
        openBoardStudio(in: app)
        assertSelected(blossom, other: original, prefix: "berry.boutique.board.", app: app)
        closeBoutique(in: app)
        openAppearanceSettings(in: app)
        assertSelected(blossom, other: original, prefix: "berry.settings.board.", app: app)

        // Switching back through Settings must also update Boutique and persist.
        app.buttons["berry.settings.board.original"].tap()
        assertSelected(original, other: blossom, prefix: "berry.settings.board.", app: app)
        closeAppearanceSettings(in: app)
        openBoardStudio(in: app)
        assertSelected(original, other: blossom, prefix: "berry.boutique.board.", app: app)
        closeBoutique(in: app)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 20))
        openAppearanceSettings(in: app)
        assertSelected(original, other: blossom, prefix: "berry.settings.board.", app: app)
        closeAppearanceSettings(in: app)
    }
}
