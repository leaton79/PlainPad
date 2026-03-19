import AppKit

/// Custom NSTextView subclass that enforces plain-text behavior
/// - Paste always strips formatting
/// - Tab key inserts literal tab character
class PlainTextView: NSTextView {
    private let viewportPreserver = ViewportPreserver()

    override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder = super.becomeFirstResponder()
        guard didBecomeFirstResponder else { return false }
        keepSelectionVisible()
        
        return true
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        viewportPreserver.disconnect()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        viewportPreserver.connect(to: self)
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        viewportPreserver.connect(to: self)
    }

    deinit {
        viewportPreserver.disconnect()
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

    private func prepareForViewportPreservation() {
        viewportPreserver.prepareForPreservation()
    }

    private func updateLastKnownVisibleOrigin() {
        viewportPreserver.captureCurrentOrigin()
    }

    private func restoreLastKnownViewport() {
        viewportPreserver.restoreIfNeeded()
    }

    override func paste(_ sender: Any?) {
        pasteAsPlainText(sender)
    }

    override func pasteAsPlainText(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        guard let string = pasteboard.string(forType: .string) else {
            NSSound.beep()
            return
        }

        insertText(string, replacementRange: selectedRange())
    }

    override func insertTab(_ sender: Any?) {
        insertText("\t", replacementRange: selectedRange())
    }

    override func insertBacktab(_ sender: Any?) {
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 48 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            insertTab(nil)
            return
        }
        
        super.keyDown(with: event)
    }

    override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        if type == .string, let string = pboard.string(forType: .string) {
            insertText(string, replacementRange: selectedRange())
            return true
        }

        if let string = pboard.string(forType: .string) {
            insertText(string, replacementRange: selectedRange())
            return true
        }
        
        return false
    }

    override var readablePasteboardTypes: [NSPasteboard.PasteboardType] {
        [.string]
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard
        if pasteboard.availableType(from: [.string]) != nil {
            return .copy
        }
        return []
    }
}

private final class ViewportPreserver {
    private static let windowWillResignKeyNotification = Notification.Name("NSWindowWillResignKeyNotification")
    private let restoreDelays: [TimeInterval] = [0, 0.05, 0.15]
    private var observers: [NSObjectProtocol] = []
    private weak var textView: PlainTextView?
    private weak var observedClipView: NSClipView?
    private weak var observedWindow: NSWindow?
    private var lastKnownVisibleOrigin: NSPoint = .zero
    private var pendingRestoreOrigin: NSPoint?
    private var isPreservingViewport = false

    func connect(to textView: PlainTextView) {
        guard let scrollView = textView.enclosingScrollView else { return }
        guard let window = textView.window else { return }
        guard observedClipView !== scrollView.contentView || observedWindow !== window else { return }

        disconnect()

        self.textView = textView
        observedClipView = scrollView.contentView
        observedWindow = window
        lastKnownVisibleOrigin = scrollView.contentView.bounds.origin

        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: Self.windowWillResignKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.prepareForPreservation()
            }
        )
        observers.append(
            center.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: scrollView.contentView,
                queue: .main
            ) { [weak self] _ in
                self?.captureCurrentOrigin()
            }
        )
        observers.append(
            center.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.restoreIfNeeded()
            }
        )
        observers.append(
            center.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.restoreIfNeeded()
            }
        )
    }

    func disconnect() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        textView = nil
        observedClipView = nil
        observedWindow = nil
        pendingRestoreOrigin = nil
        isPreservingViewport = false
    }

    func prepareForPreservation() {
        guard let scrollView = textView?.enclosingScrollView else { return }
        pendingRestoreOrigin = scrollView.contentView.bounds.origin
        isPreservingViewport = true
    }

    func captureCurrentOrigin() {
        guard let scrollView = textView?.enclosingScrollView else { return }
        guard !isPreservingViewport else { return }
        lastKnownVisibleOrigin = scrollView.contentView.bounds.origin
    }

    func restoreIfNeeded() {
        guard let textView, let scrollView = textView.enclosingScrollView else { return }
        let targetOrigin = pendingRestoreOrigin ?? lastKnownVisibleOrigin

        for delay in restoreDelays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak textView, weak scrollView] in
                guard let self, let textView, let scrollView else { return }
                scrollView.contentView.scroll(to: targetOrigin)
                scrollView.reflectScrolledClipView(scrollView.contentView)
                self.lastKnownVisibleOrigin = targetOrigin

                if textView.window?.isKeyWindow == true {
                    self.pendingRestoreOrigin = nil
                    self.isPreservingViewport = false
                }
            }
        }
    }
}
