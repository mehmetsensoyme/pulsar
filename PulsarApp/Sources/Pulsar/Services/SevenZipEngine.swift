import Foundation

private final class SevenZipOutputAccumulator: @unchecked Sendable {
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

public final class SevenZipEngine: @unchecked Sendable {
    public static let shared = SevenZipEngine()
    private let locator = EngineLocator.shared
    private let lock = NSLock()
    private var activeProcesses: [UUID: Process] = [:]

    private init() {}

    /// Aktif bir CLI sürecini anında sonlandırır
    public func cancelProcess(for taskId: UUID) {
        lock.lock()
        let process = activeProcesses.removeValue(forKey: taskId)
        lock.unlock()

        process?.terminate()
    }

    /// Arşiv içeriğini listeler
    public func listArchive(at path: String, password: String? = nil) async throws -> [ArchiveItem] {
        let binary = locator.pathForSevenZip()
        var args = ["l", "-slt", "-ba", path]
        if let pwd = password, !pwd.isEmpty {
            args.append("-p\(pwd)")
        } else {
            args.append("-p-")
        }

        let output = try await runProcess(binary: binary, arguments: args)
        return parseSltOutput(output)
    }

    /// Arşivi çıkartır
    public func extract(
        taskId: UUID = UUID(),
        archiveAt path: String,
        to destinationDirectory: String,
        selectedFiles: [String]? = nil,
        password: String? = nil,
        requiredDiskBytes: Int64 = 0,
        progress: ((Double, String) -> Void)? = nil
    ) async throws {
        // Disk alanı kontrolü
        if requiredDiskBytes > 0 {
            try DiskSpaceGuard.shared.validateSpace(forRequiredBytes: requiredDiskBytes, atDestination: destinationDirectory)
        }

        let binary = locator.pathForSevenZip()
        var args = ["x", "-y", "-o\(destinationDirectory)", path]
        if let pwd = password, !pwd.isEmpty {
            args.append("-p\(pwd)")
        } else {
            args.append("-p-")
        }

        if let files = selectedFiles, !files.isEmpty {
            args.append(contentsOf: files)
        }

        _ = try await runProcess(taskId: taskId, binary: binary, arguments: args) { line in
            if let pct = self.parsePercentage(from: line) {
                progress?(pct, line)
            }
        }
    }

    /// Finder'a sürükle-bırak için senkron tek/çoklu dosya çıkarma
    public func extractSync(
        archiveAt path: String,
        to destinationDirectory: String,
        selectedFiles: [String]? = nil,
        password: String? = nil
    ) {
        let binary = locator.pathForSevenZip()
        var args = ["x", "-y", "-o\(destinationDirectory)", path]
        if let pwd = password, !pwd.isEmpty {
            args.append("-p\(pwd)")
        } else {
            args.append("-p-")
        }
        if let files = selectedFiles, !files.isEmpty {
            args.append(contentsOf: files)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = args
        try? process.run()
        process.waitUntilExit()
    }

    /// Yeni arşiv oluşturur
    public func createArchive(
        taskId: UUID = UUID(),
        at destinationPath: String,
        from sourcePaths: [String],
        preset: Preset,
        password: String? = nil,
        progress: ((Double, String) -> Void)? = nil
    ) async throws {
        let binary = locator.pathForSevenZip()
        var args = ["a", destinationPath]

        // Sıkıştırma seviyesi
        args.append("-mx=\(preset.level.switchLevelNumber)")

        // Çoklu iş parçacığı (Threads)
        args.append("-mmt=\(preset.threads)")

        // Katı blok (Solid)
        if preset.format == .sevenZip {
            args.append(preset.solidBlock ? "-ms=on" : "-ms=off")
        }

        // Parçalara bölme (Split volumes)
        if let split = preset.splitVolumeMB, split > 0 {
            args.append("-v\(split)m")
        }

        // Şifreleme ve başlık şifreleme
        if let pwd = password, !pwd.isEmpty {
            args.append("-p\(pwd)")
            if preset.encryptFilenames && preset.format == .sevenZip {
                args.append("-mhe=on")
            }
        }

        // macOS Özel dosyalarını filtreleme
        if preset.cleanMacMetadata {
            args.append("-xr!.DS_Store")
            args.append("-xr!__MACOSX")
            args.append("-xr!._*")
            args.append("-xr!.Spotlight-V100")
            args.append("-xr!.Trashes")
        }

        args.append(contentsOf: sourcePaths)

        _ = try await runProcess(taskId: taskId, binary: binary, arguments: args) { line in
            if let pct = self.parsePercentage(from: line) {
                progress?(pct, line)
            }
        }
    }

    /// Arşivden dosya siler (Düzenleme modu)
    public func deleteItems(from archivePath: String, itemPaths: [String]) async throws {
        let binary = locator.pathForSevenZip()
        var args = ["d", archivePath]
        args.append(contentsOf: itemPaths)
        _ = try await runProcess(binary: binary, arguments: args)
    }

    /// Arşive dosya ekler (Düzenleme modu)
    public func addItems(
        to archivePath: String,
        itemsToAdd: [String],
        targetSubfolder: String? = nil,
        cleanMacMetadata: Bool = true
    ) async throws {
        let binary = locator.pathForSevenZip()
        var args = ["a", archivePath]
        if cleanMacMetadata {
            args.append("-xr!.DS_Store")
            args.append("-xr!__MACOSX")
            args.append("-xr!._*")
        }

        let trimmedSubfolder = targetSubfolder?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
        if !trimmedSubfolder.isEmpty {
            // Hedef alt dizine ekleme: Staging klasörü ve rölatif yollar
            let stagingDir = NSTemporaryDirectory().appending("PulsarStage_\(UUID().uuidString)")
            let destSubDir = (stagingDir as NSString).appendingPathComponent(trimmedSubfolder)
            try? FileManager.default.createDirectory(atPath: destSubDir, withIntermediateDirectories: true)
            TempCacheManager.shared.registerTempDirectory(stagingDir)

            var relativeItems: [String] = []
            for item in itemsToAdd {
                let filename = (item as NSString).lastPathComponent
                let stagedPath = (destSubDir as NSString).appendingPathComponent(filename)
                if (try? FileManager.default.linkItem(atPath: item, toPath: stagedPath)) == nil {
                    try? FileManager.default.copyItem(atPath: item, toPath: stagedPath)
                }
                relativeItems.append("\(trimmedSubfolder)/\(filename)")
            }
            args.append(contentsOf: relativeItems)
            _ = try await runProcess(binary: binary, arguments: args, workingDirectory: stagingDir)
        } else {
            args.append(contentsOf: itemsToAdd)
            _ = try await runProcess(binary: binary, arguments: args)
        }
    }

    /// Arşiv bütünlüğünü test eder
    public func testArchive(at archivePath: String, password: String? = nil) async throws -> Bool {
        let binary = locator.pathForSevenZip()
        var args = ["t", archivePath]
        if let pwd = password, !pwd.isEmpty {
            args.append("-p\(pwd)")
        } else {
            args.append("-p-")
        }
        let output = try await runProcess(binary: binary, arguments: args)
        return output.contains("Everything is Ok")
    }

    // MARK: - Process Runner
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
                if let wd = workingDirectory {
                    process.currentDirectoryURL = URL(fileURLWithPath: wd)
                }
                // Donma koruması: stdin'i kapat
                process.standardInput = FileHandle.nullDevice

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                if let tid = taskId {
                    self.lock.lock()
                    self.activeProcesses[tid] = process
                    self.lock.unlock()
                }

                let accumulator = SevenZipOutputAccumulator()
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
                            domain: "PulsarSevenZip",
                            code: -999,
                            userInfo: [NSLocalizedDescriptionKey: "İşlem kullanıcı tarafından iptal edildi."]
                        )
                        continuation.resume(throwing: err)
                    } else {
                        let err = NSError(
                            domain: "PulsarSevenZip",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: "7-Zip hata kodu: \(process.terminationStatus)\n\(fullOutput)"]
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

    // MARK: - Parsers
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

    private func parseSltOutput(_ raw: String) -> [ArchiveItem] {
        var items: [ArchiveItem] = []
        let blocks = raw.components(separatedBy: "\n\n")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        for block in blocks {
            let lines = block.components(separatedBy: .newlines)
            var dict: [String: String] = [:]

            for line in lines {
                let parts = line.split(separator: "=", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 {
                    dict[parts[0]] = parts[1]
                }
            }

            guard let rawPath = dict["Path"], !rawPath.isEmpty else { continue }
            // Windows ters eğik çizgilerini macOS standardı / ile normalize et
            let path = rawPath.replacingOccurrences(of: "\\", with: "/").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !path.isEmpty else { continue }

            let isFolder = dict["Folder"] == "+"
            let size = Int64(dict["Size"] ?? "0") ?? 0
            let packedSize = Int64(dict["Packed Size"] ?? "0") ?? 0
            let isEncrypted = dict["Encrypted"] == "+"
            let crc = dict["CRC"] ?? ""
            let attributes = dict["Attributes"] ?? ""

            var date: Date? = nil
            if let modStr = dict["Modified"] {
                date = dateFormatter.date(from: modStr)
            }

            let name = (path as NSString).lastPathComponent

            let item = ArchiveItem(
                path: path,
                name: name.isEmpty ? path : name,
                isDirectory: isFolder,
                size: size,
                compressedSize: packedSize,
                modifiedDate: date,
                isEncrypted: isEncrypted,
                crc: crc,
                attributes: attributes
            )
            items.append(item)
        }

        return synthesizeMissingDirectories(from: items)
    }

    private func synthesizeMissingDirectories(from items: [ArchiveItem]) -> [ArchiveItem] {
        var existingPaths = Set(items.map { $0.path })
        var synthesized: [ArchiveItem] = []

        for item in items {
            let components = item.path.split(separator: "/").map { String($0) }
            if components.count > 1 {
                var currentPath = ""
                for i in 0..<(components.count - 1) {
                    let part = components[i]
                    currentPath = currentPath.isEmpty ? part : "\(currentPath)/\(part)"
                    if !existingPaths.contains(currentPath) {
                        existingPaths.insert(currentPath)
                        synthesized.append(
                            ArchiveItem(
                                path: currentPath,
                                name: part,
                                isDirectory: true,
                                size: 0,
                                compressedSize: 0,
                                modifiedDate: item.modifiedDate,
                                attributes: "D"
                            )
                        )
                    }
                }
            }
        }
        return items + synthesized
    }
}
