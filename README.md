# PlainPad

A minimal, fast, plain-text notepad for macOS—inspired by Windows Notepad but native to the Mac.

## Purpose

PlainPad is designed as a **clean paste buffer**: a place to strip formatting when copying from the web, email, or documents. Paste anything in, get plain text out.

## Features

- **Plain text only** — No rich text, no Markdown rendering, no formatting stored in files
- **Paste strips formatting** — Default paste behavior removes all styling automatically
- **Tab key inserts tabs** — Press Tab to insert a tab character, not change focus
- **Multi-document tabs** — Standard macOS tabbed window support
- **Visibility controls** (all via Format menu + keyboard shortcuts):
  - Font size
  - Line spacing (leading)
  - Character spacing (tracking)
  - Edge padding (margins)
  - Zoom (scales rendered view, distinct from font size)
  - Themes: Light, Dark, High Contrast, Sepia
- **Standard document behavior** — New, Open, Save, Save As, recent files, autosave

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (to build)

## Building

1. Clone the repository:
```bash
   git clone https://github.com/leaton79/PlainPad.git
   cd PlainPad
```

2. Open in Xcode:
```bash
   open PlainPad.xcodeproj
```

3. Build and run (Cmd+R)

## Privacy

- **No telemetry** — PlainPad collects nothing
- **No network access** — The app never connects to the internet
- **Local only** — Preferences stored in UserDefaults; files stored wherever you choose

## License

This project is licensed under the GNU General Public License v3.0.
