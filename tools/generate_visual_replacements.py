#!/usr/bin/env python3
"""Generate deterministic v2 visual replacement assets for What We Fed.

This pass upgrades v1 visuals while preserving readability constraints and
runtime compatibility.
"""

from __future__ import annotations

import math
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SIZE_32 = 32
LANE_TOP_RATIO = 0.24
LANE_BOTTOM_RATIO = 0.74
PLAYER_X_RATIO = 0.16
ENEMY_X_RATIO = 0.80

SHOT_FAMILY_ORDER: tuple[tuple[str, str], ...] = (
    ("shot1.png", "fang"),
    ("shot2.png", "mass"),
    ("shot3.png", "needle"),
    ("shot4.png", "veil"),
    ("shot5.png", "chorus"),
    ("shot6.png", "sovereign"),
)

PROJECTILE_BODY_KEYS: tuple[str, ...] = (
    "dreg",
    "bond_reaper",
    "sovereign",
    "ashclaw",
    "bond_remnant",
    "gruvek",
    "veilskin",
    "thornback",
    "knellspine",
    "marrowward",
    "gorefane",
    "hushcoil",
    "coldvein",
    "siltgrip",
    "skitterer",
    "brute",
    "phantom",
    "spitter",
    "warden",
    "void_stalker",
)

BODY_FAMILY: dict[str, str] = {
    "dreg": "fang",
    "bond_reaper": "needle",
    "sovereign": "sovereign",
    "ashclaw": "fang",
    "bond_remnant": "veil",
    "gruvek": "mass",
    "veilskin": "needle",
    "thornback": "needle",
    "knellspine": "chorus",
    "marrowward": "mass",
    "gorefane": "mass",
    "hushcoil": "veil",
    "coldvein": "needle",
    "siltgrip": "mass",
    "skitterer": "needle",
    "brute": "mass",
    "phantom": "veil",
    "spitter": "fang",
    "warden": "mass",
    "void_stalker": "sovereign",
}


def _save(img: Image.Image, rel_path: str) -> None:
    out = ROOT / rel_path
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, format="PNG")
    print(f"wrote {rel_path}")


def _lerp(c0: tuple[int, int, int], c1: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (
        int(c0[0] + (c1[0] - c0[0]) * t),
        int(c0[1] + (c1[1] - c0[1]) * t),
        int(c0[2] + (c1[2] - c0[2]) * t),
    )


def _vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    for y in range(h):
        r, g, b = _lerp(top, bottom, y / max(1, h - 1))
        d.line((0, y, w, y), fill=(r, g, b, 255))
    return img


def _clamp_u8(v: float) -> int:
    return max(0, min(255, int(v)))


def _put(px: list[list[tuple[int, int, int, int]]], x: int, y: int, g: int, a: int) -> None:
    if not (0 <= x < SIZE_32 and 0 <= y < SIZE_32) or a <= 0:
        return
    old_g, old_a = px[y][x][0], px[y][x][3]
    if old_a == 0:
        px[y][x] = (g, g, g, a)
        return
    out_a = min(255, a + (old_a * (255 - a) // 255))
    out_g = min(255, (g * a + old_g * old_a) // max(1, a + old_a))
    px[y][x] = (out_g, out_g, out_g, out_a)


def _stroke(px: list[list[tuple[int, int, int, int]]], x0: int, y0: int, x1: int, y1: int, g: int, a: int) -> None:
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    x, y = x0, y0
    while True:
        _put(px, x, y, g, a)
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x += sx
        if e2 <= dx:
            err += dx
            y += sy


def _disk(px: list[list[tuple[int, int, int, int]]], cx: float, cy: float, r: float, g: int, a: int) -> None:
    r2 = r * r
    lo_x = int(cx - r - 1)
    hi_x = int(cx + r + 1)
    lo_y = int(cy - r - 1)
    hi_y = int(cy + r + 1)
    for y in range(max(0, lo_y), min(SIZE_32, hi_y + 1)):
        for x in range(max(0, lo_x), min(SIZE_32, hi_x + 1)):
            dist2 = (x - cx) ** 2 + (y - cy) ** 2
            if dist2 <= r2:
                edge = abs(math.sqrt(dist2) - r)
                aa = int(a * max(0.0, 1.0 - edge * 1.25) ** 2)
                _put(px, x, y, g, aa)


def _ring(px: list[list[tuple[int, int, int, int]]], cx: float, cy: float, inner: float, outer: float, g: int, a: int) -> None:
    for y in range(SIZE_32):
        for x in range(SIZE_32):
            d = math.hypot(x - cx, y - cy)
            if inner <= d <= outer:
                edge = min(d - inner, outer - d)
                aa = int(a * max(0.0, min(1.0, edge * 1.2)) ** 2)
                _put(px, x, y, g, aa)


def _to_image(px: list[list[tuple[int, int, int, int]]]) -> Image.Image:
    return Image.frombytes("RGBA", (SIZE_32, SIZE_32), b"".join(bytes(p) for row in px for p in row))


def _build_shot_overlay(family: str) -> Image.Image:
    px = [[(0, 0, 0, 0) for _ in range(SIZE_32)] for _ in range(SIZE_32)]
    if family == "fang":
        _disk(px, 6.0, 16.0, 2.2, 252, 205)
        _ring(px, 6.2, 16.0, 2.3, 3.6, 220, 95)
        for x0, y0, x1, y1, g, a in (
            (9, 16, 30, 16, 236, 180),
            (10, 15, 28, 11, 205, 124),
            (10, 17, 28, 21, 205, 124),
            (13, 16, 30, 13, 176, 74),
            (13, 16, 30, 19, 176, 74),
        ):
            _stroke(px, x0, y0, x1, y1, g, a)
    elif family == "mass":
        _disk(px, 8.5, 16.0, 4.8, 240, 186)
        _disk(px, 8.0, 16.0, 2.4, 255, 240)
        _ring(px, 8.5, 16.0, 3.8, 5.1, 214, 84)
        for y in range(11, 22):
            fall = (y - 11) / 11.0
            _stroke(px, 13, y, 30, _clamp_u8(y + (0.5 - fall) * 3.5), 208, 118)
    elif family == "needle":
        for x in range(3, 12):
            t = (x - 3) / 8.0
            _put(px, x, 16, _clamp_u8(190 + 65 * t), _clamp_u8(130 + 120 * t))
            _put(px, x, 15, _clamp_u8(176 + 56 * t), _clamp_u8(100 + 105 * t))
            _put(px, x, 17, _clamp_u8(176 + 56 * t), _clamp_u8(100 + 105 * t))
        _ring(px, 6.4, 16.0, 1.2, 2.1, 236, 106)
        for x0, y0, x1, y1, g, a in (
            (12, 16, 30, 16, 228, 178),
            (13, 15, 29, 11, 196, 118),
            (13, 17, 29, 21, 196, 118),
            (15, 16, 30, 13, 168, 72),
            (15, 16, 30, 19, 168, 72),
        ):
            _stroke(px, x0, y0, x1, y1, g, a)
    elif family == "veil":
        _disk(px, 8.0, 16.0, 3.4, 232, 134)
        _disk(px, 7.2, 16.0, 1.8, 255, 252)
        _ring(px, 8.2, 16.0, 2.2, 4.0, 208, 84)
        for x0, y0, x1, y1 in (
            (10, 16, 22, 9),
            (10, 16, 23, 16),
            (10, 16, 22, 22),
            (12, 14, 29, 8),
            (12, 18, 29, 24),
        ):
            _stroke(px, x0, y0, x1, y1, 194, 108)
    elif family == "chorus":
        for cy in (12.5, 16.0, 19.5):
            _disk(px, 6.2, cy, 1.5, 250, 228)
        _disk(px, 8.3, 16.0, 2.5, 232, 124)
        _ring(px, 6.8, 16.0, 2.0, 3.3, 214, 84)
        for x0, y0, x1, y1, g, a in (
            (10, 13, 28, 8, 212, 126),
            (10, 16, 30, 16, 228, 164),
            (10, 19, 28, 23, 212, 126),
            (12, 15, 29, 13, 182, 84),
            (12, 17, 29, 19, 182, 84),
        ):
            _stroke(px, x0, y0, x1, y1, g, a)
    else:  # sovereign
        _disk(px, 5.5, 16.0, 2.2, 248, 206)
        _ring(px, 5.8, 16.0, 2.4, 3.8, 210, 90)
        for dy in (-6, -3, 0, 3, 6):
            _stroke(px, 9, 16 + dy, 30, 16 + dy // 2, _clamp_u8(218 - abs(dy) * 6), _clamp_u8(122 - abs(dy) * 8))
        _stroke(px, 9, 10, 23, 6, 192, 98)
        _stroke(px, 9, 22, 23, 26, 192, 98)
        _disk(px, 17.0, 16.0, 3.3, 202, 72)
    return _to_image(px)


def _generate_projectile_overlays() -> None:
    for filename, family in SHOT_FAMILY_ORDER:
        _save(_build_shot_overlay(family), f"assets/sprites/{filename}")


def _body_signature(key: str) -> int:
    return sum((i + 7) * ord(c) for i, c in enumerate(key))


def _add_signature_marks(
    px: list[list[tuple[int, int, int, int]]],
    sig: int,
    family: str,
    head_y: float,
) -> None:
    crest_count = 1 + (sig % 3)
    base_x = 12 + (sig % 4)
    for i in range(crest_count):
        x = base_x + i * 4
        y = int(head_y) + ((sig // (i + 3)) % 5) - 2
        if family in ("needle", "fang"):
            _stroke(px, x, y, x + 5, y - 2, 220, 106)
        elif family == "veil":
            _stroke(px, x, y, x + 4, y + (1 if i % 2 == 0 else -1), 210, 96)
        elif family == "chorus":
            _disk(px, x, y, 0.9, 236, 156)
        else:
            _stroke(px, x, y, x + 6, y, 214, 104)

    spark_count = 2 + (sig % 3)
    for j in range(spark_count):
        sx = 18 + ((sig // (j + 5)) % 11)
        sy = int(head_y) - 4 + ((sig // (j + 7)) % 9)
        _disk(px, sx, sy, 0.7, 242, 76)


def _build_projectile_body(key: str, family: str) -> Image.Image:
    px = [[(0, 0, 0, 0) for _ in range(SIZE_32)] for _ in range(SIZE_32)]
    sig = _body_signature(key)
    y_off = (sig % 5) - 2
    head_x = 6.4 + ((sig // 11) % 3) * 0.25
    head_y = 16.0 + y_off * 0.45
    if family in ("mass", "sovereign"):
        _disk(px, head_x + 1.0, head_y, 4.2, 242, 200)
        _disk(px, head_x + 0.7, head_y, 2.0, 255, 248)
        _ring(px, head_x + 1.0, head_y, 3.4, 4.8, 214, 82)
    else:
        _disk(px, head_x, head_y, 2.3, 248, 210)
        _ring(px, head_x + 0.1, head_y, 2.3, 3.7, 212, 86)

    if family == "needle":
        for x0, y0, x1, y1, g, a in (
            (9, int(head_y), 30, int(head_y), 232, 172),
            (11, int(head_y) - 2, 30, int(head_y) - 7, 192, 108),
            (11, int(head_y) + 2, 30, int(head_y) + 7, 192, 108),
        ):
            _stroke(px, x0, y0, x1, y1, g, a)
    elif family == "veil":
        for x0, y0, x1, y1 in (
            (10, int(head_y), 23, int(head_y) - 6),
            (10, int(head_y), 25, int(head_y)),
            (10, int(head_y), 23, int(head_y) + 6),
            (12, int(head_y) - 2, 30, int(head_y) - 7),
            (12, int(head_y) + 2, 30, int(head_y) + 7),
        ):
            _stroke(px, x0, y0, x1, y1, 196, 112)
    elif family == "chorus":
        _disk(px, head_x - 1.6, head_y - 3.0, 1.2, 246, 194)
        _disk(px, head_x - 1.6, head_y + 3.0, 1.2, 246, 194)
        for x0, y0, x1, y1, g, a in (
            (10, int(head_y) - 3, 28, int(head_y) - 7, 210, 120),
            (10, int(head_y), 30, int(head_y), 228, 156),
            (10, int(head_y) + 3, 28, int(head_y) + 7, 210, 120),
        ):
            _stroke(px, x0, y0, x1, y1, g, a)
    elif family == "mass":
        for y in range(int(head_y) - 5, int(head_y) + 6):
            _stroke(px, 13, y, 30, _clamp_u8(y + ((sig % 7) - 3) * 0.25), 206, 116)
    elif family == "sovereign":
        for dy in (-5, -2, 0, 2, 5):
            _stroke(px, 11, int(head_y) + dy, 30, int(head_y) + dy // 2, _clamp_u8(220 - abs(dy) * 8), _clamp_u8(120 - abs(dy) * 8))
        _stroke(px, 11, int(head_y) - 5, 24, int(head_y) - 10, 186, 92)
        _stroke(px, 11, int(head_y) + 5, 24, int(head_y) + 10, 186, 92)
    else:  # fang
        for x0, y0, x1, y1, g, a in (
            (9, int(head_y), 30, int(head_y), 232, 174),
            (10, int(head_y) - 1, 27, int(head_y) - 5, 198, 114),
            (10, int(head_y) + 1, 27, int(head_y) + 5, 198, 114),
        ):
            _stroke(px, x0, y0, x1, y1, g, a)
    _add_signature_marks(px, sig, family, head_y)
    return _to_image(px)


def _generate_projectile_bodies() -> None:
    for key in PROJECTILE_BODY_KEYS:
        family = BODY_FAMILY.get(key, "fang")
        _save(_build_projectile_body(key, family), f"assets/sprites/projectile_bodies/{key}.png")


def _generate_impacts() -> None:
    specs: dict[str, tuple[tuple[int, int, int], tuple[int, int, int]]] = {
        "impact_perfect.png": ((252, 224, 122), (255, 248, 228)),
        "impact_parry.png": ((116, 222, 255), (236, 250, 255)),
        "impact_miss.png": ((166, 166, 176), (226, 226, 232)),
        "impact_dodge.png": ((148, 244, 190), (230, 255, 246)),
        "impact_elite.png": ((255, 150, 94), (255, 238, 216)),
        "impact_boss.png": ((236, 86, 132), (255, 220, 244)),
        "impact_slash_alt.png": ((188, 144, 248), (244, 234, 255)),
    }
    for name, (accent, hi) in specs.items():
        img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        d = ImageDraw.Draw(img, "RGBA")
        for i in range(14):
            y = 16 + i * 7
            d.line((8, y, 72 + (i % 4) * 10, y - ((i + 1) % 3) * 2), fill=(*accent, 58), width=2)
        d.polygon([(14, 68), (78, 40), (116, 46), (58, 88)], fill=(*hi, 196))
        d.polygon([(11, 70), (82, 33), (121, 39), (60, 92)], outline=(*accent, 236), width=2)
        d.polygon([(30, 68), (65, 52), (84, 55), (53, 76)], fill=(*hi, 236))
        for j in range(3):
            d.arc((22 - j * 3, 32 - j * 2, 112 + j * 4, 106 + j * 2), 316, 36, fill=(*accent, 156 - j * 26), width=2)
        _save(img, f"art/vfx/impact/{name}")


def _draw_panel_shell(size: tuple[int, int], edge: tuple[int, int, int], accent: tuple[int, int, int]) -> Image.Image:
    w, h = size
    base = _vertical_gradient(size, (16, 14, 20), (8, 8, 12))
    d = ImageDraw.Draw(base, "RGBA")
    d.rounded_rectangle((10, 10, w - 10, h - 10), radius=28, fill=(8, 10, 14, 188), outline=(*edge, 238), width=4)
    d.rounded_rectangle((24, 24, w - 24, h - 24), radius=22, fill=(0, 0, 0, 0), outline=(58, 56, 66, 210), width=2)
    for i in range(9):
        x = int((i + 0.5) * w / 9.0)
        d.line((x, 24, x, h - 24), fill=(*accent, 16), width=1)
    d.polygon([(44, 12), (138, 12), (110, 50), (28, 50)], fill=(*accent, 74))
    d.polygon([(w - 44, h - 12), (w - 138, h - 12), (w - 110, h - 50), (w - 28, h - 50)], fill=(*accent, 70))
    d.line((32, h // 2, w - 32, h // 2), fill=(255, 255, 255, 14), width=1)
    return base


def _generate_panels_and_bar() -> None:
    panel_size = (1536, 768)
    top_left = _draw_panel_shell(panel_size, (92, 108, 146), (116, 168, 238))
    top_right = _draw_panel_shell(panel_size, (118, 96, 150), (198, 130, 248))
    reward = _draw_panel_shell(panel_size, (138, 114, 72), (252, 194, 96))
    _save(top_left, "assets/ui/combat/panels/combat_panel_top_left.png")
    _save(top_right, "assets/ui/combat/panels/combat_panel_top_right.png")
    _save(reward, "assets/ui/combat/panels/combat_panel_reward_claim.png")
    # Keep legacy duplicate paths for fallback compatibility.
    _save(top_left.copy(), "assets/ui/combat/panels/combat_panel_top_left.png.png")
    _save(top_right.copy(), "assets/ui/combat/panels/combat_panel_top_right.png.png")
    _save(reward.copy(), "assets/ui/combat/panels/combat_panel_reward_claim.png.png")

    bar = Image.new("RGBA", (512, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(bar, "RGBA")
    d.rounded_rectangle((1, 1, 511, 31), radius=11, fill=(16, 18, 24, 242), outline=(86, 92, 108, 238), width=2)
    d.rounded_rectangle((10, 8, 502, 24), radius=7, fill=(32, 36, 44, 224), outline=(102, 108, 124, 188), width=1)
    d.line((16, 16, 496, 16), fill=(220, 224, 236, 28), width=1)
    _save(bar, "assets/ui/combat/bars/combat_bar_track.png")


def _glyph_frame(size: int, accent: tuple[int, int, int], phase: int, frames: int, hopeful: bool) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    t = phase / max(1, frames - 1)
    core = _lerp((232, 232, 236), accent, 0.28 + 0.62 * t)
    d.ellipse((6, 6, size - 6, size - 6), fill=(18, 18, 26, 202), outline=(*accent, 214), width=2)
    d.polygon([(size // 2, 7), (size - 8, size // 2), (size // 2, size - 8), (8, size // 2)], fill=(*core, 54), outline=(*core, 218), width=2)
    if hopeful:
        y = size // 2 - 3
        d.ellipse((size // 2 - 8, y, size // 2 - 4, y + 4), fill=(255, 246, 250, 214))
        d.ellipse((size // 2 + 4, y, size // 2 + 8, y + 4), fill=(255, 246, 250, 214))
        d.ellipse((size // 2 + 10, y - 4, size // 2 + 13, y - 1), fill=(255, 232, 245, 106))
    return img


def _sprite_strip(frames: Iterable[Image.Image], frame_size: int) -> Image.Image:
    f = list(frames)
    out = Image.new("RGBA", (frame_size * len(f), frame_size), (0, 0, 0, 0))
    for i, frame in enumerate(f):
        out.alpha_composite(frame, (i * frame_size, 0))
    return out


def _generate_reward_icons() -> None:
    dna_frames = [_glyph_frame(32, (236, 118, 238), i, 5, hopeful=False) for i in range(5)]
    quig_frames = [_glyph_frame(32, (108, 224, 196), i, 8, hopeful=True) for i in range(8)]
    _save(_sprite_strip(dna_frames, 32), "assets/sprites/dna.png")
    _save(_sprite_strip(quig_frames, 32), "assets/sprites/quig.png")


def _generate_portraits() -> None:
    species = (
        "ashclaw",
        "bond_remnant",
        "gruvek",
        "veilskin",
        "thornback",
        "knellspine",
        "marrowward",
        "gorefane",
        "hushcoil",
        "coldvein",
        "siltgrip",
    )
    accents: dict[str, tuple[int, int, int]] = {
        "ashclaw": (242, 144, 90),
        "bond_remnant": (132, 196, 255),
        "gruvek": (226, 152, 98),
        "veilskin": (146, 218, 255),
        "thornback": (246, 114, 112),
        "knellspine": (238, 206, 116),
        "marrowward": (170, 210, 184),
        "gorefane": (250, 104, 88),
        "hushcoil": (118, 212, 184),
        "coldvein": (124, 194, 255),
        "siltgrip": (100, 190, 166),
    }
    for i, sp in enumerate(species):
        img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        d = ImageDraw.Draw(img, "RGBA")
        accent = accents.get(sp, (210, 170, 130))
        d.ellipse((8, 8, 120, 120), fill=(14, 14, 21, 240), outline=(*accent, 230), width=3)
        horn = 21 + (i % 3) * 3
        d.polygon([(24, horn + 4), (52, 11), (46, 40)], fill=(*accent, 194))
        d.polygon([(104, horn + 4), (76, 11), (82, 40)], fill=(*accent, 194))
        d.polygon([(24, 90), (64, 44), (104, 90), (64, 112)], fill=(236, 232, 226, 194), outline=(*accent, 226), width=2)
        d.ellipse((49, 58, 56, 65), fill=(255, 248, 238, 236))
        d.ellipse((72, 58, 79, 65), fill=(255, 248, 238, 236))
        # Tiny controlled hopeful cue.
        d.ellipse((82, 42, 88, 48), fill=(255, 236, 248, 118))
        _save(img, f"assets/creatures/portraits/{sp}_portrait.png")


def _generate_shell_motifs() -> None:
    def motif(path: str, accent: tuple[int, int, int], title: bool) -> None:
        img = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
        d = ImageDraw.Draw(img, "RGBA")
        d.ellipse((30, 30, 290, 290), outline=(*accent, 114), width=4)
        d.ellipse((58, 58, 262, 262), outline=(*accent, 70), width=2)
        for a in range(0, 360, 30):
            x0 = 160 + int(68 * math.cos(math.radians(a)))
            y0 = 160 + int(68 * math.sin(math.radians(a)))
            x1 = 160 + int(124 * math.cos(math.radians(a)))
            y1 = 160 + int(124 * math.sin(math.radians(a)))
            d.line((x0, y0, x1, y1), fill=(*accent, 90), width=2)
        if title:
            d.polygon([(160, 88), (176, 146), (234, 146), (186, 182), (202, 242), (160, 206), (118, 242), (134, 182), (86, 146), (144, 146)], fill=(*accent, 68), outline=(*accent, 136), width=2)
        else:
            d.polygon([(160, 84), (236, 160), (160, 236), (84, 160)], fill=(*accent, 62), outline=(*accent, 126), width=2)
        _save(img, path)

    motif("assets/ui/shell/title_sigil.png", (246, 168, 120), title=True)
    motif("assets/ui/shell/route_sigil.png", (130, 214, 255), title=False)


def _generate_background(name: str, hue_shift: int) -> None:
    w, h = 1280, 720
    img = _vertical_gradient((w, h), (12 + hue_shift, 12, 18 + hue_shift), (5, 6, 10))
    d = ImageDraw.Draw(img, "RGBA")
    wall_top = int(h * 0.18)
    wall_bottom = int(h * 0.82)

    # Concrete back-wall block instead of abstract void.
    d.rectangle((0, wall_top, w, wall_bottom), fill=(18 + hue_shift // 3, 18, 24 + hue_shift // 3, 166))

    # Structural wall seams and panels.
    for i in range(0, w, 64):
        seam_alpha = 38 if (i // 64) % 2 == 0 else 24
        d.line((i, wall_top, i, wall_bottom), fill=(34 + hue_shift // 3, 30, 34 + hue_shift // 3, seam_alpha), width=1)
    for row in range(5):
        y = wall_top + int((wall_bottom - wall_top) * (row + 1) / 6.0)
        d.line((0, y, w, y), fill=(28 + hue_shift // 4, 26, 30 + hue_shift // 4, 24), width=1)

    # Recessed wall niches to imply depth and physical architecture.
    for i in range(8):
        cx = int((i + 0.55) * w / 8.0)
        niche_w = 86
        niche_h = 220 + (i % 3) * 14
        y0 = wall_top + 66 + (i % 2) * 12
        d.rectangle((cx - niche_w // 2, y0, cx + niche_w // 2, y0 + niche_h), fill=(12, 12, 16, 108))
        d.polygon(
            [(cx - niche_w // 2, y0 + niche_h), (cx + niche_w // 2, y0 + niche_h), (cx + 20, y0 + niche_h - 70), (cx - 20, y0 + niche_h - 70)],
            fill=(10, 10, 14, 164),
        )

    # Foreground floor slab.
    d.rectangle((0, int(h * 0.86), w, h), fill=(7, 8, 12, 255))
    d.rectangle((0, int(h * 0.83), w, int(h * 0.86)), fill=(18 + hue_shift // 4, 14, 14 + hue_shift // 4, 176))
    for i in range(0, w, 38):
        d.line((i, int(h * 0.86), i + 20, h), fill=(26 + hue_shift // 4, 24, 28 + hue_shift // 4, 64), width=1)

    # Lane-ground alignment pass: tie environment directly to runtime lane anchors.
    lane_step = (LANE_BOTTOM_RATIO - LANE_TOP_RATIO) / 2.0
    lane_ys = [
        int(h * (LANE_TOP_RATIO + lane_step * 0)),
        int(h * (LANE_TOP_RATIO + lane_step * 1)),
        int(h * (LANE_TOP_RATIO + lane_step * 2)),
    ]
    player_x = int(w * PLAYER_X_RATIO)
    enemy_x = int(w * ENEMY_X_RATIO)

    for idx, lane_y in enumerate(lane_ys):
        lane_tint = 28 + idx * 6
        # Solid lane deck (catwalk-style) under each combat lane.
        d.rectangle(
            (int(w * 0.08), lane_y - 16, int(w * 0.92), lane_y + 16),
            fill=(30 + hue_shift // 4, 24, lane_tint + hue_shift // 3, 88),
        )
        # Deck top and underside edges.
        d.line((int(w * 0.08), lane_y - 16, int(w * 0.92), lane_y - 16), fill=(86 + hue_shift // 3, 72, 56 + hue_shift // 3, 96), width=2)
        d.line((int(w * 0.08), lane_y + 16, int(w * 0.92), lane_y + 16), fill=(14, 14, 18, 122), width=2)
        # Groove lines aligned to lane center for readability.
        d.line(
            (int(w * 0.10), lane_y, int(w * 0.90), lane_y),
            fill=(112 + hue_shift // 3, 86, 60 + hue_shift // 3, 102),
            width=2,
        )
        d.line(
            (int(w * 0.10), lane_y - 8, int(w * 0.90), lane_y - 8),
            fill=(48 + hue_shift // 3, 40, 36 + hue_shift // 3, 74),
            width=1,
        )
        d.line(
            (int(w * 0.10), lane_y + 8, int(w * 0.90), lane_y + 8),
            fill=(40 + hue_shift // 3, 36, 32 + hue_shift // 3, 70),
            width=1,
        )

        # Repeating metal plate joints so the lane reads as engineered structure.
        for j in range(12):
            sx = int(w * 0.11) + j * 86
            d.line((sx, lane_y - 12, sx, lane_y + 12), fill=(22, 20, 22, 112), width=2)

        # Anchor pads under gameplay spawn/stance points.
        d.rounded_rectangle(
            (player_x - 38, lane_y - 14, player_x + 38, lane_y + 14),
            radius=8,
            fill=(54 + hue_shift // 4, 36, 30 + hue_shift // 4, 120),
            outline=(122 + hue_shift // 3, 84, 56 + hue_shift // 3, 144),
            width=2,
        )
        d.rounded_rectangle(
            (enemy_x - 46, lane_y - 15, enemy_x + 46, lane_y + 15),
            radius=8,
            fill=(58 + hue_shift // 4, 32, 28 + hue_shift // 4, 124),
            outline=(130 + hue_shift // 3, 80, 52 + hue_shift // 3, 148),
            width=2,
        )

        # Soft footing shadows near anchors.
        d.ellipse(
            (player_x - 62, lane_y + 34, player_x + 62, lane_y + 56),
            fill=(0, 0, 0, 76),
        )
        d.ellipse(
            (enemy_x - 82, lane_y + 30, enemy_x + 82, lane_y + 58),
            fill=(0, 0, 0, 88),
        )

        # Vertical supports connecting lanes to the wall/floor mass.
        for px in (int(w * 0.20), int(w * 0.50), int(w * 0.80)):
            d.line(
                (px, lane_y + 16, px, int(h * 0.86)),
                fill=(34 + hue_shift // 3, 30, 30 + hue_shift // 3, 62),
                width=3,
            )

    # Restrained sky accent kept faint and off the lane read zone.
    d.ellipse((1020, 54, 1146, 178), fill=(210, 224, 246, 20), outline=(230, 238, 250, 52), width=1)
    d.arc((976, 18, 1202, 234), 224, 316, fill=(150 + hue_shift, 174, 232, 36), width=2)
    _save(img, f"assets/backgrounds/combat/{name}")


def _generate_backgrounds() -> None:
    _generate_background("cbg1.png", hue_shift=0)
    _generate_background("cbg2.png", hue_shift=16)
    _generate_background("cbg3.png", hue_shift=32)
    _generate_background("cbg_predation_base_v1.png", hue_shift=8)


def main() -> None:
    _generate_impacts()
    _generate_projectile_overlays()
    _generate_projectile_bodies()
    _generate_panels_and_bar()
    _generate_reward_icons()
    _generate_portraits()
    _generate_shell_motifs()
    _generate_backgrounds()
    print("v2 visual replacement generation complete")


if __name__ == "__main__":
    main()
