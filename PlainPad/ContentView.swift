import SwiftUI

/// Main content view hosting the plain text editor
struct ContentView: View {
    @Binding var document: PlainTextDocument
    @EnvironmentObject var appearanceSettings: AppearanceSettings
    
    var body: some View {
        PlainTextEditor(text: $document.text)
            .frame(minWidth: 400, minHeight: 300)
            .background(appearanceSettings.theme.backgroundColorSwiftUI)
    }
}

#Preview {
    ContentView(document: .constant(PlainTextDocument(text: "Hello, PlainPad!")))
        .environmentObject(AppearanceSettings())
}
