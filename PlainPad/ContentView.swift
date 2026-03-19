import SwiftUI

/// Main content view hosting the plain text editor
struct ContentView: View {
    @Binding var document: PlainTextDocument
    let documentURL: URL?
    @EnvironmentObject var appearanceSettings: AppearanceSettings
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            headerBar
            
            // Separator line
            Divider()
            
            // Editor
            PlainTextEditor(text: $document.text, documentURL: documentURL)
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(appearanceSettings.theme.backgroundColorSwiftUI)
    }
    
    private var headerBar: some View {
        HStack {
            Spacer()
        }
        .frame(height: 28)
        .frame(maxWidth: .infinity)
        .background(appearanceSettings.theme.headerBackgroundColorSwiftUI)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            document: .constant(PlainTextDocument(text: "Hello, PlainPad!")),
            documentURL: nil
        )
        .environmentObject(AppearanceSettings())
    }
}
