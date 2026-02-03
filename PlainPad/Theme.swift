import SwiftUI
import AppKit

/// Available editor themes
enum Theme: String, CaseIterable, Identifiable {
    case light
    case dark
    case highContrast
    case sepia
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .highContrast: return "High Contrast"
        case .sepia: return "Sepia"
        }
    }
    
    // MARK: - Colors
    
    var backgroundColor: NSColor {
        switch self {
        case .light:
            return NSColor(calibratedWhite: 1.0, alpha: 1.0)
        case .dark:
            return NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        case .highContrast:
            return NSColor.black
        case .sepia:
            return NSColor(calibratedRed: 0.96, green: 0.94, blue: 0.88, alpha: 1.0)
        }
    }
    
    var textColor: NSColor {
        switch self {
        case .light:
            return NSColor(calibratedWhite: 0.1, alpha: 1.0)
        case .dark:
            return NSColor(calibratedWhite: 0.9, alpha: 1.0)
        case .highContrast:
            return NSColor.white
        case .sepia:
            return NSColor(calibratedRed: 0.3, green: 0.25, blue: 0.2, alpha: 1.0)
        }
    }
    
    var cursorColor: NSColor {
        switch self {
        case .light:
            return NSColor.black
        case .dark:
            return NSColor.white
        case .highContrast:
            return NSColor.yellow
        case .sepia:
            return NSColor(calibratedRed: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        }
    }
    
    var selectionColor: NSColor {
        switch self {
        case .light:
            return NSColor.selectedTextBackgroundColor
        case .dark:
            return NSColor(calibratedRed: 0.3, green: 0.4, blue: 0.6, alpha: 1.0)
        case .highContrast:
            return NSColor.yellow.withAlphaComponent(0.4)
        case .sepia:
            return NSColor(calibratedRed: 0.85, green: 0.75, blue: 0.6, alpha: 1.0)
        }
    }
    
    // MARK: - SwiftUI Color Conversions
    
    var backgroundColorSwiftUI: Color {
        Color(nsColor: backgroundColor)
    }
    
    var textColorSwiftUI: Color {
        Color(nsColor: textColor)
    }
}

// MARK: - RawRepresentable Conformance for @AppStorage

extension Theme: RawRepresentable {
    // Already conforms via String raw value
}
