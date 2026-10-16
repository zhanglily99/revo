#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
BUILD_OPTIONS=(--disable-sandbox --config-path .swiftpm/config --cache-path .swiftpm/cache --security-path .swiftpm/security)
if [[ "${REVO_UNIVERSAL:-0}" == "1" ]]; then
  swift build -c release --product Revo --triple arm64-apple-macosx14.0 --scratch-path .build "${BUILD_OPTIONS[@]}"
  swift build -c release --product Revo --triple x86_64-apple-macosx14.0 --scratch-path .build/intel "${BUILD_OPTIONS[@]}"
else
  swift build -c release --product Revo --scratch-path .build "${BUILD_OPTIONS[@]}"
fi

APP="build/Revo.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/Revo.iconset
if [[ "${REVO_UNIVERSAL:-0}" == "1" ]]; then
  lipo -create .build/arm64-apple-macosx/release/Revo .build/intel/x86_64-apple-macosx/release/Revo -output "$APP/Contents/MacOS/Revo"
else
  cp .build/release/Revo "$APP/Contents/MacOS/Revo"
fi
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp LICENSE "$APP/Contents/Resources/LICENSE.txt"
sips -z 1024 1024 Resources/AppIcon.png --out build/icon.png >/dev/null
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
