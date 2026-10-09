import SwiftUI

public struct BreadcrumbBar: View {
    @ObservedObject var manager = ArchiveManager.shared

    public var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(manager.breadcrumbs.enumerated()), id: \.offset) { index, crumb in
                        Button(action: {
                            manager.navigateToBreadcrumb(at: index)
                        }) {
                            HStack(spacing: 4) {
                                if index == 0 {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.accentColor)
                                }
                                Text(crumb)
                                    .font(.system(size: 12, weight: index == manager.breadcrumbs.count - 1 ? .semibold : .regular))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(index == manager.breadcrumbs.count - 1 ? Color.primary.opacity(0.08) : Color.clear)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)

                        if index < manager.breadcrumbs.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                }
            }

            Spacer()

            if !manager.currentFolderPath.isEmpty {
                Button(action: {
                    manager.goUpOneLevel()
                }) {
                    Label("Üst Dizin", systemImage: "arrow.up")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            // Liste / Izgara Görünüm Seçici
            Picker("", selection: $manager.isGridView) {
                Image(systemName: "list.bullet").tag(false)
                Image(systemName: "square.grid.2x2").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 64)
            .help("Liste veya Izgara Görünümü")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .overlay(
            Divider(), alignment: .bottom
        )
    }
}
