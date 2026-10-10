import SwiftUI

public final class CompressSheetViewModel: ObservableObject {
    @Published public var sourcePaths: [String] = []
    @Published public var outputName: String = "Arşiv"
    @Published public var outputDirectory: String = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? ""
    @Published public var selectedTab: Int = 0 // 0: Önayarlar, 1: Sihirbaz, 2: Uzman

    // Önayar Modu
    @Published public var selectedPreset: Preset = Preset.standardPresets[0]

    // Sihirbaz Modu
    @Published public var wizardStep: Int = 1
    @Published public var wizardFormat: ArchiveFormat = .zip
    @Published public var wizardPassword: String = ""

    // Uzman Modu
    @Published public var expertFormat: ArchiveFormat = .sevenZip
    @Published public var expertLevel: CompressionLevel = .maximum
    @Published public var expertPassword: String = ""
    @Published public var expertCleanMetadata: Bool = true
    @Published public var expertSolid: Bool = true
    @Published public var expertSplitMB: String = ""
    @Published public var expertThreads: Int = ProcessInfo.processInfo.processorCount

    public init() {}
}

public struct CompressSheetView: View {
    @ObservedObject var manager = ArchiveManager.shared
    @StateObject private var vm = CompressSheetViewModel()
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 0) {
            // Başlık
            HStack {
                Image(systemName: "archivebox.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 16))
                Text("Yeni Arşiv Oluştur")
                    .font(.headline)
                Spacer()
                Button("Vazgeç") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Mod Seçici (Önayarlar, Sihirbaz, Uzman)
            Picker("", selection: $vm.selectedTab) {
                Text("Akıllı Önayarlar").tag(0)
                Text("Adım Adım Sihirbaz").tag(1)
                Text("Uzman Kontrol Paneli").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 10)

            // Kaynak Dosyalar Seçimi
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Kaynak:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if vm.sourcePaths.isEmpty {
                        Text("Seçili dosya yok")
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(vm.sourcePaths.count) dosya/klasör seçildi")
                            .font(.subheadline)
                            .bold()
                    }
                    Spacer()
                    Button("Dosya Ekle...") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = true
                        panel.canChooseDirectories = true
                        if panel.runModal() == .OK {
                            for url in panel.urls {
                                if !vm.sourcePaths.contains(url.path) {
                                    vm.sourcePaths.append(url.path)
                                }
                            }
                            if let first = vm.sourcePaths.first, vm.outputName == "Arşiv" {
                                vm.outputName = (first as NSString).lastPathComponent
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if !vm.sourcePaths.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(vm.sourcePaths, id: \.self) { path in
                                HStack(spacing: 4) {
                                    FileIconView(fileName: (path as NSString).lastPathComponent, isDirectory: (try? FileManager.default.attributesOfItem(atPath: path)[.type] as? FileAttributeType) == .typeDirectory, size: 12)
                                    Text((path as NSString).lastPathComponent)
                                        .font(.system(size: 11))
                                    Button(action: {
                                        vm.sourcePaths.removeAll(where: { $0 == path })
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.06))
                                .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 6)

            Divider()

            // Sekme İçerikleri
            Group {
                switch vm.selectedTab {
                case 0:
                    presetsView
                case 1:
                    wizardView
                case 2:
                    expertView
                default:
                    EmptyView()
                }
            }
            .frame(height: 240)
            .padding()

            Divider()

            // Alt Çubuk: Çıktı ve Başlat Butonu
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Çıktı Konumu:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Değiştir...") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.canCreateDirectories = true
                            panel.prompt = "Hedef Klasörü Seç"
                            if panel.runModal() == .OK, let url = panel.url {
                                vm.outputDirectory = url.path
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.accentColor)
                    }

                    Text("\(vm.outputDirectory)/\(vm.outputName).\(finalExtension)".abbreviatingWithTilde)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button("Sıkıştırmayı Başlat") {
                    startCompression()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(vm.sourcePaths.isEmpty)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600)
        .onAppear {
            if !manager.pendingCompressPaths.isEmpty {
                vm.sourcePaths = manager.pendingCompressPaths
                if let first = manager.pendingCompressPaths.first {
                    let base = (first as NSString).lastPathComponent
                    let nameWithoutExt = (base as NSString).deletingPathExtension
                    vm.outputName = manager.pendingCompressPaths.count == 1 ? nameWithoutExt : "Arşiv"
                }
                manager.pendingCompressPaths = []
            }
        }
    }

    private var finalExtension: String {
        switch vm.selectedTab {
        case 0: return vm.selectedPreset.format.rawValue
        case 1: return vm.wizardFormat.rawValue
        case 2: return vm.expertFormat.rawValue
        default: return "zip"
        }
    }

    // MARK: - 1. Önayarlar Görünümü
    private var presetsView: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Preset.standardPresets) { preset in
                    Button(action: {
                        vm.selectedPreset = preset
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: preset.format.iconName)
                                .font(.system(size: 20))
                                .foregroundColor(preset.format.badgeColor)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(preset.name)
                                        .font(.system(size: 13, weight: .semibold))
                                    if preset.cleanMacMetadata {
                                        Text("TEMİZ MAC")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.green.opacity(0.12))
                                            .cornerRadius(4)
                                    }
                                }
                                Text("Format: \(preset.format.displayName) • Seviye: \(preset.level.rawValue)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if vm.selectedPreset == preset {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(10)
                        .background(vm.selectedPreset == preset ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 2. Sihirbaz Görünümü
    private var wizardView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ForEach(1...3, id: \.self) { step in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(vm.wizardStep >= step ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 18, height: 18)
                            .overlay(Text("\(step)").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                        Text(step == 1 ? "Format" : (step == 2 ? "Güvenlik" : "Hedef"))
                            .font(.system(size: 11, weight: vm.wizardStep == step ? .bold : .regular))
                    }
                    if step < 3 {
                        Spacer()
                    }
                }
            }
            .padding(.bottom, 6)

            Divider()

            if vm.wizardStep == 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Adım: Arşiv Formatını Seçin")
                        .font(.subheadline).bold()
                    Picker("Format", selection: $vm.wizardFormat) {
                        Text("ZIP (Evrensel Uyumlu)").tag(ArchiveFormat.zip)
                        Text("7-Zip (En Yüksek Sıkıştırma)").tag(ArchiveFormat.sevenZip)
                        Text("RAR (Resmi WinRAR)").tag(ArchiveFormat.rar)
                    }
                    .pickerStyle(.radioGroup)
                }
            } else if vm.wizardStep == 2 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("2. Adım: Şifreleme ve Koruma (İsteğe Bağlı)")
                        .font(.subheadline).bold()
                    SecureField("Parola belirleyin (boş bırakılabilir)", text: $vm.wizardPassword)
                        .textFieldStyle(.roundedBorder)
                    Text("AES-256 endüstri standardı şifreleme uygulanacaktır.")
                        .font(.caption).foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("3. Adım: Arşiv Adı")
                        .font(.subheadline).bold()
                    TextField("Arşiv Adı", text: $vm.outputName)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Spacer()

            HStack {
                if vm.wizardStep > 1 {
                    Button("Geri") { vm.wizardStep -= 1 }
                }
                Spacer()
                if vm.wizardStep < 3 {
                    Button("İleri") { vm.wizardStep += 1 }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - 3. Uzman Görünümü
    private var expertView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Format:").frame(width: 90, alignment: .leading)
                    Picker("", selection: $vm.expertFormat) {
                        ForEach([ArchiveFormat.sevenZip, .rar, .zip, .tar, .gzip, .bzip2, .xz]) { fmt in
                            Text(fmt.displayName).tag(fmt)
                        }
                    }
                }

                HStack {
                    Text("Seviye:").frame(width: 90, alignment: .leading)
                    Picker("", selection: $vm.expertLevel) {
                        ForEach(CompressionLevel.allCases) { lvl in
                            Text(lvl.rawValue).tag(lvl)
                        }
                    }
                }

                HStack {
                    Text("İş Parçacığı:").frame(width: 90, alignment: .leading)
                    Stepper("\(vm.expertThreads) CPU Çekirdeği", value: $vm.expertThreads, in: 1...32)
                }

                HStack {
                    Text("Parola:").frame(width: 90, alignment: .leading)
                    SecureField("AES-256 Şifre", text: $vm.expertPassword)
                        .textFieldStyle(.roundedBorder)
                }

                Toggle("Windows Dostu Temizleme (.DS_Store ve ._ metadata dosyalarını filtrele)", isOn: $vm.expertCleanMetadata)
                    .font(.system(size: 11))

                Toggle("Katı Blok Sıkıştırma (Solid Archive)", isOn: $vm.expertSolid)
                    .font(.system(size: 11))
            }
        }
    }

    // MARK: - İşlemi Başlat
    private func startCompression() {
        guard !vm.sourcePaths.isEmpty else { return }
        let ext = finalExtension
        let dest = "\(vm.outputDirectory)/\(vm.outputName).\(ext)"

        var finalPreset: Preset
        var pwd: String? = nil

        switch vm.selectedTab {
        case 0:
            finalPreset = vm.selectedPreset
        case 1:
            finalPreset = Preset(
                name: "Sihirbaz",
                format: vm.wizardFormat,
                level: .normal,
                cleanMacMetadata: true
            )
            pwd = vm.wizardPassword.isEmpty ? nil : vm.wizardPassword
        case 2:
            finalPreset = Preset(
                name: "Uzman",
                format: vm.expertFormat,
                level: vm.expertLevel,
                cleanMacMetadata: vm.expertCleanMetadata,
                solidBlock: vm.expertSolid,
                threads: vm.expertThreads
            )
            pwd = vm.expertPassword.isEmpty ? nil : vm.expertPassword
        default:
            return
        }

        dismiss()

        let task = TaskProgress(
            title: "\(vm.outputName).\(ext) Oluşturuluyor",
            type: .compress,
            archivePath: dest
        )
        manager.activeTasks.append(task)

        Task {
            do {
                if finalPreset.format == .rar {
                    try await RAREngine.shared.createArchive(
                        taskId: task.id,
                        at: dest,
                        from: vm.sourcePaths,
                        preset: finalPreset,
                        password: pwd
                    ) { pct, line in
                        DispatchQueue.main.async {
                            if let idx = self.manager.activeTasks.firstIndex(where: { $0.id == task.id }) {
                                self.manager.activeTasks[idx].percent = pct
                                self.manager.activeTasks[idx].currentFilename = (line as NSString).lastPathComponent
                            }
                        }
                    }
                } else {
                    try await SevenZipEngine.shared.createArchive(
                        taskId: task.id,
                        at: dest,
                        from: vm.sourcePaths,
                        preset: finalPreset,
                        password: pwd
                    ) { pct, line in
                        DispatchQueue.main.async {
                            if let idx = self.manager.activeTasks.firstIndex(where: { $0.id == task.id }) {
                                self.manager.activeTasks[idx].percent = pct
                                self.manager.activeTasks[idx].currentFilename = (line as NSString).lastPathComponent
                            }
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
