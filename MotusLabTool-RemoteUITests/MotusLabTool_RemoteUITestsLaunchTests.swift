//
//  MotusLabTool_RemoteUITestsLaunchTests.swift
//  MotusLabTool-RemoteUITests
//
//  Created by Pierre Couprie on 06/08/2024.
//  Copyright © 2024 Pierre Couprie. All rights reserved.
//

import XCTest

final class MotusLabTool_RemoteUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
