import Foundation
import SwiftUI

public final class PulsarSettings: ObservableObject {
    public static let shared = PulsarSettings()

    // Görünüm ve Genel
    @AppStorage("defaultLayoutMode") public var defaultLayoutMode: String = LayoutMode.modernThreePane.rawValue
    @AppStorage("cleanMacMetadataDefault") public var cleanMacMetadataDefault: Bool = true
    @AppStorage("playSounds") public var playSounds: Bool = true
    @AppStorage("sendNotifications") public var sendNotifications: Bool = true

    // Sıkıştırma ve Motorlar
    @AppStorage("defaultCompressionFormat") public var defaultCompressionFormat: String = "zip"
    @AppStorage("defaultCompressionLevel") public var defaultCompressionLevel: String = "normal"
    @AppStorage("maxCpuThreads") public var maxCpuThreads: Int = ProcessInfo.processInfo.processorCount

    // Güvenlik ve Gizlilik
    @AppStorage("savePasswordsToKeychain") public var savePasswordsToKeychain: Bool = true
    @AppStorage("startInReadOnlyMode") public var startInReadOnlyMode: Bool = true
    @AppStorage("autoCleanTempCacheOnExit") public var autoCleanTempCacheOnExit: Bool = true
    @AppStorage("confirmBeforeDelete") public var confirmBeforeDelete: Bool = true

    // Kara Delik Klasör İzleyici
    @AppStorage("enableFolderWatcher") public var enableFolderWatcher: Bool = false
    @AppStorage("folderWatcherPath") public var folderWatcherPath: String = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? ""
    @AppStorage("autoTrashAfterExtract") public var autoTrashAfterExtract: Bool = false

    // Yüzen HUD Widget
    @AppStorage("isHUDPinned") public var isHUDPinned: Bool = true
    @AppStorage("hudCorner") public var hudCorner: String = "topRight"
    @AppStorage("hudAlwaysOnTop") public var hudAlwaysOnTop: Bool = true

    private init() {}
}
