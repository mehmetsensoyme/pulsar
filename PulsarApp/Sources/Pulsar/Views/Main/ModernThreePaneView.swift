import SwiftUI

public struct ModernThreePaneView: View {
    @ObservedObject var manager = ArchiveManager.shared

    public var body: some View {
        if manager.currentArchivePath == nil {
            NavigationSplitView {
                sidebarView
            } detail: {
                EmptyArchiveHeroView()
            }
        } else {
            NavigationSplitView {
                sidebarView
            } content: {
                VStack(spacing: 0) {
                    BreadcrumbBar()
                    if manager.isGridView {
                        FileGridView()
                    } else {
                        FileTableView()
                    }
                }
            } detail: {
                InspectorView()
            }
        }
    }

    @ViewBuilder
    private var sidebarView: some View {
        // Sol Kenar Çubuğu: Gezinme, Son Arşivler ve Sistem
        List {
            Section("Gezinme Filtresi") {
                ForEach(ContentFilterMode.allCases) { mode in
                    Button(action: {
                        manager.filterMode = mode
                    }) {
                        HStack {
                            Image(systemName: mode.iconName)
                                .foregroundColor(manager.filterMode == mode ? .accentColor : .secondary)
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: manager.filterMode == mode ? .semibold : .regular))
                            Spacer()
                            if manager.filterMode == mode {
                                Circle()
                                    .fill(Color.accentColor)
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
                                FileIconView(fileName: (path as NSString).lastPathComponent, size: 14)
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

                Button(action: {
                    manager.showConverterSheet = true
                }) {
                    Label("Format Dönüştürücü", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.plain)

                Button(action: {
                    manager.openChecksumModal()
                }) {
                    Label("Sağlama Toplamı (Checksum)", systemImage: "checkmark.shield")
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
    }
}

/// Arşiv açık olmadığında görüntülenen Sci-Fi Karşılama ve Drop-Zone Ekranı
/// Arşiv açık olmadığında görüntülenen Apple HIG Karşılama ve Drop-Zone Ekranı
public struct EmptyArchiveHeroView: View {
    @ObservedObject var manager = ArchiveManager.shared

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 110, height: 110)

                    Image(systemName: "archivebox.circle.fill")
                        .font(.system(size: 64))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.accentColor)
                }

                VStack(spacing: 6) {
                    Text("Pulsar")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Açmak için bir arşiv dosyasını buraya sürükleyin")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
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
                            Image(systemName: "folder")
                            Text("Arşiv Aç (⌘O)")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)

                    Button(action: {
                        manager.showCompressSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Yeni Arşiv (⌘N)")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
                .padding(.top, 4)
            }
            .padding(36)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            // Son Arşivler Varsa Hızlı Kısayol
            if !manager.recentArchives.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SON KULLANILANLAR")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(manager.recentArchives.prefix(3), id: \.self) { path in
                            Button(action: {
                                manager.openArchive(at: path)
                            }) {
                                HStack(spacing: 6) {
                                    FileIconView(fileName: (path as NSString).lastPathComponent, size: 14)
                                    Text((path as NSString).lastPathComponent)
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
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

    private func itemProvider(for item: ArchiveItem) -> NSItemProvider {
        guard let archive = manager.currentArchivePath else {
            return NSItemProvider()
        }
        let tempDir = NSTemporaryDirectory().appending("PulsarDrag_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        TempCacheManager.shared.registerTempDirectory(tempDir)
        SevenZipEngine.shared.extractSync(archiveAt: archive, to: tempDir, selectedFiles: [item.path])
        let filePath = (tempDir as NSString).appendingPathComponent(item.path)
        let url = URL(fileURLWithPath: filePath)
        return NSItemProvider(object: url as NSURL)
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
                            FileIconView(item: item, size: 16)

                            Text(item.name)
                                .font(.system(size: 13, weight: item.isDirectory ? .semibold : .regular))
                                .foregroundColor(.primary)

                            if item.isEncrypted {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            handleItemAction(item)
                        }
                        .onDrag {
                            itemProvider(for: item)
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
                            .foregroundColor(item.isDirectory ? .clear : .accentColor)
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

                            if !firstItem.isDirectory {
                                Menu("Şununla Aç...") {
                                    Button("Metin Düzenleyici (TextEdit)") {
                                        manager.openWithApp(item: firstItem, appBundleId: "com.apple.TextEdit")
                                    }
                                    Button("Önizleme (Preview)") {
                                        manager.openWithApp(item: firstItem, appBundleId: "com.apple.Preview")
                                    }
                                    Divider()
                                    Button("Diğer Uygulama Seç...") {
                                        manager.openWithCustomApp(item: firstItem)
                                    }
                                }

                                Button("Sağlama Toplamı (Checksum)...") {
                                    manager.openChecksumModal(for: firstItem)
                                }
                            }
                        }

                        Button("Yolu Kopyala") {
                            manager.copySelectedPaths()
                        }

                        Divider()

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
                .onKeyPress(.return) {
                    if let firstId = manager.selectedItemIds.first,
                       let item = manager.allItems.first(where: { $0.id == firstId }) {
                        handleItemAction(item)
                        return .handled
                    }
                    return .ignored
                }
                .onKeyPress(.space) {
                    if let firstId = manager.selectedItemIds.first,
                       let item = manager.allItems.first(where: { $0.id == firstId }) {
                        manager.openOrPreviewItem(item)
                        return .handled
                    }
                    return .ignored
                }
            }
        }
    }
}
