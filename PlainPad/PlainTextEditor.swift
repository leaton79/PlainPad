import SwiftUI
import AppKit

/// SwiftUI wrapper for PlainTextView (NSTextView subclass)
/// Bridges AppKit text editing into SwiftUI with full appearance control
struct PlainTextEditor: NSViewRepresentable {
    private enum Layout {
        static let verticalInset: CGFloat = 24
        static let horizontalInset: CGFloat = 28
    }

    @Binding var text: String
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
        context.coordinator.updateTextLayout(for: textView, in: scrollView, force: true)
        
        // Apply initial appearance
        applyAppearance(to: textView, scrollView: scrollView)
        
        // Store current settings for comparison
        context.coordinator.lastAppearanceSnapshot = appearanceSettings.snapshot
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PlainTextView else { return }
        context.coordinator.parent = self

        // Ignore SwiftUI refreshes triggered by our own text binding writes.
        // Re-running layout during active typing can shift the viewport away
        // from the insertion point.
        if context.coordinator.isUpdating {
            return
        }

        // Passive SwiftUI refreshes can happen while the editor is idle
        // (for example due to document/autosave state updates). Re-running
        // text layout in those cases can perturb the clip view origin even
        // though neither the caret nor the viewport geometry changed.
        context.coordinator.updateTextLayout(for: textView, in: scrollView)
        
        // Only update text if it changed externally (e.g., file open)
        // and not from our own typing
        if textView.string != text {
            textView.string = text
            context.coordinator.keepSelectionVisible(in: textView)
        }
        
        // Only apply appearance if settings actually changed
        let currentSnapshot = appearanceSettings.snapshot
        if currentSnapshot != context.coordinator.lastAppearanceSnapshot {
            applyAppearance(to: textView, scrollView: scrollView)
            context.coordinator.updateTextLayout(for: textView, in: scrollView, force: true)
            context.coordinator.keepSelectionVisible(in: textView)
            context.coordinator.lastAppearanceSnapshot = currentSnapshot
        }
    }

    private func applyAppearance(to textView: PlainTextView, scrollView: NSScrollView) {
        let snapshot = appearanceSettings.snapshot
        let theme = snapshot.theme
        let fontSize = CGFloat(snapshot.fontSize)
        let lineHeight = snapshot.lineHeightMultiplier

        textView.backgroundColor = theme.backgroundColor
        scrollView.backgroundColor = theme.backgroundColor
        textView.insertionPointColor = theme.cursorColor
        textView.selectedTextAttributes = [
            .backgroundColor: theme.selectionColor,
            .foregroundColor: theme.textColor
        ]
        textView.textContainerInset = NSSize(
            width: Layout.horizontalInset,
            height: Layout.verticalInset
        )

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = CGFloat(lineHeight)
        let font = FontManager.font(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.textColor,
            .paragraphStyle: paragraphStyle
        ]
        textView.typingAttributes = attributes

        // Appearance changes intentionally re-style the entire text storage so
        // existing content matches newly typed content.
        if textView.string.count > 0 {
            let fullRange = NSRange(location: 0, length: textView.string.utf16.count)
            textView.textStorage?.setAttributes(attributes, range: fullRange)
        }

        textView.defaultParagraphStyle = paragraphStyle
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditor
        var isUpdating = false
        var lastAppearanceSnapshot: AppearanceSettings.Snapshot?
        private var lastLaidOutContentSize: NSSize?
        private var observers: [NSObjectProtocol] = []
        
        init(_ parent: PlainTextEditor) {
            self.parent = parent
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
                    forName: NSView.frameDidChangeNotification,
                    object: scrollView,
                    queue: .main
                ) { [weak self, weak textView, weak scrollView] _ in
                    guard
                        let self,
                        let textView,
                        let scrollView
                    else { return }
                    self.updateTextLayout(for: textView, in: scrollView, force: true)
                    self.keepSelectionVisible(in: textView)
                }
            )
        }

        @discardableResult
        func updateTextLayout(
            for textView: NSTextView,
            in scrollView: NSScrollView,
            force: Bool = false
        ) -> Bool {
            let contentSize = scrollView.contentSize
            if !force, lastLaidOutContentSize == contentSize {
                return false
            }
            lastLaidOutContentSize = contentSize
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
            if let textContainer = textView.textContainer {
                textView.layoutManager?.ensureLayout(for: textContainer)
            }
            return true
        }

        func keepSelectionVisible(in textView: NSTextView) {
            let selectedRange = textView.selectedRange()
            guard selectedRange.location != NSNotFound else { return }
            textView.scrollRangeToVisible(selectedRange)
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Keep SwiftUI from treating in-flight typing as an external reload,
            // which can restore an older scroll position and hide the caret.
            isUpdating = true
            parent.text = textView.string

            DispatchQueue.main.async { [weak self] in
                self?.isUpdating = false
            }
        }
    }
}
