import Foundation

public final class RAREngine {
    public static let shared = RAREngine()
    private let locator = EngineLocator.shared

    private init() {}

    /// RARLAB resmi rar motoru ile yeni .rar arşivi oluşturur
    public func createArchive(
        at destinationPath: String,
        from sourcePaths: [String],
        preset: Preset,
        password: String? = nil,
        recoveryRecordPercent: Int = 3,
        progress: ((Double, String) -> Void)? = nil
    ) async throws {
        let binary = locator.pathForRar()
        var args = ["a"]

        // Sıkıştırma seviyesi (m0-m5)
        let rarLevel = min(5, preset.level.switchLevelNumber / 2)
        args.append("-m\(rarLevel)")

        // Kurtarma kaydı (%3 varsayılan)
        if recoveryRecordPercent > 0 {
            args.append("-rr\(recoveryRecordPercent)p")
        }

        // Parçalara bölme
        if let split = preset.splitVolumeMB, split > 0 {
            args.append("-v\(split)m")
        }

        // Şifreleme
        if let pwd = password, !pwd.isEmpty {
            if preset.encryptFilenames {
                args.append("-hp\(pwd)") // Başlık şifreleme
            } else {
                args.append("-p\(pwd)")
            }
        }

        // macOS Özel dosyaları filtreleme
        if preset.cleanMacMetadata {
            args.append("-x*.DS_Store")
            args.append("-x*__MACOSX*")
            args.append("-x*._*")
        }

        args.append(destinationPath)
        args.append(contentsOf: sourcePaths)

        _ = try await runProcess(binary: binary, arguments: args) { line in
            // Parse progress percentage if available
            if let pct = self.parsePercentage(from: line) {
                progress?(pct, line)
            }
        }
    }

    /// Bozuk veya hasarlı RAR arşivini kurtarma kaydıyla onarır
    public func repairArchive(at archivePath: String) async throws -> (success: Bool, log: String) {
        let binary = locator.pathForRar()
        let dir = (archivePath as NSString).deletingLastPathComponent
        let args = ["r", archivePath]

        let output = try await runProcess(binary: binary, arguments: args, workingDirectory: dir)
        let success = output.contains("Done") || output.contains("rebuilt") || output.contains("fixed")
        return (success, output)
    }

    /// RAR arşivini unrar ile çıkarır (Bozuk dosyaları koruma seçeneği ile)
    public func extract(
        archiveAt path: String,
        to destinationDirectory: String,
        password: String? = nil,
        keepBrokenFiles: Bool = true,
        progress: ((Double, String) -> Void)? = nil
    ) async throws {
        let binary = locator.pathForUnrar()
        var args = ["x", "-y"]

        if keepBrokenFiles {
            args.append("-kb")
        }

        if let pwd = password, !pwd.isEmpty {
            args.append("-p\(pwd)")
        } else {
            args.append("-p-")
        }

        args.append(path)
        var dest = destinationDirectory
        if !dest.hasSuffix("/") { dest += "/" }
        args.append(dest)

        _ = try await runProcess(binary: binary, arguments: args) { line in
            if let pct = self.parsePercentage(from: line) {
                progress?(pct, line)
            }
        }
    }

    private func parsePercentage(from line: String) -> Double? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix("%") {
            let digits = trimmed.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
            if let val = Double(digits) {
                return val / 100.0
            }
        }
        return nil
    }

    private func runProcess(
        binary: String,
        arguments: [String],
        workingDirectory: String? = nil,
        onOutputLine: ((String) -> Void)? = nil
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: binary)
                process.arguments = arguments
                if let wd = workingDirectory {
                    process.currentDirectoryURL = URL(fileURLWithPath: wd)
                }

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                var fullOutput = ""
                let handle = pipe.fileHandleForReading

                handle.readabilityHandler = { fh in
                    let data = fh.availableData
                    if data.isEmpty { return }
                    if let str = String(data: data, encoding: .utf8) {
                        fullOutput += str
                        let lines = str.components(separatedBy: .newlines)
                        for line in lines where !line.isEmpty {
                            onOutputLine?(line)
                        }
                    }
                }

                do {
                    try process.run()
                    process.waitUntilExit()
                    handle.readabilityHandler = nil

                    if process.terminationStatus == 0 || process.terminationStatus == 1 {
                        continuation.resume(returning: fullOutput)
                    } else {
                        let err = NSError(
                            domain: "PulsarRAR",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: "RAR motoru işlem tamamlayamadı: \(process.terminationStatus)\n\(fullOutput)"]
                        )
                        continuation.resume(throwing: err)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
