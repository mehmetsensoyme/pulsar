import SwiftUI
import UniformTypeIdentifiers

public final class MainWindowViewModel: ObservableObject {
    @Published public var isWindowDropTargeted: Bool = false
    public init() {}
}

public struct MainWindowView: View {
    @ObservedObject var manager = ArchiveManager.shared
    @StateObject private var vm = MainWindowViewModel()

    public var body: some View {
        ZStack(alignment: .topTrailing) {
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
            .frame(minWidth: 800, minHeight: 520)

            // Yüzen HUD Widget (Sağ üst köşe)
            if manager.isHUDVisible {
                FloatingHUDView()
                    .padding(16)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
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
        .toolbar {
            PulsarToolbarContent()
        }
        .searchable(text: $manager.searchQuery, prompt: "Arşiv içinde ara...")
        .onDrop(of: [.fileURL], isTargeted: $vm.isWindowDropTargeted) { providers in
            for provider in providers {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                    DispatchQueue.main.async {
                        let path = url.path
                        if ArchiveFormat.detect(from: path) != nil {
                            self.manager.openArchive(at: path)
                        } else {
                            // Arşiv dışı bir dosya bırakıldı ve düzenleme açıksa ekle
                            if self.manager.isEditingUnlocked && self.manager.currentArchivePath != nil {
                                self.manager.addFilesToCurrentArchive(filePaths: [path])
                            } else {
                                self.manager.showCompressSheet = true
                            }
                        }
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
        .sheet(isPresented: $manager.showPasswordModal) {
            PasswordModalView()
        }
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
