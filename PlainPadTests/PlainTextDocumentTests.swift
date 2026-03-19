import XCTest
@testable import PlainPad

final class PlainTextDocumentTests: XCTestCase {
    func testDecodeTextNormalizesMixedLineEndings() throws {
        let source = "one\r\ntwo\rthree\nfour"
        let data = try XCTUnwrap(source.data(using: .utf8))

        let text = try PlainTextDocument.decodeText(from: data)

        XCTAssertEqual(text, "one\ntwo\nthree\nfour")
    }

    func testDecodeTextFallsBackToLatin1WhenUTF8DecodingFails() throws {
        let source = "café"
        let data = try XCTUnwrap(source.data(using: .isoLatin1))

        let text = try PlainTextDocument.decodeText(from: data)

        XCTAssertEqual(text, source)
    }

    func testSerializedDataWritesUTF8Data() {
        let document = PlainTextDocument(text: "hello")
        let data = document.serializedData()

        XCTAssertEqual(String(data: data, encoding: .utf8), "hello")
    }
}
