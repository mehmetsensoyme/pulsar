#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$ROOT_DIR/Engines/bin"
APP_DIR="$ROOT_DIR/PulsarApp"
BUNDLE_DIR="$ROOT_DIR/build/Pulsar.app"

echo "🌌 [PULSAR] Derleme Süreci Başlatılıyor..."

# 1. 7zz Motorunu Kontrol Et
if [ ! -f "$BIN_DIR/7zz" ]; then
    echo "⚡ [7-Zip] $BIN_DIR/7zz aranıyor..."
    if [ -d "$ROOT_DIR/../7z2604-src" ]; then
        make -C "$ROOT_DIR/../7z2604-src/CPP/7zip/Bundles/Alone2" -f makefile.gcc -j$(sysctl -n hw.ncpu)
        mkdir -p "$BIN_DIR"
        cp "$ROOT_DIR/../7z2604-src/CPP/7zip/Bundles/Alone2/_o/7zz" "$BIN_DIR/7zz"
        chmod +x "$BIN_DIR/7zz"
    fi
fi

# 2. İkilileri Hazırla
mkdir -p "$BIN_DIR"
for bin in "$BIN_DIR"/*; do
    if [ -f "$bin" ]; then
        xattr -c "$bin" 2>/dev/null || true
        chmod +x "$bin" 2>/dev/null || true
    fi
done

# 3. Swift Release Derlemesi
echo "🚀 [Swift] Pulsar Native App derleniyor (Release modu)..."
cd "$APP_DIR"
swift build -c release

RELEASE_BIN_DIR="$(swift build -c release --show-bin-path 2>/dev/null || true)"
if [ -n "$RELEASE_BIN_DIR" ] && [ -f "$RELEASE_BIN_DIR/Pulsar" ]; then
    PULSAR_BIN="$RELEASE_BIN_DIR/Pulsar"
elif [ -f "$APP_DIR/.build/release/Pulsar" ]; then
    PULSAR_BIN="$APP_DIR/.build/release/Pulsar"
else
    PULSAR_BIN="$(find "$APP_DIR/.build" -name "Pulsar" -type f ! -path "*/dSYM/*" | head -n 1)"
fi

if [ -z "$PULSAR_BIN" ] || [ ! -f "$PULSAR_BIN" ]; then
    echo "❌ Hata: Derlenmiş Pulsar ikili dosyası bulunamadı!"
    exit 1
fi
echo "📍 Kullanılan ikili dosya: $PULSAR_BIN"

# 4. macOS .app Paketi Oluştur
echo "📦 [macOS] Pulsar.app uygulama paketi oluşturuluyor..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources/bin"

cp "$PULSAR_BIN" "$BUNDLE_DIR/Contents/MacOS/Pulsar"
[ -f "$BIN_DIR/7zz" ] && cp "$BIN_DIR/7zz" "$BUNDLE_DIR/Contents/Resources/bin/"
[ -f "$BIN_DIR/rar" ] && cp "$BIN_DIR/rar" "$BUNDLE_DIR/Contents/Resources/bin/"
[ -f "$BIN_DIR/unrar" ] && cp "$BIN_DIR/unrar" "$BUNDLE_DIR/Contents/Resources/bin/"

chmod +x "$BUNDLE_DIR/Contents/MacOS/Pulsar"
for rbin in "$BUNDLE_DIR/Contents/Resources/bin"/*; do
    [ -f "$rbin" ] && chmod +x "$rbin" 2>/dev/null || true
done

# Info.plist Oluştur
cat << 'EOF' > "$BUNDLE_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Pulsar</string>
    <key>CFBundleIdentifier</key>
    <string>com.pulsar.archive</string>
    <key>CFBundleName</key>
    <string>Pulsar</string>
    <key>CFBundleDisplayName</key>
    <string>Pulsar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.0</string>
    <key>CFBundleVersion</key>
    <string>2613</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Pulsar Contributors. All rights reserved.</string>
</dict>
</plist>
EOF

# Kod İmzalama (Ad-Hoc)
echo "🔏 [Codesign] Ad-hoc kod imzalama uygulanıyor..."
xattr -cr "$BUNDLE_DIR" 2>/dev/null || true
codesign --force --deep --timestamp=none --sign - "$BUNDLE_DIR" || echo "⚠️ Ad-hoc kod imzalama atlandı veya uyarı verdi (CI ortamı)"

echo "✨ [PULSAR] Başarıyla derlendi ve paketlendi: $BUNDLE_DIR"
