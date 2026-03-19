import SwiftUI

@main
struct PlainPadApp: App {
    private enum DefaultsKey {
        static let windowTabbingMode = "AppleWindowTabbingMode"
    }

    @StateObject private var appearanceSettings = AppearanceSettings()
    
    init() {
        NSWindow.allowsAutomaticWindowTabbing = true
        UserDefaults.standard.set("always", forKey: DefaultsKey.windowTabbingMode)
    }

    var body: some Scene {
        DocumentGroup(newDocument: PlainTextDocument()) { file in
            ContentView(document: file.$document, documentURL: file.fileURL)
                .environmentObject(appearanceSettings)
        }
        .commands {
            PlainTextEditingCommands()
            PlainPadFormatCommands(appearanceSettings: appearanceSettings)
        }
    }
}
