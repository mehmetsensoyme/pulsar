# 🌌 PULSAR
### Next-Generation macOS Archive & Data Compression Ecosystem
#### *Light-Speed Performance Powered by Apple Silicon, 7-Zip Native & WinRAR Engines*

[![macOS](https://img.shields.io/badge/macOS-14.0%2B%20%7C%2015.0%2B-blue?logo=apple&style=for-the-badge)](https://apple.com)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20(Universal%2FARM64)-cyan?style=for-the-badge)](https://apple.com)
[![Version](https://img.shields.io/badge/Version-v1.0.0%20(Event%20Horizon)-8B5CF6?style=for-the-badge)](CHANGELOG.md)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

> **GitHub Repository Description (0 / 350 characters):**  
> `🚀 Fast, sci-fi themed archive manager for macOS powered by native 7-Zip & WinRAR engines. Supports 7z, RAR, ZIP, TAR, GZ, XZ, ISO, DMG and more with 3 layout modes, Warp Benchmark, instant cancellation, background HUD, and zero dependencies.`  
> *(247 / 350 karakter - Tam hazır)*

---

## 🖥️ Uygulama Ekranları ve UX Vitrini / Screen Showcase & Visual Tour

Pulsar, macOS Sonoma ve Sequoia Human Interface Guidelines (HIG) ilkelerine tam uyumlu; yarı saydam canlı cam (Liquid Glass/Vibrancy), SF Symbols ve dinamik nötron ışımaları ile tasarlanmıştır.

```
+---------------------------------------------------------------------------------------------------------+
|  [● ● ●]   [ Görünüm: 3-Bölmeli | Kompakt | Sekmeli ]   [ ⤒ Çıkar ]  [ + Yeni ]  [ 🔒 Salt Okunur ] ...  |
+---------------------------------------------------------------------------------------------------------+
|  GEZİNME             |  📁 Kök > Kaynak_Kodlar > Models                 |  [ İNCELEME & DETAY PANELİ ]  |
|  ------------------- |  ----------------------------------------------- |  ---------------------------  |
|  📂 Tüm İçerik       |  📁 Models              --          --       --  |            📄                 |
|  📄 Sadece Dosyalar  |  📄 ArchiveFormat.swift 3.4 KB      1.1 KB  %68 |       ArchiveFormat.swift     |
|                      |  📄 ArchiveItem.swift   4.2 KB      1.2 KB  %71 |       [ SWIFT SOURCE ]        |
|  SON ARŞİVLER        |  📄 TaskProgress.swift  2.1 KB      0.7 KB  %66 |                               |
|  ------------------- |  📄 Preset.swift        2.8 KB      0.9 KB  %67 |  Orijinal:      3.4 KB        |
|  📦 Proje_2026.7z    |  ⚙️ 7zz                 2.68 MB     1.1 MB  %59 |  Sıkıştırılmış: 1.1 KB        |
|  📦 Yedek_Paket.rar  |                                                 |  Oran:          %67.6         |
|  📦 Windows.zip      |                                                 |  CRC32:         E4F91B02      |
|                      |                                                 |  ---------------------------  |
|  SİSTEM MODÜLLERİ    |                                                 |  [ 👁 Önizle ]  [ ⤒ Çıkar ]    |
|  ⚡ Warp Benchmark  |                                                 |                               |
|  🌌 Kara Delik       |                                                 |                               |
|  🔧 Kurtarma         |                                                 |    +---------------------+    |
|                      |                                                 |    | 🛸 PULSAR HUD  [x]  |    |
|                      |                                                 |    |    ( %84 )          |    |
|                      |                                                 |    |    124.5 MB/s       |    |
|                      |                                                 |    +---------------------+    |
+---------------------------------------------------------------------------------------------------------+
```

---

### 1. Ana Tarayıcı ve 3 Değiştirilebilir Düzen (`⌘1`, `⌘2`, `⌘3`)

Pulsar, her kullanıcının çalışma tarzına uyum sağlayan 3 bağımsız arayüz modu sunar:

* **Mod 1: Modern 3-Bölmeli Düzen (Inspector - `⌘1`)**:
  * **Sol Panel (Sidebar):** Son açılan arşivler listesi, sık kullanılanlar ve sistem modüllerine (Warp Benchmark, Kara Delik, Kurtarma İstasyonu) tek tıkla hızlı erişim.
  * **Orta Panel (Browser):** Tıklanabilir ekmek kırıntısı (Breadcrumbs) ile arşiv içi derin klasörlerde gezinme, dosya adı, sıkıştırılmış boyut, orijinal boyut, sıkıştırma oranı ve tarih tablosu. Çift tıkla klasöre girme veya dosya önizleme.
  * **Sağ Panel (Inspector):** Seçili dosyanın canlı QuickLook önizlemesi, dosya türü rozeti, CRC32 sağlama toplamı, izinler ve `[Önizle]` / `[Çıkar]` hızlı aksiyon butonları.
* **Mod 2: Kompakt Klasik Liste (Finder / WinRAR Stili - `⌘2`)**:
  * Yan panelleri gizleyerek tüm ekranı yüksek bilgi yoğunluklu dosya hiyerarşisine ayırır. Yüzlerce dosyayı hızlıca taramak isteyen profesyoneller için idealdir.
* **Mod 3: Sekmeli Stüdyo (Tabbed Studio - `⌘3`)**:
  * Aynı anda birden çok arşivi sekmeler halinde açık tutar. Sekmeler arasında dosya sürükleyip bırakarak bir arşivden diğerine anında dosya aktarımı yapabilirsiniz.

---

### 2. Çift Modlu Güvenlik Kilidi (Safe Lock UX - `⌘L`)

* **🔒 Salt Okunur Mod (Varsayılan)**: Arşivin kazara değiştirilmesini, bozulmasını veya üzerine yazılmasını engeller. Çift tıklanan dosyalar güvenli sanal sandbox alanında açılır.
* **🔓 Canlı Düzenleme Modu**: Araç çubuğundaki kilit butonuna tıklandığında aktifleşir. Finder'dan doğrudan açık arşiv penceresine dosya sürükleyip ekleyebilir (`⌘N`), seçili dosyaları arşivden silebilir (`Delete`) veya harici programda düzenlenen dosyaları anında arşive geri yazabilirsiniz.

---

### 3. Yüzen Mini Panel (Floating HUD / Widget - `⌘⇧H`)

* Ekranın 4 köşesinden birine mıknatıslanarak sabitlenebilen veya serbest taşınabilen yarı saydam kompakt widget kartı.
* **Akıllı Drop-Zone:** Üzerine masaüstünden herhangi bir dosya veya klasör bırakıldığında en son kullanılan önayarla (varsayılan: Windows Dostu Temiz ZIP) anında arka planda sıkıştırır.
* **Canlı Nötron Halkası:** Aktif sıkıştırma/çıkarma işlemlerini dairesel yüzde animasyonu, MB/s anlık transfer hızı ve kalan süre göstergesi ile takip eder.

---

### 4. Sıkıştırma Konfigüratörü & "Windows Dostu" Filtre

Yeni arşiv oluştururken 3 farklı seviyede kontrol:
1. **Akıllı Önayarlar (Presets):** Tek tıkla "Windows Uyumlu Temiz ZIP", "7-Zip Ultra Maksimum", "Hızlı Paylaşım ZIP", "RAR 100MB Parçalı Arşiv".
2. **Adım Adım Sihirbaz (Wizard):** 3 adımlı rehber (1. Format ➔ 2. Güvenlik & Parola ➔ 3. Hedef Konum).
3. **Uzman Kontrol Paneli:** Sözlük boyutu, CPU çekirdek sayısı (threads), katı blok (solid) sıkıştırma, ciltlere bölme boyutu (volume split) ve AES-256 şifreleme parametreleri.
4. **Temiz Mac Filtresi:** macOS'un oluşturduğu `.DS_Store`, AppleDouble `._*` ve `__MACOSX` gizli metadata artıklarını otomatik ayıklar; Windows kullanıcılarına temiz dosya iletir.

---

### 5. Bilim Kurgu Modülleri

#### ⚡ Pulsar Warp Core (Apple Silicon Donanım Hız Testi - `⌘⇧B`)
Apple Silicon çipinizin (M1/M2/M3/M4 Pro/Max/Ultra) tüm performans ve verimlilik çekirdeklerini çalıştırır. Yerleşik multithreaded 7-Zip motorunu koşturarak gerçek zamanlı **MIPS** (Million Instructions Per Second) ve saniyelik veri akışını hesaplar; uzay temalı dairesel hız göstergesiyle raporlar.

#### 🌌 Kara Delik Klasör İzleyici (Black Hole Folder Watcher)
macOS `FSEvents` API'si ile `~/Downloads` klasörünüzü arka planda gözlemler. Yeni bir `.zip`, `.rar`, `.7z`, `.tar.gz` dosyası indirildiği anda arşivi otomatik olarak kendi adındaki klasöre açar, tercihe göre orijinal arşivi Çöp Sepetine taşır ve yerel macOS sesli bildirimi gönderir.

#### 🔧 Arşiv Kurtarma İstasyonu (Archive Repair Station)
Bozuk, CRC hatalı veya eksik inmiş RAR arşivlerini WinRAR dahili **Kurtarma Kaydı (Recovery Record)** algoritması ile tarar ve hasarlı sektörleri onararak `rebuilt.arşiv_adı.rar` olarak yeniden inşa eder.

---

## 🌌 Evrensel Format Galaksisi / Supported Formats

Pulsar, çift motorlu altyapısı sayesinde sektör standardı tüm formatları destekler:

| Kategori | Desteklenen Dosya Uzantıları | Motor | Özellikler |
| :--- | :--- | :--- | :--- |
| **Tam Okuma & Yazma** | `.7z`, `.zip`, `.tar`, `.gz`, `.bz2`, `.xz` | 7-Zip ARM64 | AES-256, Katı Blok, Çoklu Çekirdek |
| **Resmi WinRAR** | `.rar` | WinRAR CLI | Oluşturma, Açma, Kurtarma Kaydı Onarımı |
| **Yeni Nesil Hız** | `.zst`, `.zstd`, `.tzst`, `.lzma` | 7-Zip ARM64 | Ultra Yüksek Hızlı Zstandard Algoritması |
| **Paket & İmajlar** | `.iso`, `.img`, `.dmg`, `.wim`, `.swm`, `.esd` | 7-Zip ARM64 | Disk Kalıplarını ve İmajlarını İnceleme/Çıkarma |
| **Sistem & Dağıtım** | `.rpm`, `.deb`, `.cpio`, `.xar`, `.pkg` | 7-Zip ARM64 | Linux ve macOS Paketlerini İnceleme/Açma |
| **Eski & Özel** | `.cab`, `.arj`, `.lzh`, `.lha`, `.chm`, `.001` | 7-Zip ARM64 | Arşiv ve Parçalı Dosya Desteği |

---

## ⌨️ Klavye Kısayolları / Keyboard Shortcuts

| Kısayol | Eylem |
| :--- | :--- |
| `⌘1` | Modern 3-Bölmeli Düzen (Inspector) |
| `⌘2` | Kompakt Liste Düzeni |
| `⌘3` | Sekmeli Stüdyo Düzeni |
| `⌘⇧H` | Yüzen HUD Mini Paneli Göster / Gizle |
| `⌘L` | Güvenlik Kilidini Aç / Kapat (Salt Okunur vs Düzenleme) |
| `⌘N` | Yeni Arşiv Oluştur (Sıkıştırma Paneli) |
| `⌘O` | Arşiv Aç |
| `⌘E` | Açık Arşivin Tümünü Çıkar |
| `⌘⇧B` | Pulsar Warp Core Hız Testini Aç |
| `Space` | Seçili Dosyayı Canlı Önizle (QuickLook) |
| `Delete` | Seçili Dosyayı Arşivden Sil (Düzenleme açıkken) |

---

## 🛠️ Derleme ve Kurulum / Build & Installation

### Gereksinimler:
* macOS 14.0 (Sonoma) veya macOS 15.0+ (Sequoia)
* Apple Silicon (M1/M2/M3/M4) veya Universal mimari
* Swift 5.9+ / Command Line Tools

### Tek Komutla Derleme:
```bash
# 1. Projeyi klonlayın
git clone https://github.com/mehmetsensoyme/pulsar.git
cd pulsar

# 2. Pulsar.app paketini derleyin
./Scripts/build.sh

# 3. Dağıtım DMG imajını oluşturun
./Scripts/package_dmg.sh
```

Üretilen `.dmg` dosyası `dist/Pulsar-1.0.0-arm64.dmg` konumunda hazır olacaktır.

---

## 🚀 GitHub'da Yayınlama Rehberi / Release Guide

Pulsar'ı kendi GitHub hesabınızda yayınlamak için:

1. **Uzak Depoyu Ekleyin:**
   ```bash
   git remote add origin https://github.com/mehmetsensoyme/pulsar.git
   git push -u origin main
   ```

2. **İlk Sürümü (Release) Gönderin:**
   GitHub Actions otomasyonu (`release.yml`), etiket gönderildiğinde otomatik derleme yapar ve DMG dosyasını Releases sayfasına ekler:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **Tanıtım Web Sitesini Canlıya Alın (GitHub Pages):**
   * Repo ayarlarınızda **Settings ➔ Pages** sekmesine gidin.
   * **Source:** `Deploy from a branch`
   * **Branch:** `main` | **Folder:** `/Website` seçip kaydedin.
   * Siteniz `https://mehmetsensoyme.github.io/pulsar` adresinde canlıya geçer!

---

## 📄 Lisans / License

Bu proje **MIT Lisansı** altında lisanslanmıştır. Dahili 7-Zip motoru Igor Pavlov'un LGPL lisansına, RAR motoru ise RARLAB kullanım koşullarına tabidir.
