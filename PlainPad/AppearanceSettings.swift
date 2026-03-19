import SwiftUI
import Combine

/// Manages all user-configurable appearance settings with persistence
final class AppearanceSettings: ObservableObject {
    
    // MARK: - Font Size
    
    @AppStorage("fontSize") var fontSize: Double = 14.0 {
        didSet { objectWillChange.send() }
    }
    
    private let fontSizeMin: Double = 8.0
    private let fontSizeMax: Double = 72.0
    private let fontSizeStep: Double = 2.0
    
    func increaseFontSize() {
        fontSize = min(fontSize + fontSizeStep, fontSizeMax)
    }
    
    func decreaseFontSize() {
        fontSize = max(fontSize - fontSizeStep, fontSizeMin)
    }
    
    // MARK: - Zoom (distinct from font size)
    
    @AppStorage("zoomLevel") var zoomLevel: Double = 1.0 {
        didSet { objectWillChange.send() }
    }
    
    private let zoomMin: Double = 0.5
    private let zoomMax: Double = 3.0
    private let zoomStep: Double = 0.1
    
    func zoomIn() {
        zoomLevel = min(zoomLevel + zoomStep, zoomMax)
    }
    
    func zoomOut() {
        zoomLevel = max(zoomLevel - zoomStep, zoomMin)
    }
    
    func resetZoom() {
        zoomLevel = 1.0
    }
    
    // MARK: - Line Spacing (line height multiplier)
    
    @AppStorage("lineHeightMultiplier") var lineHeightMultiplier: Double = 1.2 {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Character Spacing (tracking/kerning)
    
    @AppStorage("characterSpacing") var characterSpacing: Double = 0.0 {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Edge Padding (margins inside editor)
    
    @AppStorage("edgePadding") var edgePadding: Double = 16.0 {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Theme
    
    @AppStorage("theme") var theme: Theme = .light {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Computed Properties
    
    /// Returns the effective font size after zoom is applied
    /// Note: Zoom is applied separately via scroll view magnification,
    /// but this can be useful for calculations
    var effectiveDisplaySize: Double {
        fontSize * zoomLevel
    }
}
