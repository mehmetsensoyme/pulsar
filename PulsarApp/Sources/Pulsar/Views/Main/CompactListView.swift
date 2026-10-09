import SwiftUI

public struct CompactListView: View {
    @ObservedObject var manager = ArchiveManager.shared

    public var body: some View {
        if manager.currentArchivePath == nil {
            EmptyArchiveHeroView()
        } else {
            VStack(spacing: 0) {
                BreadcrumbBar()
                FileTableView()
            }
        }
    }
}

public struct TabbedStudioView: View {
    @ObservedObject var manager = ArchiveManager.shared

    public var body: some View {
        VStack(spacing: 0) {
            // Sekme Çubuğu
            if !manager.openTabs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(Array(manager.openTabs.enumerated()), id: \.offset) { index, path in
                            let isSelected = manager.activeTabIndex == index
                            let name = (path as NSString).lastPathComponent

                            HStack(spacing: 6) {
                                FileIconView(fileName: name, size: 14)

                                Text(name)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                                    .lineLimit(1)

                                Button(action: {
                                    closeTab(at: index)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color(NSColor.controlBackgroundColor) : Color.clear)
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                manager.activeTabIndex = index
                                manager.openArchive(at: path)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
                .overlay(Divider(), alignment: .bottom)
            }

            // Sekme İçeriği
            ModernThreePaneView()
        }
    }

    private func closeTab(at index: Int) {
        guard index < manager.openTabs.count else { return }
        manager.openTabs.remove(at: index)
        if manager.openTabs.isEmpty {
            manager.currentArchivePath = nil
            manager.allItems.removeAll()
        } else {
            let nextIndex = min(manager.activeTabIndex, manager.openTabs.count - 1)
            manager.activeTabIndex = nextIndex
            manager.openArchive(at: manager.openTabs[nextIndex])
        }
    }
}
