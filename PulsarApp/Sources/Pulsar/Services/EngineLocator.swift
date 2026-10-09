import Foundation

public final class EngineLocator {
    public static let shared = EngineLocator()

    private init() {}

    public func pathForSevenZip() -> String {
        return findBinary(named: "7zz")
    }

    public func pathForRar() -> String {
        return findBinary(named: "rar")
    }

    public func pathForRAR() -> String {
        return pathForRar()
    }

    public func pathForUnrar() -> String {
        return findBinary(named: "unrar")
    }

    private func findBinary(named name: String) -> String {
        let fm = FileManager.default

        // 1. Bundle Resources/bin
        if let bundleBin = Bundle.main.resourceURL?.appendingPathComponent("bin").appendingPathComponent(name).path,
           fm.isExecutableFile(atPath: bundleBin) {
            return bundleBin
        }

        // 2. Bundle Contents/Resources/bin
        if let bundleDir = Bundle.main.resourcePath {
            let direct = (bundleDir as NSString).appendingPathComponent("bin/\(name)")
            if fm.isExecutableFile(atPath: direct) {
                return direct
            }
        }

        // 3. Relative to executable
        let exeDir = (CommandLine.arguments[0] as NSString).deletingLastPathComponent
        let relativeBin = (exeDir as NSString).appendingPathComponent("../../../Engines/bin/\(name)")
        let standardized = (relativeBin as NSString).standardizingPath
        if fm.isExecutableFile(atPath: standardized) {
            return standardized
        }

        // 4. Development path relative to current working directory
        let cwdBin = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent("Engines/bin/\(name)")
        if fm.isExecutableFile(atPath: cwdBin) {
            return cwdBin
        }

        // 5. System PATH fallback
        return name
    }
}
