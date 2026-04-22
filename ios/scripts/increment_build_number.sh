#!/bin/sh
# Bump pubspec.yaml build (+N) before Flutter's xcode_backend reads it.
# Only runs when Xcode archives (ACTION=install), so normal Run/Debug does not
# rewrite pubspec.yaml on every build.

set -eu

if [ "${ACTION:-}" != "install" ]; then
  echo "Bump build: skipping (ACTION is '${ACTION:-build}', not install)."
  exit 0
fi

REPO_ROOT="${SRCROOT}/.."
cd "$REPO_ROOT"

PUBSPEC="pubspec.yaml"
if [ ! -f "$PUBSPEC" ]; then
  echo "error: pubspec.yaml not found at $REPO_ROOT" >&2
  exit 1
fi

before=$(grep -E '^[[:space:]]*version:' "$PUBSPEC" | head -1 || true)
if [ -z "$before" ]; then
  echo "error: no version: line in pubspec.yaml" >&2
  exit 1
fi

perl -i -pe 'if(/^\s*version:\s*([0-9.]+)\+([0-9]+)\s*$/){$_="version: $1+".($2+1)."\n";}' "$PUBSPEC"

after=$(grep -E '^[[:space:]]*version:' "$PUBSPEC" | head -1 || true)
if [ "$before" = "$after" ]; then
  echo "error: failed to bump pubspec version (need x.y.z+N, e.g. 1.0.0+1). Was: $before" >&2
  exit 1
fi

echo "Bump build: $before -> $after"

if [ -z "${FLUTTER_ROOT:-}" ] && [ -f "${SRCROOT}/Flutter/Generated.xcconfig" ]; then
  FLUTTER_ROOT=$(grep '^FLUTTER_ROOT=' "${SRCROOT}/Flutter/Generated.xcconfig" | head -1 | cut -d= -f2- | tr -d '\r')
  export FLUTTER_ROOT
fi

if [ -z "${FLUTTER_ROOT:-}" ] || [ ! -x "$FLUTTER_ROOT/bin/flutter" ]; then
  echo "error: FLUTTER_ROOT not set or flutter not found at FLUTTER_ROOT/bin/flutter" >&2
  exit 1
fi

"$FLUTTER_ROOT/bin/flutter" pub get

echo "Bump build: flutter pub get completed."
