import SwiftUI

public struct ModernThreePaneView: View {
    @ObservedObject var manager = ArchiveManager.shared

    public var body: some View {
        NavigationSplitView {
            // Sol Kenar Çubuğu: Gezinme, Son Arşivler ve Sistem
            List {
                Section("Gezinme Filtresi") {
                    ForEach(ContentFilterMode.allCases) { mode in
                        Button(action: {
                            manager.filterMode = mode
                        }) {
                            HStack {
                                Image(systemName: mode.iconName)
                                    .foregroundColor(manager.filterMode == mode ? .cyan : .secondary)
                                Text(mode.rawValue)
                                    .font(.system(size: 12, weight: manager.filterMode == mode ? .semibold : .regular))
                                Spacer()
                                if manager.filterMode == mode {
                                    Circle()
                                        .fill(Color.cyan)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Son Açılan Arşivler") {
                    if manager.recentArchives.isEmpty {
                        Text("Son arşiv bulunmuyor")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(manager.recentArchives, id: \.self) { path in
                            Button(action: {
                                manager.openArchive(at: path)
                            }) {
                                HStack {
                                    Image(systemName: "archivebox.fill")
                                        .foregroundColor(manager.currentArchivePath == path ? .cyan : .secondary)
                                    Text((path as NSString).lastPathComponent)
                                        .lineLimit(1)
                                        .font(.system(size: 12, weight: manager.currentArchivePath == path ? .semibold : .regular))
                                }
                                .padding(.vertical, 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Sistem & Modüller") {
                    Button(action: {
                        manager.showBenchmarkSheet = true
                    }) {
                        Label("Warp Benchmark", systemImage: "bolt.fill")
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        manager.showFolderWatcherSheet = true
                    }) {
                        Label("Kara Delik İzleyici", systemImage: "circle.circle")
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        manager.showRepairSheet = true
                    }) {
                        Label("Kurtarma İstasyonu", systemImage: "wrench.and.screwdriver")
                    }
                    .buttonStyle(.plain)

                    Divider()

                    Button(action: {
                        manager.showSettingsSheet = true
                    }) {
                        Label("Ayarlar & Tercihler...", systemImage: "gearshape.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 190, idealWidth: 220)
        } content: {
            // Orta Bölüm: Arşiv açık değilse Hero Karşılama, açıksa Breadcrumbs + Tablo
            if manager.currentArchivePath == nil {
                EmptyArchiveHeroView()
            } else {
                VStack(spacing: 0) {
                    BreadcrumbBar()
                    FileTableView()
                }
            }
        } detail: {
            // Sağ Bölüm: Canlı Denetçi & Önizleme
            InspectorView()
        }
    }
}

/// Arşiv açık olmadığında görüntülenen Sci-Fi Karşılama ve Drop-Zone Ekranı
public struct EmptyArchiveHeroView: View {
    @ObservedObject var manager = ArchiveManager.shared

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Pulsar Yıldızı & Parıltı Efekti
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.35), Color.purple.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)

                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan.opacity(0.8), radius: 16)
            }

            VStack(spacing: 6) {
                Text("PULSAR")
                    .font(.system(size: 26, weight: .black, design: .monospaced))
                    .foregroundColor(.primary)

                Text("macOS İçin Işık Hızında Arşiv ve Sıkıştırma Ekosistemi")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            // Hızlı Aksiyon Butonları
            HStack(spacing: 16) {
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.prompt = "Arşiv Aç"
                    if panel.runModal() == .OK, let url = panel.url {
                        manager.openArchive(at: url.path)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.gearshape")
                        Text("Arşiv Aç (⌘O)")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Button(action: {
                    manager.showCompressSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                        Text("Yeni Arşiv Oluştur (⌘N)")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }

            // Bırakma İpucu
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 11))
                Text("Veya herhangi bir arşivi doğrudan bu pencereye sürükleyip bırakın")
                    .font(.system(size: 11))
            }
            .foregroundColor(.secondary.opacity(0.8))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
    }
}

public struct FileTableView: View {
    @ObservedObject var manager = ArchiveManager.shared

    private func handleItemAction(_ item: ArchiveItem) {
        if item.isDirectory {
            manager.openFolder(item: item)
        } else {
            manager.openOrPreviewItem(item)
        }
    }

    public var body: some View {
        Group {
            if manager.currentFolderItems.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text(manager.searchQuery.isEmpty ? "Bu klasörde görüntülenecek öğe yok" : "Arama ile eşleşen dosya bulunamadı")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(manager.currentFolderItems, selection: $manager.selectedItemIds) {
                    TableColumn("Ad") { item in
                        HStack(spacing: 8) {
                            Image(systemName: item.iconName)
                                .foregroundColor(item.iconColor)
                                .font(.system(size: 14))

                            Text(item.name)
                                .font(.system(size: 13, weight: item.isDirectory ? .semibold : .regular))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            handleItemAction(item)
                        }
                    }
                    .width(min: 200, ideal: 300)

                    TableColumn("Boyut") { item in
                        Text(item.formattedSize)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                handleItemAction(item)
                            }
                    }
                    .width(min: 70, ideal: 90)

                    TableColumn("Sıkıştırılmış") { item in
                        Text(item.formattedCompressedSize)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                handleItemAction(item)
                            }
                    }
                    .width(min: 80, ideal: 100)

                    TableColumn("Oran") { item in
                        Text(item.compressionRatioPercentage)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(item.isDirectory ? .clear : .cyan)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                handleItemAction(item)
                            }
                    }
                    .width(min: 60, ideal: 70)

                    TableColumn("Tarih") { item in
                        Text(item.formattedDate)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                handleItemAction(item)
                            }
                    }
                    .width(min: 120, ideal: 150)
                }
                .contextMenu {
                    if !manager.selectedItemIds.isEmpty {
                        if let firstId = manager.selectedItemIds.first,
                           let firstItem = manager.allItems.first(where: { $0.id == firstId }) {
                            Button("Önizle (QuickLook)") {
                                manager.openOrPreviewItem(firstItem)
                            }
                        }

                        Button("Seçileni Çıkar...") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.prompt = "Buraya Çıkar"
                            if panel.runModal() == .OK, let url = panel.url {
                                manager.extractSelected(to: url.path)
                            }
                        }

                        Divider()

                        Button("Tüm Arşivi Çıkar...") {
                            manager.extractAll()
                        }

                        if manager.isEditingUnlocked {
                            Divider()
                            Button("Arşivden Sil", role: .destructive) {
                                manager.deleteSelectedItems()
                            }
                        }
                    } else {
                        Button("Tüm Arşivi Çıkar...") {
                            manager.extractAll()
                        }
                    }
                }
            }
        }
    }
}
