import Foundation
import SwiftUI

public final class PulsarSettings: ObservableObject {
    public static let shared = PulsarSettings()

    // Görünüm ve Genel
    @AppStorage("defaultLayoutMode") public var defaultLayoutMode: String = LayoutMode.modernThreePane.rawValue
    @AppStorage("cleanMacMetadataDefault") public var cleanMacMetadataDefault: Bool = true
    @AppStorage("playSounds") public var playSounds: Bool = true
    @AppStorage("sendNotifications") public var sendNotifications: Bool = true

    // İlk Kurulum, Tema ve Kişiselleştirme
    @AppStorage("hasCompletedOnboarding") public var hasCompletedOnboarding: Bool = false
    @AppStorage("selectedTheme") public var selectedTheme: String = "system" // system, dark, light
    @AppStorage("accentColorChoice") public var accentColorChoice: String = "cyan" // cyan, purple, orange, green, blue
    @AppStorage("uiScale") public var uiScale: String = "standard" // compact, standard, spacious
    @AppStorage("selectedLanguage") public var selectedLanguage: String = "auto" // auto, en, tr, or custom

    public var resolvedAccentColor: Color {
        switch accentColorChoice {
        case "purple": return Color(red: 0.65, green: 0.35, blue: 0.95)
        case "orange": return Color(red: 1.0, green: 0.58, blue: 0.0)
        case "green": return Color(red: 0.2, green: 0.78, blue: 0.35)
        case "blue": return Color(red: 0.0, green: 0.48, blue: 1.0)
        default: return Color(red: 0.0, green: 0.75, blue: 0.95) // Pulsar Cyan
        }
    }

    public var resolvedColorScheme: ColorScheme? {
        switch selectedTheme {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }

    public var contentRowPadding: CGFloat {
        switch uiScale {
        case "compact": return 2
        case "spacious": return 8
        default: return 5
        }
    }

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
