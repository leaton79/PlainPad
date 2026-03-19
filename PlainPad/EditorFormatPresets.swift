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

    static let characterSpacing: [EditorMenuOption<Double>] = [
        .init(label: "Tight (-0.5)", value: -0.5),
        .init(label: "Normal (0)", value: 0),
        .init(label: "Loose (0.5)", value: 0.5),
        .init(label: "Wide (1.0)", value: 1.0),
    ]

    static let edgePadding: [EditorMenuOption<Double>] = [
        .init(label: "None", value: 0),
        .init(label: "Small (8)", value: 8),
        .init(label: "Medium (16)", value: 16),
        .init(label: "Large (32)", value: 32),
        .init(label: "Extra Large (48)", value: 48),
    ]
}
