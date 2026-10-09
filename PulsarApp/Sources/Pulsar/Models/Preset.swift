import Foundation

public enum CompressionLevel: String, CaseIterable, Identifiable, Codable {
    case store = "Depolama (0 - Sıkıştırmasız)"
    case fastest = "En Hızlı (1)"
    case fast = "Hızlı (3)"
    case normal = "Normal (5)"
    case maximum = "Maksimum (7)"
    case ultra = "Ultra (9 - En Yüksek)"

    public var id: String { rawValue }

    public var switchLevelNumber: Int {
        switch self {
        case .store: return 0
        case .fastest: return 1
        case .fast: return 3
        case .normal: return 5
        case .maximum: return 7
        case .ultra: return 9
        }
    }
}

public struct Preset: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var format: ArchiveFormat
    public var level: CompressionLevel
    public var cleanMacMetadata: Bool
    public var splitVolumeMB: Int?
    public var encryptFilenames: Bool
    public var solidBlock: Bool
    public var threads: Int

    public init(
        id: UUID = UUID(),
        name: String,
        format: ArchiveFormat,
        level: CompressionLevel = .normal,
        cleanMacMetadata: Bool = true,
        splitVolumeMB: Int? = nil,
        encryptFilenames: Bool = false,
        solidBlock: Bool = true,
        threads: Int = ProcessInfo.processInfo.processorCount
    ) {
        self.id = id
        self.name = name
        self.format = format
        self.level = level
        self.cleanMacMetadata = cleanMacMetadata
        self.splitVolumeMB = splitVolumeMB
        self.encryptFilenames = encryptFilenames
        self.solidBlock = solidBlock
        self.threads = threads
    }

    public static let standardPresets: [Preset] = [
        Preset(
            name: "Windows Dostu Temiz ZIP",
            format: .zip,
            level: .normal,
            cleanMacMetadata: true
        ),
        Preset(
            name: "7-Zip Ultra Maksimum",
            format: .sevenZip,
            level: .ultra,
            cleanMacMetadata: true,
            solidBlock: true
        ),
        Preset(
            name: "Hızlı Paylaşım ZIP",
            format: .zip,
            level: .fastest,
            cleanMacMetadata: true
        ),
        Preset(
            name: "Güvenli Kasa (7z + Şifreli İsimler)",
            format: .sevenZip,
            level: .maximum,
            cleanMacMetadata: true,
            encryptFilenames: true
        ),
        Preset(
            name: "RAR 100MB Parçalı Arşiv",
            format: .rar,
            level: .normal,
            cleanMacMetadata: true,
            splitVolumeMB: 100
        )
    ]
}
