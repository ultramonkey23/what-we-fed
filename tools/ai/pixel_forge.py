import sys
import os
import math
from PIL import Image

# SOVEREIGN MATRIX: "Legendary Pixel Fable Ink" Palette
# Derived from UIStyle.gd and core game assets.
PALETTE = {
    "ink_black": (8, 5, 10),       # MM_INK_BLACK
    "deep_violet": (15, 8, 20),    # MM_DEEP_VIOLET
    "blood_ember": (230, 40, 38),  # MM_BLOOD_EMBER
    "mutation_magenta": (209, 41, 189), # MM_MUTATION_MAGENTA
    "bond_teal": (61, 219, 189),   # MM_BOND_TEAL
    "alert_gold": (245, 199, 76),  # MM_ALERT_GOLD
    "paper": (245, 240, 230),      # MM_PAPER
    "ruin_shadow": (5, 3, 8),      # Deep ruins shadow
    "spirit_dust": (166, 148, 184) # Desaturated purple
}

def color_distance(c1, c2):
    return math.sqrt(sum((a - b) ** 2 for a, b in zip(c1, c2)))

def snap_to_palette(pixel):
    r, g, b = pixel[:3]
    closest_color = None
    min_dist = float('inf')
    
    for name, p_color in PALETTE.items():
        dist = color_distance((r, g, b), p_color)
        if dist < min_dist:
            min_dist = dist
            closest_color = p_color
            
    # Preserve original alpha if it exists
    if len(pixel) == 4:
        return closest_color + (pixel[3],)
    return closest_color

def process_ai_image(input_path, output_path, target_size=(64, 64), remove_bg=True):
    print(f"[PIXEL FORGE] Processing {input_path}...")
    try:
        img = Image.open(input_path).convert("RGBA")
    except Exception as e:
        print(f"Error loading image: {e}")
        return

    # 1. Downscale to pixel art resolution (Nearest Neighbor to prevent blurring)
    img = img.resize(target_size, Image.NEAREST)
    print(f"  -> Downscaled to {target_size[0]}x{target_size[1]}")

    pixels = img.load()
    width, height = img.size

    # 2. Simple Background Removal (assumes top-left pixel is background color)
    bg_color = pixels[0, 0]
    
    for y in range(height):
        for x in range(width):
            current_pixel = pixels[x, y]
            
            # Remove Background
            if remove_bg and color_distance(current_pixel[:3], bg_color[:3]) < 30:
                pixels[x, y] = (0, 0, 0, 0)
                continue
                
            # 3. Snap to Sovereign Palette
            if current_pixel[3] > 0: # If not fully transparent
                pixels[x, y] = snap_to_palette(current_pixel)

    img.save(output_path)
    print(f"[PIXEL FORGE] Success! Saved game-ready asset to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python pixel_forge.py <input_ai_image.png> <output_sprite.png> [width] [height]")
        sys.exit(1)
        
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    w = int(sys.argv[3]) if len(sys.argv) > 3 else 64
    h = int(sys.argv[4]) if len(sys.argv) > 4 else 64
    
    process_ai_image(input_file, output_file, (w, h))
