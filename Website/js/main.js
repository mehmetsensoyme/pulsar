document.addEventListener("DOMContentLoaded", () => {
  // Sürüm Bilgilerini changelog.json'dan Yükle
  fetch("changelog.json")
    .then((res) => res.json())
    .then((data) => {
      document.querySelectorAll(".version-tag").forEach((el) => {
        el.textContent = `v${data.currentVersion} (${data.currentCodeName})`;
      });
      document.querySelectorAll(".sha-tag").forEach((el) => {
        el.textContent = `SHA-256: ${data.download.sha256.substring(0, 16)}...`;
      });
      document.querySelectorAll(".dmg-size").forEach((el) => {
        el.textContent = data.download.dmgSize;
      });
    })
    .catch((err) => console.log("Changelog yüklenemedi", err));

  // Canlı Ekran Görüntüleri ve Tema Değiştirici
  const showcaseTabs = document.querySelectorAll(".showcase-tab");
  const darkBtn = document.getElementById("theme-dark-btn");
  const lightBtn = document.getElementById("theme-light-btn");
  const mainScreenshot = document.getElementById("main-screenshot");
  const captionEl = document.getElementById("screenshot-caption");

  let currentView = "hero";
  let currentTheme = "dark";

  const viewData = {
    hero: {
      dark: "assets/hero_dark.png",
      light: "assets/hero_light.png",
      caption: "<strong>Ferah Boş Durum (Empty Hero Zone):</strong> Arşiv açık değilken tüm çalışma alanına yayılan Apple karşılama paneli, sürükle-bırak hedef alanı, ⌘O Arşiv Aç, ⌘N Yeni Arşiv ve son kullanılanlar."
    },
    browse: {
      dark: "assets/browse_dark.png",
      light: "assets/browse_light.png",
      caption: "<strong>Modern 3-Bölmeli Arşiv Gezgini:</strong> Sanal dizin sentezleme, Finder klasör simgeleri, QuickLook (Boşluk) önizleme, sıralanabilir sütunlar ve dosya denetçisi (Inspector)."
    },
    compact: {
      dark: "assets/compact_dark.png",
      light: "assets/compact_light.png",
      caption: "<strong>Kompakt Liste Düzeni (⌘2):</strong> Yalnızca breadcrumb gezinme çubuğu ve yoğunlaştırılmış dosya listesini içeren sade arayüz görünümü."
    },
    settings: {
      dark: "assets/settings_dark.png",
      light: "assets/settings_light.png",
      caption: "<strong>Ayarlar Stüdyosu - Genel (⌘,):</strong> 600×500 px standart macOS paneli, Sonoma/Sequoia tarzı form kartları, canlı arayüz düzeni senkronizasyonu ve bildirim kontrolleri."
    },
    settings_engines: {
      dark: "assets/settings_engines_dark.png",
      light: "assets/settings_engines_light.png",
      caption: "<strong>Motorlar & Donanım Stüdyosu:</strong> Apple Silicon ARM64 native 7-Zip (7zz 26.04) ve resmi WinRAR motor durumları, çekirdek iş parçacığı ayarı ve canlı sağlık testleri."
    },
    compress: {
      dark: "assets/compress_dark.png",
      light: "assets/compress_light.png",
      caption: "<strong>Yeni Arşiv Oluşturucu (⌘N):</strong> Hedef klasör seçici (Destination Picker), çıkarılabilir kaynak etiketleri, akıllı hazır ayarlar ve Windows uyumlu .DS_Store temizleyici."
    },
    folderwatcher: {
      dark: "assets/folderwatcher_dark.png",
      light: "assets/folderwatcher_light.png",
      caption: "<strong>Kara Delik Klasör İzleyici:</strong> İndirilenler klasörüne düşen arşivleri arka planda FSEvents ile yakalayıp otomatik açar ve işlenen arşivleri yönetir."
    },
    benchmark: {
      dark: "assets/benchmark_dark.png",
      light: "assets/benchmark_light.png",
      caption: "<strong>Warp Core Donanım Hız Testi (⌘⇧B):</strong> Apple Silicon M4/M3/M2 çoklu çekirdeklerini zorlayan gerçek zamanlı MIPS ve sıkıştırma hız ölçer."
    },
    repair: {
      dark: "assets/repair_dark.png",
      light: "assets/repair_light.png",
      caption: "<strong>Kurtarma İstasyonu:</strong> WinRAR Recovery Record (Kurtarma Kaydı) algoritmasını çalıştırarak hasarlı veya CRC hatalı arşivleri onaran sistem aracı."
    }
  };

  function updateShowcase() {
    if (!mainScreenshot || !viewData[currentView]) return;
    const data = viewData[currentView];
    const newSrc = currentTheme === "dark" ? data.dark : data.light;
    mainScreenshot.style.opacity = "0.4";
    setTimeout(() => {
      mainScreenshot.src = newSrc;
      mainScreenshot.style.opacity = "1";
    }, 120);
    if (captionEl) {
      captionEl.innerHTML = data.caption;
    }
  }

  showcaseTabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      showcaseTabs.forEach((t) => t.classList.remove("active"));
      tab.classList.add("active");
      currentView = tab.getAttribute("data-view");
      updateShowcase();
    });
  });

  if (darkBtn && lightBtn) {
    darkBtn.addEventListener("click", () => {
      darkBtn.classList.add("active");
      lightBtn.classList.remove("active");
      currentTheme = "dark";
      updateShowcase();
    });
    lightBtn.addEventListener("click", () => {
      lightBtn.classList.add("active");
      darkBtn.classList.remove("active");
      currentTheme = "light";
      updateShowcase();
    });
  }

  // Canlı Benchmark Simülatörü
  const benchBtn = document.getElementById("run-bench-btn");
  const benchScore = document.getElementById("bench-score");
  const benchStatus = document.getElementById("bench-status");

  if (benchBtn && benchScore && benchStatus) {
    benchBtn.addEventListener("click", () => {
      benchBtn.disabled = true;
      benchStatus.textContent = "Warp Core çekirdekleri ölçülüyor...";
      benchScore.textContent = "0";

      let current = 0;
      const target = 127984; // Apple M4 Pro skoru
      const step = Math.floor(target / 40);

      const interval = setInterval(() => {
        current += step;
        if (current >= target) {
          current = target;
          clearInterval(interval);
          benchScore.textContent = current.toLocaleString();
          benchStatus.textContent = "Test Tamamlandı! (Apple M4 Pro 12C / 12T)";
          benchBtn.disabled = false;
        } else {
          benchScore.textContent = current.toLocaleString();
        }
      }, 30);
    });
  }
});
