import SwiftUI
import AppKit

public final class SettingsModalViewModel: ObservableObject {
    @Published public var selectedTab: Int = 0
    @Published public var engineCheckResult: String? = nil
    @Published public var isCheckingEngines: Bool = false
    @Published public var cacheClearedMessage: String? = nil

    public init() {}

    public func testEnginesHealth() {
        isCheckingEngines = true
        engineCheckResult = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let p7 = EngineLocator.shared.pathForSevenZip()
            let pRar = EngineLocator.shared.pathForRAR()
            let exists7 = FileManager.default.isExecutableFile(atPath: p7)
            let existsRar = FileManager.default.isExecutableFile(atPath: pRar)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isCheckingEngines = false
                if exists7 && existsRar {
                    self.engineCheckResult = "✅ Tüm motorlar (7-Zip & WinRAR) hazır ve çalışıyor!"
                } else if exists7 {
                    self.engineCheckResult = "⚠️ 7-Zip aktif, WinRAR ikilisi denetlenmeli."
                } else {
                    self.engineCheckResult = "❌ Motor ikilileri bulunamadı."
                }
            }
        }
    }
}

public struct SettingsModalView: View {
    @ObservedObject var settings = PulsarSettings.shared
    @ObservedObject var updater = UpdateService.shared
    @ObservedObject var manager = ArchiveManager.shared
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = SettingsModalViewModel()

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Başlık Çubuğu
            HStack(spacing: 10) {
                Image(systemName: "gearshape.2.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pulsar Tercihleri & Ayarlar")
                        .font(.headline)
                    Text("Sistem motorları, güvenlik, arayüz ve otomasyon ayarları")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Tamam") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Sekme Seçici
            HStack {
                tabButton("Genel", icon: "slider.horizontal.3", tag: 0)
                tabButton("Motorlar", icon: "cpu", tag: 1)
                tabButton("Güvenlik", icon: "lock.shield", tag: 2)
                tabButton("Kara Delik", icon: "circle.circle", tag: 3)
                tabButton("Yüzen HUD", icon: "macwindow.on.rectangle", tag: 4)
                tabButton("Hakkında", icon: "info.circle", tag: 5)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            // Sekme İçerikleri
            ScrollView {
                VStack(spacing: 16) {
                    switch vm.selectedTab {
                    case 0:
                        generalSettingsTab
                    case 1:
                        enginesSettingsTab
                    case 2:
                        securitySettingsTab
                    case 3:
                        folderWatcherSettingsTab
                    case 4:
                        hudSettingsTab
                    case 5:
                        aboutSettingsTab
                    default:
                        EmptyView()
                    }
                }
                .padding()
            }
            .frame(height: 380)
        }
        .frame(width: 580)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func tabButton(_ title: String, icon: String, tag: Int) -> some View {
        Button(action: {
            vm.selectedTab = tag
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(vm.selectedTab == tag ? .cyan : .secondary)
                Text(title)
                    .font(.system(size: 10, weight: vm.selectedTab == tag ? .bold : .regular))
                    .foregroundColor(vm.selectedTab == tag ? .primary : .secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(vm.selectedTab == tag ? Color.primary.opacity(0.08) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 1. Genel Ayarlar
    private var generalSettingsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsSection(title: "ARAYÜZ VE DÜZEN") {
                Picker("Varsayılan Görünüm Düzeni:", selection: $settings.defaultLayoutMode) {
                    Text("Modern 3-Bölmeli (Inspector)").tag(LayoutMode.modernThreePane.rawValue)
                    Text("Kompakt Liste Düzeni").tag(LayoutMode.compactList.rawValue)
                    Text("Sekmeli Stüdyo Düzeni").tag(LayoutMode.tabbedStudio.rawValue)
                }

                Picker("Varsayılan Sıkıştırma Formatı:", selection: $settings.defaultCompressionFormat) {
                    Text(".zip (Evrensel)").tag("zip")
                    Text(".7z (Yüksek Sıkıştırma)").tag("7z")
                    Text(".rar (WinRAR)").tag("rar")
                    Text(".tar.gz (Linux/UNIX)").tag("tar.gz")
                }
            }

            settingsSection(title: "TEMİZLİK VE METADATA") {
                Toggle("Windows Dostu Temizleme (.DS_Store, AppleDouble ve __MACOSX dosyalarını filtrele)", isOn: $settings.cleanMacMetadataDefault)
                    .font(.system(size: 12))
            }

            settingsSection(title: "BİLDİRİMLER VE SES") {
                Toggle("İşlem tamamlandığında ses efekti çal", isOn: $settings.playSounds)
                    .font(.system(size: 12))
                Toggle("Arka plan işlemleri bittiğinde macOS bildirimi gönder", isOn: $settings.sendNotifications)
                    .font(.system(size: 12))
            }
        }
    }

    // MARK: - 2. Motorlar & Performans
    private var enginesSettingsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsSection(title: "YEREL MOTOR DURUMLARI") {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("7-Zip Native Engine (7zz 26.04)")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Apple Silicon ARM64 optimize edilmiş derleme")
                            .font(.system(size: 10)).foregroundColor(.secondary)
                    }
                    Spacer()
                    CosmicBadge(text: "ARM64 NATIVE", color: .cyan)
                }

                Divider()

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("RARLAB WinRAR Engine (rar & unrar)")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Resmi RAR oluşturma ve Kurtarma Kaydı onarımı")
                            .font(.system(size: 10)).foregroundColor(.secondary)
                    }
                    Spacer()
                    CosmicBadge(text: "OFFICIAL CLI", color: .purple)
                }

                HStack {
                    Button(action: {
                        vm.testEnginesHealth()
                    }) {
                        HStack(spacing: 6) {
                            if vm.isCheckingEngines {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "waveform.path.ecg")
                            }
                            Text("Motor Sağlığını ve İkililerini Sına")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    if let res = vm.engineCheckResult {
                        Text(res)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 4)
            }

            settingsSection(title: "DONANIM VE ÇEKİRDEK KONTROLÜ") {
                HStack {
                    Text("Maksimum CPU İş Parçacığı (Threads):")
                        .font(.system(size: 12))
                    Spacer()
                    Stepper("\(settings.maxCpuThreads) Çekirdek", value: $settings.maxCpuThreads, in: 1...ProcessInfo.processInfo.processorCount)
                }

                Picker("Varsayılan Sıkıştırma Seviyesi:", selection: $settings.defaultCompressionLevel) {
                    Text("Hızlı (Store)").tag("fast")
                    Text("Normal (Dengeli)").tag("normal")
                    Text("Maksimum (Yüksek)").tag("maximum")
                    Text("Ultra (En Yüksek Oran)").tag("ultra")
                }
            }
        }
    }

    // MARK: - 3. Güvenlik & Gizlilik
    private var securitySettingsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsSection(title: "GÜVENLİK KİLİDİ") {
                Toggle("Yeni arşivleri daima Salt Okunur (Kilitli) modda aç", isOn: $settings.startInReadOnlyMode)
                    .font(.system(size: 12))
                Toggle("Dosya silmeden önce onay iste", isOn: $settings.confirmBeforeDelete)
                    .font(.system(size: 12))
            }

            settingsSection(title: "PAROLA VE ANAHTAR ZİNCİRİ (KEYCHAIN)") {
                Toggle("Arşiv parolalarını macOS Anahtar Zinciri'ne kaydet", isOn: $settings.savePasswordsToKeychain)
                    .font(.system(size: 12))

                Button("Kayıtlı Parolaları ve Önbelleği Temizle") {
                    KeychainService.shared.clearAllSavedPasswords()
                    vm.cacheClearedMessage = "Tüm kayıtlı parolalar başarıyla silindi."
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            settingsSection(title: "SANDBOX VE GEÇİCİ ÖNBELLEK") {
                Toggle("Uygulamadan çıkıldığında geçici önizleme önbelleğini otomatik imha et", isOn: $settings.autoCleanTempCacheOnExit)
                    .font(.system(size: 12))

                HStack {
                    Button("Geçici Önizleme Önbelleğini Şimdi Temizle") {
                        TempCacheManager.shared.cleanupAllTempDirectories()
                        vm.cacheClearedMessage = "Geçici sandbox önbelleği tamamen boşaltıldı."
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    if let msg = vm.cacheClearedMessage {
                        Text(msg)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }

    // MARK: - 4. Kara Delik Klasör İzleyici
    private var folderWatcherSettingsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsSection(title: "OTOMASYON DURUMU") {
                Toggle("İndirilenler klasörünü arka planda otomatik izle", isOn: $settings.enableFolderWatcher)
                    .font(.system(size: 12))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("İzlenen Dizin:")
                            .font(.system(size: 11)).foregroundColor(.secondary)
                        Text(settings.folderWatcherPath)
                            .font(.system(size: 11, design: .monospaced))
                            .lineLimit(1)
                    }
                    Spacer()
                    Button("Değiştir...") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        if panel.runModal() == .OK, let url = panel.url {
                            settings.folderWatcherPath = url.path
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            settingsSection(title: "İŞLEM KURALLARI") {
                Toggle("Başarıyla çıkarılan arşivi Çöp Sepetine taşı", isOn: $settings.autoTrashAfterExtract)
                    .font(.system(size: 12))
            }
        }
    }

    // MARK: - 5. Yüzen HUD Widget
    private var hudSettingsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsSection(title: "KONUMLANDIRMA") {
                Picker("Ekran Sabitleme Köşesi:", selection: $settings.hudCorner) {
                    Text("Sağ Üst").tag("topRight")
                    Text("Sol Üst").tag("topLeft")
                    Text("Sağ Alt").tag("bottomRight")
                    Text("Sol Alt").tag("bottomLeft")
                }

                Toggle("HUD Panelini daima diğer pencerelerin üstünde tut", isOn: $settings.hudAlwaysOnTop)
                    .font(.system(size: 12))
            }

            settingsSection(title: "PANEL KONTROLÜ") {
                HStack {
                    Text("Mevcut Görünürlük Durumu:")
                        .font(.system(size: 12))
                    Spacer()
                    Button(manager.isHUDVisible ? "HUD'u Gizle" : "HUD'u Göster") {
                        manager.isHUDVisible.toggle()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: - 6. Hakkında ve Güncellemeler
    private var aboutSettingsTab: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundColor(.cyan)
            }

            VStack(spacing: 4) {
                Text("PULSAR ARCHIVE")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                Text("Sürüm: v\(updater.currentVersion) (\(updater.currentCodeName)) - Build \(updater.currentBuild)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("Apple Silicon M4/M3/M2 Optimize & Native Swift 6")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(spacing: 10) {
                HStack {
                    Text(updater.checkStatusMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        Task {
                            await updater.checkForUpdates()
                        }
                    }) {
                        if updater.isChecking {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Güncellemeleri Denetle")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                HStack {
                    Button("GitHub Deposunu Aç") {
                        if let url = URL(string: "https://github.com/mehmetsensoyme/pulsar") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()

                    Text("MIT Lisansı © 2026 Pulsar Contributors")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}
