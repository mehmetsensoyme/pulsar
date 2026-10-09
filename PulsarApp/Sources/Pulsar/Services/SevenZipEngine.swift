import Foundation

public final class SevenZipEngine {
    public static let shared = SevenZipEngine()
    private let locator = EngineLocator.shared

    private init() {}

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
        archiveAt path: String,
        to destinationDirectory: String,
        selectedFiles: [String]? = nil,
        password: String? = nil,
        progress: ((Double, String) -> Void)? = nil
    ) async throws {
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

        _ = try await runProcess(binary: binary, arguments: args) { line in
            if let pct = self.parsePercentage(from: line) {
                progress?(pct, line)
            }
        }
    }

    /// Yeni arşiv oluşturur
    public func createArchive(
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

        _ = try await runProcess(binary: binary, arguments: args) { line in
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
    public func addItems(to archivePath: String, itemsToAdd: [String], cleanMacMetadata: Bool = true) async throws {
        let binary = locator.pathForSevenZip()
        var args = ["a", archivePath]
        if cleanMacMetadata {
            args.append("-xr!.DS_Store")
            args.append("-xr!__MACOSX")
            args.append("-xr!._*")
        }
        args.append(contentsOf: itemsToAdd)
        _ = try await runProcess(binary: binary, arguments: args)
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
        binary: String,
        arguments: [String],
        onOutputLine: ((String) -> Void)? = nil
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: binary)
                process.arguments = arguments

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
                            domain: "PulsarSevenZip",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: "7-Zip hata kodu: \(process.terminationStatus)\n\(fullOutput)"]
                        )
                        continuation.resume(throwing: err)
                    }
                } catch {
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

            guard let path = dict["Path"], !path.isEmpty else { continue }

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

        return items
    }
}
