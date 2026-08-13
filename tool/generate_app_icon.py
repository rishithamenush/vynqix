#!/usr/bin/env python3
"""Draws the Vynqix launcher icon masters.

The mark is the Vynqix "V" drawn as a checkmark: one stroke, a short arm and a
long rising arm, so it reads as both the brand letter and a completed task. The
short arm takes the palette's accent so the shape has depth without a gradient.
Flat fills only, which keeps it crisp down to 40px and matches the in-app
palette in `lib/core/theme/app_colors.dart`.

Outputs (run from the repo root, requires Pillow):
  assets/branding/app_icon.png             1024px, full bleed, iOS/macOS/web/windows
  assets/branding/app_icon_foreground.png  1024px, transparent, Android adaptive
  assets/branding/app_icon_monochrome.png  1024px, white on transparent, Android 13 themed

Then regenerate the platform assets:
  dart run flutter_launcher_icons

Heads up: flutter_launcher_icons 0.14.4 writes `AppIcon` into
ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS in
ios/Runner.xcodeproj/project.pbxproj — a boolean setting, and the key it
actually wants (ASSETCATALOG_COMPILER_APPICON_NAME) is already correct. Reset
those two lines to YES after every run, or `git checkout` the pbxproj.
"""

from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # supersample factor; the master is drawn 4x and downscaled

INK = (0x0F, 0x1A, 0x16, 255)  # AppColors.light.foreground — the tile
MINT = (0x34, 0xD3, 0x99, 255)  # AppColors.light.accent — the short arm
WHITE = (0xFF, 0xFF, 0xFF, 255)

# The stroke in its own 1000-unit design space: short arm, vertex, long arm.
A = (120, 520)
B = (400, 800)
C = (880, 200)
STROKE = 128


def _mark(width: float, long_arm=WHITE, short_arm=MINT) -> Image.Image:
    """Renders the check-V on transparent pixels, trimmed to its bounds.

    `width` is the requested width in final (pre-supersample) pixels.
    """
    pad = STROKE  # room for the round caps before trimming
    box = 1000 + 2 * pad
    layer = Image.new("RGBA", (box * SS, box * SS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    pts = [((x + pad) * SS, (y + pad) * SS) for x, y in (A, B, C)]
    radius = STROKE * SS / 2

    def cap(point, colour):
        x, y = point
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=colour)

    if short_arm == long_arm:
        # One continuous stroke; `joint="curve"` rounds the vertex for us.
        draw.line(pts, fill=long_arm, width=STROKE * SS, joint="curve")
        cap(pts[0], long_arm)
        cap(pts[2], long_arm)
    else:
        # Two strokes, each round-capped at the vertex so they meet cleanly.
        draw.line([pts[0], pts[1]], fill=short_arm, width=STROKE * SS)
        cap(pts[0], short_arm)
        cap(pts[1], short_arm)
        draw.line([pts[1], pts[2]], fill=long_arm, width=STROKE * SS)
        cap(pts[1], long_arm)
        cap(pts[2], long_arm)

    mark = layer.crop(layer.getbbox())
    scale = width * SS / mark.width
    return mark.resize(
        (round(mark.width * scale), round(mark.height * scale)),
        Image.LANCZOS,
    )


def _compose(background, mark: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", (SIZE * SS, SIZE * SS), background or (0, 0, 0, 0))
    canvas.alpha_composite(
        mark,
        ((canvas.width - mark.width) // 2, (canvas.height - mark.height) // 2),
    )
    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


def main() -> None:
    out = Path(__file__).resolve().parent.parent / "assets" / "branding"
    out.mkdir(parents=True, exist_ok=True)

    # Full bleed: the mark spans 62% of the tile, which survives the iOS
    # squircle mask with margin to spare.
    _compose(INK, _mark(SIZE * 0.62)).save(out / "app_icon.png")

    # Android crops adaptive layers to the centre 72/108 of the canvas, and
    # flutter_launcher_icons insets this layer a further 16% in its template.
    # 0.61 x 0.68 lands the mark at ~62% of the visible icon — the same optical
    # size as the full-bleed master above.
    _compose(None, _mark(SIZE * 0.61)).save(out / "app_icon_foreground.png")

    # Themed ("monochrome") icons are tinted by the launcher, so this layer has
    # to be a single flat colour rather than the two-tone mark.
    _compose(None, _mark(SIZE * 0.61, long_arm=WHITE, short_arm=WHITE)).save(
        out / "app_icon_monochrome.png"
    )

    for name in ("app_icon.png", "app_icon_foreground.png", "app_icon_monochrome.png"):
        print(f"wrote {out / name}")


if __name__ == "__main__":
    main()
