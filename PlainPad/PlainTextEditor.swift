import SwiftUI
import AppKit

/// SwiftUI wrapper for PlainTextView (NSTextView subclass)
/// Bridges AppKit text editing into SwiftUI with full appearance control
struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String
    let documentURL: URL?
    @EnvironmentObject var appearanceSettings: AppearanceSettings
    
    func makeNSView(context: Context) -> NSScrollView {
        // Create scroll view container
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.contentView.postsBoundsChangedNotifications = true
        scrollView.postsFrameChangedNotifications = true
        
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
        textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.frame = NSRect(origin: .zero, size: scrollView.contentSize)
        
        // Text container setup for wrapping
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        
        // Set delegate for text changes
        textView.delegate = context.coordinator
        context.coordinator.attach(to: textView, scrollView: scrollView)
        
        // Set initial text
        textView.string = text
        
        // Configure scroll view
        scrollView.documentView = textView
        context.coordinator.updateTextLayout(for: textView, in: scrollView)
        
        // Apply initial appearance
        applyAppearance(to: textView, scrollView: scrollView)
        
        // Store current settings for comparison
        context.coordinator.lastAppearanceState = appearanceState
        context.coordinator.restorePersistedStateIfNeeded(on: textView, scrollView: scrollView)
        
        // Check for Roboto font on first launch
        FontManager.showInstallPromptIfNeeded()
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PlainTextView else { return }
        context.coordinator.parent = self
        context.coordinator.updateTextLayout(for: textView, in: scrollView)
        
        // Only update text if it changed externally (e.g., file open)
        // and not from our own typing
        if !context.coordinator.isUpdating && textView.string != text {
            let editorState = context.coordinator.captureEditorState(from: textView, scrollView: scrollView)
            textView.string = text
            context.coordinator.restore(editorState, on: textView, scrollView: scrollView)
        }
        
        // Only apply appearance if settings actually changed
        let currentState = appearanceState
        if currentState != context.coordinator.lastAppearanceState {
            let editorState = context.coordinator.captureEditorState(from: textView, scrollView: scrollView)
            applyAppearance(to: textView, scrollView: scrollView)
            context.coordinator.restore(editorState, on: textView, scrollView: scrollView)
            context.coordinator.lastAppearanceState = currentState
        }
    }
    
    // MARK: - Appearance State Tracking
    
    private var appearanceState: String {
        "\(appearanceSettings.fontSize)-\(appearanceSettings.zoomLevel)-\(appearanceSettings.lineHeightMultiplier)-\(appearanceSettings.characterSpacing)-\(appearanceSettings.edgePadding)-\(appearanceSettings.theme.rawValue)"
    }
    
    // MARK: - Appearance Application
    
    private func applyAppearance(to textView: PlainTextView, scrollView: NSScrollView) {
        let theme = appearanceSettings.theme
        let fontSize = CGFloat(appearanceSettings.fontSize)
        let lineHeight = appearanceSettings.lineHeightMultiplier
        let charSpacing = appearanceSettings.characterSpacing
        let padding = CGFloat(appearanceSettings.edgePadding)
        let zoom = CGFloat(appearanceSettings.zoomLevel)
        let effectiveFontSize = fontSize * zoom
        
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
        let font = FontManager.font(ofSize: effectiveFontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.textColor,
            .kern: CGFloat(charSpacing) * zoom,
            .paragraphStyle: paragraphStyle
        ]
        
        // Apply to typing attributes (new text)
        textView.typingAttributes = attributes
        
        // Apply to existing text
        if textView.string.count > 0 {
            let fullRange = NSRange(location: 0, length: textView.string.utf16.count)
            textView.textStorage?.setAttributes(attributes, range: fullRange)
        }
        
        // Keep zoom in the text metrics instead of scroll-view magnification,
        // which breaks text wrapping during live window resizing.
        scrollView.magnification = 1.0
        scrollView.allowsMagnification = false
    }
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        struct EditorState: Codable {
            var selectedLocation: Int
            var selectedLength: Int
            var scrollX: Double
            var scrollY: Double
        }

        var parent: PlainTextEditor
        var isUpdating = false
        var isRestoringState = false
        var lastAppearanceState: String = ""
        private var observers: [NSObjectProtocol] = []
        private var pendingPersistedState: EditorState?
        
        init(_ parent: PlainTextEditor) {
            self.parent = parent
            self.pendingPersistedState = Self.loadState(for: parent.documentURL)
        }

        deinit {
            for observer in observers {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        func attach(to textView: PlainTextView, scrollView: NSScrollView) {
            let center = NotificationCenter.default

            observers.append(
                center.addObserver(
                    forName: NSTextView.didChangeSelectionNotification,
                    object: textView,
                    queue: .main
                ) { [weak self, weak textView, weak scrollView] _ in
                    guard
                        let self,
                        let textView,
                        let scrollView
                    else { return }
                    self.persistCurrentState(from: textView, scrollView: scrollView)
                }
            )

            observers.append(
                center.addObserver(
                    forName: NSView.boundsDidChangeNotification,
                    object: scrollView.contentView,
                    queue: .main
                ) { [weak self, weak textView, weak scrollView] _ in
                    guard
                        let self,
                        let textView,
                        let scrollView
                    else { return }
                    self.persistCurrentState(from: textView, scrollView: scrollView)
                }
            )

            observers.append(
                center.addObserver(
                    forName: NSView.frameDidChangeNotification,
                    object: scrollView,
                    queue: .main
                ) { [weak self, weak textView, weak scrollView] _ in
                    guard
                        let self,
                        let textView,
                        let scrollView
                    else { return }
                    self.updateTextLayout(for: textView, in: scrollView)
                }
            )
        }

        func updateTextLayout(for textView: NSTextView, in scrollView: NSScrollView) {
            let contentSize = scrollView.contentSize
            let targetWidth = contentSize.width

            if textView.frame.width != targetWidth {
                textView.frame.size.width = targetWidth
            }

            if textView.frame.height < contentSize.height {
                textView.frame.size.height = contentSize.height
            }

            textView.textContainer?.containerSize = NSSize(
                width: targetWidth,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.textContainer?.widthTracksTextView = true
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        }

        func restorePersistedStateIfNeeded(on textView: PlainTextView, scrollView: NSScrollView) {
            guard let state = pendingPersistedState else { return }
            pendingPersistedState = nil
            restore(state, on: textView, scrollView: scrollView)
        }

        func captureEditorState(from textView: NSTextView, scrollView: NSScrollView) -> EditorState {
            let selectedRange = textView.selectedRange()
            let origin = scrollView.contentView.bounds.origin

            return EditorState(
                selectedLocation: selectedRange.location,
                selectedLength: selectedRange.length,
                scrollX: origin.x,
                scrollY: origin.y
            )
        }

        func restore(_ state: EditorState, on textView: NSTextView, scrollView: NSScrollView) {
            let clampedRange = clampedSelectedRange(for: state, text: textView.string)
            let clampedPoint = NSPoint(
                x: max(0, CGFloat(state.scrollX)),
                y: max(0, CGFloat(state.scrollY))
            )

            isRestoringState = true
            textView.setSelectedRange(clampedRange)
            persistCurrentState(from: textView, scrollView: scrollView)

            DispatchQueue.main.async { [weak self, weak textView, weak scrollView] in
                guard
                    let self,
                    let textView,
                    let scrollView
                else { return }

                textView.layoutManager?.ensureLayout(for: textView.textContainer!)
                scrollView.contentView.scroll(to: clampedPoint)
                scrollView.reflectScrolledClipView(scrollView.contentView)
                textView.setSelectedRange(clampedRange)
                self.isRestoringState = false
                self.persistCurrentState(from: textView, scrollView: scrollView)
            }
        }

        func persistCurrentState(from textView: NSTextView, scrollView: NSScrollView) {
            guard !isRestoringState else { return }
            let state = captureEditorState(from: textView, scrollView: scrollView)
            pendingPersistedState = state
            Self.saveState(state, for: parent.documentURL)
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Keep SwiftUI from treating in-flight typing as an external reload,
            // which can restore an older scroll position and hide the caret.
            isUpdating = true
            parent.text = textView.string
            if let scrollView = textView.enclosingScrollView {
                persistCurrentState(from: textView, scrollView: scrollView)
            }

            DispatchQueue.main.async { [weak self] in
                self?.isUpdating = false
            }
        }

        private func clampedSelectedRange(for state: EditorState, text: String) -> NSRange {
            let upperBound = text.utf16.count
            let location = min(max(0, state.selectedLocation), upperBound)
            let length = min(max(0, state.selectedLength), upperBound - location)
            return NSRange(location: location, length: length)
        }

        private static func saveState(_ state: EditorState, for documentURL: URL?) {
            guard let key = storageKey(for: documentURL) else { return }
            guard let data = try? JSONEncoder().encode(state) else { return }
            UserDefaults.standard.set(data, forKey: key)
        }

        private static func loadState(for documentURL: URL?) -> EditorState? {
            guard let key = storageKey(for: documentURL) else { return nil }
            guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(EditorState.self, from: data)
        }

        private static func storageKey(for documentURL: URL?) -> String? {
            guard let documentURL else { return nil }
            return "PlainPad.EditorState.\(documentURL.standardizedFileURL.path)"
        }
    }
}
