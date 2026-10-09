import Foundation
import SwiftUI
import Combine

public enum ContentFilterMode: String, CaseIterable, Identifiable {
    case all = "Tüm İçerik"
    case filesOnly = "Sadece Dosyalar"
    case foldersOnly = "Sadece Klasörler"
    case images = "Görseller"
    case documents = "Belgeler"
    case code = "Kod & Betik"
    case media = "Medya"

    public var id: String { rawValue }
    public var iconName: String {
        switch self {
        case .all: return "tray.full.fill"
        case .filesOnly: return "doc.fill"
        case .foldersOnly: return "folder.fill"
        case .images: return "photo.fill"
        case .documents: return "doc.text.fill"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .media: return "play.circle.fill"
        }
    }
}

public final class ArchiveManager: ObservableObject {
    public static let shared = ArchiveManager()

    // MARK: - Arşiv Durumu
    @Published public var currentArchivePath: String? = nil
    @Published public var currentFormat: ArchiveFormat? = nil
    @Published public var allItems: [ArchiveItem] = []
    @Published public var currentFolderPath: String = "" // Breadcrumbs için: "" = kök
    @Published public var searchQuery: String = ""
    @Published public var filterMode: ContentFilterMode = .all
    @Published public var selectedItemIds: Set<UUID> = []
    @Published public var sortColumn: String = "name"
    @Published public var sortAscending: Bool = true

    // MARK: - Görünüm Modu ve Seçenekler
    @Published public var isGridView: Bool = false

    // MARK: - Güvenlik ve Modlar
    @Published public var isEditingUnlocked: Bool = false
    @Published public var currentLayoutMode: LayoutMode = .modernThreePane

    // MARK: - Sekmeli Stüdyo
    @Published public var openTabs: [String] = [] // Arşiv yolları
    @Published public var activeTabIndex: Int = 0

    // MARK: - Arka Plan Görevleri
    @Published public var activeTasks: [TaskProgress] = []
    @Published public var isHUDVisible: Bool = false

    public func startTask(_ task: TaskProgress) {
        activeTasks.append(task)
        withAnimation(.easeInOut(duration: 0.25)) {
            isHUDVisible = true
        }
    }

    // MARK: - Modal Tetikleyicileri
    @Published public var showCompressSheet: Bool = false
    @Published public var showBenchmarkSheet: Bool = false
    @Published public var showRepairSheet: Bool = false
    @Published public var showFolderWatcherSheet: Bool = false
    @Published public var showUpdateSheet: Bool = false
    @Published public var showSettingsSheet: Bool = false
    @Published public var showPasswordModal: Bool = false
    @Published public var passwordPromptCallback: ((String?) -> Void)? = nil
    @Published public var showChecksumSheet: Bool = false
    @Published public var checksumTargetItem: ArchiveItem? = nil
    @Published public var showConverterSheet: Bool = false
    @Published public var showOnboardingSheet: Bool = false
    @Published public var showDiffSheet: Bool = false

    // MARK: - Hata ve Bilgi
    @Published public var errorMessage: String? = nil
    @Published public var recentArchives: [String] = []

    private let sevenZip = SevenZipEngine.shared
    private let rar = RAREngine.shared
    private let keychain = KeychainService.shared

    private init() {
        if let mode = LayoutMode(rawValue: PulsarSettings.shared.defaultLayoutMode) {
            self.currentLayoutMode = mode
        }
        loadRecents()

        // İlk kurulum yapılmamışsa sihirbazı otomatik aç
        if !PulsarSettings.shared.hasCompletedOnboarding {
            self.showOnboardingSheet = true
        }
    }

    // MARK: - Filtrelenmiş ve Konumlandırılmış Öğeler
    public var currentFolderItems: [ArchiveItem] {
        var items = allItems

        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            items = items.filter { $0.name.lowercased().contains(q) || $0.path.lowercased().contains(q) }
        } else {
            if currentFolderPath.isEmpty {
                // Kök dizindeki öğeler
                items = items.filter {
                    let p = $0.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    return !p.contains("/")
                }
            } else {
                let prefix = currentFolderPath.hasSuffix("/") ? currentFolderPath : "\(currentFolderPath)/"
                items = items.filter {
                    guard $0.path.hasPrefix(prefix) else { return false }
                    let remaining = String($0.path.dropFirst(prefix.count))
                    let clean = remaining.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    return !clean.contains("/")
                }
            }
        }

        // Filtre Modu (Tüm İçerik, Sadece Dosyalar, Klasörler, Görseller, Belgeler, Kod, Medya)
        switch filterMode {
        case .all:
            break
        case .filesOnly:
            items = items.filter { !$0.isDirectory }
        case .foldersOnly:
            items = items.filter { $0.isDirectory }
        case .images:
            let exts = ["png", "jpg", "jpeg", "gif", "webp", "svg", "heic", "tiff", "bmp", "ico"]
            items = items.filter { !$0.isDirectory && exts.contains($0.fileExtension.lowercased()) }
        case .documents:
            let exts = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "pages", "numbers"]
            items = items.filter { !$0.isDirectory && exts.contains($0.fileExtension.lowercased()) }
        case .code:
            let exts = ["swift", "py", "js", "ts", "c", "cpp", "h", "html", "css", "json", "xml", "sh", "zsh", "yml", "yaml", "rb", "go", "rs"]
            items = items.filter { !$0.isDirectory && exts.contains($0.fileExtension.lowercased()) }
        case .media:
            let exts = ["mp3", "wav", "aac", "flac", "m4a", "mp4", "mov", "mkv", "avi"]
            items = items.filter { !$0.isDirectory && exts.contains($0.fileExtension.lowercased()) }
        }

        // Önce klasörler, sonra seçilen sütuna göre sırala
        return items.sorted { item1, item2 in
            if item1.isDirectory != item2.isDirectory {
                return item1.isDirectory && !item2.isDirectory
            }
            switch sortColumn {
            case "size":
                return sortAscending ? item1.size < item2.size : item1.size > item2.size
            case "compressedSize":
                return sortAscending ? item1.compressedSize < item2.compressedSize : item1.compressedSize > item2.compressedSize
            case "ratio":
                return sortAscending ? item1.compressionRatio < item2.compressionRatio : item1.compressionRatio > item2.compressionRatio
            case "date":
                return sortAscending ? item1.dateValue < item2.dateValue : item1.dateValue > item2.dateValue
            default:
                let comp = item1.name.localizedStandardCompare(item2.name)
                return sortAscending ? comp == .orderedAscending : comp == .orderedDescending
            }
        }
    }

    public func toggleSort(column: String) {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
    }

    public var breadcrumbs: [String] {
        if currentFolderPath.isEmpty { return ["Kök"] }
        let components = currentFolderPath.split(separator: "/").map { String($0) }
        return ["Kök"] + components
    }

    public func navigateToBreadcrumb(at index: Int) {
        if index == 0 {
            currentFolderPath = ""
        } else {
            let components = currentFolderPath.split(separator: "/").map { String($0) }
            let slice = components.prefix(index)
            currentFolderPath = slice.joined(separator: "/")
        }
        if let first = currentFolderItems.first {
            selectedItemIds = [first.id]
        }
    }

    public func openFolder(item: ArchiveItem) {
        guard item.isDirectory else { return }
        currentFolderPath = item.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if let first = currentFolderItems.first {
            selectedItemIds = [first.id]
        }
    }

    public func goUpOneLevel() {
        guard !currentFolderPath.isEmpty else { return }
        var components = currentFolderPath.split(separator: "/").map { String($0) }
        components.removeLast()
        currentFolderPath = components.joined(separator: "/")
        if let first = currentFolderItems.first {
            selectedItemIds = [first.id]
        }
    }

    // MARK: - Arşiv Açma
    public func openArchive(at path: String, password: String? = nil) {
        guard FileManager.default.fileExists(atPath: path) else {
            errorMessage = "Arşiv dosyası bulunamadı: \(path)"
            return
        }

        currentArchivePath = path
        currentFormat = ArchiveFormat.detect(from: path)
        currentFolderPath = ""
        selectedItemIds.removeAll()
        isEditingUnlocked = false

        addToRecents(path: path)
        if !openTabs.contains(path) {
            openTabs.append(path)
            activeTabIndex = openTabs.count - 1
        } else if let idx = openTabs.firstIndex(of: path) {
            activeTabIndex = idx
        }

        // Keychain'de şifre var mı kontrol et
        let savedPwd = password ?? keychain.getPassword(forArchive: path)

        Task {
            do {
                let items: [ArchiveItem]
                if currentFormat == .rar {
                    items = try await sevenZip.listArchive(at: path, password: savedPwd)
                } else {
                    items = try await sevenZip.listArchive(at: path, password: savedPwd)
                }

                await MainActor.run {
                    self.allItems = items
                    if self.selectedItemIds.isEmpty, let first = self.currentFolderItems.first {
                        self.selectedItemIds = [first.id]
                    }
                }
            } catch {
                await MainActor.run {
                    if error.localizedDescription.contains("password") || error.localizedDescription.contains("Can not open encrypted archive") {
                        self.promptPassword(for: path)
                    } else {
                        self.errorMessage = "Arşiv okunamadı: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    public func closeArchive() {
        currentArchivePath = nil
        currentFormat = nil
        currentFolderPath = ""
        allItems.removeAll()
        selectedItemIds.removeAll()
        isEditingUnlocked = false
        openTabs.removeAll()
        activeTabIndex = 0
    }

    public func promptPassword(for path: String) {
        if let savedPwd = keychain.getPassword(forArchive: path) {
            self.openArchive(at: path, password: savedPwd)
            return
        }
        self.showPasswordModal = true
        self.passwordPromptCallback = { [weak self] pwd in
            guard let self = self, let pwd = pwd, !pwd.isEmpty else { return }
            if PulsarSettings.shared.savePasswordsToKeychain {
                self.keychain.savePassword(pwd, forArchive: path)
            }
            self.openArchive(at: path, password: pwd)
        }
    }

    // MARK: - Görev İptal Etme (Cancellation)
    public func cancelTask(id: UUID) {
        guard let task = activeTasks.first(where: { $0.id == id }) else { return }

        // Motorlardaki arka plan sürecini sonlandır
        sevenZip.cancelProcess(for: id)
        rar.cancelProcess(for: id)

        // Görevi iptal edildi olarak işaretle
        if let idx = activeTasks.firstIndex(where: { $0.id == id }) {
            activeTasks[idx].status = .failed("İşlem kullanıcı tarafından iptal edildi.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.activeTasks.removeAll(where: { $0.id == id })
                if self.activeTasks.isEmpty {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        self.isHUDVisible = false
                    }
                }
            }
        }

        // Sıkıştırma işleminde yarım kalan bozuk dosyayı temizle
        if task.type == .compress && !task.archivePath.isEmpty {
            try? FileManager.default.removeItem(atPath: task.archivePath)
        }
    }

    // MARK: - Çıkarma İşlemi
    public func extractAll(to destinationFolder: String? = nil) {
        guard let archive = currentArchivePath else { return }
        let dest = destinationFolder ?? (archive as NSString).deletingPathExtension
        try? FileManager.default.createDirectory(atPath: dest, withIntermediateDirectories: true)

        let totalUncompressedBytes = allItems.reduce(0) { $0 + $1.size }

        let task = TaskProgress(
            title: "Arşiv Çıkarılıyor",
            type: .extract,
            archivePath: archive
        )
        startTask(task)

        Task {
            do {
                if currentFormat == .rar {
                    try await rar.extract(
                        taskId: task.id,
                        archiveAt: archive,
                        to: dest,
                        requiredDiskBytes: totalUncompressedBytes
                    ) { pct, line in
                        self.updateTaskProgress(id: task.id, percent: pct, file: line)
                    }
                } else {
                    try await sevenZip.extract(
                        taskId: task.id,
                        archiveAt: archive,
                        to: dest,
                        requiredDiskBytes: totalUncompressedBytes
                    ) { pct, line in
                        self.updateTaskProgress(id: task.id, percent: pct, file: line)
                    }
                }

                await MainActor.run {
                    self.finishTask(id: task.id)
                    // Finder'da aç
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: dest)
                }
            } catch {
                await MainActor.run {
                    self.failTask(id: task.id, error: error.localizedDescription)
                }
            }
        }
    }

    public func extractSelected(to destinationFolder: String) {
        guard let archive = currentArchivePath else { return }
        let selectedItems = allItems.filter { selectedItemIds.contains($0.id) }
        let selectedFiles = selectedItems.map { $0.path }
        guard !selectedFiles.isEmpty else { return }

        let selectedBytes = selectedItems.reduce(0) { $0 + $1.size }

        let task = TaskProgress(
            title: "\(selectedFiles.count) Dosya Çıkarılıyor",
            type: .extract,
            archivePath: archive
        )
        startTask(task)

        Task {
            do {
                try await sevenZip.extract(
                    taskId: task.id,
                    archiveAt: archive,
                    to: destinationFolder,
                    selectedFiles: selectedFiles,
                    requiredDiskBytes: selectedBytes
                ) { pct, line in
                    self.updateTaskProgress(id: task.id, percent: pct, file: line)
                }

                await MainActor.run {
                    self.finishTask(id: task.id)
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: destinationFolder)
                }
            } catch {
                await MainActor.run {
                    self.failTask(id: task.id, error: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Canlı Geçici Önizleme
    public func openOrPreviewItem(_ item: ArchiveItem) {
        guard !item.isDirectory, let archive = currentArchivePath else {
            openFolder(item: item)
            return
        }

        let tempDir = NSTemporaryDirectory().appending("PulsarPreview_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        TempCacheManager.shared.registerTempDirectory(tempDir)

        Task {
            do {
                try await sevenZip.extract(archiveAt: archive, to: tempDir, selectedFiles: [item.path])
                let extractedFilePath = (tempDir as NSString).appendingPathComponent(item.path)

                await MainActor.run {
                    let url = URL(fileURLWithPath: extractedFilePath)
                    NSWorkspace.shared.open(url)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Önizleme dosyası çıkarılamadı: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Yerel macOS QuickLook (Hızlı Bakış)
    public func quickLookItem(_ item: ArchiveItem) {
        guard !item.isDirectory, let archive = currentArchivePath else { return }

        let tempDir = NSTemporaryDirectory().appending("PulsarQuickLook_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        TempCacheManager.shared.registerTempDirectory(tempDir)

        Task {
            do {
                try await sevenZip.extract(archiveAt: archive, to: tempDir, selectedFiles: [item.path])
                let extractedFilePath = (tempDir as NSString).appendingPathComponent(item.path)
                let url = URL(fileURLWithPath: extractedFilePath)
                await MainActor.run {
                    QuickLookService.shared.togglePreview(for: url)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Hızlı önizleme dosyası çıkarılamadı: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Şununla Aç (Open With)
    public func openWithApp(item: ArchiveItem, appBundleId: String) {
        guard !item.isDirectory, let archive = currentArchivePath else { return }
        let tempDir = NSTemporaryDirectory().appending("PulsarOpenWith_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        TempCacheManager.shared.registerTempDirectory(tempDir)

        Task {
            do {
                try await sevenZip.extract(archiveAt: archive, to: tempDir, selectedFiles: [item.path])
                let extractedFilePath = (tempDir as NSString).appendingPathComponent(item.path)
                let url = URL(fileURLWithPath: extractedFilePath)

                await MainActor.run {
                    if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appBundleId) {
                        NSWorkspace.shared.open([url], withApplicationAt: appUrl, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
                    } else {
                        NSWorkspace.shared.open(url)
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Dosya açılamadı: \(error.localizedDescription)"
                }
            }
        }
    }

    public func openWithCustomApp(item: ArchiveItem) {
        guard !item.isDirectory, let archive = currentArchivePath else { return }
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Aç"
        panel.message = "\(item.name) dosyasını açmak için bir uygulama seçin"

        if panel.runModal() == .OK, let appUrl = panel.url {
            let tempDir = NSTemporaryDirectory().appending("PulsarOpenWith_\(UUID().uuidString)")
            try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
            TempCacheManager.shared.registerTempDirectory(tempDir)

            Task {
                do {
                    try await sevenZip.extract(archiveAt: archive, to: tempDir, selectedFiles: [item.path])
                    let extractedFilePath = (tempDir as NSString).appendingPathComponent(item.path)
                    let url = URL(fileURLWithPath: extractedFilePath)

                    await MainActor.run {
                        NSWorkspace.shared.open([url], withApplicationAt: appUrl, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Dosya açılamadı: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    // MARK: - Düzenleme Modu İşlemleri
    public func deleteSelectedItems() {
        guard isEditingUnlocked, let archive = currentArchivePath else { return }
        let pathsToDelete = allItems.filter { selectedItemIds.contains($0.id) }.map { $0.path }
        guard !pathsToDelete.isEmpty else { return }

        Task {
            do {
                try await sevenZip.deleteItems(from: archive, itemPaths: pathsToDelete)
                await MainActor.run {
                    self.openArchive(at: archive)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Dosyalar silinemedi: \(error.localizedDescription)"
                }
            }
        }
    }

    public func addFilesToCurrentArchive(filePaths: [String]) {
        guard isEditingUnlocked, let archive = currentArchivePath else { return }

        Task {
            do {
                try await sevenZip.addItems(to: archive, itemsToAdd: filePaths)
                await MainActor.run {
                    self.openArchive(at: archive)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Dosyalar eklenemedi: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - İlerleme Yönetimi
    private func updateTaskProgress(id: UUID, percent: Double, file: String) {
        DispatchQueue.main.async {
            if let idx = self.activeTasks.firstIndex(where: { $0.id == id }) {
                self.activeTasks[idx].percent = percent
                self.activeTasks[idx].currentFilename = (file as NSString).lastPathComponent
                self.activeTasks[idx].status = .running
            }
        }
    }

    private func finishTask(id: UUID) {
        if let idx = activeTasks.firstIndex(where: { $0.id == id }) {
            activeTasks[idx].percent = 1.0
            activeTasks[idx].status = .completed
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.activeTasks.removeAll(where: { $0.id == id })
                if self.activeTasks.isEmpty {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        self.isHUDVisible = false
                    }
                }
            }
        }
    }

    private func failTask(id: UUID, error: String) {
        if let idx = activeTasks.firstIndex(where: { $0.id == id }) {
            activeTasks[idx].status = .failed(error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                self.activeTasks.removeAll(where: { $0.id == id })
                if self.activeTasks.isEmpty {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        self.isHUDVisible = false
                    }
                }
            }
        }
    }

    // MARK: - Son Arşivler
    private func addToRecents(path: String) {
        var recents = recentArchives.filter { $0 != path }
        recents.insert(path, at: 0)
        if recents.count > 10 { recents.removeLast() }
        recentArchives = recents
        UserDefaults.standard.set(recents, forKey: "PulsarRecents")
    }

    private func loadRecents() {
        if let recents = UserDefaults.standard.stringArray(forKey: "PulsarRecents") {
            recentArchives = recents
        }
    }

    public func clearRecentArchives() {
        recentArchives.removeAll()
        UserDefaults.standard.removeObject(forKey: "PulsarRecents")
    }

    public func removeFromRecents(path: String) {
        recentArchives.removeAll(where: { $0 == path })
        UserDefaults.standard.set(recentArchives, forKey: "PulsarRecents")
    }

    public func itemCount(for mode: ContentFilterMode) -> Int {
        switch mode {
        case .all:
            return allItems.count
        case .filesOnly:
            return allItems.filter { !$0.isDirectory }.count
        case .foldersOnly:
            return allItems.filter { $0.isDirectory }.count
        case .images:
            let exts = ["png", "jpg", "jpeg", "gif", "webp", "svg", "heic", "tiff", "bmp", "ico"]
            return allItems.filter { !$0.isDirectory && exts.contains($0.fileExtension.lowercased()) }.count
        case .documents:
            let exts = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "pages", "numbers"]
            return allItems.filter { !$0.isDirectory && exts.contains($0.fileExtension.lowercased()) }.count
        case .code:
            let exts = ["swift", "py", "js", "ts", "c", "cpp", "h", "html", "css", "json", "xml", "sh", "zsh", "yml", "yaml", "rb", "go", "rs"]
            return allItems.filter { !$0.isDirectory && exts.contains($0.fileExtension.lowercased()) }.count
        case .media:
            let exts = ["mp3", "wav", "aac", "flac", "m4a", "mp4", "mov", "mkv", "avi"]
            return allItems.filter { !$0.isDirectory && exts.contains($0.fileExtension.lowercased()) }.count
        }
    }

    // MARK: - Seçim ve Pano Yardımcıları
    public var selectedTotalSize: String {
        let selected = allItems.filter { selectedItemIds.contains($0.id) }
        let total = selected.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    public var freeDiskSpaceText: String? {
        guard let path = currentArchivePath ?? FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path else { return nil }
        if let bytes = DiskSpaceGuard.shared.availableFreeBytes(atPath: path) {
            return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        }
        return nil
    }

    public func selectAllItems() {
        self.selectedItemIds = Set(currentFolderItems.map { $0.id })
    }

    public func copySelectedPaths() {
        let selected = allItems.filter { selectedItemIds.contains($0.id) }
        let paths = selected.map { $0.path }.joined(separator: "\n")
        guard !paths.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(paths, forType: .string)
    }

    public func openChecksumModal(for item: ArchiveItem? = nil) {
        self.checksumTargetItem = item
        self.showChecksumSheet = true
    }

    // MARK: - Arşiv Format Dönüştürücü (Converter)
    public func convertCurrentArchive(to targetFormat: ArchiveFormat, completion: @escaping (Bool) -> Void) {
        guard let sourceArchive = currentArchivePath else {
            completion(false)
            return
        }
        let sourceUrl = URL(fileURLWithPath: sourceArchive)
        let baseName = sourceUrl.deletingPathExtension().lastPathComponent
        let dir = sourceUrl.deletingLastPathComponent().path
        let targetPath = (dir as NSString).appendingPathComponent("\(baseName)_converted.\(targetFormat.rawValue)")

        let totalBytes = allItems.reduce(0) { $0 + $1.size }
        let task = TaskProgress(
            title: "\(targetFormat.rawValue.uppercased()) Formatına Dönüştürülüyor",
            type: .compress,
            archivePath: targetPath
        )
        startTask(task)

        let tempExtractDir = NSTemporaryDirectory().appending("PulsarConvert_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(atPath: tempExtractDir, withIntermediateDirectories: true)
        TempCacheManager.shared.registerTempDirectory(tempExtractDir)

        Task {
            do {
                // 1. Önce içeriği geçici klasöre çıkar
                try await sevenZip.extract(
                    taskId: task.id,
                    archiveAt: sourceArchive,
                    to: tempExtractDir,
                    requiredDiskBytes: totalBytes
                ) { pct, line in
                    self.updateTaskProgress(id: task.id, percent: pct * 0.5, file: "Çıkarılıyor: " + line)
                }

                // 2. Geçici klasördeki dosyaları yeni formata sıkıştır
                let contents = try FileManager.default.contentsOfDirectory(atPath: tempExtractDir).map {
                    (tempExtractDir as NSString).appendingPathComponent($0)
                }

                let preset = Preset(
                    name: "Converter",
                    format: targetFormat,
                    level: .normal,
                    solidBlock: true,
                    threads: PulsarSettings.shared.maxCpuThreads
                )

                try await sevenZip.createArchive(
                    taskId: task.id,
                    at: targetPath,
                    from: contents,
                    preset: preset
                ) { pct, line in
                    self.updateTaskProgress(id: task.id, percent: 0.5 + (pct * 0.5), file: "Paketleniyor: " + line)
                }

                await MainActor.run {
                    self.finishTask(id: task.id)
                    self.openArchive(at: targetPath)
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.failTask(id: task.id, error: error.localizedDescription)
                    self.errorMessage = "Dönüştürme başarısız oldu: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
}
