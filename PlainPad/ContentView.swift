import SwiftUI

/// Main content view hosting the plain text editor
struct ContentView: View {
    @Binding var document: PlainTextDocument
    @EnvironmentObject var appearanceSettings: AppearanceSettings
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            headerBar
            
            // Separator line
            Divider()
            
            // Editor
            PlainTextEditor(text: $document.text)
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
        .background(headerBackgroundColor)
    }
    
    private var headerBackgroundColor: Color {
        switch appearanceSettings.theme {
        case .light:
            return Color(nsColor: NSColor(calibratedWhite: 0.92, alpha: 1.0))
        case .dark:
            return Color(nsColor: NSColor(calibratedWhite: 0.15, alpha: 1.0))
        case .highContrast:
            return Color(nsColor: NSColor(calibratedWhite: 0.08, alpha: 1.0))
        case .sepia:
            return Color(nsColor: NSColor(calibratedRed: 0.91, green: 0.88, blue: 0.82, alpha: 1.0))
        }
    }
}

#Preview {
    ContentView(document: .constant(PlainTextDocument(text: "Hello, PlainPad!")))
        .environmentObject(AppearanceSettings())
}
