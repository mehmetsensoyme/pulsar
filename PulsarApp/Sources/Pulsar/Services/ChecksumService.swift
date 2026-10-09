import Foundation
import CryptoKit

public struct ChecksumResult: Equatable {
    public let fileName: String
    public let fileSize: Int64
    public let sha256: String
    public let md5: String
    public let sha1: String

    public init(fileName: String, fileSize: Int64, sha256: String, md5: String, sha1: String) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.sha256 = sha256
        self.md5 = md5
        self.sha1 = sha1
    }

    public func matches(hash: String) -> (matched: Bool, algorithm: String?) {
        let clean = hash.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if clean.isEmpty { return (false, nil) }
        if sha256.lowercased() == clean { return (true, "SHA-256") }
        if md5.lowercased() == clean { return (true, "MD5") }
        if sha1.lowercased() == clean { return (true, "SHA-1") }
        return (false, nil)
    }
}

public final class ChecksumService {
    public static let shared = ChecksumService()

    private init() {}

    /// Verilen dosyanın SHA-256, MD5 ve SHA-1 sağlama toplamlarını hesaplar
    public func computeChecksums(forFileAt path: String) async throws -> ChecksumResult {
        let fileURL = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw NSError(domain: "ChecksumError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Dosya bulunamadı: \(path)"])
        }

        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let size = (attrs[.size] as? NSNumber)?.int64Value ?? 0
        let name = fileURL.lastPathComponent

        return try await Task.detached(priority: .userInitiated) {
            let handle = try FileHandle(forReadingFrom: fileURL)
            defer { try? handle.close() }

            var sha256Hasher = SHA256()
            var md5Hasher = Insecure.MD5()
            var sha1Hasher = Insecure.SHA1()

            let bufferSize = 1024 * 1024 // 1 MB tampon
            while autoreleasepool(invoking: {
                let data = handle.readData(ofLength: bufferSize)
                if data.isEmpty { return false }
                sha256Hasher.update(data: data)
                md5Hasher.update(data: data)
                sha1Hasher.update(data: data)
                return true
            }) {}

            let sha256Digest = sha256Hasher.finalize()
            let md5Digest = md5Hasher.finalize()
            let sha1Digest = sha1Hasher.finalize()

            let sha256Str = sha256Digest.map { String(format: "%02x", $0) }.joined()
            let md5Str = md5Digest.map { String(format: "%02x", $0) }.joined()
            let sha1Str = sha1Digest.map { String(format: "%02x", $0) }.joined()

            return ChecksumResult(
                fileName: name,
                fileSize: size,
                sha256: sha256Str,
                md5: md5Str,
                sha1: sha1Str
            )
        }.value
    }
}
