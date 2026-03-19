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
        
        // Attempt UTF-8 first, then fall back to other encodings
        if let string = String(data: data, encoding: .utf8) {
            self.text = Self.normalizeLineEndings(string)
        } else if let string = String(data: data, encoding: .isoLatin1) {
            self.text = Self.normalizeLineEndings(string)
        } else if let string = String(data: data, encoding: .windowsCP1252) {
            self.text = Self.normalizeLineEndings(string)
        } else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
    }
    
    // Write to file
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
    
    // MARK: - Line Ending Normalization
    
    /// Converts all line endings to Unix-style \n
    /// Handles: \r\n (Windows), \r (old Mac), \n (Unix)
    private static func normalizeLineEndings(_ string: String) -> String {
        var result = string
        // Replace Windows CRLF first (order matters)
        result = result.replacingOccurrences(of: "\r\n", with: "\n")
        // Replace remaining old Mac CR
        result = result.replacingOccurrences(of: "\r", with: "\n")
        return result
    }
}
