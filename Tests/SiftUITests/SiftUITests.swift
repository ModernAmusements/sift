import XCTest

final class SiftUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-hasOnboarded", "YES",
            "-seedContacts", "YES",
            "-reseedContacts", "YES",
            "-uiFixtures", "YES"
        ]
        app.launch()
        addUIInterruptionMonitor(withDescription: "System permission") { alert in
            for label in ["Allow Full Access", "Vollen Zugriff erlauben", "Allow", "Erlauben", "OK"] {
                if alert.buttons[label].exists {
                    alert.buttons[label].tap()
                    return true
                }
            }
            return false
        }
    }

    func testOnboarding() {
        app.terminate()
        app.launchArguments = ["-resetOnboarding", "YES"]
        app.launch()

        let hero = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "A lighter")
        ).firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 10))
        capture("00-onboarding")

        app.buttons["Get started"].tap()
        XCTAssertTrue(app.buttons["Scan my iPhone"].waitForExistence(timeout: 10))
    }

    func testOnboardingBottom() {
        app.terminate()
        app.launchArguments = ["-resetOnboarding", "YES"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS %@", "A lighter")
            ).firstMatch.waitForExistence(timeout: 10)
        )
        app.swipeUp()
        app.swipeUp()
        capture("00b-onboarding-bottom")
    }

    func testScanAndBrowse() {
        XCTAssertTrue(app.buttons["Scan my iPhone"].waitForExistence(timeout: 15))
        capture("01-home")

        app.buttons["Scan my iPhone"].tap()
        allowSystemPrompt()

        let found = app.staticTexts["Found"]
        XCTAssertTrue(found.waitForExistence(timeout: 180), "Scan did not finish")
        sleep(1)
        capture("02-results")

        // Screenshots
        openRow(containing: "Screenshots")
        XCTAssertTrue(app.navigationBars["Screenshots"].waitForExistence(timeout: 8))
        sleep(1)
        capture("03-screenshots")
        back()

        // Duplicates
        openRow(containing: "Duplicates")
        XCTAssertTrue(app.navigationBars["Duplicates"].waitForExistence(timeout: 8))
        sleep(1)
        capture("04-duplicates")
        back()

        // Similar
        openRow(containing: "Similar photos")
        XCTAssertTrue(app.navigationBars["Similar photos"].waitForExistence(timeout: 8))
        sleep(1)
        capture("05-similar")
        back()

        // Blurry
        openRow(containing: "Blurry photos")
        XCTAssertTrue(app.navigationBars["Blurry photos"].waitForExistence(timeout: 8))
        sleep(1)
        capture("06-blurry")
        back()

        // Large files
        openRow(containing: "Large files")
        XCTAssertTrue(app.navigationBars["Large files"].waitForExistence(timeout: 8))
        sleep(1)
        capture("07-large-files")
        back()

        // Contacts
        openRow(containing: "Duplicate contacts")
        XCTAssertTrue(app.navigationBars["Duplicate contacts"].waitForExistence(timeout: 8))
        sleep(2)
        capture("08-contacts")
        back()

        // Files
        openRow(containing: "Files & documents")
        XCTAssertTrue(app.navigationBars["Files & documents"].waitForExistence(timeout: 8))
        capture("11-files")
        back()

        // System data guide
        openRow(containing: "System data")
        XCTAssertTrue(app.navigationBars["System data"].waitForExistence(timeout: 8))
        capture("12-system-data")
        back()

        // Swipe review
        app.swipeUp()
        openRow(containing: "Swipe review")
        XCTAssertTrue(app.navigationBars["Swipe review"].waitForExistence(timeout: 8))
        sleep(2)
        capture("09-swipe")
        back()

        // Settings
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8))
        capture("10-settings")
    }

    func testCheckInBaselineOnFirstRun() {
        app.terminate()
        app.launchArguments = ["-hasOnboarded", "YES", "-resetLedger", "YES"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Baseline saved. Sift shows the real change next time."].waitForExistence(timeout: 15),
            "First run should promise a measurement, not a result"
        )
        capture("17-checkin-baseline")
    }

    func testCheckInReportsMeasuredDeltaWithoutClaimingCredit() {
        app.terminate()
        app.launchArguments = ["-hasOnboarded", "YES", "-seedLedgerBackGB", "3"]
        app.launch()

        let headline = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "3.0 GB came back since")
        ).firstMatch
        XCTAssertTrue(headline.waitForExistence(timeout: 15), "A real measurement should be reported")

        // Sift moved nothing in this session, so it may not take credit for the gain.
        XCTAssertTrue(
            app.staticTexts["iOS returned space. Sift moved nothing this time."].waitForExistence(timeout: 5)
        )
        capture("18-checkin-delta")
    }

    func testHomeFooterCreditsModernAmusement() {
        for _ in 0..<4 { app.swipeUp() }
        let credit = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "ModernAmusement")
        ).firstMatch
        XCTAssertTrue(credit.waitForExistence(timeout: 8), "The ModernAmusement byline is missing from the home footer")
        capture("20-home-footer")
    }

    func testPhoneHealthOnlyClaimsWhatIOSExposes() {
        openRow(containing: "Phone health")
        XCTAssertTrue(app.navigationBars["Phone health"].waitForExistence(timeout: 8))

        let battery = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "Battery health")
        ).firstMatch
        XCTAssertTrue(battery.waitForExistence(timeout: 5))
        XCTAssertTrue(battery.label.contains("no public API"))

        // The screen names the impossible things only to deny them.
        let disclaimer = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "There is no speed, RAM or battery boost")
        ).firstMatch
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 3))

        for word in ["junk", "optimize", "cool the CPU", "speed up"] {
            let claims = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] %@", word)
            )
            XCTAssertEqual(claims.count, 0, "Health screen must not claim \(word)")
        }
        capture("19-phone-health")
    }

    private func openRow(containing label: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        let button = app.buttons.matching(predicate).firstMatch
        if button.waitForExistence(timeout: 5) {
            scrollUntilHittable(button)
            button.tap()
            return
        }
        let text = app.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: 5), "Row \(label) not found")
        scrollUntilHittable(text)
        text.tap()
    }

    /// XL Dynamic Type pushes rows below the fold; a tap needs a hittable row.
    private func scrollUntilHittable(_ element: XCUIElement) {
        var attempts = 0
        while !element.isHittable && attempts < 4 {
            app.swipeUp()
            attempts += 1
        }
    }

    func testContactMerge() throws {
        openRow(containing: "Duplicate contacts")
        let groups = app.staticTexts["2 groups"]
        guard groups.waitForExistence(timeout: 20) else {
            throw XCTSkip("Contacts permission was not granted or fixtures were not seeded")
        }
        capture("11-contacts-before-merge")

        let ada = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Ada Lovelace")
        ).firstMatch
        XCTAssertTrue(ada.waitForExistence(timeout: 5))
        ada.tap()

        XCTAssertTrue(app.navigationBars["Merge contact"].waitForExistence(timeout: 5))
        capture("12-contact-merge-sheet")

        let merge = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Merge 2 duplicate")
        ).firstMatch
        XCTAssertTrue(merge.waitForExistence(timeout: 5))
        merge.tap()

        let alert = app.alerts["Merge these cards?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Merge"].tap()

        XCTAssertTrue(app.staticTexts["1 group"].waitForExistence(timeout: 10))
        capture("13-contacts-after-merge")
    }

    func testDeleteScreenshots() throws {
        app.buttons["Scan my iPhone"].tap()
        allowSystemPrompt()
        guard app.staticTexts["Found"].waitForExistence(timeout: 180) else {
            throw XCTSkip("Scan did not finish")
        }

        openRow(containing: "Screenshots")
        guard app.navigationBars["Screenshots"].waitForExistence(timeout: 8) else {
            throw XCTSkip("Screenshot category unavailable")
        }
        guard app.buttons["Select all"].waitForExistence(timeout: 5) else {
            throw XCTSkip("No screenshot fixtures in this library")
        }
        capture("14-screenshots-before-delete")

        app.buttons["Select all"].tap()

        let move = app.buttons["Move to Recently Deleted"]
        XCTAssertTrue(move.waitForExistence(timeout: 5))
        let enabled = NSPredicate(format: "isEnabled == true")
        expectation(for: enabled, evaluatedWith: move, handler: nil)
        waitForExpectations(timeout: 5)
        move.tap()

        let deleteButton = NSPredicate(format: "label BEGINSWITH %@", "Delete")
        let confirm = app.buttons.matching(deleteButton).firstMatch
        if confirm.waitForExistence(timeout: 10) {
            capture("15-delete-confirmation")
            confirm.tap()
        } else {
            let photos = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
            let photosDelete = photos.buttons.matching(deleteButton).firstMatch
            if photosDelete.waitForExistence(timeout: 6) {
                capture("15-delete-confirmation")
                photosDelete.tap()
            } else {
                let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                let springboardDelete = springboard.buttons.matching(deleteButton).firstMatch
                XCTAssertTrue(springboardDelete.waitForExistence(timeout: 10), "No system delete confirmation")
                springboardDelete.tap()
            }
        }

        // The proof screen appears as soon as the session ends: bytes moved, nothing claimed yet.
        let proofHeadline = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", "Moved ", "Freed so far: 0 bytes.")
        ).firstMatch
        if proofHeadline.waitForExistence(timeout: 10) {
            capture("16a-proof-unverified")
            XCTAssertTrue(
                app.staticTexts.matching(
                    NSPredicate(format: "label CONTAINS %@", "Nothing is freed until Recently Deleted is emptied.")
                ).firstMatch.exists
            )
            app.buttons["Done"].tap()
        }

        XCTAssertTrue(app.buttons["Scan again"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["0 screenshots"].waitForExistence(timeout: 10))
        capture("16-after-delete")
    }

    private func back() {
        let button = app.navigationBars.buttons.element(boundBy: 0)
        if button.exists { button.tap() }
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func allowSystemPrompt() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let labels = [
            "Allow Full Access", "Vollen Zugriff erlauben",
            "Allow Access to All Photos", "Zugriff auf alle Fotos erlauben",
            "Allow", "Erlauben", "OK"
        ]
        // The Photos prompt can arrive several seconds after the tap. Poll
        // instead of spending a fixed wait on the first English label.
        let deadline = Date().addingTimeInterval(25)
        while Date() < deadline {
            for label in labels {
                let springboardButton = springboard.buttons[label]
                if springboardButton.exists {
                    springboardButton.tap()
                    return
                }
                let appButton = app.buttons[label]
                if appButton.exists {
                    appButton.tap()
                    return
                }
            }
            usleep(300_000)
        }
    }
}
