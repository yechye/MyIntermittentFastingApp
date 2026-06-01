//
//  FastingAppUITests.swift
//  FastingAppUITests
//
//  Created by Tal Yechye on 29/05/2026.
//

import XCTest

final class FastingAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testStartFastStartsElapsedTimer() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetTimerForUITests"]
        app.launch()

        let startButton = app.buttons["timer.startFastButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let elapsedText = app.staticTexts["timer.elapsedText"]
        XCTAssertTrue(elapsedText.waitForExistence(timeout: 5))

        let timerAdvanced = NSPredicate(format: "label != %@", "00:00:00")
        expectation(for: timerAdvanced, evaluatedWith: elapsedText)
        waitForExpectations(timeout: 3)

        XCTAssertTrue(app.buttons["timer.endFastButton"].exists)
    }

    @MainActor
    func testEndingFastEarlyAsCompletedReturnsToStartState() throws {
        let app = XCUIApplication()

        try endFastEarly(in: app, choosingButtonIdentifier: "timer.saveAsCompletedButton")

        XCTAssertTrue(app.buttons["timer.startFastButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["timer.endFastButton"].exists)
    }

    @MainActor
    func testEndingFastEarlyAsSkippedReturnsToStartState() throws {
        let app = XCUIApplication()

        try endFastEarly(in: app, choosingButtonIdentifier: "timer.saveAsSkippedButton")

        XCTAssertTrue(app.buttons["timer.startFastButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["timer.endFastButton"].exists)
    }

    @MainActor
    func disabled_testLaunchPerformance() throws {
        // Rename to `testLaunchPerformance` when launch metrics should be collected.
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    private func endFastEarly(in app: XCUIApplication, choosingButtonIdentifier actionIdentifier: String) throws {
        app.launchArguments = ["-resetTimerForUITests"]
        app.launch()

        let startButton = app.buttons["timer.startFastButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let elapsedText = app.staticTexts["timer.elapsedText"]
        XCTAssertTrue(elapsedText.waitForExistence(timeout: 5))

        let timerAdvanced = NSPredicate(format: "label != %@", "00:00:00")
        expectation(for: timerAdvanced, evaluatedWith: elapsedText)
        waitForExpectations(timeout: 3)

        let endButton = app.buttons["timer.endFastButton"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 5))
        endButton.tap()

        let actionButton = app.buttons[actionIdentifier].firstMatch
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5))
        actionButton.tap()
    }
}
