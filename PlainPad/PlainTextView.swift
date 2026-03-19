import AppKit

/// Custom NSTextView subclass that enforces plain-text behavior
/// - Paste always strips formatting
/// - Tab key inserts literal tab character
class PlainTextView: NSTextView {
    
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
