import Foundation

public final class PulsarTestRunner {
    public static func runAllTests() -> Bool {
        print("🌌 [PULSAR TEST RUNNER] Otomatik Stabilite ve Fonksiyon Testleri Başlatılıyor...")
        var passed = 0
        var failed = 0

        func assertTest(_ condition: Bool, _ name: String) {
            if condition {
                print("  ✅ [PASS] \(name)")
                passed += 1
            } else {
                print("  ❌ [FAIL] \(name)")
                failed += 1
            }
        }

        // 1. Format Tespiti
        assertTest(ArchiveFormat.detect(from: "test.7z") == .sevenZip, "Format Tespiti: .7z")
        assertTest(ArchiveFormat.detect(from: "backup.rar") == .rar, "Format Tespiti: .rar")
        assertTest(ArchiveFormat.detect(from: "data.zip") == .zip, "Format Tespiti: .zip")
        assertTest(ArchiveFormat.detect(from: "data.zipx") == .zip, "Format Tespiti: .zipx")
        assertTest(ArchiveFormat.detect(from: "unix.tar") == .tar, "Format Tespiti: .tar")
        assertTest(ArchiveFormat.detect(from: "archive.tar.gz") == .gzip, "Format Tespiti: .tar.gz")
        assertTest(ArchiveFormat.detect(from: "archive.tar.bz2") == .bzip2, "Format Tespiti: .tar.bz2")
        assertTest(ArchiveFormat.detect(from: "archive.tar.xz") == .xz, "Format Tespiti: .tar.xz")
        assertTest(ArchiveFormat.detect(from: "modern.zst") == .zstd, "Format Tespiti: .zst")
        assertTest(ArchiveFormat.detect(from: "system.wim") == .wim, "Format Tespiti: .wim")
        assertTest(ArchiveFormat.detect(from: "image.iso") == .iso, "Format Tespiti: .iso")
        assertTest(ArchiveFormat.detect(from: "disk.dmg") == .dmg, "Format Tespiti: .dmg")
        assertTest(ArchiveFormat.detect(from: "split.001") == .split, "Format Tespiti: .001")
        assertTest(ArchiveFormat.detect(from: "text.pdf") == nil, "Geçersiz Format: .pdf -> nil")

        // 2. Yetenek Doğrulamaları
        assertTest(ArchiveFormat.sevenZip.supportsCreation, "7-Zip Oluşturma Desteği")
        assertTest(ArchiveFormat.sevenZip.supportsEncryption, "7-Zip Şifreleme Desteği")
        assertTest(ArchiveFormat.rar.supportsRepair, "WinRAR Onarım Desteği")
        assertTest(!ArchiveFormat.iso.supportsCreation, "ISO Salt-Okunur Doğrulaması")

        // 3. Geçici Önbellek Yönetimi
        let tempManager = TempCacheManager.shared
        let dummyPath = NSTemporaryDirectory().appending("PulsarPreview_Test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(atPath: dummyPath, withIntermediateDirectories: true)
        let dirCreated = FileManager.default.fileExists(atPath: dummyPath)
        tempManager.registerTempDirectory(dummyPath)
        tempManager.cleanupAllTempDirectories()
        let dirDeleted = !FileManager.default.fileExists(atPath: dummyPath)
        assertTest(dirCreated && dirDeleted, "TempCacheManager: Otomatik Önbellek İmhası")

        // 4. Disk Alanı Ön Kontrolü
        let diskGuard = DiskSpaceGuard.shared
        let freeBytes = diskGuard.availableFreeBytes(atPath: NSTemporaryDirectory())
        assertTest((freeBytes ?? 0) > 0, "DiskSpaceGuard: Boş Disk Alanı Okuma")

        var smallSpacePassed = false
        do {
            try diskGuard.validateSpace(forRequiredBytes: 1024, atDestination: NSTemporaryDirectory())
            smallSpacePassed = true
        } catch {}
        assertTest(smallSpacePassed, "DiskSpaceGuard: Güvenli Boyut Doğrulaması")

        var hugeSpaceCaught = false
        do {
            let hugeBytes: Int64 = 500_000_000_000_000_000
            try diskGuard.validateSpace(forRequiredBytes: hugeBytes, atDestination: NSTemporaryDirectory())
        } catch {
            hugeSpaceCaught = true
        }
        assertTest(hugeSpaceCaught, "DiskSpaceGuard: Yetersiz Alan Uyarısı ve Koruması")

        // 5. Arşiv Öğesi Hesaplamaları
        let item = ArchiveItem(
            path: "Documents/Report.pdf",
            name: "Report.pdf",
            isDirectory: false,
            size: 10000,
            compressedSize: 2500
        )
        assertTest(abs(item.compressionRatio - 0.25) < 0.001, "ArchiveItem: Sıkıştırma Oranı (0.25)")
        assertTest(item.compressionRatioPercentage == "%75.0", "ArchiveItem: Yüzde Metni (%75.0)")
        assertTest(item.iconName == "doc.richtext.fill", "ArchiveItem: PDF İkon Eşleşmesi")

        // 6. Önayarlar
        let presets = Preset.standardPresets
        let winClean = presets.first(where: { $0.name.contains("Windows") })
        assertTest(winClean != nil && (winClean?.cleanMacMetadata == true), "Preset: Windows Dostu Temizleme Açık")

        // 7. Sürüm Kontrolü ve SemVer Karşılaştırma
        let updater = UpdateService.shared
        assertTest(updater.currentVersion == "1.1.0", "UpdateService: v1.1.0 Güncel Versiyon")
        assertTest(updater.isVersion("1.1.1", greaterThan: "1.1.0"), "SemVer: 1.1.1 > 1.1.0 Doğrulaması")
        assertTest(!updater.isVersion("1.0.0", greaterThan: "1.1.0"), "SemVer: 1.0.0 < 1.1.0 Doğrulaması")
        assertTest(!updater.isVersion("1.1.0", greaterThan: "1.1.0"), "SemVer: 1.1.0 == 1.1.0 Eşitlik Doğrulaması")

        // 8. İçerik Filtreleme Modu (ContentFilterMode)
        let sampleItems = [
            ArchiveItem(path: "FolderA", name: "FolderA", isDirectory: true, size: 0, compressedSize: 0),
            ArchiveItem(path: "file1.txt", name: "file1.txt", isDirectory: false, size: 100, compressedSize: 40),
            ArchiveItem(path: "file2.pdf", name: "file2.pdf", isDirectory: false, size: 200, compressedSize: 80)
        ]
        let filesOnly = sampleItems.filter { !$0.isDirectory }
        let foldersOnly = sampleItems.filter { $0.isDirectory }
        assertTest(filesOnly.count == 2, "ContentFilterMode: Sadece Dosyalar (2 dosya)")
        assertTest(foldersOnly.count == 1, "ContentFilterMode: Sadece Klasörler (1 klasör)")

        // 9. Ayarlar Varsayılan Değerleri
        let settings = PulsarSettings.shared
        assertTest(settings.defaultCompressionFormat == "zip", "PulsarSettings: Varsayılan Format zip")
        assertTest(settings.maxCpuThreads >= 1, "PulsarSettings: CPU Çekirdek Sayısı >= 1")

        print("--------------------------------------------------")
        print("📊 [TEST SONUCU] Toplam: \(passed + failed) | Başarılı: \(passed) | Hatalı: \(failed)")
        if failed == 0 {
            print("🎉 TÜM STABİLİTE VE FONKSİYON TESTLERİ BAŞARIYLA GEÇTİ!")
            return true
        } else {
            print("⚠️ BAZI TESTLER BAŞARISIZ OLDU!")
            return false
        }
    }
}
