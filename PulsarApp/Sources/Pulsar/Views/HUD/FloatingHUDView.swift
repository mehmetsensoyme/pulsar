import SwiftUI
import AppKit

public final class FloatingHUDViewModel: ObservableObject {
    @Published public var isTargetedForDrop: Bool = false
    @Published public var isHovered: Bool = false
    public init() {}
}

public struct FloatingHUDView: View {
    @ObservedObject var manager = ArchiveManager.shared
    @StateObject private var vm = FloatingHUDViewModel()

    private var activeTask: TaskProgress? {
        manager.activeTasks.first
    }

    public var body: some View {
        VStack(spacing: 10) {
            // HUD Üst Çubuk
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(activeTask != nil ? Color.green : Color.blue)
                        .frame(width: 8, height: 8)
                        .shadow(color: (activeTask != nil ? Color.green : Color.blue).opacity(0.8), radius: 4)

                    Text("PULSAR HUD")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary.opacity(0.8))
                }

                Spacer()

                Button(action: {
                    manager.isHUDVisible = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            if let task = activeTask {
                // Aktif İşlem Göstergesi (Canlı İlerleme)
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 5)
                            .frame(width: 54, height: 54)

                        Circle()
                            .trim(from: 0.0, to: CGFloat(task.percent))
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [.blue, .purple, .cyan]),
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: 54, height: 54)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.2), value: task.percent)

                        Text(String(format: "%%%.0f", task.percent * 100))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }

                    Text(task.title)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)

                    if !task.currentFilename.isEmpty {
                        Text(task.currentFilename)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Text(task.formattedSpeed)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.cyan)

                        Text(task.formattedRemainingTime)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Boşta: Hızlı Bırakma Alanı (Drop-Zone)
                VStack(spacing: 6) {
                    Image(systemName: vm.isTargetedForDrop ? "arrow.down.circle.fill" : "shippingbox")
                        .font(.system(size: 26))
                        .foregroundColor(vm.isTargetedForDrop ? .cyan : .secondary)
                        .scaleEffect(vm.isTargetedForDrop ? 1.15 : 1.0)
                        .animation(.spring(response: 0.25), value: vm.isTargetedForDrop)

                    Text(vm.isTargetedForDrop ? "Sıkıştırmak İçin Bırakın" : "Dosya veya Klasör Bırakın")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(vm.isTargetedForDrop ? .primary : .secondary)
                        .multilineTextAlignment(.center)

                    Text("Windows Uyumlu Temiz ZIP")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.vertical, 8)
            }
        }
        .padding(12)
        .frame(width: 190)
        .background(
            ZStack {
                GlassBackground(material: .hudWindow, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [
                                vm.isTargetedForDrop ? Color.cyan : Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: vm.isTargetedForDrop ? 2 : 1
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
        .onDrop(of: [.fileURL], isTargeted: $vm.isTargetedForDrop) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                DispatchQueue.main.async {
                    let path = url.path
                    if ArchiveFormat.detect(from: path) != nil {
                        self.manager.openArchive(at: path)
                    } else {
                        self.compressDroppedFile(at: path)
                    }
                }
            }
        }
    }

    private func compressDroppedFile(at path: String) {
        let dest = "\(path).zip"
        let preset = Preset.standardPresets[0]

        let task = TaskProgress(
            title: "Hızlı Sıkıştırma",
            type: .compress,
            archivePath: dest
        )
        manager.activeTasks.append(task)

        Task {
            do {
                try await SevenZipEngine.shared.createArchive(
                    at: dest,
                    from: [path],
                    preset: preset
                ) { pct, line in
                    DispatchQueue.main.async {
                        if let idx = self.manager.activeTasks.firstIndex(where: { $0.id == task.id }) {
                            self.manager.activeTasks[idx].percent = pct
                            self.manager.activeTasks[idx].currentFilename = (line as NSString).lastPathComponent
                        }
                    }
                }

                await MainActor.run {
                    if let idx = self.manager.activeTasks.firstIndex(where: { $0.id == task.id }) {
                        self.manager.activeTasks[idx].percent = 1.0
                        self.manager.activeTasks[idx].status = .completed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.manager.activeTasks.removeAll(where: { $0.id == task.id })
                        }
                    }
                    NSWorkspace.shared.selectFile(dest, inFileViewerRootedAtPath: (dest as NSString).deletingLastPathComponent)
                }
            } catch {
                await MainActor.run {
                    if let idx = self.manager.activeTasks.firstIndex(where: { $0.id == task.id }) {
                        self.manager.activeTasks[idx].status = .failed(error.localizedDescription)
                    }
                }
            }
        }
    }
}
