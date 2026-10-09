import Foundation

public enum TaskType: String {
    case extract = "Çıkarma"
    case compress = "Sıkıştırma"
    case benchmark = "Warp Core Hız Testi"
    case repair = "Onarım"
    case testArchive = "Bütünlük Testi"

    public var iconName: String {
        switch self {
        case .extract: return "arrow.up.bin.fill"
        case .compress: return "arrow.down.doc.fill"
        case .benchmark: return "bolt.shield.fill"
        case .repair: return "wrench.and.screwdriver.fill"
        case .testArchive: return "checkmark.shield.fill"
        }
    }
}

public enum TaskStatus: Equatable {
    case idle
    case running
    case paused
    case completed
    case failed(String)
}

public struct TaskProgress: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var type: TaskType
    public var percent: Double // 0.0 ... 1.0
    public var bytesProcessed: Int64
    public var totalBytes: Int64
    public var currentSpeedMBs: Double
    public var remainingSeconds: Int
    public var status: TaskStatus
    public var archivePath: String
    public var currentFilename: String

    public init(
        id: UUID = UUID(),
        title: String,
        type: TaskType,
        percent: Double = 0.0,
        bytesProcessed: Int64 = 0,
        totalBytes: Int64 = 0,
        currentSpeedMBs: Double = 0.0,
        remainingSeconds: Int = 0,
        status: TaskStatus = .idle,
        archivePath: String = "",
        currentFilename: String = ""
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.percent = percent
        self.bytesProcessed = bytesProcessed
        self.totalBytes = totalBytes
        self.currentSpeedMBs = currentSpeedMBs
        self.remainingSeconds = remainingSeconds
        self.status = status
        self.archivePath = archivePath
        self.currentFilename = currentFilename
    }

    public var formattedSpeed: String {
        if currentSpeedMBs <= 0 { return "-- MB/s" }
        return String(format: "%.1f MB/s", currentSpeedMBs)
    }

    public var formattedRemainingTime: String {
        if remainingSeconds <= 0 { return "Hesaplanıyor..." }
        if remainingSeconds < 60 { return "\(remainingSeconds) sn kaldı" }
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return "\(mins) dk \(secs) sn kaldı"
    }

    public static func == (lhs: TaskProgress, rhs: TaskProgress) -> Bool {
        lhs.id == rhs.id && lhs.percent == rhs.percent && lhs.status == rhs.status
    }
}
