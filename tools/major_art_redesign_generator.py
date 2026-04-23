#!/usr/bin/env python3
"""
Major Art Redesign Generator (v3.0 - "The Pulse & Resin")
Generates high-detail, visceral "Manga Monstrosity" & "Premium Menace" assets.
"""
import math
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]

# MM Palette from UIStyle.gd
INK_BLACK = (8, 5, 10, 255)         # MM_INK_BLACK
DEEP_VIOLET = (36, 20, 51, 255)      # MM_DEEP_VIOLET
BLOOD_EMBER = (230, 82, 38, 255)    # MM_BLOOD_EMBER
MUTATION_MAGENTA = (209, 41, 189, 255) # MM_MUTATION_MAGENTA
BOND_TEAL = (61, 219, 189, 255)     # MM_BOND_TEAL
ALERT_GOLD = (245, 199, 77, 255)    # MM_ALERT_GOLD
PAPER_WHITE = (245, 240, 230, 255)  # MM_PAPER

def save(img, rel_path):
    out = ROOT / rel_path
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, format="PNG")
    print(f"Generated: {rel_path}")

def jaggedize_polygon(points, iterations=2, displacement=5):
    """Adds random jaggedness to a polygon."""
    for _ in range(iterations):
        new_points = []
        for i in range(len(points)):
            p1 = points[i]
            p2 = points[(i + 1) % len(points)]
            mid = ((p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2)
            
            # Perpendicular vector for displacement
            dx = p2[0] - p1[0]
            dy = p2[1] - p1[1]
            dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0:
                nx = -dy / dist
                ny = dx / dist
                offset = random.uniform(-displacement, displacement)
                mid = (mid[0] + nx * offset, mid[1] + ny * offset)
            
            new_points.append(p1)
            new_points.append(mid)
        points = new_points
    return points

def draw_visceral_shape(draw, points, color):
    """Draws a jagged polygon with inner cross-hatching details."""
    jagged = jaggedize_polygon(points, iterations=2, displacement=8)
    draw.polygon(jagged, fill=color)
    
    # Add inner "bone/muscle" etching
    for _ in range(10):
        p1 = random.choice(jagged)
        p2 = random.choice(jagged)
        if random.random() > 0.5:
            draw.line([p1, p2], fill=(*DEEP_VIOLET[:3], 128), width=2)

def apply_cross_hatch(img, mask, spacing=15, angle=45):
    """Applies a cross-hatch texture to the masked area."""
    draw = ImageDraw.Draw(img)
    w, h = img.size
    rad = math.radians(angle)
    cos_a = math.cos(rad)
    sin_a = math.sin(rad)
    
    # Simple line-based cross hatching
    for i in range(-w, w + h, spacing):
        # Line from (i, 0) in rotated space
        start = (i, 0)
        end = (i, h * 2)
        # Transform back
        # This is a bit simplified, but gives the ink-look
        draw.line([(i, 0), (i + h, h)], fill=(*PAPER_WHITE[:3], 40), width=1)
        draw.line([(i + h, 0), (i, h)], fill=(*PAPER_WHITE[:3], 40), width=1)

def generate_ink_panel(size, accent_color, name):
    w, h = size
    # Base ink-heavy layer
    panel = Image.new("RGBA", size, INK_BLACK)
    d = ImageDraw.Draw(panel)
    
    # Deep violet wash (vertical gradient)
    for y in range(h):
        t = y / max(1, h-1)
        r = int(INK_BLACK[0] + (DEEP_VIOLET[0] - INK_BLACK[0]) * t * 0.4)
        g = int(INK_BLACK[1] + (DEEP_VIOLET[1] - INK_BLACK[1]) * t * 0.4)
        b = int(INK_BLACK[2] + (DEEP_VIOLET[2] - INK_BLACK[2]) * t * 0.4)
        d.line((0, y, w, y), fill=(r, g, b, 255))
    
    # Inner "etched" border
    margin = 8
    d.rectangle([margin, margin, w - margin, h - margin], outline=(*accent_color[:3], 80), width=1)
    
    # Thick main border with "Manga" style jagged corners
    border_w = 4
    d.rectangle([border_w//2, border_w//2, w - border_w//2, h - border_w//2], outline=accent_color, width=border_w)
    
    # Sharp notches
    notch = 30
    d.polygon([(0, 0), (notch, 0), (0, notch)], fill=accent_color)
    d.polygon([(w, h), (w-notch, h), (w, h-notch)], fill=accent_color)
    
    # Add a bit of "Resin" texture (subtle gloss streaks)
    for _ in range(5):
        lx = random.randint(0, w)
        lw = random.randint(20, 100)
        d.line([(lx, 0), (lx + lw, h)], fill=(*PAPER_WHITE[:3], 15), width=2)
    
    save(panel, f"assets/ui/combat/panels/{name}.png")

def generate_sprite_strip(frame_size, name, frame_count, pose_type, color=INK_BLACK):
    strip_w = frame_size[0] * frame_count
    strip_h = frame_size[1]
    strip = Image.new("RGBA", (strip_w, strip_h), (0, 0, 0, 0))
    
    w, h = frame_size
    cx, cy = w // 2, h // 2
    
    for i in range(frame_count):
        layer = Image.new("RGBA", frame_size, (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        
        # Movement offset
        offset_y = int(math.sin(i * 0.5) * 15)
        
        # Base body points (will be jaggedized)
        if "ashclaw" in name:
            body_pts = [(cx-w//4, cy+h//3), (cx-w//3, cy), (cx-w//6, cy-h//4), (cx+w//6, cy-h//4), (cx+w//3, cy), (cx+w//4, cy+h//3)]
            draw_visceral_shape(d, body_pts, color)
            # Add jagged claws
            draw_visceral_shape(d, [(cx-w//3, cy+h//4), (cx-w//2, cy+h//2), (cx-w//4, cy+h//2)], color)
            draw_visceral_shape(d, [(cx+w//3, cy+h//4), (cx+w//2, cy+h//2), (cx+w//4, cy+h//2)], color)
        elif "player" in name:
            head_pts = [(cx-w//10, cy-h//4), (cx, cy-h//3), (cx+w//10, cy-h//4), (cx, cy-h//6)]
            body_pts = [(cx-w//8, cy-h//8), (cx+w//8, cy-h//8), (cx+w//12, cy+h//4), (cx-w//12, cy+h//4)]
            draw_visceral_shape(d, head_pts, color)
            draw_visceral_shape(d, body_pts, color)
            
            # Weapon
            if pose_type == "attack":
                strike = i / max(1, frame_count - 1)
                wx = cx + int(w//4 + strike * w//3)
                draw_visceral_shape(d, [(cx+w//10, cy), (wx, cy-h//2), (wx-w//8, cy-h//3)], color)
            elif pose_type == "parry":
                draw_visceral_shape(d, [(cx-w//6, cy-h//4), (cx-w//4, cy-h//2), (cx+w//4, cy-h//2), (cx+w//6, cy-h//4)], color)
            else:
                draw_visceral_shape(d, [(cx+w//10, cy), (cx+w//3, cy-h//2), (cx+w//4, cy-h//3)], color)
        elif "bond_remnant" in name:
            # Ethereal wisp
            draw_visceral_shape(d, [(cx-w//8, cy+h//4), (cx-w//6, cy), (cx, cy-h//3), (cx+w//6, cy), (cx+w//8, cy+h//4)], color)
        else: # generic stalker
            draw_visceral_shape(d, [(cx-w//5, cy+h//3), (cx-w//4, cy), (cx, cy-h//4), (cx+w//4, cy), (cx+w//5, cy+h//3)], color)

        # Apply outline for visibility
        mask = layer.split()[3]
        outline = mask.filter(ImageFilter.MaxFilter(11)) # Thicker outline for v3
        outline_frame = Image.new("RGBA", frame_size, PAPER_WHITE)
        outline_frame.putalpha(outline)
        
        final_frame = Image.alpha_composite(outline_frame, layer)
        
        # Add high-contrast highlights (cross-hatching)
        highlights = Image.new("RGBA", frame_size, (0, 0, 0, 0))
        apply_cross_hatch(highlights, mask)
        final_frame = Image.alpha_composite(final_frame, highlights)
        
        # Glowing eyes
        if "ashclaw" in name or "stalker" in name:
            de = ImageDraw.Draw(final_frame)
            de.ellipse([cx-w//15, cy-h//8+offset_y, cx-w//30, cy-h//10+offset_y], fill=BLOOD_EMBER)
            de.ellipse([cx+w//30, cy-h//8+offset_y, cx+w//15, cy-h//10+offset_y], fill=BLOOD_EMBER)

        strip.paste(final_frame, (i * w, 0))
    
    save(strip, f"assets/sprites/silhouettes/{name}_{pose_type}_strip.png")

def main():
    print("Starting Major Art Redesign Refinement (v3.0 - Visceral Upgrade)...")
    
    # UI Panels
    panel_size = (512, 256)
    generate_ink_panel(panel_size, BOND_TEAL, "panel_performance")
    generate_ink_panel(panel_size, MUTATION_MAGENTA, "panel_mutation")
    generate_ink_panel(panel_size, ALERT_GOLD, "panel_alert")
    generate_ink_panel(panel_size, BLOOD_EMBER, "panel_apex")
    
    # Sprite Strips (512x512)
    res = (512, 512)
    generate_sprite_strip(res, "player", 12, "idle")
    generate_sprite_strip(res, "player", 8, "attack")
    generate_sprite_strip(res, "player", 7, "parry")
    generate_sprite_strip(res, "player", 4, "hurt")
    
    generate_sprite_strip(res, "ashclaw_baby", 12, "idle")
    generate_sprite_strip(res, "ashclaw_adult", 12, "idle")
    generate_sprite_strip(res, "bond_remnant", 12, "idle", color=DEEP_VIOLET)
    generate_sprite_strip(res, "enemy_stalker", 12, "idle", color=INK_BLACK)
    
    print("Refinement Phase COMPLETE.")

if __name__ == "__main__":
    main()
