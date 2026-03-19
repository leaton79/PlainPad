import SwiftUI
import Combine

/// Manages all user-configurable appearance settings with persistence
final class AppearanceSettings: ObservableObject {
    struct Snapshot: Equatable {
        let fontSize: Double
        let zoomLevel: Double
        let lineHeightMultiplier: Double
        let characterSpacing: Double
        let edgePadding: Double
        let theme: Theme
    }

    private enum Key {
        static let fontSize = "fontSize"
        static let zoomLevel = "zoomLevel"
        static let lineHeightMultiplier = "lineHeightMultiplier"
        static let characterSpacing = "characterSpacing"
        static let edgePadding = "edgePadding"
        static let theme = "theme"
    }

    enum Bounds {
        static let fontSizeMin = 8.0
        static let fontSizeMax = 72.0
        static let fontSizeStep = 2.0
        static let zoomMin = 0.5
        static let zoomMax = 3.0
        static let zoomStep = 0.1
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

    @AppStorage(Key.zoomLevel) var zoomLevel: Double = 1.0 {
        didSet { objectWillChange.send() }
    }

    func zoomIn() {
        zoomLevel = Self.clampZoomLevel(zoomLevel + Bounds.zoomStep)
    }

    func zoomOut() {
        zoomLevel = Self.clampZoomLevel(zoomLevel - Bounds.zoomStep)
    }

    func resetZoom() {
        zoomLevel = 1.0
    }

    @AppStorage(Key.lineHeightMultiplier) var lineHeightMultiplier: Double = 1.2 {
        didSet { objectWillChange.send() }
    }

    @AppStorage(Key.characterSpacing) var characterSpacing: Double = 0.0 {
        didSet { objectWillChange.send() }
    }

    @AppStorage(Key.edgePadding) var edgePadding: Double = 16.0 {
        didSet { objectWillChange.send() }
    }

    @AppStorage(Key.theme) var theme: Theme = .light {
        didSet { objectWillChange.send() }
    }

    var snapshot: Snapshot {
        Snapshot(
            fontSize: fontSize,
            zoomLevel: zoomLevel,
            lineHeightMultiplier: lineHeightMultiplier,
            characterSpacing: characterSpacing,
            edgePadding: edgePadding,
            theme: theme
        )
    }

    static func clampFontSize(_ value: Double) -> Double {
        min(max(value, Bounds.fontSizeMin), Bounds.fontSizeMax)
    }

    static func clampZoomLevel(_ value: Double) -> Double {
        min(max(value, Bounds.zoomMin), Bounds.zoomMax)
    }
}
