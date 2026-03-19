import AppKit
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
}
