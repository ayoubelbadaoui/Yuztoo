#!/usr/bin/env bash
# Generate every app icon + notification icon Yuztoo needs from the single
# source PNG at `assets/branding/app_icon.png`.
#
# Pipeline:
#   1. Build the monochrome silhouette + status-bar icons (Python + Pillow).
#   2. Run `flutter_launcher_icons` to produce the iOS + Android launcher
#      icons (legacy mipmaps + adaptive icon + Android-13 themed icon).
#
# Run from project root:  ./tools/build_app_icons.sh
set -euo pipefail

cd "$(dirname "$0")/.."

SRC="assets/branding/app_icon.png"
if [[ ! -f "$SRC" ]]; then
  echo "❌ $SRC missing — save the 1024×1024 bird-in-pin PNG there first." >&2
  exit 1
fi

echo "▶ checking source dimensions"
DIMS=$(sips -g pixelWidth -g pixelHeight "$SRC" 2>/dev/null | awk '/pixel(Width|Height)/ {print $2}' | tr '\n' 'x' | sed 's/x$//')
echo "   $SRC is ${DIMS}"
if [[ "$DIMS" != *"1024"* ]] && [[ "$DIMS" != *"2048"* ]]; then
  echo "⚠ warning: source is not 1024×1024 (or 2048×2048). Icons will still"
  echo "  generate, but the smaller densities may look blurry. 1024+ recommended."
fi

echo ""
echo "▶ generating Android notification icons + monochrome silhouette"
python3 tools/build_notification_icon.py

echo ""
echo "▶ generating iOS + Android launcher icons via flutter_launcher_icons"
dart run flutter_launcher_icons

echo ""
echo "✅ done. Check the changes:"
echo "   • ios/Runner/Assets.xcassets/AppIcon.appiconset/"
echo "   • android/app/src/main/res/mipmap-*/"
echo "   • android/app/src/main/res/drawable-*/ic_stat_yuztoo.png"
echo ""
echo "Hot-restart won't pick up native icon changes — do a full"
echo "  flutter clean && flutter run -d <device>"
echo "to see the new launcher icon."
