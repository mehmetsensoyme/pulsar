# Changelog - Pulsar

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-10-09 (Apple HIG & Dynamic Themes)

### Added & Refined
- **Native macOS Finder File & Folder Icons (`FileIconView`)**: Replaced artificial emojis with real system file and folder icons fetched via `NSWorkspace.shared.icon(for:)` and `UniformTypeIdentifiers.UTType`.
- **Dynamic Light & Dark System Appearance**: Replaced fixed dark colors with native macOS semantic colors (`NSColor.windowBackgroundColor`, `NSColor.controlBackgroundColor`, `accentColor`, `primary`, `secondary`) ensuring seamless dynamic adaptation to macOS appearance settings.
- **Redesigned Settings Studio (`⌘,`)**: Compact top segmented tab bar with Sonoma/Sequoia grouped form cards, 600×500 px unified sheet dimensions, and `Esc` / `⌘W` / `Bitti` button dismissal.
- **Full-Width Centered Empty State Hero Zone**: When no archive is opened, the detail inspector is cleanly hidden so the hero drop-zone expands across the entire workspace.
- **Close Archive Shortcut (`⌘W` / File -> Arşivi Kapat)**: Allows closing open archives to return cleanly to the empty state hero zone.
- **Unified 600px Modal Sheet Architecture**: Standardized Compress (`⌘N`), Benchmark (`⌘⇧B`), Folder Watcher, and Repair Station modals to 600px width with Esc dismissal.
- **Tilde Privacy Masking**: Masked all user paths with `~` tilde abbreviations (`~/...`) across all UI displays.

## [1.1.0] - 2026-10-09 (Supernova)

### Added
- **Settings Studio (⌘,)**: Full-featured 6-tab preferences window covering General preferences, Engines & live health diagnostics, Security & cache auto-clean, Black Hole folder watcher automation, Floating HUD positioning and opacity, and About & live updates.
- **Live GitHub Releases Update Service**: Real-time GitHub API SemVer release check with user notifications, direct download links, and release notes display.
- **Sidebar Navigation Filter**: Instant toggle buttons in the sidebar ("All Items", "Files Only", "Folders Only") to filter archive contents with visual indicators.
- **Empty State Hero Drop Zone**: Sci-fi hero screen when no archive is loaded, offering quick-open (`⌘O`), new archive creation (`⌘N`), drop guidance, and quick access to recent archives.
- **Compress Studio Enhancements**: Added custom output destination picker (`NSOpenPanel`) and removable source item tags with `[x]` buttons.
- **Enhanced Table Interaction**: Full-row double click support and rich context menu (`Preview`, `Extract Selected...`, `Extract All...`, `Delete from Archive`).
- **Standard Preferences Shortcut**: Bound macOS HIG standard `⌘,` keyboard shortcut to open the Settings Studio across all views and menu bar.

## [1.0.0] - 2026-10-09 (Event Horizon)

### Added
- **Native Apple Silicon Architecture**: 100% native Swift 6 and AppKit/SwiftUI implementation optimized for Apple Silicon (M1/M2/M3/M4).
- **Dual-Engine Architecture**:
  - Embedded Apple Silicon ARM64 native `7zz` (7-Zip 26.04) engine.
  - Official RARLAB `rar` and `unrar` engine bridge for RAR creation and extraction.
- **3-in-1 Adaptive Window Layout**:
  - **Modern 3-Pane (Inspector)**: Left sidebar, central content table, and right live QuickLook inspector.
  - **Compact Classic List**: High-density table view with all technical archive metrics.
  - **Tabbed Studio**: Multi-archive workspace with draggable tab headers and inter-archive transfers.
- **Dual-Mode Safety Lock**:
  - Read-Only mode by default prevents accidental destruction.
  - Toolbar lock toggle allows live file modification, dragging files directly into the archive, and deletion.
- **Floating HUD (Cosmic Mini Widget)**:
  - Translucent glass card pinnable to screen corners (`⌘⇧H`).
  - Drag-and-drop drop-zone for instant background archiving with circular progress ring.
- **Pulsar Warp Core Benchmark**:
  - Built-in Apple Silicon hardware compression & decompression speed tester utilizing multi-core 7-Zip engine.
  - Real-time MIPS scoring and hardware metrics.
- **Black Hole Folder Watcher (Kara Delik)**:
  - FSEvents-powered background folder watcher for `~/Downloads`.
  - Automatic archive detection, batch unpack queue, optional auto-trash, and native system notification.
- **Archive Repair Station**:
  - WinRAR Recovery Record parser and repair station for damaged or CRC-corrupted archives.
- **Windows-Friendly Clean Filter**:
  - Automatic exclusion and stripping of macOS metadata (`.DS_Store`, AppleDouble `._*`, `__MACOSX`).
- **Hybrid Keychain Security**:
  - AES-256 encrypted archive support with Touch ID and macOS Keychain password memory.
- **Interactive Promotional Landing Website**:
  - Responsive, space-themed glassmorphism showcase with live changelog tracker and interactive preview mockups.
