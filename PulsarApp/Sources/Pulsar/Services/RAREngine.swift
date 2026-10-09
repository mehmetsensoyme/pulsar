import Foundation

private final class RAROutputAccumulator: @unchecked Sendable {
    private let lock = NSLock()
    private var text = ""

    func append(_ str: String) {
        lock.lock()
        text += str
        lock.unlock()
    }

    func value() -> String {
        lock.lock()
        defer { lock.unlock() }
        return text
    }
}

public final class RAREngine: @unchecked Sendable {
    public static let shared = RAREngine()
    private let locator = EngineLocator.shared
    private let lock = NSLock()
    private var activeProcesses: [UUID: Process] = [:]

    private init() {}

    /// Aktif bir RAR CLI sürecini sonlandırır
    public func cancelProcess(for taskId: UUID) {
        lock.lock()
        let process = activeProcesses.removeValue(forKey: taskId)
        lock.unlock()

        process?.terminate()
    }

    /// RARLAB resmi rar motoru ile yeni .rar arşivi oluşturur
    public func createArchive(
        taskId: UUID = UUID(),
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

        _ = try await runProcess(taskId: taskId, binary: binary, arguments: args) { line in
            if let pct = self.parsePercentage(from: line) {
                progress?(pct, line)
            }
        }
    }

    /// Bozuk veya hasarlı RAR arşivini kurtarma kaydıyla onarır
    public func repairArchive(taskId: UUID = UUID(), at archivePath: String) async throws -> (success: Bool, log: String) {
        let binary = locator.pathForRar()
        let dir = (archivePath as NSString).deletingLastPathComponent
        let args = ["r", archivePath]

        let output = try await runProcess(taskId: taskId, binary: binary, arguments: args, workingDirectory: dir)
        let success = output.contains("Done") || output.contains("rebuilt") || output.contains("fixed")
        return (success, output)
    }

    /// RAR arşivini unrar ile çıkarır (Bozuk dosyaları koruma seçeneği ile)
    public func extract(
        taskId: UUID = UUID(),
        archiveAt path: String,
        to destinationDirectory: String,
        password: String? = nil,
        keepBrokenFiles: Bool = true,
        requiredDiskBytes: Int64 = 0,
        progress: ((Double, String) -> Void)? = nil
    ) async throws {
        if requiredDiskBytes > 0 {
            try DiskSpaceGuard.shared.validateSpace(forRequiredBytes: requiredDiskBytes, atDestination: destinationDirectory)
        }

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

        _ = try await runProcess(taskId: taskId, binary: binary, arguments: args) { line in
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
        taskId: UUID? = nil,
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
                process.standardInput = FileHandle.nullDevice

                if let wd = workingDirectory {
                    process.currentDirectoryURL = URL(fileURLWithPath: wd)
                }

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                if let tid = taskId {
                    self.lock.lock()
                    self.activeProcesses[tid] = process
                    self.lock.unlock()
                }

                let accumulator = RAROutputAccumulator()
                let handle = pipe.fileHandleForReading

                handle.readabilityHandler = { fh in
                    let data = fh.availableData
                    if data.isEmpty { return }
                    if let str = String(data: data, encoding: .utf8) {
                        accumulator.append(str)
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
                    let fullOutput = accumulator.value()

                    if let tid = taskId {
                        self.lock.lock()
                        self.activeProcesses.removeValue(forKey: tid)
                        self.lock.unlock()
                    }

                    if process.terminationStatus == 0 || process.terminationStatus == 1 {
                        continuation.resume(returning: fullOutput)
                    } else if process.terminationReason == .uncaughtSignal {
                        let err = NSError(
                            domain: "PulsarRAR",
                            code: -999,
                            userInfo: [NSLocalizedDescriptionKey: "İşlem kullanıcı tarafından iptal edildi."]
                        )
                        continuation.resume(throwing: err)
                    } else {
                        let err = NSError(
                            domain: "PulsarRAR",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: "RAR motoru işlem tamamlayamadı: \(process.terminationStatus)\n\(fullOutput)"]
                        )
                        continuation.resume(throwing: err)
                    }
                } catch {
                    if let tid = taskId {
                        self.lock.lock()
                        self.activeProcesses.removeValue(forKey: tid)
                        self.lock.unlock()
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
