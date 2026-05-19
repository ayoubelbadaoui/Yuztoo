#!/usr/bin/env python3
"""Generate Android notification + themed-launcher icon silhouettes from the
colored app icon.

Why this script exists: `flutter_launcher_icons` only handles launcher icons.
Android needs two more derivative assets that it doesn't produce:

  1. `assets/branding/app_icon_monochrome.png`
     A pure-alpha silhouette of the bird-in-pin used by `flutter_launcher_icons`
     in a second pass (the `adaptive_icon_monochrome` field) to render the
     Android 13+ themed launcher icon.

  2. `android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/
      ic_stat_yuztoo.png`
     The notification status-bar icon at all densities. Android strips RGB
     from notification icons and renders them tinted using only the alpha
     channel, so we drop colors entirely and keep the shape as a fully-opaque
     white silhouette on a transparent background.

Input:  assets/branding/app_icon.png  (1024×1024, colored bird-in-pin on white)
Output: see above.

Run from project root:  python3 tools/build_notification_icon.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from PIL import Image  # type: ignore


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SOURCE = PROJECT_ROOT / "assets" / "branding" / "app_icon.png"
MONO_OUT = PROJECT_ROOT / "assets" / "branding" / "app_icon_monochrome.png"
ANDROID_RES = PROJECT_ROOT / "android" / "app" / "src" / "main" / "res"


# Status-bar icon sizes per Android density bucket. These are the
# recommended sizes from the Material design guidance — they get rendered at
# 24×24 dp regardless of the user's display density.
DENSITY_SIZES = {
    "drawable-mdpi": 24,
    "drawable-hdpi": 36,
    "drawable-xhdpi": 48,
    "drawable-xxhdpi": 72,
    "drawable-xxxhdpi": 96,
}


def build_silhouette(src_path: Path) -> Image.Image:
    """Return a transparent-background silhouette of the YuzToo BIRD only.

    Strategy: the brand mark has the gold bird sitting inside the navy pin.
    For the small (24×24 dp) status-bar notification icon and the Android-13+
    themed launcher icon we want the SIMPLEST shape that still reads as the
    YuzToo bird. We:
      1. Pick only the gold pixels (the bird + pin outline + the small
         ground shadow at the bottom).
      2. Connected-component label every gold blob.
      3. Keep ONLY the largest connected blob (the bird body) — drops the
         pin outline, the ground shadow, and any anti-aliasing speckle.
      4. Crop tight to the bird, pad with an 8 % safe zone, and resize to
         1024×1024 master.

    Android tints the alpha mask with the FCM `default_notification_color`
    (navy) so users see a navy bird silhouette in the status bar.
    """
    from collections import deque

    with src_path.open("rb") as f:
        original = Image.open(f).convert("RGBA")

    w, h = original.size
    px = original.load()

    def is_gold(r: int, g: int, b: int) -> bool:
        return r > 150 and g > 110 and b < 110 and r > b + 50

    mask = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 16 and is_gold(r, g, b):
                mask[y][x] = True

    # BFS connected-component labelling — iterative to avoid recursion limits.
    labels = [[0] * w for _ in range(h)]
    sizes: dict[int, int] = {}
    next_label = 0
    for sy in range(h):
        for sx in range(w):
            if not mask[sy][sx] or labels[sy][sx] != 0:
                continue
            next_label += 1
            size = 0
            q: deque[tuple[int, int]] = deque([(sx, sy)])
            labels[sy][sx] = next_label
            while q:
                x, y = q.popleft()
                size += 1
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if (0 <= nx < w and 0 <= ny < h
                            and mask[ny][nx]
                            and labels[ny][nx] == 0):
                        labels[ny][nx] = next_label
                        q.append((nx, ny))
            sizes[next_label] = size

    if not sizes:
        # Fallback: return the empty canvas so the caller sees blank tiles
        # instead of crashing. Shouldn't happen with the real source.
        return Image.new("RGBA", (w, h), (0, 0, 0, 0))

    biggest = max(sizes, key=lambda lbl: sizes[lbl])

    bird = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    bird_px = bird.load()
    for y in range(h):
        for x in range(w):
            if labels[y][x] == biggest:
                bird_px[x, y] = (255, 255, 255, 255)

    # Crop tight, pad to a square with 8% safe zone (so status-bar icons
    # don't touch the edges), then upscale to 1024×1024.
    bbox = bird.getbbox()
    if bbox is None:
        return bird
    cropped = bird.crop(bbox)
    cw, ch = cropped.size
    side = max(cw, ch)
    pad = int(side * 0.08)
    canvas = side + 2 * pad
    square = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    square.paste(cropped, ((canvas - cw) // 2, (canvas - ch) // 2), cropped)
    return square.resize((1024, 1024), Image.LANCZOS)


def main() -> int:
    if not SOURCE.exists():
        print(
            f"[icons] source missing: {SOURCE}\n"
            f"        save the 1024×1024 bird-in-pin PNG there first",
            file=sys.stderr,
        )
        return 1

    print(f"[icons] reading {SOURCE.relative_to(PROJECT_ROOT)}")
    silhouette = build_silhouette(SOURCE)

    # 1. Monochrome asset for flutter_launcher_icons (Android 13+ themed icon).
    MONO_OUT.parent.mkdir(parents=True, exist_ok=True)
    silhouette.save(MONO_OUT, format="PNG")
    print(f"[icons] wrote {MONO_OUT.relative_to(PROJECT_ROOT)}")

    # 2. Status-bar icon at every Android density.
    for folder, size in DENSITY_SIZES.items():
        target = ANDROID_RES / folder / "ic_stat_yuztoo.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        resized = silhouette.resize((size, size), Image.LANCZOS)
        resized.save(target, format="PNG")
        print(f"[icons] wrote {target.relative_to(PROJECT_ROOT)}  ({size}×{size})")

    print("[icons] done")
    return 0


if __name__ == "__main__":
    sys.exit(main())
