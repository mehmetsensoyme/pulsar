import SwiftUI

public struct ModernThreePaneView: View {
    @ObservedObject var manager = ArchiveManager.shared

    public var body: some View {
        NavigationSplitView {
            // Sol Kenar Çubuğu: Son Arşivler ve Konumlar
            List {
                Section("Gezinme") {
                    Label("Tüm İçerik", systemImage: "folder")
                        .tag("all")
                    Label("Sadece Dosyalar", systemImage: "doc")
                        .tag("files")
                }

                Section("Son Açılan Arşivler") {
                    ForEach(manager.recentArchives, id: \.self) { path in
                        Button(action: {
                            manager.openArchive(at: path)
                        }) {
                            HStack {
                                Image(systemName: "archivebox")
                                    .foregroundColor(.secondary)
                                Text((path as NSString).lastPathComponent)
                                    .lineLimit(1)
                                    .font(.system(size: 12))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Sistem") {
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
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180, idealWidth: 200)
        } content: {
            // Orta Bölüm: Breadcrumb + Dosya Tablosu
            VStack(spacing: 0) {
                BreadcrumbBar()
                FileTableView()
            }
        } detail: {
            // Sağ Bölüm: Canlı Denetçi & Önizleme
            InspectorView()
        }
    }
}

public struct FileTableView: View {
    @ObservedObject var manager = ArchiveManager.shared

    public var body: some View {
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
                    if item.isDirectory {
                        manager.openFolder(item: item)
                    } else {
                        manager.openOrPreviewItem(item)
                    }
                }
            }
            .width(min: 200, ideal: 300)

            TableColumn("Boyut") { item in
                Text(item.formattedSize)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .width(min: 70, ideal: 90)

            TableColumn("Sıkıştırılmış") { item in
                Text(item.formattedCompressedSize)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .width(min: 80, ideal: 100)

            TableColumn("Oran") { item in
                Text(item.compressionRatioPercentage)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(item.isDirectory ? .clear : .cyan)
            }
            .width(min: 60, ideal: 70)

            TableColumn("Tarih") { item in
                Text(item.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .width(min: 120, ideal: 150)
        }
        .contextMenu {
            if !manager.selectedItemIds.isEmpty {
                Button("Seçileni Çıkar...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.prompt = "Çıkar"
                    if panel.runModal() == .OK, let url = panel.url {
                        manager.extractSelected(to: url.path)
                    }
                }

                if manager.isEditingUnlocked {
                    Divider()
                    Button("Arşivden Sil", role: .destructive) {
                        manager.deleteSelectedItems()
                    }
                }
            }
        }
    }
}
