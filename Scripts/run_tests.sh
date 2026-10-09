#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$ROOT_DIR/PulsarApp"

echo "🧪 [PULSAR] Test paketi derleniyor ve koşturuluyor..."
cd "$APP_DIR"
swift build

DEBUG_BIN_DIR="$(swift build --show-bin-path 2>/dev/null || true)"
if [ -n "$DEBUG_BIN_DIR" ] && [ -f "$DEBUG_BIN_DIR/Pulsar" ]; then
    TEST_BIN="$DEBUG_BIN_DIR/Pulsar"
elif [ -f "$APP_DIR/.build/debug/Pulsar" ]; then
    TEST_BIN="$APP_DIR/.build/debug/Pulsar"
else
    TEST_BIN="$(find "$APP_DIR/.build" -name "Pulsar" -type f ! -path "*/dSYM/*" | head -n 1)"
fi

if [ -z "$TEST_BIN" ] || [ ! -f "$TEST_BIN" ]; then
    echo "❌ Hata: Test ikili dosyası bulunamadı!"
    exit 1
fi
echo "📍 Test ikili dosyası: $TEST_BIN"

"$TEST_BIN" --run-tests
