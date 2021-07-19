//
//  MainViewTests.swift
//  CalendrUITests
//
//  Created by Paker on 14/07/2021.
//

import XCTest

class MainViewTests: UITestCase {

    func testMainStatusItemClicked_shouldDisplayMainView() {

        MenuBar.main.click()

        XCTAssertTrue(Main.view.didAppear)
        XCTAssertTrue(Main.pinBtn.isHittable)

        Main.view.outside.click()

        XCTAssertFalse(Main.pinBtn.isHittable)
    }

    func testPinButtonClicked_shouldNotHideMainView() {

        MenuBar.main.click()

        XCTAssertTrue(Main.view.didAppear)
        XCTAssertEqual(app.state, .runningForeground)

        Main.pinBtn.click()
        Main.view.outside.click()

        XCTAssertTrue(Main.pinBtn.isHittable)

        Main.pinBtn.click()
        Main.view.outside.click()

        XCTAssertFalse(Main.pinBtn.isHittable)
    }

    func testEventStatusItemClicked_shouldDisplayEventDetails() {

        XCTAssertTrue(MenuBar.event.waitForExistence(timeout: 1))

        MenuBar.event.click()

        XCTAssertTrue(EventDetails.view.waitForExistence(timeout: 1))
        XCTAssertTrue(EventDetails.view.didAppear)

        EventDetails.view.outside.click()

        XCTAssertFalse(EventDetails.view.exists)
    }

    func testCalendarButtonClicked_shouldOpenCalendarApp() {

        let calendar = XCUIApplication(url: NSWorkspace.shared.urlForApplication(toOpen: URL(string: "webcal://")!)!)

        MenuBar.main.click()

        XCTAssertEqual(app.state, .runningForeground)

        Main.calendarBtn.click()

        XCTAssertEqual(app.state, .runningBackground)
        XCTAssertEqual(calendar.state, .runningForeground)
    }

    // TODO: Click settings button and check that it opens SettingsViewController
}