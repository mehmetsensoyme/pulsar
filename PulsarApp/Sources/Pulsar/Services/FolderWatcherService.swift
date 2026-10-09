import Foundation
import Combine
import UserNotifications

public struct WatchedArchiveEvent: Identifiable, Equatable {
    public let id: UUID = UUID()
    public let filename: String
    public let path: String
    public let date: Date
    public var status: String

    public static func == (lhs: WatchedArchiveEvent, rhs: WatchedArchiveEvent) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status
    }
}

public final class FolderWatcherService: ObservableObject {
    public static let shared = FolderWatcherService()

    @Published public var isWatching: Bool = false
    @Published public var watchedDirectory: String = ""
    @Published public var processedEvents: [WatchedArchiveEvent] = []

    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1
    private var knownFiles: Set<String> = []

    private init() {
        requestNotificationPermission()
    }

    public func startWatching(path: String) {
        stopWatching()

        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            return
        }

        watchedDirectory = path

        // Mevcut dosyaları kaydet
        if let items = try? fm.contentsOfDirectory(atPath: path) {
            knownFiles = Set(items)
        }

        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let s = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .attrib, .link],
            queue: DispatchQueue.global(qos: .utility)
        )

        s.setEventHandler { [weak self] in
            self?.checkForNewArchives()
        }

        s.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }

        source = s
        s.resume()
        isWatching = true
    }

    public func stopWatching() {
        source?.cancel()
        source = nil
        isWatching = false
    }

    private func checkForNewArchives() {
        let fm = FileManager.default
        guard let currentItems = try? fm.contentsOfDirectory(atPath: watchedDirectory) else { return }

        let currentSet = Set(currentItems)
        let newItems = currentSet.subtracting(knownFiles)
        knownFiles = currentSet

        let supportedExtensions = ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "zst", "lzma", "cab", "wim", "cpio", "rpm", "deb", "arj", "lzh", "iso", "dmg", "pkg", "001"]

        for item in newItems {
            // Geçici indirme dosyalarını bekle (.crdownload, .download)
            if item.hasSuffix(".crdownload") || item.hasSuffix(".download") || item.hasSuffix(".part") {
                continue
            }

            let ext = (item as NSString).pathExtension.lowercased()
            if supportedExtensions.contains(ext) {
                let fullPath = (watchedDirectory as NSString).appendingPathComponent(item)
                DispatchQueue.main.async {
                    self.handleDetectedArchive(at: fullPath, filename: item)
                }
            }
        }
    }

    private func handleDetectedArchive(at fullPath: String, filename: String) {
        let event = WatchedArchiveEvent(
            filename: filename,
            path: fullPath,
            date: Date(),
            status: "Açılıyor..."
        )
        processedEvents.insert(event, at: 0)

        // Hedef klasör: arşiv adında yeni alt klasör
        let destFolder = (fullPath as NSString).deletingPathExtension
        try? FileManager.default.createDirectory(atPath: destFolder, withIntermediateDirectories: true)

        Task {
            do {
                if filename.lowercased().hasSuffix(".rar") {
                    try await RAREngine.shared.extract(archiveAt: fullPath, to: destFolder)
                } else {
                    try await SevenZipEngine.shared.extract(archiveAt: fullPath, to: destFolder)
                }

                await MainActor.run {
                    if let idx = self.processedEvents.firstIndex(where: { $0.path == fullPath }) {
                        self.processedEvents[idx].status = "Tamamlandı"
                    }

                    // Kullanıcı tercihine göre orijinali çöpe taşı
                    if PulsarSettings.shared.autoTrashAfterExtract {
                        try? FileManager.default.trashItem(at: URL(fileURLWithPath: fullPath), resultingItemURL: nil)
                    }

                    self.sendNotification(
                        title: "Kara Delik Arşiv Çıkarıldı",
                        body: "\(filename) başarıyla klasörüne açıldı."
                    )
                }
            } catch {
                await MainActor.run {
                    if let idx = self.processedEvents.firstIndex(where: { $0.path == fullPath }) {
                        self.processedEvents[idx].status = "Hata: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func sendNotification(title: String, body: String) {
        guard PulsarSettings.shared.sendNotifications else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
