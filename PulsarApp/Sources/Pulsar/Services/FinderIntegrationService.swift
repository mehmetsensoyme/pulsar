import Foundation
import AppKit

public final class FinderIntegrationService: ObservableObject {
    public static let shared = FinderIntegrationService()

    public let servicesDir: URL

    @Published public var isInstalled: Bool = false

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        servicesDir = home.appendingPathComponent("Library/Services")
        checkInstallationStatus()
    }

    public func checkInstallationStatus() {
        let compressPath = servicesDir.appendingPathComponent("Pulsar ile Sıkıştır.workflow").path
        let extractPath = servicesDir.appendingPathComponent("Pulsar ile Çıkar.workflow").path
        let installed = FileManager.default.fileExists(atPath: compressPath) && FileManager.default.fileExists(atPath: extractPath)
        DispatchQueue.main.async {
            self.isInstalled = installed
        }
    }

    public func installQuickActions() throws {
        try FileManager.default.createDirectory(at: servicesDir, withIntermediateDirectories: true)

        let appPath = "/Applications/Pulsar.app"

        // 1. "Pulsar ile Sıkıştır" Hızlı Eylemi
        let compressWorkflow = servicesDir.appendingPathComponent("Pulsar ile Sıkıştır.workflow")
        try createWorkflowBundle(
            at: compressWorkflow,
            name: "Pulsar ile Sıkıştır",
            scriptContent: """
            on run {input, parameters}
                set fileList to {}
                repeat with f in input
                    copy (POSIX path of f) to end of fileList
                end repeat
                tell application "\(appPath)"
                    activate
                    open input
                end tell
                return input
            end run
            """
        )

        // 2. "Pulsar ile Çıkar" Hızlı Eylemi
        let extractWorkflow = servicesDir.appendingPathComponent("Pulsar ile Çıkar.workflow")
        try createWorkflowBundle(
            at: extractWorkflow,
            name: "Pulsar ile Çıkar",
            scriptContent: """
            on run {input, parameters}
                tell application "\(appPath)"
                    activate
                    open input
                end tell
                return input
            end run
            """
        )

        checkInstallationStatus()
    }

    public func uninstallQuickActions() {
        let compressWorkflow = servicesDir.appendingPathComponent("Pulsar ile Sıkıştır.workflow")
        let extractWorkflow = servicesDir.appendingPathComponent("Pulsar ile Çıkar.workflow")

        try? FileManager.default.removeItem(at: compressWorkflow)
        try? FileManager.default.removeItem(at: extractWorkflow)

        checkInstallationStatus()
    }

    private func createWorkflowBundle(at url: URL, name: String, scriptContent: String) throws {
        try? FileManager.default.removeItem(at: url)
        let contentsDir = url.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contentsDir, withIntermediateDirectories: true)

        // Info.plist
        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>NSServices</key>
            <array>
                <dict>
                    <key>NSMenuItem</key>
                    <dict>
                        <key>default</key>
                        <string>\(name)</string>
                    </dict>
                    <key>NSMessage</key>
                    <string>runWorkflowAsService</string>
                    <key>NSSendFileTypes</key>
                    <array>
                        <string>public.item</string>
                    </array>
                </dict>
            </array>
        </dict>
        </plist>
        """
        try infoPlist.write(to: contentsDir.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)

        // document.wflow
        let documentWflow = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>AMApplicationBuild</key>
            <string>523</string>
            <key>AMApplicationVersion</key>
            <string>2.10</string>
            <key>AMDocumentVersion</key>
            <string>2</string>
            <key>actions</key>
            <array>
                <dict>
                    <key>action</key>
                    <dict>
                        <key>AMAccepts</key>
                        <dict>
                            <key>Container</key>
                            <string>List</string>
                            <key>Types</key>
                            <array>
                                <string>com.apple.cocoa.path</string>
                            </array>
                        </dict>
                        <key>AMActionVersion</key>
                        <string>1.0.2</string>
                        <key>ActionBundlePath</key>
                        <string>/System/Library/Automator/Run AppleScript.action</string>
                        <key>ActionName</key>
                        <string>Run AppleScript</string>
                        <key>ActionParameters</key>
                        <dict>
                            <key>source</key>
                            <string>\(scriptContent.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</string>
                        </dict>
                        <key>BundleIdentifier</key>
                        <string>com.apple.Automator.RunScript</string>
                    </dict>
                </dict>
            </array>
        </dict>
        </plist>
        """
        try documentWflow.write(to: contentsDir.appendingPathComponent("document.wflow"), atomically: true, encoding: .utf8)
    }
}
