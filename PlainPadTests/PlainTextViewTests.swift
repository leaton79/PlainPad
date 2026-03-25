import AppKit
import SwiftUI
import XCTest
@testable import PlainPad

@MainActor
final class PlainTextViewTests: XCTestCase {
    func testInsertTabAddsLiteralTabCharacter() {
        let textView = PlainTextView(frame: .zero)
        textView.string = "abc"
        textView.setSelectedRange(NSRange(location: 1, length: 0))

        textView.insertTab(nil)

        XCTAssertEqual(textView.string, "a\tbc")
    }

    func testPasteAsPlainTextUsesStringPasteboardContents() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        XCTAssertTrue(pasteboard.setString("plain text", forType: .string))

        let textView = PlainTextView(frame: .zero)
        textView.string = "abc"
        textView.setSelectedRange(NSRange(location: 1, length: 1))

        textView.pasteAsPlainText(nil)

        XCTAssertEqual(textView.string, "aplain textc")
    }

    func testPassiveLayoutRefreshWithStableGeometryIsIgnored() {
        let editor = PlainTextEditor(text: .constant(String(repeating: "line\n", count: 200)))
        let coordinator = editor.makeCoordinator()

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 480, height: 320))
        scrollView.hasVerticalScroller = true

        let textView = PlainTextView(frame: scrollView.contentView.bounds)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: .greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.string = String(repeating: "line\n", count: 200)
        scrollView.documentView = textView

        XCTAssertTrue(coordinator.updateTextLayout(for: textView, in: scrollView, force: true))

        let originalOrigin = NSPoint(x: 0, y: 180)
        scrollView.contentView.scroll(to: originalOrigin)
        scrollView.reflectScrolledClipView(scrollView.contentView)

        XCTAssertFalse(coordinator.updateTextLayout(for: textView, in: scrollView))
        XCTAssertEqual(scrollView.contentView.bounds.origin.y, originalOrigin.y, accuracy: 0.001)
    }
}
