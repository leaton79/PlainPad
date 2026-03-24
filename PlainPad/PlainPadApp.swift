import SwiftUI

@main
struct PlainPadApp: App {
    @StateObject private var appearanceSettings = AppearanceSettings()
    
    init() {
        NSWindow.allowsAutomaticWindowTabbing = true
    }

    var body: some Scene {
        DocumentGroup(newDocument: PlainTextDocument()) { file in
            ContentView(document: file.$document)
                .environmentObject(appearanceSettings)
        }
        .commands {
            PlainTextEditingCommands()
            PlainPadFormatCommands(appearanceSettings: appearanceSettings)
        }
    }
}
