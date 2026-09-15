#!/bin/zsh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

app="$root/dist/KeepDrivesAwake.app"
macos="$app/Contents/MacOS"
resources="$app/Contents/Resources"

rm -rf "$app"
mkdir -p "$macos" "$resources"

swiftc -O -parse-as-library \
  -framework AppKit \
  -target arm64-apple-macos14.0 \
  -o "$macos/KeepDrivesAwake" \
  "$root"/Sources/KeepDrivesAwake/*.swift

cp "$root/Info.plist" "$app/Contents/Info.plist"
echo -n 'APPL????' > "$app/Contents/PkgInfo"

# Stable identity so macOS can remember Removable Volumes permission.
codesign --force --sign - --identifier ca.arnall.KeepDrivesAwake "$app"

echo "Built $app"
echo "Copy to /Applications, then open it. Allow Removable Volumes once."
