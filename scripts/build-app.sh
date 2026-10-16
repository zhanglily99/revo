#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release --product Revo \
  --disable-sandbox --scratch-path .build \
  --config-path .swiftpm/config --cache-path .swiftpm/cache --security-path .swiftpm/security

APP="build/Revo.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/Revo.iconset
cp .build/release/Revo "$APP/Contents/MacOS/Revo"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp LICENSE "$APP/Contents/Resources/LICENSE.txt"
.build/release/Revo --export-icon "$PWD/build/icon.png"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" build/icon.png --out "build/Revo.iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" build/icon.png --out "build/Revo.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns build/Revo.iconset -o "$APP/Contents/Resources/Revo.icns"
# This obsolete generated photo is no longer used by the layer-based renderer.
rm -f "$APP/Contents/Resources/shredder.png"
codesign --force --sign - "$APP"
echo "built: $APP"
