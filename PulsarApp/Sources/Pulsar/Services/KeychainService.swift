import Foundation
import Security
import Combine

public struct SavedPasswordItem: Identifiable, Equatable {
    public var id: String { archivePath }
    public let archivePath: String
    public var archiveName: String {
        return (archivePath as NSString).lastPathComponent
    }

    public init(archivePath: String) {
        self.archivePath = archivePath
    }
}

public final class KeychainService: ObservableObject {
    public static let shared = KeychainService()
    private let serviceName = "com.pulsar.archive.passwords"
    private let knownArchivesKey = "PulsarKeychainKnownArchives"

    @Published public var savedArchives: [String] = []

    private init() {
        loadKnownArchives()
    }

    private func loadKnownArchives() {
        if let list = UserDefaults.standard.stringArray(forKey: knownArchivesKey) {
            self.savedArchives = list
        }
    }

    private func persistKnownArchives() {
        UserDefaults.standard.set(savedArchives, forKey: knownArchivesKey)
    }

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

        if !savedArchives.contains(archivePath) {
            savedArchives.append(archivePath)
            persistKnownArchives()
        }
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

        if let idx = savedArchives.firstIndex(of: archivePath) {
            savedArchives.remove(at: idx)
            persistKnownArchives()
        }
    }

    public func clearAllSavedPasswords() {
        for path in savedArchives {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: path
            ]
            SecItemDelete(query as CFDictionary)
        }

        let queryAll: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        SecItemDelete(queryAll as CFDictionary)

        savedArchives.removeAll()
        persistKnownArchives()
    }
}
