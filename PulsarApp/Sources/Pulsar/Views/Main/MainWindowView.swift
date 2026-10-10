import SwiftUI
import UniformTypeIdentifiers

public final class MainWindowViewModel: ObservableObject {
    @Published public var isWindowDropTargeted: Bool = false
    public init() {}
}

public struct MainWindowView: View {
    @ObservedObject var manager = ArchiveManager.shared
    @ObservedObject var settings = PulsarSettings.shared
    @StateObject private var vm = MainWindowViewModel()

    private var hudAlignment: Alignment {
        switch settings.hudCorner {
        case "topLeft": return .topLeading
        case "bottomRight": return .bottomTrailing
        case "bottomLeft": return .bottomLeading
        default: return .topTrailing
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: hudAlignment) {
                // Ana Düzen
                Group {
                    switch manager.currentLayoutMode {
                    case .modernThreePane:
                        ModernThreePaneView()
                    case .compactList:
                        CompactListView()
                    case .tabbedStudio:
                        TabbedStudioView()
                    }
                }
                .frame(minWidth: 800, minHeight: 500)

                // Yüzen HUD Widget
                if manager.isHUDVisible {
                    FloatingHUDView()
                        .padding(16)
                        .transition(.opacity)
                }

                // Sürükle-Bırak Görsel Geri Bildirimi
                if vm.isWindowDropTargeted {
                    ZStack {
                        Color.black.opacity(0.4)
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.cyan)
                            Text("Açmak İçin Arşivi Buraya Bırakın")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan, lineWidth: 2))
                    }
                    .transition(.opacity)
                }
            }

            // macOS HIG Alt Durum Çubuğu
            StatusFooterBarView()
        }
        .toolbar {
            PulsarToolbarContent()
        }
        .searchable(text: $manager.searchQuery, prompt: "Arşiv içinde ara...")
        .onDrop(of: [.fileURL], isTargeted: $vm.isWindowDropTargeted) { providers in
            let group = DispatchGroup()
            var droppedPaths: [String] = []
            let lock = NSLock()

            for provider in providers {
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    defer { group.leave() }
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    lock.lock()
                    droppedPaths.append(url.path)
                    lock.unlock()
                }
            }

            group.notify(queue: .main) {
                guard !droppedPaths.isEmpty else { return }

                if droppedPaths.count == 1, let first = droppedPaths.first, ArchiveFormat.detect(from: first) != nil {
                    self.manager.openArchive(at: first)
                } else {
                    if self.manager.isEditingUnlocked && self.manager.currentArchivePath != nil {
                        self.manager.addFilesToCurrentArchive(filePaths: droppedPaths, targetSubfolder: self.manager.currentFolderPath)
                    } else {
                        self.manager.pendingCompressPaths = droppedPaths
                        self.manager.showCompressSheet = true
                    }
                }
            }
            return true
        }
        .sheet(isPresented: $manager.showCompressSheet) {
            CompressSheetView()
        }
        .sheet(isPresented: $manager.showBenchmarkSheet) {
            WarpBenchmarkView()
        }
        .sheet(isPresented: $manager.showFolderWatcherSheet) {
            FolderWatcherView()
        }
        .sheet(isPresented: $manager.showRepairSheet) {
            RepairStationView()
        }
        .sheet(isPresented: $manager.showUpdateSheet) {
            UpdateModalView()
        }
        .sheet(isPresented: $manager.showSettingsSheet) {
            SettingsModalView()
        }
        .sheet(isPresented: $manager.showPasswordModal) {
            PasswordModalView()
        }
        .sheet(isPresented: $manager.showChecksumSheet) {
            ChecksumModalView()
        }
        .sheet(isPresented: $manager.showConverterSheet) {
            ConverterSheetView()
        }
        .sheet(isPresented: $manager.showOnboardingSheet) {
            OnboardingSheetView()
        }
        .sheet(isPresented: $manager.showDiffSheet) {
            ArchiveDiffModalView()
        }
        .tint(settings.resolvedAccentColor)
        .preferredColorScheme(settings.resolvedColorScheme)
        .alert(isPresented: Binding<Bool>(
            get: { manager.errorMessage != nil },
            set: { if !$0 { manager.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Pulsar Bildirimi"),
                message: Text(manager.errorMessage ?? "Bilinmeyen bir hata oluştu"),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
}

private struct StatusFooterBarView: View {
    @ObservedObject var manager = ArchiveManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                // Sol: Öğe Sayısı ve Seçim Bilgisi
                HStack(spacing: 6) {
                    Image(systemName: manager.isGridView ? "square.grid.2x2" : "list.bullet")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text("\(manager.currentFolderItems.count) öğe")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    if !manager.selectedItemIds.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("\(manager.selectedItemIds.count) seçildi (\(manager.selectedTotalSize))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }

                Spacer()

                // Orta: Canlı Görev İlerleme Çubuğu (Varsa)
                if let activeTask = manager.activeTasks.last {
                    HStack(spacing: 8) {
                        ProgressView(value: activeTask.percent, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(width: 110)

                        Text("\(activeTask.title): %\(Int(activeTask.percent * 100))")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.accentColor)
                            .lineLimit(1)

                        Button(action: {
                            manager.cancelTask(id: activeTask.id)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("İşlemi İptal Et")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(6)
                }

                Spacer()

                // Sağ: Disk Durumu
                if let freeSpace = manager.freeDiskSpaceText {
                    HStack(spacing: 4) {
                        Image(systemName: "internaldrive")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("Disk: \(freeSpace) boş")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.85))
        }
    }
}
