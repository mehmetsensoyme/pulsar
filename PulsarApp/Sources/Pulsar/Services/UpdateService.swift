import Foundation
import Combine

public struct PulsarReleaseInfo: Codable, Identifiable {
    public var id: String { version }
    public let version: String
    public let codeName: String
    public let releaseDate: String
    public let downloadUrl: String
    public let releaseNotes: [String]
    public let isCritical: Bool
}

public final class UpdateService: ObservableObject {
    public static let shared = UpdateService()

    public let currentVersion = "1.0.0"
    public let currentCodeName = "Event Horizon"
    public let currentBuild = "2604"

    @Published public var isChecking: Bool = false
    @Published public var hasUpdateAvailable: Bool = false
    @Published public var latestRelease: PulsarReleaseInfo?
    @Published public var lastCheckDate: Date? = nil

    private init() {
        // Varsayılan sürüm bilgisi
        latestRelease = PulsarReleaseInfo(
            version: "1.0.0",
            codeName: "Event Horizon",
            releaseDate: "Ekim 2026",
            downloadUrl: "https://github.com/mehmetsensoyme/pulsar/releases/latest",
            releaseNotes: [
                "Apple Silicon M4/M3/M2 yerel 7-Zip (7zz 26.04) ve WinRAR motor entegrasyonu",
                "3 Değiştirilebilir Görünüm: Modern 3-Bölmeli, Kompakt Liste, Sekmeli Stüdyo",
                "Yüzen Yarı Saydam Mini Panel (Floating HUD / Widget) desteği",
                "Pulsar Warp Core Donanım Hız Testi (Benchmark)",
                "Kara Delik Otomatik Klasör İzleyici (Downloads auto-unpack)",
                "Arşiv Kurtarma İstasyonu (RAR Recovery Record onarımı)",
                "Windows Dostu .DS_Store ve AppleDouble temizleme filtresi"
            ],
            isCritical: false
        )
    }

    public func checkForUpdates() async {
        await MainActor.run {
            isChecking = true
        }

        // Simüle edilmiş / GitHub Releases API kontrolü
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await MainActor.run {
            self.isChecking = false
            self.lastCheckDate = Date()
            // Eğer daha yüksek versiyon varsa hasUpdateAvailable = true
            self.hasUpdateAvailable = false
        }
    }
}
