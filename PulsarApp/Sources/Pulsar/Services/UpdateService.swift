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

    public init(
        version: String,
        codeName: String,
        releaseDate: String,
        downloadUrl: String,
        releaseNotes: [String],
        isCritical: Bool = false
    ) {
        self.version = version
        self.codeName = codeName
        self.releaseDate = releaseDate
        self.downloadUrl = downloadUrl
        self.releaseNotes = releaseNotes
        self.isCritical = isCritical
    }
}

public final class UpdateService: ObservableObject {
    public static let shared = UpdateService()

    public let currentVersion = "1.2.0"
    public let currentCodeName = "Supernova"
    public let currentBuild = "2613"

    @Published public var isChecking: Bool = false
    @Published public var hasUpdateAvailable: Bool = false
    @Published public var latestRelease: PulsarReleaseInfo?
    @Published public var lastCheckDate: Date? = nil
    @Published public var checkStatusMessage: String = "Pulsar güncel (v1.2.0 Supernova)"

    private init() {
        latestRelease = PulsarReleaseInfo(
            version: "1.2.0",
            codeName: "Supernova",
            releaseDate: "Ekim 2026",
            downloadUrl: "https://github.com/mehmetsensoyme/pulsar/releases/latest",
            releaseNotes: [
                "Finder'a Doğrudan Sürükle-Bırak (.onDrag): Arşivdeki dosyaları masaüstüne sürükleyerek anında çıkarma",
                "Finder Tarzı Izgara / Galeri Görünümü (FileGridView): Büyük simgeler ve çift tıklama ile gezinme",
                "Pencere Altı Canlı Durum ve Görev Çubuğu: Öğe sayısı, seçili boyut, canlı görev ve boş disk alanı",
                "Kriptografik Sağlama Toplamı (Checksum) Doğrulayıcı: SHA-256, MD5 ve SHA-1 hesaplama ve pano eşleştirme",
                "Arşiv Format Dönüştürücü: .rar, .zip veya .tar dosyalarını tek tıkla .7z veya .zst formatına dönüştürme",
                "Akıllı Dosya Filtreleri: Görseller, Belgeler, Kod ve Medya kategorilerine göre anlık filtreleme",
                "macOS Klavye Kısayolları Paketi (⌘A Tümünü Seç, ⌘↑ Üst Klasör, ⌘↓ Aç, ⌘C Yolu Kopyala, ⌘⌫ Sil)"
            ],
            isCritical: false
        )
    }

    public func checkForUpdates() async {
        await MainActor.run {
            isChecking = true
            checkStatusMessage = "Güncellemeler denetleniyor..."
        }

        // GitHub Releases API sorgusu
        let apiUrl = URL(string: "https://api.github.com/repos/mehmetsensoyme/pulsar/releases/latest")!
        var request = URLRequest(url: apiUrl)
        request.timeoutInterval = 8
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    let remoteVersion = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
                    let releaseName = json["name"] as? String ?? "Pulsar \(tagName)"
                    let body = json["body"] as? String ?? ""
                    let htmlUrl = json["html_url"] as? String ?? "https://github.com/mehmetsensoyme/pulsar/releases/latest"

                    let notes = body.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty && ($0.hasPrefix("-") || $0.hasPrefix("•") || $0.hasPrefix("*")) }
                        .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "-•* ")) }

                    let isNewer = isVersion(remoteVersion, greaterThan: currentVersion)

                    await MainActor.run {
                        self.isChecking = false
                        self.lastCheckDate = Date()
                        self.hasUpdateAvailable = isNewer
                        if isNewer {
                            self.latestRelease = PulsarReleaseInfo(
                                version: remoteVersion,
                                codeName: releaseName,
                                releaseDate: "Yeni Sürüm",
                                downloadUrl: htmlUrl,
                                releaseNotes: notes.isEmpty ? ["Hata düzeltmeleri ve performans iyileştirmeleri."] : notes
                            )
                            self.checkStatusMessage = "Yeni bir sürüm mevcut: v\(remoteVersion)!"
                        } else {
                            self.checkStatusMessage = "Pulsar güncel (v\(self.currentVersion) \(self.currentCodeName))"
                        }
                    }
                    return
                }
            }
        } catch {
            // Ağ hatası durumunda yerel durum
        }

        await MainActor.run {
            self.isChecking = false
            self.lastCheckDate = Date()
            self.hasUpdateAvailable = false
            self.checkStatusMessage = "Pulsar güncel (v\(self.currentVersion) \(self.currentCodeName))"
        }
    }

    /// Basit SemVer karşılaştırması
    public func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(parts1.count, parts2.count)

        for i in 0..<maxCount {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 > p2 { return true }
            if p1 < p2 { return false }
        }
        return false
    }
}
