#!/usr/bin/env python3
"""Regenerate combat projectile body textures (32x32, RGBA).

Sprites are authored as neutral grayscale + alpha so Godot can tint them via
Sprite2D.modulate (see Projectile.gd). Run from repo root:

  python tools/generate_shot_sprites.py
"""
from __future__ import annotations

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


def _fang() -> Image.Image:
	px: list[list[tuple[int, int, int, int]]] = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]
	# Single sharp shard facing -X (leading edge on the left)
	for x, y, g, a in [
		(5, 16, 235, 210),
		(6, 15, 245, 235),
		(6, 16, 255, 255),
		(6, 17, 245, 235),
		(7, 14, 220, 200),
		(7, 15, 248, 245),
		(7, 16, 255, 255),
		(7, 17, 248, 245),
		(7, 18, 220, 200),
		(8, 15, 230, 215),
		(8, 16, 242, 235),
		(8, 17, 230, 215),
		(9, 16, 215, 185),
	]:
		_put(px, x, y, g, a)
	_disk(px, 7.4, 16.0, 2.2, 248, 160)
	# Primary tail + light splinter accents
	for (x0, y0, x1, y1, g, a) in [
		(10, 16, 28, 16, 228, 175),
		(11, 15, 24, 12, 195, 105),
		(11, 17, 24, 20, 195, 105),
		(13, 16, 29, 14, 175, 80),
		(13, 16, 29, 18, 175, 80),
	]:
		_stroke_line(px, x0, y0, x1, y1, g, a)
	return Image.frombytes("RGBA", (SIZE, SIZE), b"".join(bytes(p) for row in px for p in row))


def _mass() -> Image.Image:
	px = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]
	_disk(px, 10.0, 16.0, 4.6, 252, 200)
	_disk(px, 9.6, 16.0, 3.0, 255, 235)
	_disk(px, 8.8, 16.0, 1.6, 255, 255)
	# Broad comet tail
	for dy in range(-4, 5):
		w = max(1, 4 - abs(dy) // 2)
		for dx in range(12, 30):
			fall = 1.0 - (dx - 12) / 18.0
			a = int(200 * fall * fall * (0.75 + 0.25 * (1 - abs(dy) / 5.0)))
			g = int(210 + 35 * (1 - fall))
			for ox in range(w):
				_put(px, dx + ox, 16 + dy, min(255, g), max(0, min(255, a)))
	# Side ribbons
	_stroke_line(px, 11, 12, 22, 8, 195, 100)
	_stroke_line(px, 11, 20, 22, 23, 190, 95)
	return Image.frombytes("RGBA", (SIZE, SIZE), b"".join(bytes(p) for row in px for p in row))


def _needle() -> Image.Image:
	px = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]
	# Razor head
	for x in range(4, 11):
		t = (x - 4) / 6.0
		g = int(200 + 55 * t)
		a = int(140 + 115 * t)
		_put(px, x, 16, g, a)
	_put(px, 11, 16, 255, 255)
	_put(px, 10, 15, 245, 220)
	_put(px, 10, 17, 245, 220)
	# Long filament trail
	_stroke_line(px, 12, 16, 30, 16, 215, 160)
	_stroke_line(px, 13, 15, 28, 12, 185, 110)
	_stroke_line(px, 13, 17, 28, 20, 185, 110)
	_stroke_line(px, 15, 16, 29, 14, 170, 85)
	_stroke_line(px, 15, 16, 29, 18, 170, 85)
	return Image.frombytes("RGBA", (SIZE, SIZE), b"".join(bytes(p) for row in px for p in row))


def _veil() -> Image.Image:
	px = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]
	_disk(px, 9.5, 16.0, 3.4, 236, 140)
	_disk(px, 8.7, 16.0, 1.9, 255, 245)
	# Soft ribbon + curls (ethereal)
	curves = [
		(11, 16, 20, 10, 200, 115),
		(11, 16, 22, 16, 215, 125),
		(11, 16, 19, 21, 198, 110),
		(12, 14, 26, 7, 175, 85),
		(12, 18, 25, 24, 172, 82),
		(13, 15, 27, 12, 168, 78),
		(13, 17, 27, 19, 168, 78),
	]
	for args in curves:
		_stroke_line(px, *args)
	# Speck shimmer
	for x, y, g, a in [
		(18, 13, 220, 90),
		(21, 18, 210, 80),
		(24, 11, 195, 65),
		(26, 20, 188, 58),
		(16, 12, 205, 70),
		(20, 20, 200, 68),
	]:
		_put(px, x, y, g, a)
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
	]
	for name, fn in specs:
		img = fn()
		path = out_dir / name
		img.save(path, format="PNG")
		print(f"wrote {path.relative_to(root)}")


if __name__ == "__main__":
	main()
