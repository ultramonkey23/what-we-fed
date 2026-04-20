#!/usr/bin/env python3
"""Regenerate combat projectile art (32x32, RGBA).

- shot1.png–shot6.png: neutral grayscale overlays (song-section shot modifiers).
- assets/sprites/projectile_bodies/<enemy_key>.png: per-species / per-type body cores.

Run from what-we-fed/:

  python tools/generate_shot_sprites.py
"""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image


SIZE = 32


def _put(px: list[list[tuple[int, int, int, int]]], x: int, y: int, g: int, a: int) -> None:
	if 0 <= x < SIZE and 0 <= y < SIZE and a > 0:
		og, oa = px[y][x][0], px[y][x][3]
		# alpha-composite onto existing (straight alpha)
		if oa == 0:
			px[y][x] = (g, g, g, a)
		else:
			na = min(255, a + (oa * (255 - a) // 255))
			ng = min(255, (g * a + og * oa) // max(1, a + oa))
			px[y][x] = (ng, ng, ng, na)


def _stroke_line(px, x0: int, y0: int, x1: int, y1: int, g: int, a: int) -> None:
	# Bresenham
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


def _disk(px, cx: float, cy: float, r: float, g: int, a: int) -> None:
	r2 = r * r
	lo = int(cx - r - 1)
	hi = int(cx + r + 1)
	for y in range(max(0, lo), min(SIZE, hi + 1)):
		for x in range(max(0, lo), min(SIZE, hi + 1)):
			if (x - cx) ** 2 + (y - cy) ** 2 <= r2:
				edge = abs(((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 - r)
				fe = max(0.0, 1.0 - edge * 1.25)
				aa = int(a * fe * fe)
				_put(px, x, y, g, aa)


def _annulus(px, cx: float, cy: float, r_inner: float, r_outer: float, g: int, a: int) -> None:
	for y in range(SIZE):
		for x in range(SIZE):
			d = math.hypot(x - cx, y - cy)
			if r_inner <= d <= r_outer:
				edge = min(d - r_inner, r_outer - d)
				fe = max(0.0, min(1.0, edge * 1.1))
				aa = int(a * fe * fe)
				_put(px, x, y, g, aa)


def _spark(px, x: int, y: int, g: int, a: int, spread: int = 1) -> None:
	for dy in range(-spread, spread + 1):
		for dx in range(-spread, spread + 1):
			f = 1.0 - (abs(dx) + abs(dy)) * 0.22
			if f > 0:
				_put(px, x + dx, y + dy, g, int(a * f))


def _fang() -> Image.Image:
	px: list[list[tuple[int, int, int, int]]] = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]
	# Sharp shard: leading edge left (-X motion), wake +X
	for x, y, g, a in [
		(4, 16, 220, 185),
		(5, 15, 238, 225),
		(5, 16, 252, 250),
		(5, 17, 238, 225),
		(6, 14, 228, 210),
		(6, 15, 250, 248),
		(6, 16, 255, 255),
		(6, 17, 250, 248),
		(6, 18, 228, 210),
		(7, 13, 205, 165),
		(7, 14, 235, 220),
		(7, 15, 252, 250),
		(7, 16, 255, 255),
		(7, 17, 252, 250),
		(7, 18, 235, 220),
		(7, 19, 205, 165),
		(8, 15, 225, 200),
		(8, 16, 242, 232),
		(8, 17, 225, 200),
		(9, 16, 210, 175),
	]:
		_put(px, x, y, g, a)
	_disk(px, 6.9, 16.0, 2.35, 250, 175)
	_annulus(px, 6.9, 16.0, 2.5, 3.6, 218, 95)
	for (x0, y0, x1, y1, g, a) in [
		(10, 16, 29, 16, 232, 185),
		(11, 15, 26, 11, 205, 118),
		(11, 17, 26, 21, 205, 118),
		(12, 14, 28, 9, 188, 88),
		(12, 18, 28, 23, 188, 88),
		(14, 16, 30, 14, 172, 72),
		(14, 16, 30, 18, 172, 72),
	]:
		_stroke_line(px, x0, y0, x1, y1, g, a)
	for sx, sy in [(18, 14), (22, 12), (25, 17), (27, 15), (20, 19)]:
		_spark(px, sx, sy, 240, 70, 1)
	return Image.frombytes("RGBA", (SIZE, SIZE), b"".join(bytes(p) for row in px for p in row))


def _mass() -> Image.Image:
	px = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]
	_disk(px, 9.2, 16.0, 5.0, 248, 185)
	_disk(px, 9.0, 16.0, 3.6, 255, 230)
	_disk(px, 8.2, 16.0, 2.0, 255, 255)
	_annulus(px, 8.8, 16.0, 3.8, 5.2, 215, 88)
	for dy in range(-5, 6):
		w = max(1, 5 - abs(dy) // 2)
		for dx in range(13, 31):
			fall = 1.0 - (dx - 13) / 17.0
			a = int(210 * fall * fall * (0.72 + 0.28 * (1 - abs(dy) / 5.5)))
			g = int(205 + 45 * (1 - fall))
			for ox in range(w):
				_put(px, dx + ox, 16 + dy, min(255, g), max(0, min(255, a)))
	_stroke_line(px, 10, 11, 23, 7, 198, 105)
	_stroke_line(px, 10, 21, 23, 24, 195, 102)
	_stroke_line(px, 12, 16, 28, 16, 220, 115)
	for sx, sy in [(17, 13), (21, 10), (24, 19), (27, 14)]:
		_spark(px, sx, sy, 235, 65, 1)
	return Image.frombytes("RGBA", (SIZE, SIZE), b"".join(bytes(p) for row in px for p in row))


def _needle() -> Image.Image:
	px = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]
	for x in range(3, 11):
		t = (x - 3) / 7.0
		g = int(188 + 62 * t)
		a = int(120 + 130 * t)
		_put(px, x, 16, g, a)
		_put(px, x, 15, int(g * 0.92), int(a * 0.82))
		_put(px, x, 17, int(g * 0.92), int(a * 0.82))
	_put(px, 11, 16, 255, 255)
	_annulus(px, 6.5, 16.0, 1.1, 2.0, 235, 110)
	for (x0, y0, x1, y1, g, a) in [
		(12, 16, 30, 16, 222, 175),
		(13, 15, 29, 11, 195, 118),
		(13, 17, 29, 21, 195, 118),
		(14, 14, 30, 9, 178, 92),
		(14, 18, 30, 23, 178, 92),
		(16, 16, 30, 13, 168, 78),
		(16, 16, 30, 19, 168, 78),
	]:
		_stroke_line(px, x0, y0, x1, y1, g, a)
	for sx, sy in [(20, 15), (24, 16), (27, 14), (26, 18)]:
		_spark(px, sx, sy, 245, 62, 1)
	return Image.frombytes("RGBA", (SIZE, SIZE), b"".join(bytes(p) for row in px for p in row))


def _veil() -> Image.Image:
	px = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]
	_disk(px, 9.0, 16.0, 3.6, 232, 135)
	_disk(px, 8.2, 16.0, 2.0, 255, 248)
	_annulus(px, 8.5, 16.0, 2.2, 4.0, 208, 85)
	curves = [
		(10, 16, 21, 9, 205, 120),
		(10, 16, 23, 16, 218, 132),
		(10, 16, 20, 22, 202, 115),
		(11, 14, 26, 6, 182, 92),
		(11, 18, 26, 25, 180, 90),
		(12, 15, 28, 11, 172, 82),
		(12, 17, 28, 20, 172, 82),
		(13, 16, 29, 8, 165, 75),
		(13, 16, 29, 23, 165, 75),
	]
	for args in curves:
		_stroke_line(px, *args)
	for x, y, g, a in [
		(17, 12, 225, 88),
		(19, 19, 212, 78),
		(22, 10, 198, 68),
		(25, 21, 190, 62),
		(15, 11, 208, 72),
		(24, 14, 200, 65),
	]:
		_put(px, x, y, g, a)
	return Image.frombytes("RGBA", (SIZE, SIZE), b"".join(bytes(p) for row in px for p in row))


def _chorus() -> Image.Image:
	"""Triadic head + woven tails (harmony / stacked voices)."""
	px = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]
	for cx, cy, r, g, a in [
		(5.5, 12.5, 1.45, 250, 225),
		(6.6, 16.0, 1.65, 255, 255),
		(5.5, 19.5, 1.45, 250, 225),
	]:
		_disk(px, cx, cy, r, g, a)
	_disk(px, 8.0, 16.0, 2.5, 225, 125)
	_annulus(px, 6.4, 16.0, 1.8, 3.2, 215, 88)
	for (x0, y0, x1, y1, g, a) in [
		(10, 13, 27, 8, 208, 128),
		(10, 16, 29, 16, 228, 165),
		(10, 19, 27, 23, 208, 128),
		(11, 14, 25, 11, 190, 100),
		(11, 18, 25, 21, 190, 100),
		(12, 15, 28, 13, 182, 88),
		(12, 17, 28, 19, 182, 88),
	]:
		_stroke_line(px, x0, y0, x1, y1, g, a)
	for sx, sy in [(18, 11), (22, 16), (26, 9), (24, 22)]:
		_spark(px, sx, sy, 238, 68, 1)
	return Image.frombytes("RGBA", (SIZE, SIZE), b"".join(bytes(p) for row in px for p in row))


def _sovereign() -> Image.Image:
	"""Crown-like prow + layered heavy wake."""
	px = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]
	for x, y, g, a in [
		(3, 16, 215, 185),
		(4, 15, 235, 220),
		(4, 16, 252, 248),
		(4, 17, 235, 220),
		(5, 13, 210, 195),
		(5, 14, 248, 238),
		(5, 15, 255, 255),
		(5, 16, 255, 255),
		(5, 17, 255, 255),
		(5, 18, 248, 238),
		(5, 19, 210, 195),
		(6, 12, 200, 175),
		(6, 13, 238, 225),
		(6, 14, 252, 248),
		(6, 15, 255, 255),
		(6, 16, 255, 255),
		(6, 17, 255, 255),
		(6, 18, 252, 248),
		(6, 19, 238, 225),
		(6, 20, 200, 175),
		(7, 11, 195, 168),
		(7, 12, 228, 208),
		(7, 19, 228, 208),
		(7, 20, 195, 168),
		(8, 16, 225, 198),
	]:
		_put(px, x, y, g, a)
	_disk(px, 5.8, 16.0, 2.15, 245, 175)
	_annulus(px, 5.9, 16.0, 2.4, 3.8, 212, 92)
	for dy in (-6, -3, 0, 3, 6):
		_stroke_line(px, 9, 16 + dy, 29, 16 + dy // 2, 218 - abs(dy) * 5, 125 - abs(dy) * 9)
	_stroke_line(px, 9, 10, 23, 6, 192, 105)
	_stroke_line(px, 9, 22, 23, 25, 192, 105)
	_disk(px, 17.0, 16.0, 3.4, 205, 75)
	for sx, sy in [(14, 10), (14, 22), (22, 8), (24, 16), (22, 23)]:
		_spark(px, sx, sy, 242, 72, 1)
	return Image.frombytes("RGBA", (SIZE, SIZE), b"".join(bytes(p) for row in px for p in row))


BODY_KEYS: tuple[str, ...] = (
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


def _body_procedural(key: str) -> Image.Image:
	"""Deterministic grayscale+alpha silhouette; always leads -X, wake +X."""
	rng = random.Random((hash(key) & 0xFFFFFFFF) ^ 0x9E3779B9)
	px: list[list[tuple[int, int, int, int]]] = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]

	hx = 5.2 + rng.random() * 1.6
	hy = 16.0 + rng.uniform(-1.4, 1.4)
	n_blobs = 4 + rng.randint(0, 3)
	for i in range(n_blobs):
		_disk(
			px,
			hx + i * 0.45 + rng.uniform(0, 0.5),
			hy + rng.uniform(-1.2, 1.2),
			0.75 + rng.random() * 1.35,
			225 + rng.randint(0, 30),
			140 + rng.randint(0, 95),
		)
	_annulus(px, hx + 1.8, hy, 1.6, 2.85, 218, 85)

	n_tails = 3 + rng.randint(0, 3)
	for _ in range(n_tails):
		x0 = 10 + rng.randint(0, 3)
		y0 = int(hy) + rng.randint(-3, 3)
		x1 = 27 + rng.randint(0, 4)
		y1 = y0 + rng.randint(-6, 6)
		_stroke_line(px, x0, y0, x1, y1, 198 + rng.randint(0, 40), 100 + rng.randint(0, 70))

	if rng.random() < 0.65:
		_stroke_line(px, 9, int(hy) - 4, 22, 7 + rng.randint(0, 3), 188, 78)
	if rng.random() < 0.65:
		_stroke_line(px, 9, int(hy) + 4, 22, 24 - rng.randint(0, 3), 185, 76)

	for _ in range(4 + rng.randint(0, 4)):
		sx = 14 + rng.randint(0, 16)
		sy = int(hy) + rng.randint(-5, 5)
		if sx >= 12:
			_spark(px, sx, sy, 238, 55 + rng.randint(0, 35), 1)

	return Image.frombytes("RGBA", (SIZE, SIZE), b"".join(bytes(p) for row in px for p in row))


def main() -> None:
	root = Path(__file__).resolve().parents[1]
	out_dir = root / "assets" / "sprites"
	out_dir.mkdir(parents=True, exist_ok=True)
	specs = [
		("shot1.png", _fang),
		("shot2.png", _mass),
		("shot3.png", _needle),
		("shot4.png", _veil),
		("shot5.png", _chorus),
		("shot6.png", _sovereign),
	]
	for name, fn in specs:
		img = fn()
		path = out_dir / name
		img.save(path, format="PNG")
		print(f"wrote {path.relative_to(root)}")

	body_dir = root / "assets" / "sprites" / "projectile_bodies"
	body_dir.mkdir(parents=True, exist_ok=True)
	for key in BODY_KEYS:
		img_b = _body_procedural(key)
		p = body_dir / f"{key}.png"
		img_b.save(p, format="PNG")
		print(f"wrote {p.relative_to(root)}")


if __name__ == "__main__":
	main()
