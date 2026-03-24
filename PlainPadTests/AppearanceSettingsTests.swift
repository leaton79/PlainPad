import XCTest
@testable import PlainPad

final class AppearanceSettingsTests: XCTestCase {
    func testClampFontSizeUsesConfiguredBounds() {
        XCTAssertEqual(AppearanceSettings.clampFontSize(2), AppearanceSettings.Bounds.fontSizeMin)
        XCTAssertEqual(AppearanceSettings.clampFontSize(14), 14)
        XCTAssertEqual(AppearanceSettings.clampFontSize(200), AppearanceSettings.Bounds.fontSizeMax)
    }
}
