import AppKit

/// Custom NSTextView subclass that enforces plain-text behavior
/// - Paste always strips formatting
/// - Tab key inserts literal tab character
class PlainTextView: NSTextView {
    private var notificationObservers: [NSObjectProtocol] = []
    private var observedClipView: NSClipView?
    private var observedWindow: NSWindow?
    private var lastKnownVisibleOrigin: NSPoint = .zero
    private var pendingViewportRestoreOrigin: NSPoint?
    private var isPreservingViewport = false
    
    // MARK: - Focus Handling
    
    override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder = super.becomeFirstResponder()
        guard didBecomeFirstResponder else { return false }
        keepSelectionVisible()
        
        return true
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        removeObservers()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        registerObserversIfNeeded()
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        registerObserversIfNeeded()
    }

    deinit {
        removeObservers()
    }

    private func keepSelectionVisible() {
        let currentSelection = selectedRange()
        guard currentSelection.location != NSNotFound else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.scrollRangeToVisible(currentSelection)
            self.updateLastKnownVisibleOrigin()
        }
    }

    private func registerObserversIfNeeded() {
        guard let scrollView = enclosingScrollView else { return }
        guard let window else { return }
        guard observedClipView !== scrollView.contentView || observedWindow !== window else { return }

        removeObservers()

        observedClipView = scrollView.contentView
        observedWindow = window
        lastKnownVisibleOrigin = scrollView.contentView.bounds.origin

        let center = NotificationCenter.default
        notificationObservers.append(
            center.addObserver(
                forName: Notification.Name("NSWindowWillResignKeyNotification"),
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.prepareForViewportPreservation()
            }
        )
        notificationObservers.append(
            center.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: scrollView.contentView,
                queue: .main
            ) { [weak self] _ in
                self?.updateLastKnownVisibleOrigin()
            }
        )
        notificationObservers.append(
            center.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.restoreLastKnownViewport()
            }
        )
        notificationObservers.append(
            center.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.restoreLastKnownViewport()
            }
        )
    }

    private func prepareForViewportPreservation() {
        guard let scrollView = enclosingScrollView else { return }
        pendingViewportRestoreOrigin = scrollView.contentView.bounds.origin
        isPreservingViewport = true
    }

    private func updateLastKnownVisibleOrigin() {
        guard let scrollView = enclosingScrollView else { return }
        guard !isPreservingViewport else { return }
        lastKnownVisibleOrigin = scrollView.contentView.bounds.origin
    }

    private func restoreLastKnownViewport() {
        guard let scrollView = enclosingScrollView else { return }
        let targetOrigin = pendingViewportRestoreOrigin ?? lastKnownVisibleOrigin

        let restoreDelays: [TimeInterval] = [0, 0.05, 0.15]
        for delay in restoreDelays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak scrollView] in
                guard let self, let scrollView else { return }
                scrollView.contentView.scroll(to: targetOrigin)
                scrollView.reflectScrolledClipView(scrollView.contentView)
                self.lastKnownVisibleOrigin = targetOrigin

                if self.window?.isKeyWindow == true {
                    self.pendingViewportRestoreOrigin = nil
                    self.isPreservingViewport = false
                }
            }
        }
    }

    private func removeObservers() {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
        observedClipView = nil
        observedWindow = nil
    }
    
    // MARK: - Paste Behavior
    
    /// Override paste to always strip formatting (paste as plain text)
    override func paste(_ sender: Any?) {
        pasteAsPlainText(sender)
    }
    
    /// Explicit paste as plain text - reads string from pasteboard, ignoring RTF/HTML
    override func pasteAsPlainText(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        
        // Try to get plain string from pasteboard
        guard let string = pasteboard.string(forType: .string) else {
            // Nothing to paste, or no string representation
            NSSound.beep()
            return
        }
        
        // Insert the plain text at current selection
        insertText(string, replacementRange: selectedRange())
    }
    
    // MARK: - Tab Key Behavior
    
    /// Override insertTab to insert a literal tab character instead of changing focus
    override func insertTab(_ sender: Any?) {
        insertText("\t", replacementRange: selectedRange())
    }
    
    /// Also handle backtab (Shift+Tab) to insert tab if desired, or do nothing
    override func insertBacktab(_ sender: Any?) {
        // Option 1: Do nothing (standard behavior would move focus backward)
        // Option 2: Insert tab anyway
        // We'll do nothing to match typical text editor behavior
    }
    
    // MARK: - Key Handling
    
    /// Ensure Tab key is handled by us, not the responder chain
    override func keyDown(with event: NSEvent) {
        // Tab key without modifiers should insert tab
        if event.keyCode == 48 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            insertTab(nil)
            return
        }
        
        super.keyDown(with: event)
    }
    
    // MARK: - Drag and Drop
    
    /// Override to handle dropped text as plain text only
    override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        // Only accept string type to ensure plain text
        if type == .string, let string = pboard.string(forType: .string) {
            insertText(string, replacementRange: selectedRange())
            return true
        }
        
        // Try to get string even if type is different (e.g., RTF dropped)
        if let string = pboard.string(forType: .string) {
            insertText(string, replacementRange: selectedRange())
            return true
        }
        
        return false
    }
    
    /// Declare what types we accept for drag/drop
    override var readablePasteboardTypes: [NSPasteboard.PasteboardType] {
        return [.string]
    }
    
    /// Accept dragged items as plain text only
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard
        if pasteboard.availableType(from: [.string]) != nil {
            return .copy
        }
        return []
    }
}
