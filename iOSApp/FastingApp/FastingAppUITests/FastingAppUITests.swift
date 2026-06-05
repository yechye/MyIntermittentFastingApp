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
    func testScheduleAppliesBeginnerTemplate() throws {
        let app = XCUIApplication()
        launchSchedule(in: app)

        applyBeginnerScheduleTemplate(in: app)

        XCTAssertTrue(app.staticTexts["16:8 Intermittent Fasting"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "16:8 Window")).firstMatch.exists)
    }

    @MainActor
    func testScheduleAsksToApplyNewFastingStartToOtherDays() throws {
        let app = XCUIApplication()
        launchSchedule(in: app)
        applyBeginnerScheduleTemplate(in: app)

        openScheduleDay(2, in: app)
        let statePicker = app.segmentedControls["schedule.editor.statePicker"]
        XCTAssertTrue(statePicker.waitForExistence(timeout: 5))
        statePicker.buttons["Cheat"].tap()
        app.buttons["schedule.editor.saveButton"].tap()
        XCTAssertTrue(app.staticTexts["Cheat day"].waitForExistence(timeout: 5))

        openScheduleDay(2, in: app)
        let updatedStatePicker = app.segmentedControls["schedule.editor.statePicker"]
        XCTAssertTrue(updatedStatePicker.waitForExistence(timeout: 5))
        updatedStatePicker.buttons["Fasting"].tap()
        app.buttons["schedule.editor.saveButton"].tap()

        XCTAssertTrue(app.buttons["schedule.applyStartTimeToOtherDaysButton"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["schedule.keepSingleDayStartTimeButton"].firstMatch.exists)
    }

    @MainActor
    func testScheduleDayEditorCanSaveCheatDay() throws {
        let app = XCUIApplication()
        launchSchedule(in: app)

        openScheduleDay(2, in: app)

        let statePicker = app.segmentedControls["schedule.editor.statePicker"]
        XCTAssertTrue(statePicker.waitForExistence(timeout: 5))
        statePicker.buttons["Cheat"].tap()

        let reasonField = app.textFields["schedule.editor.cheatReason"]
        XCTAssertTrue(reasonField.waitForExistence(timeout: 5))
        reasonField.tap()
        reasonField.typeText("Family dinner")

        app.buttons["schedule.editor.saveButton"].tap()

        XCTAssertTrue(app.staticTexts["Cheat day"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Family dinner"].exists)
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

    @MainActor
    private func applyBeginnerScheduleTemplate(in app: XCUIApplication) {
        let templatesButton = app.buttons["schedule.templatesButton"]
        XCTAssertTrue(templatesButton.waitForExistence(timeout: 5))
        templatesButton.tap()

        let beginnerTemplate = app.buttons["schedule.template.beginner16_8"]
        XCTAssertTrue(beginnerTemplate.waitForExistence(timeout: 5))
        beginnerTemplate.tap()

        let applyButton = app.buttons["schedule.applyTemplateButton"].firstMatch
        XCTAssertTrue(applyButton.waitForExistence(timeout: 5))
        applyButton.tap()
    }

    @MainActor
    private func openScheduleDay(_ weekday: Int, in app: XCUIApplication) {
        let day = app.buttons.matching(identifier: "schedule.day.\(weekday)").firstMatch
        XCTAssertTrue(day.waitForExistence(timeout: 5))
        day.tap()
    }

    @MainActor
    private func launchSchedule(in app: XCUIApplication) {
        app.launchArguments = [
            "-resetTimerForUITests",
            "-resetScheduleForUITests",
            "-skipSplashForUITests",
            "-openScheduleForUITests",
            "-useInMemoryStoreForUITests"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Build your weekly rhythm"].waitForExistence(timeout: 8))
    }
}
