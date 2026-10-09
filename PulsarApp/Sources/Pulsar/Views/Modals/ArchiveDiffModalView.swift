import SwiftUI
import AppKit

public final class ArchiveDiffViewModel: ObservableObject {
    @Published public var archiveAPath: String = ""
    @Published public var archiveBPath: String = ""
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var diffResult: ArchiveDiffResult? = nil
    @Published public var selectedFilter: DiffFilter = .all
    @Published public var searchText: String = ""
    @Published public var copiedReport: Bool = false

    public enum DiffFilter: String, CaseIterable {
        case all = "Tümü"
        case added = "Eklenen"
        case removed = "Silinen"
        case modified = "Değiştirilen"
    }

    public init() {
        if let current = ArchiveManager.shared.currentArchivePath {
            self.archiveAPath = current
        }
    }

    public var filteredItems: [DiffItem] {
        guard let result = diffResult else { return [] }
        var list = result.items

        switch selectedFilter {
        case .all:
            break
        case .added:
            list = list.filter { $0.status == .added }
        case .removed:
            list = list.filter { $0.status == .removed }
        case .modified:
            list = list.filter { $0.status == .modified }
        }

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter { $0.path.lowercased().contains(q) }
        }

        return list
    }

    public func runComparison() {
        guard !archiveAPath.isEmpty && !archiveBPath.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let res = try await ArchiveDiffService.shared.compareArchives(
                    archiveAPath: archiveAPath,
                    archiveBPath: archiveBPath
                )
                await MainActor.run {
                    self.diffResult = res
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Karşılaştırma başarısız: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    public func copyReportToPasteboard() {
        guard let report = diffResult?.generateMarkdownReport() else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        copiedReport = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.copiedReport = false
        }
    }
}

public struct ArchiveDiffModalView: View {
    @ObservedObject var manager = ArchiveManager.shared
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var vm = ArchiveDiffViewModel()

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Başlık Çubuğu
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.split.2x1.fill")
                            .foregroundColor(.cyan)
                        Text("Arşiv Karşılaştırma & Diff")
                            .font(.headline)
                    }
                    Text("İki arşiv arasındaki farkları ve değişen dosyaları inceleyin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Arşiv Seçiciler
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    archivePicker(
                        title: "Arşiv A (Kaynak)",
                        path: $vm.archiveAPath,
                        badgeColor: .blue
                    )
                    archivePicker(
                        title: "Arşiv B (Hedef)",
                        path: $vm.archiveBPath,
                        badgeColor: .purple
                    )
                }

                HStack {
                    if let err = vm.errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Spacer()

                    Button(action: { vm.runComparison() }) {
                        HStack(spacing: 6) {
                            if vm.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.triangle.swap")
                            }
                            Text("Karşılaştır (⌘⇧D)")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.archiveAPath.isEmpty || vm.archiveBPath.isEmpty || vm.isLoading)
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Sonuç Bölümü
            if let result = vm.diffResult {
                VStack(spacing: 0) {
                    // İstatistik Rozetleri
                    HStack(spacing: 12) {
                        statCard(title: "Eklenen", count: result.addedCount, color: .green, icon: "plus.circle.fill")
                        statCard(title: "Silinen", count: result.removedCount, color: .red, icon: "minus.circle.fill")
                        statCard(title: "Değişen", count: result.modifiedCount, color: .orange, icon: "arrow.triangle.2.circlepath")
                        statCard(title: "Eşleşen", count: result.identicalCount, color: .secondary, icon: "checkmark.circle")
                    }
                    .padding(12)

                    // Filtreleme ve Arama
                    HStack {
                        Picker("Filtre", selection: $vm.selectedFilter) {
                            ForEach(ArchiveDiffViewModel.DiffFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 320)

                        Spacer()

                        TextField("Farklarda ara...", text: $vm.searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)

                        Button(action: { vm.copyReportToPasteboard() }) {
                            HStack(spacing: 4) {
                                Image(systemName: vm.copiedReport ? "checkmark" : "doc.on.doc")
                                Text(vm.copiedReport ? "Kopyalandı!" : "Raporu Kopyala")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)

                    Divider()

                    // Fark Listesi
                    List(vm.filteredItems) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.status.iconName)
                                .foregroundColor(color(for: item.status))
                                .font(.system(size: 14))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.path)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .lineLimit(1)

                                HStack(spacing: 12) {
                                    Text("A: \(item.formattedSizeA)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("B: \(item.formattedSizeB)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Text(item.formattedSizeDiff)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(color(for: item.status))
                        }
                        .padding(.vertical, 2)
                    }
                    .listStyle(.inset)
                }
            } else {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "square.split.2x1")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Karşılaştırmak için iki arşiv dosyası seçin ve 'Karşılaştır' butonuna basın.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            }
        }
        .frame(minWidth: 680, idealWidth: 720, minHeight: 520, idealHeight: 560)
    }

    private func archivePicker(title: String, path: Binding<String>, badgeColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(badgeColor)
                Spacer()
                Button("Seç...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.prompt = "Seç"
                    if panel.runModal() == .OK, let url = panel.url {
                        path.wrappedValue = url.path
                    }
                }
                .controlSize(.small)
            }

            Text(path.wrappedValue.isEmpty ? "Arşiv dosyası seçilmedi" : (path.wrappedValue as NSString).lastPathComponent)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(path.wrappedValue.isEmpty ? .secondary : .primary)
                .lineLimit(1)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }

    private func statCard(title: String, count: Int, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(count)")
                    .font(.headline)
                    .foregroundColor(color)
            }
            Spacer()
        }
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .frame(maxWidth: .infinity)
    }

    private func color(for status: DiffStatus) -> Color {
        switch status {
        case .added: return .green
        case .removed: return .red
        case .modified: return .orange
        case .identical: return .secondary
        }
    }
}
