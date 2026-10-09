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
                            .contextMenu {
                                Button("Sekmeyi Kapat") {
                                    closeTab(at: index)
                                }
                                Button("Sekmeyi Çoğalt") {
                                    duplicateTab(at: index)
                                }
                                Divider()
                                Button("Diğer Sekmeleri Kapat") {
                                    closeOtherTabs(except: index)
                                }
                            }
                        }

                        // Safari Tarzı Yeni Sekme Butonu (+)
                        Button(action: {
                            openNewTab()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .help("Yeni Sekmede Arşiv Aç (⌘T)")
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

    private func openNewTab() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Sekmede Aç"
        if panel.runModal() == .OK, let url = panel.url {
            manager.openArchive(at: url.path)
        }
    }

    private func duplicateTab(at index: Int) {
        guard index < manager.openTabs.count else { return }
        let path = manager.openTabs[index]
        manager.openTabs.insert(path, at: index + 1)
        manager.activeTabIndex = index + 1
    }

    private func closeOtherTabs(except keepIndex: Int) {
        guard keepIndex < manager.openTabs.count else { return }
        let keepPath = manager.openTabs[keepIndex]
        manager.openTabs = [keepPath]
        manager.activeTabIndex = 0
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
