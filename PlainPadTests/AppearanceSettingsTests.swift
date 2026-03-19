import XCTest
@testable import PlainPad

final class AppearanceSettingsTests: XCTestCase {
    func testClampFontSizeUsesConfiguredBounds() {
        XCTAssertEqual(AppearanceSettings.clampFontSize(2), AppearanceSettings.Bounds.fontSizeMin)
        XCTAssertEqual(AppearanceSettings.clampFontSize(14), 14)
        XCTAssertEqual(AppearanceSettings.clampFontSize(200), AppearanceSettings.Bounds.fontSizeMax)
    }

    func testClampZoomLevelUsesConfiguredBounds() {
        XCTAssertEqual(AppearanceSettings.clampZoomLevel(0.1), AppearanceSettings.Bounds.zoomMin, accuracy: 0.0001)
        XCTAssertEqual(AppearanceSettings.clampZoomLevel(1.25), 1.25, accuracy: 0.0001)
        XCTAssertEqual(AppearanceSettings.clampZoomLevel(5), AppearanceSettings.Bounds.zoomMax, accuracy: 0.0001)
    }
}
