import SwiftUI

public struct PulsarToolbarContent: ToolbarContent {
    @ObservedObject var manager = ArchiveManager.shared

    public var body: some ToolbarContent {
        // Sol Bölüm: Görünüm Modu Seçici
        ToolbarItem(placement: .navigation) {
            Picker("Görünüm", selection: $manager.currentLayoutMode) {
                ForEach(LayoutMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .help("Arayüz Düzeni (⌘1, ⌘2, ⌘3)")
        }

        // Ana Aksiyonlar: Çıkar, Sıkıştır, Ekle
        ToolbarItemGroup(placement: .principal) {
            Button(action: {
                manager.extractAll()
            }) {
                Label("Tümünü Çıkar", systemImage: "arrow.up.bin.fill")
            }
            .disabled(manager.currentArchivePath == nil)
            .help("Arşiv içeriğini klasöre çıkar")

            Button(action: {
                manager.showCompressSheet = true
            }) {
                Label("Yeni Arşiv", systemImage: "plus.rectangle.fill.on.rectangle.fill")
            }
            .help("Yeni dosya veya klasör sıkıştır")

            // Güvenlik Kilidi (Safe Lock Toggle)
            Button(action: {
                withAnimation {
                    manager.isEditingUnlocked.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: manager.isEditingUnlocked ? "lock.open.fill" : "lock.fill")
                        .foregroundColor(manager.isEditingUnlocked ? .orange : .green)
                    Text(manager.isEditingUnlocked ? "Düzenleme Açık" : "Salt Okunur")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(manager.isEditingUnlocked ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help(manager.isEditingUnlocked ? "Düzenleme Modu Aktif (Dosya eklenebilir/silinebilir)" : "Güvenlik Kilidi Aktif (Kazara değişiklikler engellenir)")

            if manager.isEditingUnlocked {
                Button(action: {
                    manager.deleteSelectedItems()
                }) {
                    Label("Sil", systemImage: "trash")
                }
                .disabled(manager.selectedItemIds.isEmpty)
                .help("Seçili dosyaları arşivden sil")
            }
        }

        // Sağ Bölüm: Sci-Fi Modülleri & Arama
        ToolbarItemGroup(placement: .primaryAction) {
            // Pulsar Warp Core Benchmark
            Button(action: {
                manager.showBenchmarkSheet = true
            }) {
                Label("Warp Hız Testi", systemImage: "bolt.fill")
            }
            .help("Pulsar Warp Core Donanım Benchmarkı")

            // Kara Delik Klasör İzleyici
            Button(action: {
                manager.showFolderWatcherSheet = true
            }) {
                Label("Kara Delik", systemImage: "circle.circle")
            }
            .help("Kara Delik Otomatik Klasör İzleyici")

            // Arşiv Kurtarma
            Button(action: {
                manager.showRepairSheet = true
            }) {
                Label("Kurtarma", systemImage: "wrench.and.screwdriver")
            }
            .help("Bozuk Arşiv Kurtarma İstasyonu")

            // Yüzen HUD Aç/Kapat
            Button(action: {
                manager.isHUDVisible.toggle()
            }) {
                Label("Yüzen HUD", systemImage: "macwindow.on.rectangle")
            }
            .help("Yüzen Mini Paneli (HUD) Göster/Gizle (⌘⇧H)")

            // Gelişmiş Ayarlar
            Button(action: {
                manager.showSettingsSheet = true
            }) {
                Label("Ayarlar", systemImage: "gearshape.fill")
            }
            .help("Pulsar Ayarları ve Tercihler (⌘,)")
        }
    }
}
