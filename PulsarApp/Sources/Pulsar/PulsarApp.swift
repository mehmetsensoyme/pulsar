import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        TempCacheManager.shared.cleanupAllTempDirectories()
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

            // Araçlar Menüsü
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
