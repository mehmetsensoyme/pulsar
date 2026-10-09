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

  // İnteraktif Görünüm Modları Değiştirici
  const tabs = document.querySelectorAll(".window-tab");
  const previewContent = document.getElementById("preview-content");

  const modeViews = {
    threePane: `
      <div style="display: grid; grid-template-columns: 200px 1fr 220px; gap: 12px; height: 360px;">
        <div style="background: rgba(255,255,255,0.03); border-radius: 8px; padding: 12px; font-size: 0.85rem;">
          <div style="color: #8a99ad; font-size: 0.75rem; font-weight: bold; margin-bottom: 8px;">SON ARŞİVLER</div>
          <div style="padding: 6px; background: rgba(0,242,254,0.1); border-radius: 6px; color: #00f2fe; margin-bottom: 4px;">📦 Proje_Arsivi.7z</div>
          <div style="padding: 6px; color: #cbd5e1; margin-bottom: 4px;">📦 Yedekler_2026.rar</div>
          <div style="padding: 6px; color: #cbd5e1;">📦 Asset_Paketi.zip</div>
          <div style="margin-top: 24px; color: #8a99ad; font-size: 0.75rem; font-weight: bold; margin-bottom: 8px;">SİSTEM MODÜLLERİ</div>
          <div style="padding: 6px; color: #c499f3;">⚡ Warp Benchmark</div>
          <div style="padding: 6px; color: #c499f3;">🌌 Kara Delik İzleyici</div>
          <div style="padding: 6px; color: #c499f3;">🔧 Kurtarma İstasyonu</div>
        </div>
        <div style="background: rgba(255,255,255,0.02); border-radius: 8px; padding: 12px;">
          <div style="display: flex; gap: 8px; font-size: 0.8rem; border-bottom: 1px solid rgba(255,255,255,0.1); padding-bottom: 8px; margin-bottom: 8px; color: #8a99ad;">
            <span style="flex: 2;">AD</span>
            <span style="flex: 1;">BOYUT</span>
            <span style="flex: 1;">SIKIŞTIRILMIŞ</span>
            <span style="flex: 1;">ORAN</span>
          </div>
          <div style="display: flex; gap: 8px; font-size: 0.85rem; padding: 6px 0; border-bottom: 1px solid rgba(255,255,255,0.05); color: #fff;">
            <span style="flex: 2;">📁 Kaynak_Kodlar</span>
            <span style="flex: 1;">--</span>
            <span style="flex: 1;">--</span>
            <span style="flex: 1;">--</span>
          </div>
          <div style="display: flex; gap: 8px; font-size: 0.85rem; padding: 6px 0; border-bottom: 1px solid rgba(255,255,255,0.05); color: #fff;">
            <span style="flex: 2;">📄 Main.swift</span>
            <span style="flex: 1;">12.4 KB</span>
            <span style="flex: 1;">3.2 KB</span>
            <span style="flex: 1; color: #00f2fe;">%74.2</span>
          </div>
          <div style="display: flex; gap: 8px; font-size: 0.85rem; padding: 6px 0; color: #fff;">
            <span style="flex: 2;">📄 RenderEngine.metal</span>
            <span style="flex: 1;">84.0 KB</span>
            <span style="flex: 1;">18.5 KB</span>
            <span style="flex: 1; color: #00f2fe;">%78.0</span>
          </div>
        </div>
        <div style="background: rgba(255,255,255,0.03); border-radius: 8px; padding: 16px; text-align: center;">
          <div style="font-size: 2.5rem; margin-bottom: 8px;">📄</div>
          <div style="font-weight: bold; font-size: 0.9rem; margin-bottom: 4px;">Main.swift</div>
          <div style="display: inline-block; padding: 2px 8px; border-radius: 99px; background: rgba(0,242,254,0.15); color: #00f2fe; font-size: 0.75rem; margin-bottom: 16px;">SWIFT SOURCE</div>
          <div style="text-align: left; font-size: 0.8rem; color: #8a99ad; display: flex; flex-direction: column; gap: 6px;">
            <div>Orijinal: <strong style="color: #fff;">12.4 KB</strong></div>
            <div>Sıkıştırılmış: <strong style="color: #fff;">3.2 KB</strong></div>
            <div>CRC32: <strong style="color: #fff; font-family: monospace;">A8F19B02</strong></div>
          </div>
        </div>
      </div>
    `,
    compactList: `
      <div style="background: rgba(255,255,255,0.02); border-radius: 8px; padding: 16px; height: 360px;">
        <div style="display: flex; gap: 8px; font-size: 0.8rem; border-bottom: 1px solid rgba(255,255,255,0.1); padding-bottom: 8px; margin-bottom: 8px; color: #8a99ad; font-weight: bold;">
          <span style="flex: 3;">DOSYA ADI</span>
          <span style="flex: 1;">TÜR</span>
          <span style="flex: 1;">BOYUT</span>
          <span style="flex: 1;">SIKIŞTIRILMIŞ</span>
          <span style="flex: 1;">ORAN</span>
          <span style="flex: 2;">DEĞİŞTİRİLME</span>
        </div>
        <div style="display: flex; gap: 8px; font-size: 0.85rem; padding: 6px 0; border-bottom: 1px solid rgba(255,255,255,0.05); color: #fff;">
          <span style="flex: 3;">📁 Sources</span>
          <span style="flex: 1;">Klasör</span>
          <span style="flex: 1;">--</span>
          <span style="flex: 1;">--</span>
          <span style="flex: 1;">--</span>
          <span style="flex: 2; color: #8a99ad;">Bugün 17:34</span>
        </div>
        <div style="display: flex; gap: 8px; font-size: 0.85rem; padding: 6px 0; border-bottom: 1px solid rgba(255,255,255,0.05); color: #fff;">
          <span style="flex: 3;">📄 PulsarApp.swift</span>
          <span style="flex: 1;">Swift</span>
          <span style="flex: 1;">4.2 KB</span>
          <span style="flex: 1;">1.1 KB</span>
          <span style="flex: 1; color: #00f2fe;">%73.8</span>
          <span style="flex: 2; color: #8a99ad;">Bugün 17:30</span>
        </div>
        <div style="display: flex; gap: 8px; font-size: 0.85rem; padding: 6px 0; border-bottom: 1px solid rgba(255,255,255,0.05); color: #fff;">
          <span style="flex: 3;">📄 SevenZipEngine.swift</span>
          <span style="flex: 1;">Swift</span>
          <span style="flex: 1;">8.9 KB</span>
          <span style="flex: 1;">2.3 KB</span>
          <span style="flex: 1; color: #00f2fe;">%74.1</span>
          <span style="flex: 2; color: #8a99ad;">Bugün 17:28</span>
        </div>
        <div style="display: flex; gap: 8px; font-size: 0.85rem; padding: 6px 0; border-bottom: 1px solid rgba(255,255,255,0.05); color: #fff;">
          <span style="flex: 3;">⚙️ 7zz</span>
          <span style="flex: 1;">ARM64 İkili</span>
          <span style="flex: 1;">2.68 MB</span>
          <span style="flex: 1;">1.14 MB</span>
          <span style="flex: 1; color: #00f2fe;">%57.4</span>
          <span style="flex: 2; color: #8a99ad;">Bugün 17:25</span>
        </div>
      </div>
    `,
    tabbedStudio: `
      <div style="height: 360px; display: flex; flex-direction: column;">
        <div style="display: flex; gap: 4px; background: rgba(0,0,0,0.3); padding: 4px 8px; border-radius: 8px 8px 0 0; border-bottom: 1px solid rgba(255,255,255,0.1);">
          <div style="padding: 6px 14px; background: rgba(255,255,255,0.1); border-radius: 6px; font-size: 0.8rem; font-weight: bold; color: #00f2fe;">📦 Pulsar_M4_Build.7z ✕</div>
          <div style="padding: 6px 14px; background: transparent; border-radius: 6px; font-size: 0.8rem; color: #8a99ad;">📦 Windows_Clean.zip ✕</div>
          <div style="padding: 6px 14px; background: transparent; border-radius: 6px; font-size: 0.8rem; color: #8a99ad;">📦 Backup_Split.part1.rar ✕</div>
        </div>
        <div style="flex: 1; background: rgba(255,255,255,0.02); padding: 16px; border-radius: 0 0 8px 8px;">
          <div style="color: #00f2fe; font-size: 0.85rem; font-weight: bold; margin-bottom: 12px;">SEKMELER ARASI SÜRÜKLE-BIRAK AKTİF</div>
          <div style="color: #8a99ad; font-size: 0.85rem;">Birden çok arşivi sekmeler halinde açık tutabilir, dosyaları bir arşivden diğerine anında kopyalayabilirsiniz.</div>
        </div>
      </div>
    `,
  };

  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      tabs.forEach((t) => t.classList.remove("active"));
      tab.classList.add("active");
      const mode = tab.getAttribute("data-mode");
      if (modeViews[mode]) {
        previewContent.innerHTML = modeViews[mode];
      }
    });
  });

  // Varsayılan görünümü yükle
  if (previewContent) {
    previewContent.innerHTML = modeViews.threePane;
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
