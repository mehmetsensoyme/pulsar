import SwiftUI

public enum ArchiveFormat: String, CaseIterable, Identifiable, Codable {
    case sevenZip = "7z"
    case rar = "rar"
    case zip = "zip"
    case tar = "tar"
    case gzip = "gz"
    case bzip2 = "bz2"
    case xz = "xz"
    case zstd = "zst"
    case lzma = "lzma"
    case cab = "cab"
    case wim = "wim"
    case cpio = "cpio"
    case rpm = "rpm"
    case deb = "deb"
    case arj = "arj"
    case lzh = "lzh"
    case chm = "chm"
    case xar = "xar"
    case iso = "iso"
    case dmg = "dmg"
    case split = "001"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sevenZip: return "7-Zip (.7z)"
        case .rar: return "WinRAR (.rar)"
        case .zip: return "ZIP (.zip)"
        case .tar: return "TAR (.tar)"
        case .gzip: return "GZip (.gz)"
        case .bzip2: return "BZip2 (.bz2)"
        case .xz: return "XZ (.xz)"
        case .zstd: return "Zstandard (.zst)"
        case .lzma: return "LZMA (.lzma)"
        case .cab: return "Microsoft Cabinet (.cab)"
        case .wim: return "Windows Imaging (.wim)"
        case .cpio: return "Unix CPIO (.cpio)"
        case .rpm: return "Red Hat Paketi (.rpm)"
        case .deb: return "Debian Paketi (.deb)"
        case .arj: return "ARJ Arşivi (.arj)"
        case .lzh: return "LHA / LZH (.lzh)"
        case .chm: return "Yardım Dosyası (.chm)"
        case .xar: return "macOS XAR / PKG (.xar)"
        case .iso: return "Disk Kalıbı (.iso)"
        case .dmg: return "Apple DMG (.dmg)"
        case .split: return "Parçalı Arşiv (.001)"
        }
    }

    public var extensionName: String {
        return rawValue
    }

    public var badgeColor: Color {
        switch self {
        case .sevenZip: return Color(red: 0.15, green: 0.55, blue: 0.95) // Neon Mavi
        case .rar: return Color(red: 0.85, green: 0.25, blue: 0.35)      // Kozmik Kırmızı
        case .zip: return Color(red: 0.95, green: 0.65, blue: 0.15)     // Kehribar Sarısı
        case .tar, .gzip, .bzip2, .xz, .zstd, .lzma: return Color(red: 0.2, green: 0.8, blue: 0.6) // Zümrüt Yeşili
        case .iso, .dmg, .wim: return Color(red: 0.7, green: 0.5, blue: 0.95) // Nebula Moru
        case .rpm, .deb, .cpio: return Color(red: 0.95, green: 0.45, blue: 0.2) // Kızıl Turuncu
        case .cab, .arj, .lzh, .chm, .xar, .split: return Color(red: 0.4, green: 0.7, blue: 0.9) // Çelik Mavisi
        }
    }

    public var iconName: String {
        switch self {
        case .sevenZip: return "shippingbox.fill"
        case .rar: return "archivebox.fill"
        case .zip: return "doc.zipper"
        case .tar, .gzip, .bzip2, .xz, .zstd, .lzma: return "square.stack.3d.down.right.fill"
        case .iso, .dmg: return "opticaldisc.fill"
        case .wim: return "externaldrive.fill"
        case .rpm, .deb, .xar: return "shippingbox.circle.fill"
        case .cab, .arj, .lzh, .chm, .cpio, .split: return "doc.badge.gearshape.fill"
        }
    }

    public var supportsCreation: Bool {
        switch self {
        case .sevenZip, .rar, .zip, .tar, .gzip, .bzip2, .xz: return true
        default: return false
        }
    }

    public var supportsEncryption: Bool {
        switch self {
        case .sevenZip, .rar, .zip: return true
        default: return false
        }
    }

    public var supportsHeaderEncryption: Bool {
        switch self {
        case .sevenZip, .rar: return true
        default: return false
        }
    }

    public var supportsRepair: Bool {
        switch self {
        case .rar: return true
        default: return false
        }
    }

    public static func detect(from path: String) -> ArchiveFormat? {
        let lower = path.lowercased()
        if lower.hasSuffix(".7z") { return .sevenZip }
        if lower.hasSuffix(".rar") { return .rar }
        if lower.hasSuffix(".zip") || lower.hasSuffix(".zipx") || lower.hasSuffix(".jar") || lower.hasSuffix(".war") { return .zip }
        if lower.hasSuffix(".tar") { return .tar }
        if lower.hasSuffix(".tar.gz") || lower.hasSuffix(".tgz") || lower.hasSuffix(".gz") { return .gzip }
        if lower.hasSuffix(".tar.bz2") || lower.hasSuffix(".tbz2") || lower.hasSuffix(".bz2") { return .bzip2 }
        if lower.hasSuffix(".tar.xz") || lower.hasSuffix(".txz") || lower.hasSuffix(".xz") { return .xz }
        if lower.hasSuffix(".tar.zst") || lower.hasSuffix(".tzst") || lower.hasSuffix(".zst") { return .zstd }
        if lower.hasSuffix(".lzma") || lower.hasSuffix(".tlz") { return .lzma }
        if lower.hasSuffix(".cab") { return .cab }
        if lower.hasSuffix(".wim") || lower.hasSuffix(".swm") || lower.hasSuffix(".esd") { return .wim }
        if lower.hasSuffix(".cpio") { return .cpio }
        if lower.hasSuffix(".rpm") { return .rpm }
        if lower.hasSuffix(".deb") { return .deb }
        if lower.hasSuffix(".arj") { return .arj }
        if lower.hasSuffix(".lzh") || lower.hasSuffix(".lha") { return .lzh }
        if lower.hasSuffix(".chm") { return .chm }
        if lower.hasSuffix(".xar") || lower.hasSuffix(".pkg") { return .xar }
        if lower.hasSuffix(".iso") || lower.hasSuffix(".img") { return .iso }
        if lower.hasSuffix(".dmg") { return .dmg }
        if lower.hasSuffix(".001") { return .split }
        return nil
    }
}
