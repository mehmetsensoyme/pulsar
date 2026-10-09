import Foundation

public final class TempCacheManager {
    public static let shared = TempCacheManager()

    private let lock = NSLock()
    private var registeredDirectories: Set<String> = []

    private init() {}

    /// Yeni bir geçici önizleme klasörünü kaydeder
    public func registerTempDirectory(_ path: String) {
        lock.lock()
        defer { lock.unlock() }
        registeredDirectories.insert(path)
    }

    /// Belirli bir geçici klasörü güvenli şekilde siler
    public func purgeDirectory(at path: String) {
        lock.lock()
        registeredDirectories.remove(path)
        lock.unlock()

        try? FileManager.default.removeItem(atPath: path)
    }

    /// Tüm kayıtlı ve sistemdeki PulsarPreview_* klasörlerini temizler
    public func cleanupAllTempDirectories() {
        lock.lock()
        let dirsToClean = Array(registeredDirectories)
        registeredDirectories.removeAll()
        lock.unlock()

        let fm = FileManager.default
        for dir in dirsToClean {
            try? fm.removeItem(atPath: dir)
        }

        // NSTemporaryDirectory içindeki tüm artık PulsarPreview klasörlerini temizle
        let tempRoot = NSTemporaryDirectory()
        if let items = try? fm.contentsOfDirectory(atPath: tempRoot) {
            for item in items where item.hasPrefix("PulsarPreview_") {
                let fullPath = (tempRoot as NSString).appendingPathComponent(item)
                try? fm.removeItem(atPath: fullPath)
            }
        }
    }
}
