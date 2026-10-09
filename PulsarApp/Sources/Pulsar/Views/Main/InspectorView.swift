import SwiftUI
import AppKit
import QuickLook

public final class InspectorPreviewViewModel: ObservableObject {
    @Published public var previewImage: NSImage? = nil
    @Published public var previewText: String? = nil
    @Published public var isLoading: Bool = false
    private var currentPath: String = ""

    public init() {}

    public func loadPreview(for item: ArchiveItem?, archivePath: String?) {
        guard let item = item, !item.isDirectory, let archive = archivePath else {
            previewImage = nil
            previewText = nil
            currentPath = ""
            return
        }
        if currentPath == item.path { return }
        currentPath = item.path

        let ext = item.fileExtension
        let isImage = ["png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "ico"].contains(ext)
        let isText = ["txt", "md", "json", "swift", "py", "c", "cpp", "h", "xml", "html", "css", "log", "yaml", "yml", "sh", "zsh"].contains(ext)

        guard isImage || isText else {
            previewImage = nil
            previewText = nil
            return
        }

        isLoading = true
        let tempDir = NSTemporaryDirectory().appending("PulsarThumb_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        TempCacheManager.shared.registerTempDirectory(tempDir)

        Task {
            do {
                try await SevenZipEngine.shared.extract(archiveAt: archive, to: tempDir, selectedFiles: [item.path])
                let filePath = (tempDir as NSString).appendingPathComponent(item.path)
                if isImage, let img = NSImage(contentsOfFile: filePath) {
                    await MainActor.run {
                        self.previewImage = img
                        self.previewText = nil
                        self.isLoading = false
                    }
                } else if isText, let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                    let lines = content.components(separatedBy: .newlines).prefix(14).joined(separator: "\n")
                    await MainActor.run {
                        self.previewText = lines
                        self.previewImage = nil
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

public struct InspectorView: View {
    @ObservedObject var manager = ArchiveManager.shared
    @StateObject private var previewVM = InspectorPreviewViewModel()

    private var selectedItem: ArchiveItem? {
        guard let firstId = manager.selectedItemIds.first else { return nil }
        return manager.allItems.first(where: { $0.id == firstId })
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let item = selectedItem {
                ScrollView {
                    VStack(spacing: 16) {
                        // Dosya İkonu ve Adı
                        VStack(spacing: 8) {
                            if let img = previewVM.previewImage {
                                Image(nsImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 120)
                                    .cornerRadius(6)
                                    .shadow(color: Color.black.opacity(0.15), radius: 4, y: 2)
                                    .padding(.top, 8)
                            } else {
                                FileIconView(item: item, size: 56)
                                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                            }

                            Text(item.name)
                                .font(.system(size: 13, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)

                            if item.isEncrypted {
                                CosmicBadge(text: "ŞİFRELİ (AES)", color: .yellow, icon: "lock.fill")
                            }
                        }
                        .padding(.top, 16)

                        if let txt = previewVM.previewText {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("İÇERİK ÖNİZLEMESİ")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if previewVM.isLoading {
                                        ProgressView().controlSize(.mini)
                                    }
                                }
                                Text(txt)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.primary.opacity(0.9))
                                    .lineLimit(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(Color(NSColor.textBackgroundColor).opacity(0.6))
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                            }
                            .padding(.horizontal, 14)
                        }

                        Divider()

                        // Hızlı Aksiyonlar
                        HStack(spacing: 12) {
                            Button(action: {
                                if item.isDirectory {
                                    manager.openFolder(item: item)
                                } else {
                                    manager.quickLookItem(item)
                                }
                            }) {
                                Label(item.isDirectory ? "Klasörü Aç" : "Hızlı Bakış (⎵)", systemImage: item.isDirectory ? "folder.fill" : "eye.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)

                            Button(action: {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = false
                                panel.canChooseDirectories = true
                                panel.canCreateDirectories = true
                                panel.prompt = "Buraya Çıkar"
                                if panel.runModal() == .OK, let url = panel.url {
                                    manager.extractSelected(to: url.path)
                                }
                            }) {
                                Label("Çıkar", systemImage: "arrow.up.bin")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                        }
                        .padding(.horizontal, 16)

                        Divider()

                        // Detaylı Meta Veriler
                        VStack(alignment: .leading, spacing: 10) {
                            Text("BİLGİLER")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)

                            InfoRow(label: "Orijinal Boyut", value: item.formattedSize)
                            InfoRow(label: "Sıkıştırılmış", value: item.formattedCompressedSize)
                            InfoRow(label: "Sıkıştırma Oranı", value: item.compressionRatioPercentage)
                            InfoRow(label: "Değiştirilme", value: item.formattedDate)

                            if !item.crc.isEmpty {
                                InfoRow(label: "CRC32", value: item.crc)
                            }

                            if !item.attributes.isEmpty {
                                InfoRow(label: "Öznitelikler", value: item.attributes)
                            }

                            InfoRow(label: "Yol", value: item.path)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 20)
                }
            } else {
                // Seçim Yoksa Arşiv Genel Özeti
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "sidebar.right")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Detayları ve önizlemeyi görmek için bir dosya seçin")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()

                    if let format = manager.currentFormat {
                        VStack(spacing: 6) {
                            Divider()
                            HStack {
                                Text("Toplam Dosya:")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(manager.allItems.count)")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            HStack {
                                Text("Format:")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Spacer()
                                CosmicBadge(text: format.rawValue, color: format.badgeColor)
                            }
                        }
                        .padding(12)
                    }
                }
            }
        }
        .frame(minWidth: 230, idealWidth: 260)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .onAppear {
            previewVM.loadPreview(for: selectedItem, archivePath: manager.currentArchivePath)
        }
        .onChange(of: manager.selectedItemIds) {
            previewVM.loadPreview(for: selectedItem, archivePath: manager.currentArchivePath)
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}
