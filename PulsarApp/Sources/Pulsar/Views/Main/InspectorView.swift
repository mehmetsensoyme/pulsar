import SwiftUI
import QuickLook

public struct InspectorView: View {
    @ObservedObject var manager = ArchiveManager.shared

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
                            Image(systemName: item.iconName)
                                .font(.system(size: 48))
                                .foregroundColor(item.iconColor)
                                .shadow(color: item.iconColor.opacity(0.3), radius: 8, x: 0, y: 4)

                            Text(item.name)
                                .font(.system(size: 14, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)

                            if item.isEncrypted {
                                CosmicBadge(text: "ŞİFRELİ (AES)", color: .yellow, icon: "lock.fill")
                            }
                        }
                        .padding(.top, 16)

                        Divider()

                        // Hızlı Aksiyonlar
                        HStack(spacing: 12) {
                            Button(action: {
                                manager.openOrPreviewItem(item)
                            }) {
                                Label("Önizle", systemImage: "eye.fill")
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
