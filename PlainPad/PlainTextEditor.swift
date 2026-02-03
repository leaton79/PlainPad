import SwiftUI
import AppKit

/// SwiftUI wrapper for PlainTextView (NSTextView subclass)
/// Bridges AppKit text editing into SwiftUI with full appearance control
struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String
    @EnvironmentObject var appearanceSettings: AppearanceSettings
    
    func makeNSView(context: Context) -> NSScrollView {
        // Create scroll view container
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        // Create our custom text view
        let textView = PlainTextView()
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        
        // Allow text view to resize horizontally with scroll view
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        
        // Text container setup for wrapping
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        
        // Set delegate for text changes
        textView.delegate = context.coordinator
        
        // Set initial text
        textView.string = text
        
        // Configure scroll view
        scrollView.documentView = textView
        
        // Apply initial appearance
        applyAppearance(to: textView, scrollView: scrollView)
        
        // Check for Roboto font on first launch
        FontManager.showInstallPromptIfNeeded()
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PlainTextView else { return }
        
        // Update text if changed externally (e.g., file open)
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
        
        // Apply current appearance settings
        applyAppearance(to: textView, scrollView: scrollView)
    }
    
    // MARK: - Appearance Application
    
    private func applyAppearance(to textView: PlainTextView, scrollView: NSScrollView) {
        let theme = appearanceSettings.theme
        let fontSize = CGFloat(appearanceSettings.fontSize)
        let lineHeight = appearanceSettings.lineHeightMultiplier
        let charSpacing = appearanceSettings.characterSpacing
        let padding = CGFloat(appearanceSettings.edgePadding)
        let zoom = CGFloat(appearanceSettings.zoomLevel)
        
        // Background color
        textView.backgroundColor = theme.backgroundColor
        scrollView.backgroundColor = theme.backgroundColor
        
        // Cursor color
        textView.insertionPointColor = theme.cursorColor
        
        // Selection color
        textView.selectedTextAttributes = [
            .backgroundColor: theme.selectionColor,
            .foregroundColor: theme.textColor
        ]
        
        // Edge padding (text container inset)
        textView.textContainerInset = NSSize(width: padding, height: padding)
        
        // Build paragraph style for line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = CGFloat(lineHeight)
        
        // Build typing attributes
        let font = FontManager.font(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.textColor,
            .kern: CGFloat(charSpacing),
            .paragraphStyle: paragraphStyle
        ]
        
        // Apply to typing attributes (new text)
        textView.typingAttributes = attributes
        
        // Apply to existing text
        if textView.string.count > 0 {
            let fullRange = NSRange(location: 0, length: textView.string.utf16.count)
            textView.textStorage?.setAttributes(attributes, range: fullRange)
        }
        
        // Apply zoom via scroll view magnification
        scrollView.magnification = zoom
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.5
        scrollView.maxMagnification = 3.0
    }
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditor
        
        init(_ parent: PlainTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Update binding on main thread
            DispatchQueue.main.async {
                self.parent.text = textView.string
            }
        }
    }
}
