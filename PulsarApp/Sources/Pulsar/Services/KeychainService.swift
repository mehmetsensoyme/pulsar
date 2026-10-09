import Foundation
import Security

public final class KeychainService {
    public static let shared = KeychainService()
    private let serviceName = "com.pulsar.archive.passwords"

    private init() {}

    public func savePassword(_ password: String, forArchive archivePath: String) {
        guard let data = password.data(using: .utf8) else { return }

        // Önceki kaydı sil
        deletePassword(forArchive: archivePath)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: archivePath,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    public func getPassword(forArchive archivePath: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: archivePath,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    public func deletePassword(forArchive archivePath: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: archivePath
        ]
        SecItemDelete(query as CFDictionary)
    }
}
