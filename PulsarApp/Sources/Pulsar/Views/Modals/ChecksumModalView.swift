import SwiftUI
import AppKit

public final class ChecksumViewModel: ObservableObject {
    @Published public var result: ChecksumResult? = nil
    @Published public var isLoading: Bool = true
    @Published public var errorMessage: String? = nil
    @Published public var inputHash: String = ""
    @Published public var copiedAlgorithm: String? = nil

    public init() {}

    public func compute(for targetItem: ArchiveItem?, archivePath: String?) {
        Task {
            do {
                let filePath: String
                if let item = targetItem, let archive = archivePath {
                    let tempDir = NSTemporaryDirectory().appending("PulsarChecksum_\(UUID().uuidString)")
                    try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
                    TempCacheManager.shared.registerTempDirectory(tempDir)
                    try await SevenZipEngine.shared.extract(archiveAt: archive, to: tempDir, selectedFiles: [item.path])
                    filePath = (tempDir as NSString).appendingPathComponent(item.path)
                } else if let archive = archivePath {
                    filePath = archive
                } else {
                    await MainActor.run {
                        self.errorMessage = "Hesaplanacak dosya bulunamadı."
                        self.isLoading = false
                    }
                    return
                }

                let checksums = try await ChecksumService.shared.computeChecksums(forFileAt: filePath)
                await MainActor.run {
                    self.result = checksums
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

public struct ChecksumModalView: View {
    @ObservedObject var manager = ArchiveManager.shared
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ChecksumViewModel()

    private var targetTitle: String {
        if let item = manager.checksumTargetItem {
            return item.name
        } else if let archive = manager.currentArchivePath {
            return (archive as NSString).lastPathComponent
        }
        return "Bilinmeyen Dosya"
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Modal Başlığı
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sağlama Toplamı (Checksum) Doğrulayıcı")
                        .font(.headline)
                    Text(targetTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button("Kapat") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(18)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: 18) {
                    if vm.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.large)
                            Text("Kriptografik özet değerleri hesaplanıyor...")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = vm.errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.red)
                            Text("Hesaplama Hatası")
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let r = vm.result {
                        // Özet Kartları
                        VStack(spacing: 12) {
                            hashCard(title: "SHA-256 (Önerilen)", hash: r.sha256, algorithm: "SHA-256")
                            hashCard(title: "MD5", hash: r.md5, algorithm: "MD5")
                            hashCard(title: "SHA-1", hash: r.sha1, algorithm: "SHA-1")
                        }

                        Divider()
                            .padding(.vertical, 4)

                        // Otomatik Eşleştirme & Doğrulama Paneli
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hızlı Doğrulama & Eşleştirme")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)

                            HStack {
                                TextField("Karşılaştırılacak hash değerini buraya yapıştırın...", text: $vm.inputHash)
                                    .textFieldStyle(.roundedBorder)

                                if !vm.inputHash.isEmpty {
                                    Button(action: {
                                        vm.inputHash = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if !vm.inputHash.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                let match = r.matches(hash: vm.inputHash)
                                HStack(spacing: 8) {
                                    Image(systemName: match.matched ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(match.matched ? .green : .red)

                                    Text(match.matched ? "EŞLEŞTİ! Değer \(match.algorithm ?? "") ile birebir uyuşuyor." : "EŞLEŞMEDİ: Girilen hash bu dosyanın özetleriyle uyuşmuyor.")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(match.matched ? .green : .red)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background((match.matched ? Color.green : Color.red).opacity(0.12))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            // Alt Butonlar
            HStack {
                if let r = vm.result {
                    Text("Dosya Boyutu: \(ByteCountFormatter.string(fromByteCount: r.fileSize, countStyle: .file))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Tamam") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 540, height: 460)
        .onAppear {
            vm.compute(for: manager.checksumTargetItem, archivePath: manager.currentArchivePath)
        }
    }

    private func hashCard(title: String, hash: String, algorithm: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(hash, forType: .string)
                    vm.copiedAlgorithm = algorithm
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if self.vm.copiedAlgorithm == algorithm { self.vm.copiedAlgorithm = nil }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: vm.copiedAlgorithm == algorithm ? "checkmark" : "doc.on.doc")
                        Text(vm.copiedAlgorithm == algorithm ? "Kopyalandı" : "Kopyala")
                    }
                    .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
            }

            Text(hash)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.textBackgroundColor).opacity(0.6))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
    }
}
