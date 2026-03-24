import AppKit

/// Manages font selection with Roboto preference and graceful fallback
enum FontManager {
    private static let preferredFontName = "Roboto"
    private static let preferredRegularFontNames = ["Roboto-Regular", "Roboto"]

    static var isRobotoAvailable: Bool {
        let availableFonts = NSFontManager.shared.availableFontFamilies
        return availableFonts.contains(preferredFontName)
    }

    static func font(ofSize size: CGFloat) -> NSFont {
        if isRobotoAvailable {
            for name in preferredRegularFontNames {
                if let roboto = NSFont(name: name, size: size) {
                    return roboto
                }
            }
        }

        return NSFont.systemFont(ofSize: size, weight: .regular)
    }
}
