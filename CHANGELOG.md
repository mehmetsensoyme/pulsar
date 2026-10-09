# Changelog - Pulsar

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.2] - 2026-10-10 (Icon, Onboarding & Event-Driven HUD)

### Added & Refined
- **Bespoke Pulsar Logo & macOS AppIcon (`AppIcon.icns`)**: Designed authentic macOS Sequoia squircle icon featuring rotating neutron star plasma beams and translucent geometric data capsule; compiled via `iconutil` into full Retina multi-resolution `.icns`.
- **Enriched Onboarding Setup Assistant**: Integrated official Pulsar Logo and 4 core capability cards (Apple Silicon speed, Finder drag-and-drop, safety lock & Windows cleaner, smart filters) into first-run walkthrough.
- **Event-Driven Floating HUD**: Hidden by default; only manifests when files are dropped or compression/extraction tasks are actively running; automatically displays green checkmark for 3 seconds before auto-dismissing.
- **System-Wide UI Auditing & Polishing**: Verified interactive button states, sheet dismissals, and empty hero states across Modern 3-Pane, Compact List, and Tabbed Studio modes.
- **Celestial Codename Rule Adherence**: Retained "Supernova" for v1.x series under the cosmic versioning specification.

## [1.2.1] - 2026-10-10 (Sidebar Refinement & Onboarding)

### Added & Refined
- **Apple HIG Sidebar Layout**: Re-architected sidebar navigation into clean "İçerik" and "Akıllı Filtreler" sections.
- **Fixed 20px Icon Slot**: Implemented fixed `.frame(width: 20, alignment: .center)` on all sidebar filter glyphs, eliminating ragged and misaligned Turkish text labels.
- **Live Badge Counters**: Added dynamic item counts to sidebar filters (Tüm İçerik, Dosyalar, Klasörler, Görseller, Belgeler, Kod, Medya).
- **Recent Archives History Management**: Added one-click "Temizle" header button, context menu ("Finder'da Göster", "Listeden Kaldır", "Geçmişi Temizle") on recent items, and clear buttons in Empty State Hero and Settings Studio.
- **Onboarding Setup Assistant (`OnboardingSheetView`)**: First-run setup modal allowing users to configure Theme (System, Dark, Light), Accent Color (Cyan, Purple, Orange, Green, Blue), UI Information Density, and Default Layout Mode with one-click restart from Settings.
- **Dynamic Appearance Customization**: Full integration of theme picker, 5 cosmic accent color choices, and 3 UI scale density modes in Settings Studio (`⌘,`).

## [1.2.0] - 2026-10-09 (Finder Drag-and-Drop & Gallery View)

### Added
- **Native Finder Drag-and-Drop (`.onDrag`)**: Drag files directly from inside the archive browser into macOS Finder folders or Desktop for instant extraction.
- **Finder-Style Gallery / Grid View (`FileGridView`)**: Switch between tabular list view and large icon gallery view with double-click navigation.
- **Live Status & Activity Bar**: Real-time counter of total items, selected file size, background task progress indicator, and free disk space monitor.
- **Cryptographic Checksum Validator (`⌘⇧K`)**: Calculate SHA-256, MD5, and SHA-1 checksums with automatic clipboard hash comparison.
- **Archive Format Converter (`⌘⇧C`)**: One-click recompression from RAR, ZIP, or TAR into high-efficiency 7Z or Zstandard formats.
- **Smart Category Filters**: Instant filtering by Images, Documents, Source Code, and Media.
- **macOS Keyboard Navigation Suite**: ⌘A (Select All), ⌘↑ (Go to Parent), ⌘↓ (Open/Preview), ⌘C (Copy Path), ⌘⌫ (Delete).

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
