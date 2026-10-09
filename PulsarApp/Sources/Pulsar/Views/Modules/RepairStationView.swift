import SwiftUI

public final class RepairStationViewModel: ObservableObject {
    @Published public var targetArchive: String = ""
    @Published public var isRepairing: Bool = false
    @Published public var repairLog: String = ""
    @Published public var repairSuccess: Bool? = nil
    public init() {}
}

public struct RepairStationView: View {
    @ObservedObject var manager = ArchiveManager.shared
    @StateObject private var vm = RepairStationViewModel()
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 0) {
            // Başlık
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text("ARŞİV KURTARMA İSTASYONU")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                    Text("Bozuk, CRC hatalı ve hasarlı RAR arşivlerini kurtarma kaydıyla onarır")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            VStack(spacing: 16) {
                // Hedef Dosya Seçimi
                HStack {
                    TextField("Bozuk veya Hasarlı Arşiv Yolu (.rar)", text: $vm.targetArchive)
                        .textFieldStyle(.roundedBorder)

                    Button("Göz At...") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.allowedContentTypes = []
                        if panel.runModal() == .OK, let url = panel.url {
                            vm.targetArchive = url.path
                        }
                    }
                    .buttonStyle(.bordered)
                }

                // Bilgilendirme Kartı
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.cyan)
                    Text("Pulsar, WinRAR motorunun dahili Kurtarma Kaydı (Recovery Record) algoritmasını çalıştırarak hasarlı sektörleri yeniden inşa eder. Onarılan dosya 'rebuilt.arşiv_adı.rar' olarak kaydedilir.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(Color.cyan.opacity(0.08))
                .cornerRadius(8)

                // Kurtarma Çıktı / Log Alanı
                VStack(alignment: .leading, spacing: 6) {
                    Text("ONARIM GÜNLÜĞÜ")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)

                    ScrollView {
                        Text(vm.repairLog.isEmpty ? "Onarım bekleniyor..." : vm.repairLog)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(vm.repairLog.isEmpty ? .secondary : .primary)
                    }
                    .padding(8)
                    .frame(height: 140)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                }

                if let success = vm.repairSuccess {
                    HStack {
                        Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(success ? .green : .red)
                        Text(success ? "Arşiv başarıyla onarıldı ve kurtarıldı!" : "Kurtarma kaydı bulunamadı veya hasar çok büyük.")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }

                Spacer()

                HStack {
                    Spacer()
                    Button(action: {
                        startRepair()
                    }) {
                        if vm.isRepairing {
                            ProgressView().controlSize(.small)
                        } else {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver")
                                Text("Onarımı Başlat")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.targetArchive.isEmpty || vm.isRepairing)
                }
            }
            .padding()
        }
        .frame(width: 500, height: 460)
        .onAppear {
            if let current = manager.currentArchivePath, current.hasSuffix(".rar") {
                vm.targetArchive = current
            }
        }
    }

    private func startRepair() {
        guard !vm.targetArchive.isEmpty else { return }
        vm.isRepairing = true
        vm.repairLog = "Kurtarma analizi başlatıldı...\n"

        Task {
            do {
                let result = try await RAREngine.shared.repairArchive(at: vm.targetArchive)
                await MainActor.run {
                    self.vm.isRepairing = false
                    self.vm.repairSuccess = result.success
                    self.vm.repairLog = result.log
                }
            } catch {
                await MainActor.run {
                    self.vm.isRepairing = false
                    self.vm.repairSuccess = false
                    self.vm.repairLog = "Hata: \(error.localizedDescription)"
                }
            }
        }
    }
}
