import Foundation

public enum ConflictResolution: String, CaseIterable, Identifiable {
    case overwrite = "Üzerine Yaz"
    case skip = "Atla"
    case rename = "Yeniden Adlandır (Akıllı Ek)"

    public var id: String { rawValue }
}

public struct ConflictItem: Identifiable, Equatable {
    public let id: UUID
    public let filename: String
    public let destinationDirectory: String
    public let sourceSize: Int64
    public let destinationSize: Int64
    public let sourceDate: Date?
    public let destinationDate: Date?
    public var resolution: ConflictResolution

    public init(
        id: UUID = UUID(),
        filename: String,
        destinationDirectory: String,
        sourceSize: Int64,
        destinationSize: Int64,
        sourceDate: Date? = nil,
        destinationDate: Date? = nil,
        resolution: ConflictResolution = .rename
    ) {
        self.id = id
        self.filename = filename
        self.destinationDirectory = destinationDirectory
        self.sourceSize = sourceSize
        self.destinationSize = destinationSize
        self.sourceDate = sourceDate
        self.destinationDate = destinationDate
        self.resolution = resolution
    }

    public var formattedSourceSize: String {
        ByteCountFormatter.string(fromByteCount: sourceSize, countStyle: .file)
    }

    public var formattedDestinationSize: String {
        ByteCountFormatter.string(fromByteCount: destinationSize, countStyle: .file)
    }

    public var isDestinationNewer: Bool {
        guard let s = sourceDate, let d = destinationDate else { return false }
        return d > s
    }
}
