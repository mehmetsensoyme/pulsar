import SwiftUI

public final class ConflictViewModel: ObservableObject {
    @Published public var applyToAll: Bool = false
    public init() {}
}

public struct ConflictModalView: View {
    public let item: ConflictItem
    public let onResolve: (ConflictResolution, Bool) -> Void

    @StateObject private var vm = ConflictViewModel()

    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dosya Çakışması Algılandı")
                        .font(.headline)
                    Text("Aynı isimde bir dosya hedef konumda zaten mevcut.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Divider()

            // Yan Yana Karşılaştırma Tablosu
            HStack(spacing: 16) {
                // Kaynak Dosya (Arşivdeki)
                VStack(alignment: .leading, spacing: 6) {
                    Text("ARŞİVDEKİ DOSYA")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(item.filename)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(2)
                    Text("Boyut: \(item.formattedSourceSize)")
                        .font(.system(size: 11, design: .monospaced))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Hedef Dosya (Diskteki)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("MEVCUT DOSYA")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        if item.isDestinationNewer {
                            Text("DAHA YENİ")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 4)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(3)
                        }
                    }
                    Text(item.filename)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(2)
                    Text("Boyut: \(item.formattedDestinationSize)")
                        .font(.system(size: 11, design: .monospaced))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }

            Toggle("Tüm çakışmalara uygula", isOn: $vm.applyToAll)
                .font(.system(size: 11))
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            HStack {
                Button("Atla") {
                    onResolve(.skip, vm.applyToAll)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Yeniden Adlandır (Akıllı Ek)") {
                    onResolve(.rename, vm.applyToAll)
                }
                .buttonStyle(.bordered)

                Button("Üzerine Yaz") {
                    onResolve(.overwrite, vm.applyToAll)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 480)
    }
}

public final class PasswordViewModel: ObservableObject {
    @Published public var passwordText: String = ""
    @Published public var rememberInKeychain: Bool = true
    public init() {}
}

public struct PasswordModalView: View {
    @ObservedObject var manager = ArchiveManager.shared
    @StateObject private var vm = PasswordViewModel()

    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Şifreli Arşiv")
                        .font(.headline)
                    Text("Bu arşiv AES şifreleme ile korunmaktadır.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            SecureField("Parolayı Girin", text: $vm.passwordText)
                .textFieldStyle(.roundedBorder)

            Toggle("macOS Anahtar Zinciri'ne (Keychain) kaydet", isOn: $vm.rememberInKeychain)
                .font(.system(size: 11))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button("İptal") {
                    manager.showPasswordModal = false
                    manager.passwordPromptCallback?(nil)
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)

                Spacer()

                Button("Kilidi Aç") {
                    manager.showPasswordModal = false
                    manager.passwordPromptCallback?(vm.passwordText)
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.passwordText.isEmpty)
            }
        }
        .padding()
        .frame(width: 380)
    }
}

public struct UpdateModalView: View {
    @ObservedObject var updater = UpdateService.shared
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.cyan)
                    .font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pulsar Sürüm Takipçisi")
                        .font(.headline)
                    Text("Güncel Sürüm: v\(updater.currentVersion) (\(updater.currentCodeName)) - Build \(updater.currentBuild)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Divider()

            if let info = updater.latestRelease {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Son Sürüm: v\(info.version)")
                            .font(.subheadline).bold()
                        CosmicBadge(text: info.codeName, color: .purple)
                        Spacer()
                        Text(info.releaseDate)
                            .font(.caption).foregroundColor(.secondary)
                    }

                    Text("Yenilikler:")
                        .font(.caption).bold()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(info.releaseNotes, id: \.self) { note in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•").foregroundColor(.cyan)
                                    Text(note).font(.system(size: 11))
                                }
                            }
                        }
                    }
                    .frame(height: 120)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }

            HStack {
                Button("Kapat") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)

                Spacer()

                Button(action: {
                    Task {
                        await updater.checkForUpdates()
                    }
                }) {
                    if updater.isChecking {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Güncellemeleri Denetle")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 440)
    }
}
