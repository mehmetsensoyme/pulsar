import Foundation
import SwiftUI

public struct ArchiveItem: Identifiable, Hashable {
    public let id: UUID
    public let path: String
    public let name: String
    public let isDirectory: Bool
    public let size: Int64
    public let compressedSize: Int64
    public let modifiedDate: Date?
    public let isEncrypted: Bool
    public let crc: String
    public let attributes: String

    public init(
        id: UUID = UUID(),
        path: String,
        name: String,
        isDirectory: Bool,
        size: Int64,
        compressedSize: Int64 = 0,
        modifiedDate: Date? = nil,
        isEncrypted: Bool = false,
        crc: String = "",
        attributes: String = ""
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.isDirectory = isDirectory
        self.size = size
        self.compressedSize = compressedSize
        self.modifiedDate = modifiedDate
        self.isEncrypted = isEncrypted
        self.crc = crc
        self.attributes = attributes
    }

    public var formattedSize: String {
        if isDirectory { return "--" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    public var formattedCompressedSize: String {
        if isDirectory || compressedSize == 0 { return "--" }
        return ByteCountFormatter.string(fromByteCount: compressedSize, countStyle: .file)
    }

    public var compressionRatio: Double {
        guard size > 0 && compressedSize > 0 else { return 0 }
        return Double(compressedSize) / Double(size)
    }

    public var compressionRatioPercentage: String {
        if isDirectory || size == 0 { return "--" }
        let pct = (1.0 - compressionRatio) * 100.0
        return String(format: "%%%.1f", max(0, pct))
    }

    public var formattedDate: String {
        guard let date = modifiedDate else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    public var dateValue: Date {
        modifiedDate ?? Date.distantPast
    }

    public var fileExtension: String {
        (name as NSString).pathExtension.lowercased()
    }

    public var iconName: String {
        if isDirectory { return "folder.fill" }
        switch fileExtension {
        case "jpg", "jpeg", "png", "heic", "webp", "gif", "svg":
            return "photo.fill"
        case "mp4", "mov", "mkv", "avi":
            return "film.fill"
        case "mp3", "m4a", "flac", "wav", "aac":
            return "music.note"
        case "pdf":
            return "doc.richtext.fill"
        case "txt", "md", "json", "xml", "csv":
            return "doc.text.fill"
        case "swift", "py", "c", "cpp", "h", "js", "ts", "html", "css", "rs", "go":
            return "curlybraces.square.fill"
        case "zip", "rar", "7z", "tar", "gz", "bz2", "xz", "zst", "lzma", "cab", "wim", "cpio", "rpm", "deb", "arj", "lzh", "001":
            return "doc.zipper"
        case "iso", "img":
            return "opticaldisc.fill"
        case "app", "dmg", "pkg", "xar":
            return "app.dashed"
        default:
            return "doc.fill"
        }
    }

    public var iconColor: Color {
        if isDirectory { return Color.accentColor }
        switch fileExtension {
        case "jpg", "jpeg", "png", "heic", "webp", "gif":
            return .pink
        case "mp4", "mov", "mkv":
            return .purple
        case "mp3", "m4a", "flac":
            return .orange
        case "pdf":
            return .red
        case "swift", "py", "cpp", "rs":
            return .cyan
        case "zip", "rar", "7z":
            return .yellow
        default:
            return .secondary
        }
    }
}

extension String {
    public var abbreviatingWithTilde: String {
        let home = NSHomeDirectory()
        if self.hasPrefix(home) {
            return "~" + self.dropFirst(home.count)
        }
        return self
    }
}
