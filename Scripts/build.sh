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

# 2. RAR İkililerini Hazırla
if [ -f "$BIN_DIR/rar" ] && [ -f "$BIN_DIR/unrar" ]; then
    xattr -c "$BIN_DIR/rar" "$BIN_DIR/unrar" 2>/dev/null || true
    chmod +x "$BIN_DIR/rar" "$BIN_DIR/unrar"
fi

# 3. Swift Release Derlemesi
echo "🚀 [Swift] Pulsar Native App derleniyor (Release modu)..."
cd "$APP_DIR"
swift build -c release

# 4. macOS .app Paketi Oluştur
echo "📦 [macOS] Pulsar.app uygulama paketi oluşturuluyor..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources/bin"

cp "$APP_DIR/.build/release/Pulsar" "$BUNDLE_DIR/Contents/MacOS/Pulsar"
cp "$BIN_DIR/7zz" "$BUNDLE_DIR/Contents/Resources/bin/"
cp "$BIN_DIR/rar" "$BUNDLE_DIR/Contents/Resources/bin/"
cp "$BIN_DIR/unrar" "$BUNDLE_DIR/Contents/Resources/bin/"
chmod +x "$BUNDLE_DIR/Contents/MacOS/Pulsar"
chmod +x "$BUNDLE_DIR/Contents/Resources/bin/"*

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
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>2604</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Pulsar Contributors. All rights reserved.</string>
</dict>
</plist>
EOF

echo "✨ [PULSAR] Başarıyla derlendi ve paketlendi: $BUNDLE_DIR"
