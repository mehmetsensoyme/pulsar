import SwiftUI
import AppKit

public final class OnboardingViewModel: ObservableObject {
    @Published public var selectedTheme: String = PulsarSettings.shared.selectedTheme
    @Published public var accentColorChoice: String = PulsarSettings.shared.accentColorChoice
    @Published public var uiScale: String = PulsarSettings.shared.uiScale
    @Published public var defaultLayout: String = PulsarSettings.shared.defaultLayoutMode

    public init() {}

    public func saveAndFinish() {
        PulsarSettings.shared.selectedTheme = selectedTheme
        PulsarSettings.shared.accentColorChoice = accentColorChoice
        PulsarSettings.shared.uiScale = uiScale
        PulsarSettings.shared.defaultLayoutMode = defaultLayout
        if let mode = LayoutMode(rawValue: defaultLayout) {
            ArchiveManager.shared.currentLayoutMode = mode
        }
        PulsarSettings.shared.hasCompletedOnboarding = true
    }
}

public struct OnboardingSheetView: View {
    @ObservedObject var settings = PulsarSettings.shared
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = OnboardingViewModel()

    public init() {}

    private let accentColors: [(id: String, name: String, color: Color)] = [
        ("cyan", "Cyan", Color(red: 0.0, green: 0.75, blue: 0.95)),
        ("purple", "Mor", Color(red: 0.65, green: 0.35, blue: 0.95)),
        ("orange", "Turuncu", Color(red: 1.0, green: 0.58, blue: 0.0)),
        ("green", "Yeşil", Color(red: 0.2, green: 0.78, blue: 0.35)),
        ("blue", "Mavi", Color(red: 0.0, green: 0.48, blue: 1.0))
    ]

    public var body: some View {
        VStack(spacing: 0) {
            // Karşılama Başlığı
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(settings.resolvedAccentColor.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundColor(settings.resolvedAccentColor)
                }

                Text("Pulsar'a Hoş Geldiniz")
                    .font(.system(size: 20, weight: .bold))

                Text("macOS arşiv deneyiminizi kişiselleştirin. Bu tercihleri daha sonra Ayarlar (⌘,) menüsünden istediğiniz zaman değiştirebilirsiniz.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // 1. Tema Seçimi
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Görünüm & Tema", systemImage: "circle.lefthalf.filled")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            themeOptionCard(id: "system", title: "Sistem (Otomatik)", icon: "gearshape")
                            themeOptionCard(id: "dark", title: "Koyu Mod", icon: "moon.fill")
                            themeOptionCard(id: "light", title: "Açık Mod", icon: "sun.max.fill")
                        }
                    }

                    // 2. Vurgu Rengi
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Sistem Vurgu Rengi", systemImage: "paintpalette.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            ForEach(accentColors, id: \.id) { item in
                                Button(action: {
                                    vm.accentColorChoice = item.id
                                    settings.accentColorChoice = item.id
                                }) {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            Circle()
                                                .fill(item.color)
                                                .frame(width: 32, height: 32)

                                            if vm.accentColorChoice == item.id {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }

                                        Text(item.name)
                                            .font(.system(size: 10, weight: vm.accentColorChoice == item.id ? .semibold : .regular))
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // 3. Arayüz Ölçeği ve Satır Yoğunluğu
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Arayüz Ölçeği & Yoğunluk", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)

                        Picker("", selection: $vm.uiScale) {
                            Text("Kompakt (Daha çok dosya)").tag("compact")
                            Text("Standart (Dengeli Apple HIG)").tag("standard")
                            Text("Ferah (Geniş satırlar)").tag("spacious")
                        }
                        .pickerStyle(.segmented)
                    }

                    // 4. Varsayılan Başlangıç Düzeni
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Varsayılan Başlangıç Düzeni", systemImage: "macwindow")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)

                        Picker("", selection: $vm.defaultLayout) {
                            Text("Modern 3-Bölmeli").tag(LayoutMode.modernThreePane.rawValue)
                            Text("Kompakt Liste").tag(LayoutMode.compactList.rawValue)
                            Text("Sekmeli Stüdyo").tag(LayoutMode.tabbedStudio.rawValue)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(24)
            }

            Divider()

            // Alt Buton
            HStack {
                Spacer()

                Button(action: {
                    vm.saveAndFinish()
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Text("Pulsar'ı Başlat")
                        Image(systemName: "arrow.right")
                    }
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 520, height: 530)
    }

    private func themeOptionCard(id: String, title: String, icon: String) -> some View {
        let isSelected = vm.selectedTheme == id
        return Button(action: {
            vm.selectedTheme = id
            settings.selectedTheme = id
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? settings.resolvedAccentColor : .secondary)

                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? settings.resolvedAccentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? settings.resolvedAccentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
