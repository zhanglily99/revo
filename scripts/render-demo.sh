#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release --product Revo --disable-sandbox --scratch-path .build \
  --config-path .swiftpm/config --cache-path .swiftpm/cache --security-path .swiftpm/security
CAPTURE=$(mktemp -d "$PWD/build/demo-frames.XXXXXX")
.build/release/Revo --record-demo "$CAPTURE"
python3 scripts/encode-demo.py "$CAPTURE" docs/images/demo.gif
echo "Capture frames retained at: $CAPTURE"
