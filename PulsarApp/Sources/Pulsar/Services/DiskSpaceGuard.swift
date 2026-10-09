import Foundation

public final class DiskSpaceGuard {
    public static let shared = DiskSpaceGuard()

    private init() {}

    /// Hedef konumun bağlı olduğu diskteki kullanılabilir boş bayt miktarını döner
    public func availableFreeBytes(atPath path: String) -> Int64? {
        let url = URL(fileURLWithPath: path)
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return capacity
            }
        } catch {}

        // Fallback: FileManager attributes
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: path),
           let freeSize = attrs[.systemFreeSize] as? NSNumber {
            return freeSize.int64Value
        }

        return nil
    }

    /// Hedef diskte yeterli alan olup olmadığını doğrular
    public func validateSpace(forRequiredBytes requiredBytes: Int64, atDestination destinationPath: String) throws {
        guard requiredBytes > 0 else { return }

        // Hedef yolun en yakın var olan üst klasörünü bul
        var checkPath = destinationPath
        let fm = FileManager.default
        while !fm.fileExists(atPath: checkPath) && checkPath != "/" {
            checkPath = (checkPath as NSString).deletingLastPathComponent
        }

        if let available = availableFreeBytes(atPath: checkPath) {
            // Güvenlik payı olarak fazladan %5 veya minimum 50MB marj
            let safetyMargin = max(50 * 1024 * 1024, Int64(Double(requiredBytes) * 0.05))
            if available < (requiredBytes + safetyMargin) {
                let requiredStr = ByteCountFormatter.string(fromByteCount: requiredBytes, countStyle: .file)
                let availableStr = ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
                throw NSError(
                    domain: "PulsarDiskSpace",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Hedef diskte yetersiz boş alan! Gereken: \(requiredStr), Kullanılabilir: \(availableStr)."]
                )
            }
        }
    }
}
