import AppKit

/// Manages font selection with Roboto preference and graceful fallback
enum FontManager {
    private static let preferredFontName = "Roboto"
    private static let preferredRegularFontNames = ["Roboto-Regular", "Roboto"]
    private static let fontDownloadURL = URL(string: "https://fonts.google.com/specimen/Roboto")
    private static let hasShownInstallPromptKey = "hasShownRobotoInstallPrompt"

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

        return NSFont.systemFont(ofSize: size)
    }

    static var hasShownInstallPrompt: Bool {
        get { UserDefaults.standard.bool(forKey: hasShownInstallPromptKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasShownInstallPromptKey) }
    }

    static func showInstallPromptIfNeeded() {
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
                if let url = fontDownloadURL {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    static func resetInstallPrompt() {
        hasShownInstallPrompt = false
    }
}
