import AppKit

/// Manages font selection with Roboto preference and graceful fallback
enum FontManager {
    
    // MARK: - Font Names
    
    private static let preferredFontName = "Roboto"
    private static let fallbackFontName = "SF Pro"
    private static let systemFallback = NSFont.systemFont(ofSize: 14).fontName
    
    // MARK: - Font Availability
    
    /// Check if Roboto is installed on the system
    static var isRobotoAvailable: Bool {
        let availableFonts = NSFontManager.shared.availableFontFamilies
        return availableFonts.contains(preferredFontName)
    }
    
    /// Returns the font family name to use (Roboto if available, otherwise SF Pro)
    static var effectiveFontFamily: String {
        if isRobotoAvailable {
            return preferredFontName
        }
        return fallbackFontName
    }
    
    // MARK: - Font Creation
    
    /// Creates a font with the preferred family at the specified size
    /// - Parameter size: Point size for the font
    /// - Returns: NSFont using Roboto if available, SF Pro otherwise
    static func font(ofSize size: CGFloat) -> NSFont {
        if isRobotoAvailable {
            if let roboto = NSFont(name: "Roboto-Regular", size: size) {
                return roboto
            }
            // Try alternate Roboto name formats
            if let roboto = NSFont(name: "Roboto", size: size) {
                return roboto
            }
        }
        
        // Fallback to system font (SF Pro on modern macOS)
        return NSFont.systemFont(ofSize: size)
    }
    
    // MARK: - Install Prompt
    
    /// Key for tracking whether we've shown the install prompt
    private static let hasShownInstallPromptKey = "hasShownRobotoInstallPrompt"
    
    /// Whether we've already shown the install prompt this install
    static var hasShownInstallPrompt: Bool {
        get { UserDefaults.standard.bool(forKey: hasShownInstallPromptKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasShownInstallPromptKey) }
    }
    
    /// Shows an alert offering to help the user install Roboto
    /// Only shows once per app install (unless reset)
    static func showInstallPromptIfNeeded() {
        // Don't show if Roboto is available or we've already shown
        guard !isRobotoAvailable, !hasShownInstallPrompt else { return }
        
        hasShownInstallPrompt = true
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Roboto Font Not Installed"
            alert.informativeText = """
                PlainPad works best with the Roboto font, but it's not installed on your system.
                
                The app will use the system font (SF Pro) instead, which works fine.
                
                If you'd like to install Roboto:
                1. Visit fonts.google.com/specimen/Roboto
                2. Download the font family
                3. Open the .ttf files and click "Install Font"
                
                You can restart PlainPad after installing to use Roboto.
                """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Google Fonts")
            alert.addButton(withTitle: "Continue with System Font")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // Open Google Fonts download page
                if let url = URL(string: "https://fonts.google.com/specimen/Roboto") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    /// Resets the install prompt flag (for testing or if user wants to see it again)
    static func resetInstallPrompt() {
        hasShownInstallPrompt = false
    }
}
