#!/usr/bin/env bash
# Regenerates AppUninstaller/AppIcon.icns from BrandAssets/AppIcon-master-1024.png
# Requires: macOS sips + iconutil

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MASTER="${ROOT}/AppUninstaller/BrandAssets/AppIcon-master-1024.png"
OUT="${ROOT}/AppUninstaller/AppIcon.iconset"
ICNS="${ROOT}/AppUninstaller/AppIcon.icns"

if [[ ! -f "$MASTER" ]]; then
  echo "error: missing master image: $MASTER" >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"

sips -z 16 16 "$MASTER" --out "$OUT/icon_16x16.png" >/dev/null
sips -z 32 32 "$MASTER" --out "$OUT/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$MASTER" --out "$OUT/icon_32x32.png" >/dev/null
sips -z 64 64 "$MASTER" --out "$OUT/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$MASTER" --out "$OUT/icon_128x128.png" >/dev/null
sips -z 256 256 "$MASTER" --out "$OUT/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$MASTER" --out "$OUT/icon_256x256.png" >/dev/null
sips -z 512 512 "$MASTER" --out "$OUT/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$MASTER" --out "$OUT/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$MASTER" --out "$OUT/icon_512x512@2x.png" >/dev/null

iconutil -c icns "$OUT" -o "$ICNS"
rm -rf "$OUT"

echo "Wrote: $ICNS"
