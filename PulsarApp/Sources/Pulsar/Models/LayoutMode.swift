import SwiftUI

public enum LayoutMode: String, CaseIterable, Identifiable {
    case modernThreePane = "Modern 3-Bölmeli"
    case compactList = "Kompakt Liste"
    case tabbedStudio = "Sekmeli Stüdyo"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .modernThreePane: return "sidebar.left"
        case .compactList: return "list.bullet"
        case .tabbedStudio: return "square.split.2x1"
        }
    }

    public var shortcutNumber: String {
        switch self {
        case .modernThreePane: return "1"
        case .compactList: return "2"
        case .tabbedStudio: return "3"
        }
    }
}
