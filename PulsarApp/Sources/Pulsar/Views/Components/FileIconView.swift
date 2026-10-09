import SwiftUI
import AppKit
import UniformTypeIdentifiers

public final class FileIconCache {
    public static let shared = FileIconCache()
    private var cache = [String: NSImage]()
    private let lock = NSLock()

    private init() {}

    public func icon(forExtension ext: String, isDirectory: Bool) -> NSImage {
        let key = isDirectory ? "__pulsar_folder__" : ext.lowercased()
        lock.lock()
        defer { lock.unlock() }

        if let cached = cache[key] {
            return cached
        }

        let image: NSImage
        if isDirectory {
            image = NSWorkspace.shared.icon(for: .folder)
        } else if !ext.isEmpty, let utType = UTType(filenameExtension: ext) {
            image = NSWorkspace.shared.icon(for: utType)
        } else {
            image = NSWorkspace.shared.icon(for: .data)
        }

        cache[key] = image
        return image
    }
}

public struct FileIconView: View {
    public let item: ArchiveItem?
    public let fileName: String
    public let isDirectory: Bool
    public let size: CGFloat

    public init(item: ArchiveItem, size: CGFloat = 18) {
        self.item = item
        self.fileName = item.name
        self.isDirectory = item.isDirectory
        self.size = size
    }

    public init(fileName: String, isDirectory: Bool = false, size: CGFloat = 18) {
        self.item = nil
        self.fileName = fileName
        self.isDirectory = isDirectory
        self.size = size
    }

    private var nsImage: NSImage {
        let ext = (fileName as NSString).pathExtension
        return FileIconCache.shared.icon(forExtension: ext, isDirectory: isDirectory)
    }

    public var body: some View {
        Image(nsImage: nsImage)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}
