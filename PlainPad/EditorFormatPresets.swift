import Foundation

struct EditorMenuOption<Value>: Identifiable {
    let label: String
    let value: Value

    var id: String { label }
}

enum EditorFormatPresets {
    static let lineSpacing: [EditorMenuOption<Double>] = [
        .init(label: "Compact (1.0)", value: 1.0),
        .init(label: "Normal (1.2)", value: 1.2),
        .init(label: "Relaxed (1.5)", value: 1.5),
        .init(label: "Spacious (2.0)", value: 2.0),
    ]
}
