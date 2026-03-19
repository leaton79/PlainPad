import SwiftUI
import AppKit

struct PlainTextEditingCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .pasteboard) {
            Button("Paste and Match Style") {
                NSApp.sendAction(#selector(NSTextView.pasteAsPlainText(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("V", modifiers: [.command, .option, .shift])
        }

        CommandGroup(after: .textEditing) {
            Divider()

            Button("Find...") {
                performTextFinderAction(.showFindInterface)
            }
            .keyboardShortcut("f", modifiers: .command)

            Button("Find and Replace...") {
                performTextFinderAction(.showReplaceInterface)
            }
            .keyboardShortcut("f", modifiers: [.command, .option])
        }
    }

    private func performTextFinderAction(_ action: NSTextFinder.Action) {
        let menuItem = NSMenuItem()
        menuItem.tag = action.rawValue
        NSApp.sendAction(#selector(NSResponder.performTextFinderAction(_:)), to: nil, from: menuItem)
    }
}

struct PlainPadFormatCommands: Commands {
    @ObservedObject var appearanceSettings: AppearanceSettings

    var body: some Commands {
        CommandMenu("Format") {
            Button("Zoom In") {
                appearanceSettings.zoomIn()
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Zoom Out") {
                appearanceSettings.zoomOut()
            }
            .keyboardShortcut("-", modifiers: .command)

            Button("Reset Zoom") {
                appearanceSettings.resetZoom()
            }
            .keyboardShortcut("0", modifiers: .command)

            Divider()

            Button("Increase Font Size") {
                appearanceSettings.increaseFontSize()
            }
            .keyboardShortcut("+", modifiers: [.command, .shift])

            Button("Decrease Font Size") {
                appearanceSettings.decreaseFontSize()
            }
            .keyboardShortcut("-", modifiers: [.command, .shift])

            Divider()

            Menu("Line Spacing") {
                ForEach(EditorFormatPresets.lineSpacing) { option in
                    Button(option.label) {
                        appearanceSettings.lineHeightMultiplier = option.value
                    }
                }
            }

            Menu("Character Spacing") {
                ForEach(EditorFormatPresets.characterSpacing) { option in
                    Button(option.label) {
                        appearanceSettings.characterSpacing = option.value
                    }
                }
            }

            Menu("Edge Padding") {
                ForEach(EditorFormatPresets.edgePadding) { option in
                    Button(option.label) {
                        appearanceSettings.edgePadding = option.value
                    }
                }
            }

            Divider()

            Menu("Theme") {
                ForEach(Theme.allCases) { theme in
                    Button(theme.displayName) {
                        appearanceSettings.theme = theme
                    }
                }
            }
        }
    }
}
