#!/usr/bin/env bash
# .githooks/sync-flutter-ios.sh
#
# Auto-sync Flutter packages and iOS pods after any git operation that
# touched the dependency manifests. Idempotent — running it twice is a
# no-op the second time.
#
# Why this exists:
#   `Podfile.lock` is versioned, but `Pods/` is not. After a `git pull`
#   that bumps a Flutter plugin (which regenerates the Podfile in
#   ephemeral/ at build time) or rotates `Podfile.lock`, the working
#   tree drifts from the lockfile and Xcode aborts with:
#     "The sandbox is not in sync with the Podfile.lock."
#   This script keeps the two in sync without any manual command.
#
# Usage (called by the post-checkout / post-merge hooks):
#   sync-flutter-ios.sh <from-rev> <to-rev>
#     from-rev: HEAD *before* the git operation
#     to-rev  : HEAD *after*  the git operation
#
# When the diff cannot be computed (initial checkout, shallow clone, or
# the rev is unknown) we force a full sync — better an extra
# `pub get`/`pod install` than a silently stale checkout that breaks
# the build five minutes later in Xcode.

set -euo pipefail

FROM="${1:-}"
TO="${2:-HEAD}"

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if [ -z "$FROM" ] || ! changed=$(git diff --name-only "$FROM" "$TO" 2>/dev/null); then
  # Unknown / missing revisions — force both. Idempotent so the cost is
  # only a few seconds and a stable, predictable shell state.
  changed=""
  force_all=1
else
  force_all=0
fi

needs_pub=0
needs_pod=0

if [ "$force_all" = "1" ]; then
  needs_pub=1
  needs_pod=1
else
  case "$changed" in
    *pubspec.yaml*|*pubspec.lock*)
      # A Flutter plugin add/remove/bump always rewrites the iOS pod
      # paths via `Generated.xcconfig`, so a pubspec change implies a
      # pod re-resolve too — even if `Podfile.lock` itself didn't move.
      needs_pub=1
      needs_pod=1
      ;;
  esac
  case "$changed" in
    *ios/Podfile|*ios/Podfile.lock)
      needs_pod=1
      ;;
  esac
fi

if [ "$needs_pub" = "1" ]; then
  if command -v flutter >/dev/null 2>&1; then
    echo "[deps-sync] pubspec changed — running 'flutter pub get'…"
    flutter pub get >/dev/null
  else
    echo "[deps-sync] flutter not on PATH — skipping pub get." >&2
  fi
fi

if [ "$needs_pod" = "1" ]; then
  # Only run pod install on macOS with an ios/ directory. Linux / Windows
  # contributors don't have the toolchain and would only see noise.
  if [ "$(uname)" = "Darwin" ] && [ -d ios ]; then
    if command -v pod >/dev/null 2>&1; then
      echo "[deps-sync] iOS dependencies changed — running 'pod install'…"
      ( cd ios && pod install >/dev/null )
    else
      echo "[deps-sync] cocoapods not installed — skipping pod install." >&2
    fi
  fi
fi

exit 0
