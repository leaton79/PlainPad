import SwiftUI
import UniformTypeIdentifiers

struct PlainTextDocument: FileDocument {
    var text: String
    
    // Supported content types
    static var readableContentTypes: [UTType] { [.plainText] }
    static var writableContentTypes: [UTType] { [.plainText] }
    
    // New empty document
    init(text: String = "") {
        self.text = text
    }
    
    // Read from file
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.text = try Self.decodeText(from: data)
    }
    
    // Write to file
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = serializedData()
        return FileWrapper(regularFileWithContents: data)
    }
    
    // MARK: - Line Ending Normalization
    
    /// Converts all line endings to Unix-style \n
    /// Handles: \r\n (Windows), \r (old Mac), \n (Unix)
    static func decodeText(from data: Data) throws -> String {
        // Attempt UTF-8 first, then fall back to other encodings
        if let string = String(data: data, encoding: .utf8) {
            return normalizeLineEndings(string)
        }
        if let string = String(data: data, encoding: .isoLatin1) {
            return normalizeLineEndings(string)
        }
        if let string = String(data: data, encoding: .windowsCP1252) {
            return normalizeLineEndings(string)
        }

        throw CocoaError(.fileReadInapplicableStringEncoding)
    }

    func serializedData() -> Data {
        text.data(using: .utf8) ?? Data()
    }

    static func normalizeLineEndings(_ string: String) -> String {
        var result = string
        // Replace Windows CRLF first (order matters)
        result = result.replacingOccurrences(of: "\r\n", with: "\n")
        // Replace remaining old Mac CR
        result = result.replacingOccurrences(of: "\r", with: "\n")
        return result
    }
}
