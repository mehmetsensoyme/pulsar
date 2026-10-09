import SwiftUI

public struct FolderWatcherView: View {
    @ObservedObject var watcher = FolderWatcherService.shared
    @ObservedObject var settings = PulsarSettings.shared
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 0) {
            // Başlık
            HStack {
                Image(systemName: "circle.circle.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text("KARA DELİK KLASÖR İZLEYİCİ")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                    Text("İndirilen yeni arşivleri otomatik tespit edip klasöre açar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Kapat") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                // Durum ve Başlat/Durdur
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(watcher.isWatching ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(watcher.isWatching ? "İzleme Aktif (Gözlemde)" : "İzleme Durduruldu")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Text("İzlenen Klasör: \(settings.folderWatcherPath.abbreviatingWithTilde)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if watcher.isWatching {
                        Button("Durdur") {
                            watcher.stopWatching()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("İzlemeyi Başlat") {
                            watcher.startWatching(path: settings.folderWatcherPath)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Tercihler
                VStack(alignment: .leading, spacing: 10) {
                    Text("OTOMASYON KURALLARI")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)

                    Toggle("Başarıyla çıkarılan arşiv dosyasını Çöp Sepetine taşı", isOn: $settings.autoTrashAfterExtract)
                        .font(.system(size: 12))

                    Toggle("İşlem tamamlandığında sesli macOS bildirimi gönder", isOn: $settings.sendNotifications)
                        .font(.system(size: 12))

                    HStack {
                        Text("İzlenecek Klasörü Değiştir:")
                            .font(.system(size: 12))
                        Spacer()
                        Button("Klasör Seç...") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            if panel.runModal() == .OK, let url = panel.url {
                                settings.folderWatcherPath = url.path
                                if watcher.isWatching {
                                    watcher.startWatching(path: url.path)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Canlı Yakalanan Dosyalar Listesi
                VStack(alignment: .leading, spacing: 8) {
                    Text("İŞLENEN ARŞİV GEÇMİŞİ")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)

                    if watcher.processedEvents.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("Henüz yeni arşiv indirilmedi")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(watcher.processedEvents) { event in
                            HStack {
                                FileIconView(fileName: event.filename, size: 16)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.filename)
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(event.status)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Göster") {
                                    NSWorkspace.shared.selectFile(event.path, inFileViewerRootedAtPath: (event.path as NSString).deletingLastPathComponent)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .frame(maxHeight: 180)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }
}
