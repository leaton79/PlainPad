import SwiftUI

@main
struct PlainPadApp: App {
    @StateObject private var appearanceSettings = AppearanceSettings()
    
    init() {
            // Force documents to open in tabs instead of new windows
            NSWindow.allowsAutomaticWindowTabbing = true
            UserDefaults.standard.set("always", forKey: "AppleWindowTabbingMode")
        }

    
    var body: some Scene {
        DocumentGroup(newDocument: PlainTextDocument()) { file in
            ContentView(document: file.$document)
                .environmentObject(appearanceSettings)
        }
        .commands {
            // MARK: - Edit Menu Additions
            CommandGroup(after: .pasteboard) {
                Button("Paste and Match Style") {
                    NSApp.sendAction(#selector(NSTextView.pasteAsPlainText(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("V", modifiers: [.command, .option, .shift])
            }
            
            // MARK: - View Menu (Appearance Controls)
            CommandMenu("Format") {
                // Zoom controls
                Button("Zoom In") {
                    appearanceSettings.zoomIn()
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Zoom Out") {
                    appearanceSettings.zoomOut()
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Button("Reset Zoom") {
                    appearanceSettings.resetZoom()
                }
                .keyboardShortcut("0", modifiers: .command)
                
                Divider()
                
                // Font size controls
                Button("Increase Font Size") {
                    appearanceSettings.increaseFontSize()
                }
                .keyboardShortcut("+", modifiers: [.command, .shift])
                
                Button("Decrease Font Size") {
                    appearanceSettings.decreaseFontSize()
                }
                .keyboardShortcut("-", modifiers: [.command, .shift])
                
                Divider()
                
                // Line spacing
                Menu("Line Spacing") {
                    Button("Compact (1.0)") { appearanceSettings.lineHeightMultiplier = 1.0 }
                    Button("Normal (1.2)") { appearanceSettings.lineHeightMultiplier = 1.2 }
                    Button("Relaxed (1.5)") { appearanceSettings.lineHeightMultiplier = 1.5 }
                    Button("Spacious (2.0)") { appearanceSettings.lineHeightMultiplier = 2.0 }
                }
                
                // Character spacing
                Menu("Character Spacing") {
                    Button("Tight (-0.5)") { appearanceSettings.characterSpacing = -0.5 }
                    Button("Normal (0)") { appearanceSettings.characterSpacing = 0 }
                    Button("Loose (0.5)") { appearanceSettings.characterSpacing = 0.5 }
                    Button("Wide (1.0)") { appearanceSettings.characterSpacing = 1.0 }
                }
                
                // Edge padding
                Menu("Edge Padding") {
                    Button("None") { appearanceSettings.edgePadding = 0 }
                    Button("Small (8)") { appearanceSettings.edgePadding = 8 }
                    Button("Medium (16)") { appearanceSettings.edgePadding = 16 }
                    Button("Large (32)") { appearanceSettings.edgePadding = 32 }
                    Button("Extra Large (48)") { appearanceSettings.edgePadding = 48 }
                }
                
                Divider()
                
                // Theme selection
                Menu("Theme") {
                    ForEach(Theme.allCases) { theme in
                        Button(theme.displayName) {
                            appearanceSettings.theme = theme
                        }
                    }
                }
            }
        }
    }
}
