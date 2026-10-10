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

            if manager.currentArchivePath != nil {
                Button(action: {
                    manager.closeArchive()
                }) {
                    Label("Kapat", systemImage: "xmark.circle")
                }
                .help("Açık arşivi kapat ve ana ekrana dön (⌘W)")
            }
        }

        // Sağ Bölüm: Modüller, Karşılaştırma, HUD ve Ayarlar
        ToolbarItemGroup(placement: .primaryAction) {
            // Arşiv Karşılaştırma & Diff (⌘⇧D)
            Button(action: {
                manager.showDiffSheet = true
            }) {
                Label("Arşiv Karşılaştır", systemImage: "square.split.2x1")
            }
            .help("İki arşiv arasındaki farkları karşılaştır (⌘⇧D)")

            // Araçlar & Modüller Açılır Menüsü
            Menu {
                Section("Performans & Otomasyon") {
                    Button(action: {
                        manager.showBenchmarkSheet = true
                    }) {
                        Label("Warp Hız Testi", systemImage: "bolt.fill")
                    }

                    Button(action: {
                        manager.showFolderWatcherSheet = true
                    }) {
                        Label("Kara Delik Klasör İzleyici", systemImage: "circle.circle")
                    }
                }

                Section("Kurtarma & Doğrulama") {
                    Button(action: {
                        manager.showRepairSheet = true
                    }) {
                        Label("Bozuk Arşiv Kurtarma", systemImage: "wrench.and.screwdriver")
                    }

                    Button(action: {
                        manager.showConverterSheet = true
                    }) {
                        Label("Format Dönüştürücü", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Button(action: {
                        manager.openChecksumModal()
                    }) {
                        Label("Sağlama Toplamı (Checksum)", systemImage: "checkmark.shield")
                    }
                }
            } label: {
                Label("Araçlar", systemImage: "sparkles.rectangle.stack")
            }
            .help("Pulsar Güç Modülleri ve Araçları")

            // Yüzen HUD Aç/Kapat
            Button(action: {
                manager.isHUDVisible.toggle()
            }) {
                Label("Yüzen HUD", systemImage: manager.isHUDVisible ? "macwindow.on.rectangle" : "macwindow")
            }
            .help("Yüzen Mini Paneli (HUD) Göster/Gizle (⌘⇧H)")

            // Gelişmiş Ayarlar
            Button(action: {
                manager.showSettingsSheet = true
            }) {
                Label("Ayarlar", systemImage: "gearshape")
            }
            .help("Pulsar Ayarları ve Tercihler (⌘,)")
        }
    }
}
