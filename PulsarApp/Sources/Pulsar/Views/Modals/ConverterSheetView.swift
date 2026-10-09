import SwiftUI

public final class ConverterViewModel: ObservableObject {
    @Published public var selectedTargetFormat: ArchiveFormat = .sevenZip
    @Published public var isConverting: Bool = false
    @Published public var isDone: Bool = false
    @Published public var progressText: String = "Hazırlanıyor..."

    public init() {}
}

public struct ConverterSheetView: View {
    @ObservedObject var manager = ArchiveManager.shared
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ConverterViewModel()

    public init() {}

    private var availableFormats: [ArchiveFormat] {
        return [.sevenZip, .zip, .tar, .zstd]
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Başlık
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Arşiv Format Dönüştürücü")
                        .font(.headline)
                    Text("Mevcut arşivi yeniden paketleyerek daha yüksek sıkıştırma veya evrensel uyumluluk elde edin.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Kapat") {
                    dismiss()
                }
                .disabled(vm.isConverting)
            }
            .padding(18)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            VStack(spacing: 20) {
                if let archive = manager.currentArchivePath {
                    // Mevcut Arşiv Bilgisi
                    HStack(spacing: 12) {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 3) {
                            Text((archive as NSString).lastPathComponent)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                            HStack {
                                Text("Format:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let format = manager.currentFormat {
                                    CosmicBadge(text: format.rawValue.uppercased(), color: format.badgeColor)
                                }
                                Text("• Toplam \(manager.allItems.count) dosya")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))

                    // Hedef Format Seçimi
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hedef Format Seçin:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)

                        Picker("", selection: $vm.selectedTargetFormat) {
                            ForEach(availableFormats) { format in
                                Text(format.rawValue.uppercased() + " — " + formatDescription(format))
                                    .tag(format)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        .disabled(vm.isConverting)
                    }

                    if vm.isConverting {
                        VStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.regular)
                            Text(vm.progressText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else if vm.isDone {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Dönüştürme başarıyla tamamlandı! Yeni arşiv yüklendi.")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        .padding(10)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(8)
                    }
                } else {
                    Text("Açık bir arşiv bulunamadı.")
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(20)

            Divider()

            // Butonlar
            HStack {
                Button("Vazgeç") {
                    dismiss()
                }
                .disabled(vm.isConverting)

                Spacer()

                Button(action: {
                    startConversion()
                }) {
                    HStack(spacing: 6) {
                        if vm.isConverting {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(vm.isDone ? "Kapat" : "Dönüştürmeyi Başlat")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isConverting || manager.currentArchivePath == nil)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 480, height: 380)
    }

    private func formatDescription(_ format: ArchiveFormat) -> String {
        switch format {
        case .sevenZip: return "Ultra yüksek sıkıştırma oranı (LZMA2)"
        case .zip: return "Tüm işletim sistemleriyle evrensel uyumluluk"
        case .tar: return "Standart Unix/Linux arşiv paketi"
        case .zstd: return "Yıldırım hızında Zstandard algoritması"
        default: return ""
        }
    }

    private func startConversion() {
        if vm.isDone {
            dismiss()
            return
        }

        vm.isConverting = true
        vm.progressText = "Arşiv açılıyor ve yeniden paketleniyor..."

        manager.convertCurrentArchive(to: vm.selectedTargetFormat) { success in
            vm.isConverting = false
            if success {
                vm.isDone = true
            }
        }
    }
}
