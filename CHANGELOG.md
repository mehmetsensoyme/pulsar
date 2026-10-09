# Changelog - Pulsar

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
