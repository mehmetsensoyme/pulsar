#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$ROOT_DIR/PulsarApp"

echo "🧪 [PULSAR] Test paketi derleniyor ve koşturuluyor..."
cd "$APP_DIR"
swift build
.build/debug/Pulsar --run-tests
