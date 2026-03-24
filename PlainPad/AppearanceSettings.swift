import SwiftUI
import Combine

/// Manages all user-configurable appearance settings with persistence
final class AppearanceSettings: ObservableObject {
    struct Snapshot: Equatable {
        let fontSize: Double
        let lineHeightMultiplier: Double
        let theme: Theme
    }

    private enum Key {
        static let fontSize = "fontSize"
        static let lineHeightMultiplier = "lineHeightMultiplier"
        static let theme = "theme"
    }

    enum Bounds {
        static let fontSizeMin = 8.0
        static let fontSizeMax = 72.0
        static let fontSizeStep = 2.0
    }

    @AppStorage(Key.fontSize) var fontSize: Double = 14.0 {
        didSet { objectWillChange.send() }
    }

    func increaseFontSize() {
        fontSize = Self.clampFontSize(fontSize + Bounds.fontSizeStep)
    }

    func decreaseFontSize() {
        fontSize = Self.clampFontSize(fontSize - Bounds.fontSizeStep)
    }

    @AppStorage(Key.lineHeightMultiplier) var lineHeightMultiplier: Double = 1.2 {
        didSet { objectWillChange.send() }
    }

    @AppStorage(Key.theme) var theme: Theme = .light {
        didSet { objectWillChange.send() }
    }

    var snapshot: Snapshot {
        Snapshot(
            fontSize: fontSize,
            lineHeightMultiplier: lineHeightMultiplier,
            theme: theme
        )
    }

    static func clampFontSize(_ value: Double) -> Double {
        min(max(value, Bounds.fontSizeMin), Bounds.fontSizeMax)
    }
}
