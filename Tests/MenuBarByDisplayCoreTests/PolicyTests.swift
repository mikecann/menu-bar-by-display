import XCTest
@testable import MenuBarByDisplayCore

final class PolicyTests: XCTestCase {
    func testLaptopScreenAloneKeepsTheMenuBarShown() {
        XCTAssertEqual(menuBarSetting(forActiveDisplays: [true]), .alwaysShown)
    }

    func testLaptopPlusMonitorAutoHides() {
        XCTAssertEqual(menuBarSetting(forActiveDisplays: [true, false]), .autoHides)
    }

    func testLidShutWithMonitorAutoHides() {
        XCTAssertEqual(menuBarSetting(forActiveDisplays: [false]), .autoHides)
    }

    func testNoActiveDisplaysChangesNothing() {
        XCTAssertNil(menuBarSetting(forActiveDisplays: []))
    }

    func testSettingsMatchSystemSettingsChoices() {
        XCTAssertEqual(MenuBarSetting.alwaysShown, MenuBarSetting(hideOnDesktop: false, showInFullScreen: true))
        XCTAssertEqual(MenuBarSetting.autoHides, MenuBarSetting(hideOnDesktop: true, showInFullScreen: false))
    }
}
