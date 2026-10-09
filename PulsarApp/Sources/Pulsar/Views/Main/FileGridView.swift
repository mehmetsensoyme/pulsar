import SwiftUI
import AppKit

public struct FileGridView: View {
    @ObservedObject var manager = ArchiveManager.shared

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 130), spacing: 14)
    ]

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
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text(manager.searchQuery.isEmpty ? "Bu klasörde görüntülenecek öğe yok" : "Arama ile eşleşen dosya bulunamadı")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(manager.currentFolderItems) { item in
                            let isSelected = manager.selectedItemIds.contains(item.id)

                            VStack(spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    FileIconView(item: item, size: 48)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                                        .padding(8)

                                    if item.isEncrypted {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.yellow)
                                            .padding(4)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                }

                                Text(item.name)
                                    .font(.system(size: 11, weight: item.isDirectory ? .semibold : .regular))
                                    .foregroundColor(isSelected ? .accentColor : .primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(height: 28, alignment: .top)

                                Text(item.isDirectory ? "Klasör" : item.formattedSize)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor).opacity(0.4))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.06), lineWidth: isSelected ? 1.5 : 1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                manager.selectedItemIds = [item.id]
                            }
                            .onTapGesture(count: 2) {
                                handleItemAction(item)
                            }
                            .onDrag {
                                itemProvider(for: item)
                            }
                            .contextMenu {
                                Button("Önizle (QuickLook)") {
                                    manager.openOrPreviewItem(item)
                                }

                                if !item.isDirectory {
                                    Menu("Şununla Aç...") {
                                        Button("Metin Düzenleyici (TextEdit)") {
                                            manager.openWithApp(item: item, appBundleId: "com.apple.TextEdit")
                                        }
                                        Button("Önizleme (Preview)") {
                                            manager.openWithApp(item: item, appBundleId: "com.apple.Preview")
                                        }
                                        Divider()
                                        Button("Diğer Uygulama Seç...") {
                                            manager.openWithCustomApp(item: item)
                                        }
                                    }

                                    Button("Sağlama Toplamı (Checksum)...") {
                                        manager.openChecksumModal(for: item)
                                    }
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

                                if manager.isEditingUnlocked {
                                    Divider()
                                    Button("Arşivden Sil", role: .destructive) {
                                        manager.deleteSelectedItems()
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}
