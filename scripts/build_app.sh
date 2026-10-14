#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
app_path="$project_root/.build/app/Learper.app"
binary_path="$app_path/Contents/MacOS/Learper"

mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
xcrun --sdk macosx swiftc \
  -target "$(uname -m)-apple-macos13.0" \
  -sdk "$sdk_path" \
  -O \
  "$project_root"/Sources/Learper/*.swift \
  -o "$binary_path"

cp -R "$project_root/Sources/Learper/Resources/." "$app_path/Contents/Resources/"
cat > "$app_path/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>Learper</string>
  <key>CFBundleIdentifier</key><string>dev.dizmerly.learper</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Learper</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

echo "$app_path"
