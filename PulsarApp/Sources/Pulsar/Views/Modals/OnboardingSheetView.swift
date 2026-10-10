import SwiftUI
import AppKit

public final class OnboardingViewModel: ObservableObject {
    @Published public var selectedTheme: String = PulsarSettings.shared.selectedTheme
    @Published public var accentColorChoice: String = PulsarSettings.shared.accentColorChoice
    @Published public var uiScale: String = PulsarSettings.shared.uiScale
    @Published public var defaultLayout: String = PulsarSettings.shared.defaultLayoutMode
    @Published public var selectedLanguage: String = PulsarSettings.shared.selectedLanguage

    public init() {}

    public func saveAndFinish() {
        PulsarSettings.shared.selectedTheme = selectedTheme
        PulsarSettings.shared.accentColorChoice = accentColorChoice
        PulsarSettings.shared.uiScale = uiScale
        PulsarSettings.shared.defaultLayoutMode = defaultLayout
        LocalizationService.shared.setLanguage(selectedLanguage)
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
            // Karşılama Başlığı & Logo
            VStack(spacing: 10) {
                PulsarLogoView(size: 68)

                VStack(spacing: 4) {
                    Text("Pulsar'a Hoş Geldiniz")
                        .font(.system(size: 22, weight: .bold))

                    Text("macOS İçin Işık Hızında Arşiv ve Sıkıştırma Gücü")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(settings.resolvedAccentColor)

                    Text("Kullanım tercihlerinizi kişiselleştirin. Bu ayarları dilediğiniz zaman Ayarlar (⌘,) menüsünden değiştirebilirsiniz.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider()

            ScrollView {
                VStack(spacing: 22) {
                    // 0. Pulsar Yetenekleri ve Bilgilendirme
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Öne Çıkan Yetenekler", systemImage: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            featureBriefCard(
                                icon: "bolt.fill",
                                color: .cyan,
                                title: "Apple Silicon Gücü",
                                desc: "Yerel 7-Zip & WinRAR motorları ile M-serisi çiplerde ultra hızlı arşivleme."
                            )
                            featureBriefCard(
                                icon: "hand.draw.fill",
                                color: .purple,
                                title: "Finder Sürükle-Bırak",
                                desc: "Arşivdeki dosyaları masaüstüne sürükleyerek anında dışa aktarma (.onDrag)."
                            )
                            featureBriefCard(
                                icon: "lock.shield.fill",
                                color: .green,
                                title: "Güvenlik & Temizlik",
                                desc: "Salt-okunur koruma kilidi ve Windows uyumlu .DS_Store metadata filtresi."
                            )
                            featureBriefCard(
                                icon: "line.3.horizontal.decrease.circle.fill",
                                color: .orange,
                                title: "Akıllı Filtreler",
                                desc: "Görseller, belgeler, kaynak kodları ve medyayı tek tıkla kategorilendirme."
                            )
                        }
                    }

                    // 1. Dil Seçimi
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Arayüz Dili / Interface Language", systemImage: "globe")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        Picker("", selection: $vm.selectedLanguage) {
                            Text("Sistemle Uyumlu (Otomatik)").tag("auto")
                            Divider()
                            ForEach(LocalizationService.shared.availableLanguages) { lang in
                                Text(lang.name).tag(lang.code)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // 2. Tema Seçimi
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Görünüm & Tema", systemImage: "circle.lefthalf.filled")
                            .font(.system(size: 11, weight: .bold))
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
        .frame(width: 560, height: 580)
    }

    private func featureBriefCard(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)

                Text(desc)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
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
