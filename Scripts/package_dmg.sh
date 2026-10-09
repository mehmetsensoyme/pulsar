#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PATH="$ROOT_DIR/build/Pulsar.app"
DIST_DIR="$ROOT_DIR/dist"
DMG_NAME="Pulsar-1.0.0-arm64.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
TEMP_DMG_DIR="$ROOT_DIR/build/dmg_temp"

echo "💿 [PULSAR] Dağıtım DMG İmajı Hazırlanıyor..."

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Hata: $APP_PATH bulunamadı. Önce build.sh çalıştırın."
    exit 1
fi

mkdir -p "$DIST_DIR"
rm -rf "$TEMP_DMG_DIR" "$DMG_PATH"
mkdir -p "$TEMP_DMG_DIR"

# Uygulamayı ve Applications sembolik bağını kopyala
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# hdiutil ile sıkıştırılmış DMG üret
echo "⚙️ hdiutil ile DMG paketleniyor..."
hdiutil create -volname "Pulsar" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "$DMG_PATH"

# SHA256 Doğrulama Özeti Oluştur
cd "$DIST_DIR"
shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"

rm -rf "$TEMP_DMG_DIR"
echo "🎉 [PULSAR] DMG başarıyla üretildi: $DMG_PATH"
cat "$DMG_PATH.sha256"
