import Foundation

public enum DiffStatus: String, CaseIterable {
    case added = "Eklenen"
    case removed = "Silinen"
    case modified = "Değiştirilen"
    case identical = "Eşleşen"

    public var iconName: String {
        switch self {
        case .added: return "plus.circle.fill"
        case .removed: return "minus.circle.fill"
        case .modified: return "arrow.triangle.2.circlepath.circle.fill"
        case .identical: return "checkmark.circle.fill"
        }
    }
}

public struct DiffItem: Identifiable, Hashable {
    public var id: String { path }
    public let path: String
    public let status: DiffStatus
    public let isDirectory: Bool
    public let sizeA: Int64?
    public let sizeB: Int64?
    public let dateA: String?
    public let dateB: String?

    public var name: String {
        return (path as NSString).lastPathComponent
    }

    public var formattedSizeA: String {
        guard let s = sizeA else { return "-" }
        return ArchiveItem.formatBytes(s)
    }

    public var formattedSizeB: String {
        guard let s = sizeB else { return "-" }
        return ArchiveItem.formatBytes(s)
    }

    public var formattedSizeDiff: String {
        let a = sizeA ?? 0
        let b = sizeB ?? 0
        let diff = b - a
        if diff > 0 {
            return "+\(ArchiveItem.formatBytes(diff))"
        } else if diff < 0 {
            return "-\(ArchiveItem.formatBytes(abs(diff)))"
        } else {
            return "0 B"
        }
    }
}

public struct ArchiveDiffResult {
    public let archiveAPath: String
    public let archiveBPath: String
    public let items: [DiffItem]
    public let addedCount: Int
    public let removedCount: Int
    public let modifiedCount: Int
    public let identicalCount: Int
    public let netSizeChange: Int64

    public var archiveAName: String {
        (archiveAPath as NSString).lastPathComponent
    }

    public var archiveBName: String {
        (archiveBPath as NSString).lastPathComponent
    }

    public func generateMarkdownReport() -> String {
        var report = "# Pulsar Arşiv Karşılaştırma Raporu\n\n"
        report += "- **Kaynak Arşiv A:** `\(archiveAName)`\n"
        report += "- **Hedef Arşiv B:** `\(archiveBName)`\n"
        report += "- **Eklenen Dosyalar:** \(addedCount)\n"
        report += "- **Silinen Dosyalar:** \(removedCount)\n"
        report += "- **Değiştirilen Dosyalar:** \(modifiedCount)\n"
        report += "- **Eşleşen Dosyalar:** \(identicalCount)\n"
        report += "- **Net Boyut Değişimi:** \(ArchiveItem.formatBytes(abs(netSizeChange))) (\(netSizeChange >= 0 ? "+" : "-"))\n\n"

        report += "## Ayrıntılı Değişiklikler\n\n"
        report += "| Durum | Dosya Yolu | Arşiv A | Arşiv B | Fark |\n"
        report += "| :--- | :--- | :--- | :--- | :--- |\n"
        for item in items.filter({ $0.status != .identical }) {
            report += "| \(item.status.rawValue) | `\(item.path)` | \(item.formattedSizeA) | \(item.formattedSizeB) | \(item.formattedSizeDiff) |\n"
        }
        return report
    }
}

public final class ArchiveDiffService {
    public static let shared = ArchiveDiffService()
    private let engine = SevenZipEngine.shared

    private init() {}

    public func compareArchives(archiveAPath: String, archiveBPath: String) async throws -> ArchiveDiffResult {
        let itemsA = try await engine.listArchive(at: archiveAPath)
        let itemsB = try await engine.listArchive(at: archiveBPath)

        return computeDiff(itemsA: itemsA, itemsB: itemsB, pathA: archiveAPath, pathB: archiveBPath)
    }

    public func computeDiff(itemsA: [ArchiveItem], itemsB: [ArchiveItem], pathA: String, pathB: String) -> ArchiveDiffResult {
        let mapA = Dictionary(uniqueKeysWithValues: itemsA.map { ($0.path, $0) })
        let mapB = Dictionary(uniqueKeysWithValues: itemsB.map { ($0.path, $0) })

        let allPaths = Set(mapA.keys).union(Set(mapB.keys)).sorted()
        var diffItems: [DiffItem] = []

        var added = 0
        var removed = 0
        var modified = 0
        var identical = 0
        var netDiff: Int64 = 0

        for path in allPaths {
            let itemA = mapA[path]
            let itemB = mapB[path]

            if let a = itemA, let b = itemB {
                if a.isDirectory && b.isDirectory {
                    identical += 1
                    diffItems.append(DiffItem(path: path, status: .identical, isDirectory: true, sizeA: 0, sizeB: 0, dateA: a.formattedDate, dateB: b.formattedDate))
                } else if a.size == b.size {
                    identical += 1
                    diffItems.append(DiffItem(path: path, status: .identical, isDirectory: false, sizeA: a.size, sizeB: b.size, dateA: a.formattedDate, dateB: b.formattedDate))
                } else {
                    modified += 1
                    let delta = b.size - a.size
                    netDiff += delta
                    diffItems.append(DiffItem(path: path, status: .modified, isDirectory: false, sizeA: a.size, sizeB: b.size, dateA: a.formattedDate, dateB: b.formattedDate))
                }
            } else if let b = itemB {
                added += 1
                netDiff += b.size
                diffItems.append(DiffItem(path: path, status: .added, isDirectory: b.isDirectory, sizeA: nil, sizeB: b.size, dateA: nil, dateB: b.formattedDate))
            } else if let a = itemA {
                removed += 1
                netDiff -= a.size
                diffItems.append(DiffItem(path: path, status: .removed, isDirectory: a.isDirectory, sizeA: a.size, sizeB: nil, dateA: a.formattedDate, dateB: nil))
            }
        }

        return ArchiveDiffResult(
            archiveAPath: pathA,
            archiveBPath: pathB,
            items: diffItems,
            addedCount: added,
            removedCount: removed,
            modifiedCount: modified,
            identicalCount: identical,
            netSizeChange: netDiff
        )
    }
}
