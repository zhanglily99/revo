#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

DMGBUILD="${REVO_DMGBUILD:-.build/packaging-venv/bin/dmgbuild}"
if [[ ! -x "$DMGBUILD" ]]; then
  echo "Install the packaging dependencies described in README.md first." >&2
  exit 1
fi

REVO_UNIVERSAL=1 ./scripts/build-app.sh
swift scripts/render-installer.swift "$PWD/build"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
mkdir -p build/release
DISK_IMAGE="build/release/Revo-${VERSION}-universal.dmg"
if [[ -e "$DISK_IMAGE" ]]; then
  echo "Release image already exists: $DISK_IMAGE" >&2
  exit 1
fi
"$DMGBUILD" -s scripts/dmg-settings.py "Revo" "$DISK_IMAGE"
hdiutil verify "$DISK_IMAGE"
codesign --verify --all-architectures --deep --strict build/Revo.app
lipo build/Revo.app/Contents/MacOS/Revo -verify_arch arm64 x86_64
# Verify the copy inside the completed image as well as the source app bundle.
REVIEW_DIR=$(mktemp -d "$PWD/build/release-check.XXXXXX")
trap 'hdiutil detach "$REVIEW_DIR" >/dev/null 2>&1 || true; rmdir "$REVIEW_DIR" 2>/dev/null || true' EXIT
hdiutil attach -readonly -nobrowse -mountpoint "$REVIEW_DIR" "$DISK_IMAGE" >/dev/null
codesign --verify --all-architectures --deep --strict "$REVIEW_DIR/Revo.app"
cmp build/Revo.app/Contents/MacOS/Revo "$REVIEW_DIR/Revo.app/Contents/MacOS/Revo"
cmp LICENSE "$REVIEW_DIR/Revo.app/Contents/Resources/LICENSE.txt"
[[ "$(readlink "$REVIEW_DIR/Applications")" == "/Applications" ]]
hdiutil detach "$REVIEW_DIR" >/dev/null
rmdir "$REVIEW_DIR"
trap - EXIT
cp LICENSE build/release/LICENSE.txt
(cd build/release && shasum -a 256 "Revo-${VERSION}-universal.dmg" LICENSE.txt > SHA256SUMS.txt)
echo "Packaged: $DISK_IMAGE"
