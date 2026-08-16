import XCTest

final class BlueNapUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesSettingsWindow() {
        let app = launchApp(openSettings: true)

        XCTAssertTrue(app.windows["BlueNap Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.checkboxes["Launch at login"].exists)
        XCTAssertTrue(app.checkboxes["Show menu bar icon"].exists)
        XCTAssertTrue(app.buttons["Refresh device list"].exists)
    }

    func testShowMenuBarIconToggleCanBeTurnedOffAndOn() {
        let app = launchApp(openSettings: true)
        let toggle = app.checkboxes["Show menu bar icon"]

        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? Int, 1)

        toggle.click()
        XCTAssertEqual(toggle.value as? Int, 0)

        toggle.click()
        XCTAssertEqual(toggle.value as? Int, 1)
    }

    func testRefreshButtonIsClickable() {
        let app = launchApp(openSettings: true)
        let refreshButton = app.buttons["Refresh device list"]

        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.click()
        XCTAssertTrue(app.windows["BlueNap Settings"].exists)
    }

    private func launchApp(openSettings: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_MODE"] = "1"
        app.launchArguments = ["--uitest-reset-defaults"]
        if openSettings {
            app.launchArguments.append("--uitest-open-settings")
        }
        app.launch()
        return app
    }
}
