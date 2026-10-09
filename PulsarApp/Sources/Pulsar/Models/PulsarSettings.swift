import Foundation
import SwiftUI

public final class PulsarSettings: ObservableObject {
    public static let shared = PulsarSettings()

    @AppStorage("defaultLayoutMode") public var defaultLayoutMode: String = LayoutMode.modernThreePane.rawValue
    @AppStorage("enableFolderWatcher") public var enableFolderWatcher: Bool = false
    @AppStorage("folderWatcherPath") public var folderWatcherPath: String = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? ""
    @AppStorage("autoTrashAfterExtract") public var autoTrashAfterExtract: Bool = false
    @AppStorage("playSounds") public var playSounds: Bool = true
    @AppStorage("sendNotifications") public var sendNotifications: Bool = true
    @AppStorage("savePasswordsToKeychain") public var savePasswordsToKeychain: Bool = true
    @AppStorage("cleanMacMetadataDefault") public var cleanMacMetadataDefault: Bool = true
    @AppStorage("isHUDPinned") public var isHUDPinned: Bool = true
    @AppStorage("hudCorner") public var hudCorner: String = "topRight"

    private init() {}
}
