import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") ?? Bundle.main.path(forResource: "logo", ofType: "png"),
           let img = NSImage(contentsOfFile: iconPath) {
            NSApplication.shared.applicationIconImage = img
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        TempCacheManager.shared.cleanupAllTempDirectories()
    }

    func application(_ application: NSApplication, openFiles filenames: [String]) {
        if let first = filenames.first {
            ArchiveManager.shared.openArchive(at: first)
        }
    }
}

@main
struct PulsarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager = ArchiveManager.shared
    @StateObject private var settings = PulsarSettings.shared
    @StateObject private var updater = UpdateService.shared

    init() {
        if CommandLine.arguments.contains("--run-tests") {
            let success = PulsarTestRunner.runAllTests()
            exit(success ? 0 : 1)
        }

        // Otomatik Klasör İzleyici aktifse başlat
        if PulsarSettings.shared.enableFolderWatcher {
            FolderWatcherService.shared.startWatching(path: PulsarSettings.shared.folderWatcherPath)
        }
    }

    var body: some Scene {
        // 1. Ana Uygulama Penceresi
        WindowGroup {
            MainWindowView()
                .environmentObject(manager)
                .environmentObject(settings)
                .environmentObject(updater)
                .onOpenURL { url in
                    if url.isFileURL {
                        manager.openArchive(at: url.path)
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            // Ayarlar Menüsü (⌘,)
            CommandGroup(replacing: .appSettings) {
                Button("Ayarlar...") {
                    manager.showSettingsSheet = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            // Görünüm Menüsü Kısayolları
            CommandGroup(replacing: .sidebar) {
                Button("Modern 3-Bölmeli Düzen") {
                    manager.currentLayoutMode = .modernThreePane
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Kompakt Liste Düzeni") {
                    manager.currentLayoutMode = .compactList
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Sekmeli Stüdyo Düzeni") {
                    manager.currentLayoutMode = .tabbedStudio
                }
                .keyboardShortcut("3", modifiers: .command)

                Divider()

                Button("Yüzen HUD Göster/Gizle") {
                    manager.isHUDVisible.toggle()
                }
                .keyboardShortcut("H", modifiers: [.command, .shift])

                Button("Güvenlik Kilidini Değiştir") {
                    manager.isEditingUnlocked.toggle()
                }
                .keyboardShortcut("L", modifiers: .command)
            }

            // Dosya Menüsü
            CommandGroup(replacing: .newItem) {
                Button("Yeni Arşiv Oluştur...") {
                    manager.showCompressSheet = true
                }
                .keyboardShortcut("N", modifiers: .command)

                Button("Arşiv Aç...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    if panel.runModal() == .OK, let url = panel.url {
                        manager.openArchive(at: url.path)
                    }
                }
                .keyboardShortcut("O", modifiers: .command)

                Button("Yeni Sekmede Arşiv Aç...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.prompt = "Sekmede Aç"
                    if panel.runModal() == .OK, let url = panel.url {
                        manager.currentLayoutMode = .tabbedStudio
                        manager.openArchive(at: url.path)
                    }
                }
                .keyboardShortcut("t", modifiers: .command)

                Divider()

                Button("Arşivi Kapat") {
                    manager.closeArchive()
                }
                .keyboardShortcut("w", modifiers: .command)
                .disabled(manager.currentArchivePath == nil)

                Button("Tümünü Çıkar...") {
                    manager.extractAll()
                }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(manager.currentArchivePath == nil)
            }

            // Düzen Menüsü Kısayolları (⌘A, ⌘C, ⌘⌫)
            CommandGroup(replacing: .pasteboard) {
                Button("Tümünü Seç") {
                    manager.selectAllItems()
                }
                .keyboardShortcut("a", modifiers: .command)

                Button("Yolu Kopyala") {
                    manager.copySelectedPaths()
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("Seçilenleri Sil") {
                    manager.deleteSelectedItems()
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(!manager.isEditingUnlocked || manager.selectedItemIds.isEmpty)
            }

            // Git Menüsü (⌘↑, ⌘↓)
            CommandMenu("Git") {
                Button("Üst Klasöre Git") {
                    manager.goUpOneLevel()
                }
                .keyboardShortcut(.upArrow, modifiers: .command)
                .disabled(manager.currentFolderPath.isEmpty)

                Button("Seçileni Aç veya Önizle") {
                    if let firstId = manager.selectedItemIds.first,
                       let item = manager.allItems.first(where: { $0.id == firstId }) {
                        manager.openOrPreviewItem(item)
                    }
                }
                .keyboardShortcut(.downArrow, modifiers: .command)
                .disabled(manager.selectedItemIds.isEmpty)
            }

            // Araçlar & Modüller Menüsü
            CommandMenu("Modüller") {
                Button("Pulsar Warp Benchmark") {
                    manager.showBenchmarkSheet = true
                }
                .keyboardShortcut("B", modifiers: [.command, .shift])

                Button("Kara Delik Klasör İzleyici") {
                    manager.showFolderWatcherSheet = true
                }

                Button("Arşiv Kurtarma İstasyonu") {
                    manager.showRepairSheet = true
                }

                Divider()

                Button("Arşiv Format Dönüştürücü...") {
                    manager.showConverterSheet = true
                }
                .keyboardShortcut("C", modifiers: [.command, .shift])

                Button("Sağlama Toplamı (Checksum)...") {
                    manager.openChecksumModal()
                }
                .keyboardShortcut("K", modifiers: [.command, .shift])

                Divider()

                Button("Güncellemeleri Denetle...") {
                    manager.showUpdateSheet = true
                }
            }
        }

        // 2. macOS Menü Çubuğu Eklentisi (MenuBarExtra)
        MenuBarExtra("Pulsar", systemImage: "sparkles") {
            VStack(alignment: .leading, spacing: 6) {
                Text("PULSAR v\(updater.currentVersion)")
                    .font(.caption).bold()

                Divider()

                Button("Yeni Arşiv...") {
                    manager.showCompressSheet = true
                }

                Button("Warp Core Benchmark") {
                    manager.showBenchmarkSheet = true
                }

                Button("Kara Delik Klasör İzleyici") {
                    manager.showFolderWatcherSheet = true
                }

                Divider()

                Button("Sürüm Bilgisi...") {
                    manager.showUpdateSheet = true
                }

                Button("Ayarlar...") {
                    manager.showSettingsSheet = true
                }
                .keyboardShortcut(",", modifiers: .command)

                Divider()

                Button("Pulsar'dan Çık") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("Q", modifiers: .command)
            }
        }
    }
}
