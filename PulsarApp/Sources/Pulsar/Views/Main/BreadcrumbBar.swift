import SwiftUI

public struct BreadcrumbBar: View {
    @ObservedObject var manager = ArchiveManager.shared

    public var body: some View {
        HStack(spacing: 8) {
            if !manager.currentFolderPath.isEmpty {
                Button(action: {
                    manager.goUpOneLevel()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Üst Dizine Çık (⌘↑)")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(manager.breadcrumbs.enumerated()), id: \.offset) { index, crumb in
                        let isLast = index == manager.breadcrumbs.count - 1

                        Button(action: {
                            manager.navigateToBreadcrumb(at: index)
                        }) {
                            HStack(spacing: 4) {
                                if index == 0 {
                                    Image(systemName: "archivebox.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.accentColor)
                                } else {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(isLast ? .accentColor : .secondary)
                                }
                                Text(crumb)
                                    .font(.system(size: 12, weight: isLast ? .semibold : .regular))
                                    .foregroundColor(isLast ? .primary : .secondary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(isLast ? Color.accentColor.opacity(0.12) : Color.clear)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Klasör Yolunu Kopyala") {
                                let path = manager.breadcrumbs.prefix(index + 1).dropFirst().joined(separator: "/")
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(path, forType: .string)
                            }
                        }

                        if !isLast {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(Color(NSColor.tertiaryLabelColor))
                        }
                    }
                }
            }

            Spacer()

            if manager.isEditingUnlocked {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("Düzenleme Açık")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(4)
                .help("Arşive dosya eklenebilir veya silinebilir")
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
