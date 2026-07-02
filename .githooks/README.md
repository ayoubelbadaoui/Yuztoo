# Git hooks for Yuztoo

These hooks keep the Flutter and iOS toolchains in sync with the lockfiles
that are committed in the repo. Without them, every `git pull` that bumps
a Flutter plugin or rotates `Podfile.lock` produces the familiar
`The sandbox is not in sync with the Podfile.lock` error in Xcode.

## What runs

`sync-flutter-ios.sh` is the one source of truth. The two hooks below just
hand it the right diff range:

- **`post-checkout`** — after `git checkout` / `git switch` / `git clone`.
  Only fires on branch checkouts (not single-file checkouts).
- **`post-merge`** — after `git pull` / `git merge`.

The script inspects the diff and:

- runs `flutter pub get` when `pubspec.yaml` / `pubspec.lock` moved,
- runs `pod install` when `ios/Podfile` / `ios/Podfile.lock` moved
  (or when pubspec moved — Flutter plugin changes regenerate the pod
  paths via `Generated.xcconfig`).

It is a no-op on Linux / Windows and when neither file moved.

## One-time setup (per clone)

```sh
git config core.hooksPath .githooks
```

That tells Git to look in `.githooks/` instead of the default
`.git/hooks/` for hook scripts. The repo ships the executables already
chmodded — nothing else to do.

To opt out later:

```sh
git config --unset core.hooksPath
```

## Manual run

You can also run the sync logic by hand, e.g. after a `flutter clean`:

```sh
.githooks/sync-flutter-ios.sh
```

With no arguments it forces a full sync (the same path the script takes
when it cannot resolve the previous revision).
