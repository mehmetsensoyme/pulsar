#!/bin/bash
set -e

SERVICES_DIR="$HOME/Library/Services"
mkdir -p "$SERVICES_DIR"

APP_PATH="/Applications/Pulsar.app"
if [ ! -d "$APP_PATH" ]; then
    APP_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../build/Pulsar.app" && pwd)"
fi

echo "⚡ [Pulsar] Finder Hızlı Eylemleri Hazırlanıyor..."

# 1. Pulsar ile Sıkıştır.workflow
WORKFLOW_COMPRESS="$SERVICES_DIR/Pulsar ile Sıkıştır.workflow"
mkdir -p "$WORKFLOW_COMPRESS/Contents"

cat << 'EOF' > "$WORKFLOW_COMPRESS/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>Pulsar ile Sıkıştır</string>
            </dict>
            <key>NSMessage</key>
            <string>runWorkflowAsService</string>
            <key>NSSendFileTypes</key>
            <array>
                <string>public.item</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

cat << EOF > "$WORKFLOW_COMPRESS/Contents/document.wflow"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>523</string>
    <key>AMApplicationVersion</key>
    <string>2.10</string>
    <key>AMDocumentVersion</key>
    <string>2</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run AppleScript.action</string>
                <key>ActionName</key>
                <string>Run AppleScript</string>
                <key>ActionParameters</key>
                <dict>
                    <key>source</key>
                    <string>on run {input, parameters}
    tell application "$APP_PATH"
        activate
        open input
    end tell
    return input
end run</string>
                </dict>
                <key>BundleIdentifier</key>
                <string>com.apple.Automator.RunScript</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF

# 2. Pulsar ile Çıkar.workflow
WORKFLOW_EXTRACT="$SERVICES_DIR/Pulsar ile Çıkar.workflow"
mkdir -p "$WORKFLOW_EXTRACT/Contents"

cat << 'EOF' > "$WORKFLOW_EXTRACT/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>Pulsar ile Çıkar</string>
            </dict>
            <key>NSMessage</key>
            <string>runWorkflowAsService</string>
            <key>NSSendFileTypes</key>
            <array>
                <string>public.item</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

cat << EOF > "$WORKFLOW_EXTRACT/Contents/document.wflow"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>523</string>
    <key>AMApplicationVersion</key>
    <string>2.10</string>
    <key>AMDocumentVersion</key>
    <string>2</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run AppleScript.action</string>
                <key>ActionName</key>
                <string>Run AppleScript</string>
                <key>ActionParameters</key>
                <dict>
                    <key>source</key>
                    <string>on run {input, parameters}
    tell application "$APP_PATH"
        activate
        open input
    end tell
    return input
end run</string>
                </dict>
                <key>BundleIdentifier</key>
                <string>com.apple.Automator.RunScript</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF

/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -R "$SERVICES_DIR" 2>/dev/null || true
echo "✨ [Pulsar] Finder Hızlı Eylemleri başarıyla yüklendi: ~/Library/Services"
