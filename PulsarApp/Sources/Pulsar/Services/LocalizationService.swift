import Foundation
import SwiftUI
import Combine

public struct LanguageInfo: Identifiable, Hashable {
    public var id: String { code }
    public let code: String
    public let name: String
    public let isCustom: Bool
    public let filePath: String?

    public init(code: String, name: String, isCustom: Bool = false, filePath: String? = nil) {
        self.code = code
        self.name = name
        self.isCustom = isCustom
        self.filePath = filePath
    }
}

public final class LocalizationService: ObservableObject {
    public static let shared = LocalizationService()

    @Published public var currentLanguage: String = "en"
    @Published public var availableLanguages: [LanguageInfo] = []

    private var dictionaries: [String: [String: String]] = [:]
    private let customLanguagesDir: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.customLanguagesDir = appSupport.appendingPathComponent("Pulsar/Languages")

        loadBuiltinDefaults()
        reloadAvailableLanguages()

        // Belirlenen dili ayarla
        let saved = PulsarSettings.shared.selectedLanguage
        if saved == "auto" {
            let preferred = Locale.current.language.languageCode?.identifier ?? "en"
            self.currentLanguage = dictionaries.keys.contains(preferred) ? preferred : "en"
        } else if dictionaries.keys.contains(saved) {
            self.currentLanguage = saved
        } else {
            self.currentLanguage = "en"
        }
    }

    // MARK: - Çeviri Alma (Translate)
    public func t(_ key: String, fallback: String? = nil) -> String {
        if let currentDict = dictionaries[currentLanguage], let val = currentDict[key] {
            return val
        }
        if let enDict = dictionaries["en"], let val = enDict[key] {
            return val
        }
        return fallback ?? key
    }

    public func setLanguage(_ code: String) {
        if code == "auto" {
            PulsarSettings.shared.selectedLanguage = "auto"
            let preferred = Locale.current.language.languageCode?.identifier ?? "en"
            self.currentLanguage = dictionaries.keys.contains(preferred) ? preferred : "en"
        } else {
            PulsarSettings.shared.selectedLanguage = code
            self.currentLanguage = code
        }
    }

    public func openCustomLanguagesFolder() {
        try? FileManager.default.createDirectory(at: customLanguagesDir, withIntermediateDirectories: true)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: customLanguagesDir.path)
    }

    // MARK: - Dil Dosyalarını Tara ve Yükle
    public func reloadAvailableLanguages() {
        var langs: [LanguageInfo] = [
            LanguageInfo(code: "en", name: "English", isCustom: false),
            LanguageInfo(code: "tr", name: "Türkçe", isCustom: false)
        ]

        var searchDirs: [URL] = []

        // 1. Bundle Resources
        if let resURL = Bundle.main.resourceURL?.appendingPathComponent("Languages") {
            searchDirs.append(resURL)
        }
        let fallbackAppBundle = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Languages")
        searchDirs.append(fallbackAppBundle)

        // 2. Geliştirme Yolu (Sources)
        let cwdLangs = URL(fileURLWithPath: "PulsarApp/Sources/Pulsar/Resources/Languages")
        searchDirs.append(cwdLangs)

        // 3. Kullanıcı Harici Dizini (~/Library/Application Support/Pulsar/Languages)
        searchDirs.append(customLanguagesDir)

        for dir in searchDirs {
            guard FileManager.default.fileExists(atPath: dir.path) else { continue }
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { continue }

            for file in files where file.hasSuffix(".lang") {
                let filePath = dir.appendingPathComponent(file).path
                if let (code, name, dict) = parseLangFile(at: filePath) {
                    dictionaries[code] = dict
                    let isCustom = dir == customLanguagesDir
                    if !langs.contains(where: { $0.code == code }) {
                        langs.append(LanguageInfo(code: code, name: name, isCustom: isCustom, filePath: filePath))
                    }
                }
            }
        }

        self.availableLanguages = langs
    }

    // MARK: - .lang Dosyası Ayrıştırıcı (Parser)
    public func parseLangFile(at path: String) -> (code: String, name: String, dict: [String: String])? {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        return parseLangContent(content, fallbackCode: (path as NSString).lastPathComponent.replacingOccurrences(of: ".lang", with: ""))
    }

    public func parseLangContent(_ content: String, fallbackCode: String = "en") -> (code: String, name: String, dict: [String: String])? {
        var dict: [String: String] = [:]
        var currentSection = ""
        var code = fallbackCode
        var name = fallbackCode.uppercased()

        let lines = content.components(separatedBy: .newlines)
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix("//") {
                continue
            }

            // [section] Desteği
            if line.hasPrefix("[") && line.hasSuffix("]") {
                let sec = String(line.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                currentSection = sec.isEmpty ? "" : "\(sec)."
                continue
            }

            // key = value Ayrımı
            let separator = line.contains("=") ? "=" : (line.contains(":") ? ":" : nil)
            guard let sep = separator else { continue }

            let parts = line.components(separatedBy: sep)
            guard parts.count >= 2 else { continue }

            let rawKey = parts[0].trimmingCharacters(in: .whitespaces)
            let val = parts.dropFirst().joined(separator: sep).trimmingCharacters(in: .whitespaces)

            let fullKey = rawKey.contains(".") ? rawKey : "\(currentSection)\(rawKey)"

            if fullKey == "language.code" {
                code = val
            } else if fullKey == "language.name" {
                name = val
            } else {
                dict[fullKey] = val
            }
        }

        return (code: code, name: name, dict: dict)
    }

    // MARK: - Yerleşik Varsayılan Sözlükler
    private func loadBuiltinDefaults() {
        dictionaries["en"] = [
            "app.name": "Pulsar",
            "app.tagline": "Light-Speed Archive & Data Compression Studio for macOS",
            "main.empty_title": "Pulsar",
            "main.empty_subtitle": "Drag and drop an archive file here to open",
            "main.open_archive": "Open Archive (⌘O)",
            "main.new_archive": "New Archive (⌘N)",
            "main.compare_archives": "Compare (⌘⇧D)",
            "main.recent_archives": "RECENT ARCHIVES",
            "main.clear_history": "Clear History",
            "main.drop_to_open": "Drop Archive Here to Open",
            "main.search_prompt": "Search inside archive...",
            "main.no_items": "No items to display in this folder",
            "main.no_search_results": "No files found matching your search",
            "sidebar.quick_start": "Quick Start",
            "sidebar.content": "Content",
            "sidebar.smart_filters": "Smart Filters",
            "sidebar.recent": "Recent Archives",
            "sidebar.no_recents": "No recent archives",
            "sidebar.clear": "Clear",
            "sidebar.modules": "Systems & Modules",
            "sidebar.all_items": "All Content",
            "sidebar.files_only": "Files Only",
            "sidebar.folders_only": "Folders Only",
            "sidebar.images": "Images",
            "sidebar.documents": "Documents",
            "sidebar.code": "Source Code",
            "sidebar.media": "Media",
            "sidebar.benchmark": "Warp Benchmark",
            "sidebar.folder_watcher": "Black Hole Watcher",
            "sidebar.repair": "Recovery Station",
            "sidebar.converter": "Format Converter",
            "sidebar.checksum": "Checksum (Hash)",
            "sidebar.settings": "Settings & Preferences...",
            "toolbar.extract_all": "Extract All",
            "toolbar.new_archive": "New Archive",
            "toolbar.safe_lock_locked": "Read-Only",
            "toolbar.safe_lock_unlocked": "Editing Mode",
            "toolbar.delete": "Delete",
            "toolbar.close": "Close",
            "toolbar.compare": "Compare Archives",
            "toolbar.tools": "Tools",
            "toolbar.hud": "Floating HUD",
            "toolbar.settings": "Settings",
            "toolbar.parent_folder": "Parent Folder (⌘↑)",
            "breadcrumb.up": "Go Up",
            "breadcrumb.copy_path": "Copy Folder Path",
            "breadcrumb.editing_active": "Editing Active",
            "column.name": "Name",
            "column.size": "Size",
            "column.compressed": "Compressed",
            "column.ratio": "Ratio",
            "column.date": "Date Modified",
            "table.folder": "Folder",
            "table.encrypted": "ENCRYPTED (AES)",
            "inspector.content_preview": "CONTENT PREVIEW",
            "inspector.open_folder": "Open Folder",
            "inspector.quick_look": "QuickLook (⎵)",
            "inspector.extract": "Extract",
            "inspector.details": "INFORMATION",
            "inspector.original_size": "Original Size",
            "inspector.compressed_size": "Compressed",
            "inspector.ratio": "Compression Ratio",
            "inspector.modified": "Modified",
            "inspector.crc32": "CRC32",
            "inspector.attributes": "Attributes",
            "inspector.path": "Path",
            "inspector.no_selection": "Select a file to view details and preview",
            "inspector.total_files": "Total Files",
            "inspector.format": "Format",
            "menu.quick_look": "QuickLook Preview (⎵)",
            "menu.open_with": "Open With...",
            "menu.checksum": "Checksum...",
            "menu.copy_path": "Copy Path",
            "menu.extract_selected": "Extract Selected...",
            "menu.extract_all": "Extract All...",
            "menu.delete_item": "Delete from Archive",
            "menu.show_in_finder": "Show in Finder",
            "menu.remove_from_list": "Remove from List",
            "modal.cancel": "Cancel",
            "modal.save": "Save",
            "modal.start": "Start",
            "modal.close": "Close",
            "compress.title": "Create New Archive",
            "compress.presets": "Smart Presets",
            "compress.wizard": "Step-by-Step Wizard",
            "compress.expert": "Expert Control Panel",
            "compress.source": "Source:",
            "compress.output": "Output Destination:",
            "compress.start_btn": "Start Compression",
            "settings.title": "Pulsar Preferences & Settings",
            "settings.general": "General",
            "settings.engines": "Engines & Diagnostics",
            "settings.security": "Security & Vault",
            "settings.hud": "Floating HUD",
            "settings.about": "About & Updates",
            "settings.language": "Interface Language",
            "settings.language_auto": "System Default (Automatic)",
            "settings.theme": "Appearance Theme",
            "settings.accent": "Cosmic Accent Color",
            "settings.density": "Information Density",
            "settings.open_custom_lang_dir": "Open Custom Languages Folder...",
            "footer.items": "items",
            "footer.selected": "selected",
            "footer.disk_free": "Disk: %@ free"
        ]

        dictionaries["tr"] = [
            "app.name": "Pulsar",
            "app.tagline": "macOS İçin Işık Hızında Arşiv ve Sıkıştırma Gücü",
            "main.empty_title": "Pulsar",
            "main.empty_subtitle": "Açmak için bir arşiv dosyasını buraya sürükleyin",
            "main.open_archive": "Arşiv Aç (⌘O)",
            "main.new_archive": "Yeni Arşiv (⌘N)",
            "main.compare_archives": "Karşılaştır (⌘⇧D)",
            "main.recent_archives": "SON KULLANILANLAR",
            "main.clear_history": "Geçmişi Temizle",
            "main.drop_to_open": "Açmak İçin Arşivi Buraya Bırakın",
            "main.search_prompt": "Arşiv içinde ara...",
            "main.no_items": "Bu klasörde görüntülenecek öğe yok",
            "main.no_search_results": "Arama ile eşleşen dosya bulunamadı",
            "sidebar.quick_start": "Hızlı Başlangıç",
            "sidebar.content": "İçerik",
            "sidebar.smart_filters": "Akıllı Filtreler",
            "sidebar.recent": "Son Açılan Arşivler",
            "sidebar.no_recents": "Son arşiv bulunmuyor",
            "sidebar.clear": "Temizle",
            "sidebar.modules": "Sistem & Modüller",
            "sidebar.all_items": "Tüm İçerik",
            "sidebar.files_only": "Sadece Dosyalar",
            "sidebar.folders_only": "Sadece Klasörler",
            "sidebar.images": "Görseller",
            "sidebar.documents": "Belgeler",
            "sidebar.code": "Kaynak Kodu",
            "sidebar.media": "Medya",
            "sidebar.benchmark": "Warp Benchmark",
            "sidebar.folder_watcher": "Kara Delik İzleyici",
            "sidebar.repair": "Kurtarma İstasyonu",
            "sidebar.converter": "Format Dönüştürücü",
            "sidebar.checksum": "Sağlama Toplamı (Checksum)",
            "sidebar.settings": "Ayarlar & Tercihler...",
            "toolbar.extract_all": "Tümünü Çıkar",
            "toolbar.new_archive": "Yeni Arşiv",
            "toolbar.safe_lock_locked": "Salt Okunur",
            "toolbar.safe_lock_unlocked": "Düzenleme Açık",
            "toolbar.delete": "Sil",
            "toolbar.close": "Kapat",
            "toolbar.compare": "Arşiv Karşılaştır",
            "toolbar.tools": "Araçlar",
            "toolbar.hud": "Yüzen HUD",
            "toolbar.settings": "Ayarlar",
            "toolbar.parent_folder": "Üst Dizin (⌘↑)",
            "breadcrumb.up": "Üst Dizin",
            "breadcrumb.copy_path": "Klasör Yolunu Kopyala",
            "breadcrumb.editing_active": "Düzenleme Açık",
            "column.name": "Ad",
            "column.size": "Boyut",
            "column.compressed": "Sıkıştırılmış",
            "column.ratio": "Oran",
            "column.date": "Değiştirilme Tarihi",
            "table.folder": "Klasör",
            "table.encrypted": "ŞİFRELİ (AES)",
            "inspector.content_preview": "İÇERİK ÖNİZLEMESİ",
            "inspector.open_folder": "Klasörü Aç",
            "inspector.quick_look": "Hızlı Bakış (⎵)",
            "inspector.extract": "Çıkar",
            "inspector.details": "BİLGİLER",
            "inspector.original_size": "Orijinal Boyut",
            "inspector.compressed_size": "Sıkıştırılmış",
            "inspector.ratio": "Sıkıştırma Oranı",
            "inspector.modified": "Değiştirilme",
            "inspector.crc32": "CRC32",
            "inspector.attributes": "Öznitelikler",
            "inspector.path": "Yol",
            "inspector.no_selection": "Detayları ve önizlemeyi görmek için bir dosya seçin",
            "inspector.total_files": "Toplam Dosya",
            "inspector.format": "Format",
            "menu.quick_look": "Hızlı Bakış (QuickLook) ⎵",
            "menu.open_with": "Şununla Aç...",
            "menu.checksum": "Sağlama Toplamı (Checksum)...",
            "menu.copy_path": "Yolu Kopyala",
            "menu.extract_selected": "Seçileni Çıkar...",
            "menu.extract_all": "Tüm Arşivi Çıkar...",
            "menu.delete_item": "Arşivden Sil",
            "menu.show_in_finder": "Finder'da Göster",
            "menu.remove_from_list": "Listeden Kaldır",
            "modal.cancel": "Vazgeç",
            "modal.save": "Kaydet",
            "modal.start": "Başlat",
            "modal.close": "Kapat",
            "compress.title": "Yeni Arşiv Oluştur",
            "compress.presets": "Akıllı Önayarlar",
            "compress.wizard": "Adım Adım Sihirbaz",
            "compress.expert": "Uzman Kontrol Paneli",
            "compress.source": "Kaynak:",
            "compress.output": "Çıktı Konumu:",
            "compress.start_btn": "Sıkıştırmayı Başlat",
            "settings.title": "Pulsar Tercihler ve Ayarlar",
            "settings.general": "Genel",
            "settings.engines": "Motorlar & Teşhis",
            "settings.security": "Güvenlik & Kasa",
            "settings.hud": "Yüzen HUD",
            "settings.about": "Hakkında & Güncellemeler",
            "settings.language": "Arayüz Dili",
            "settings.language_auto": "Sistem Varsayılanı (Otomatik)",
            "settings.theme": "Görünüm Teması",
            "settings.accent": "Kozmik Vurgu Rengi",
            "settings.density": "Bilgi Yoğunluğu",
            "settings.open_custom_lang_dir": "Harici Dil Klasörünü Aç...",
            "footer.items": "öğe",
            "footer.selected": "seçildi",
            "footer.disk_free": "Disk: %@ boş"
        ]
    }
}

public enum L10n {
    public static func tr(_ key: String, fallback: String? = nil) -> String {
        return LocalizationService.shared.t(key, fallback: fallback)
    }
}
