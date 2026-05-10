import sys
import os
import time
import math
import shutil
import re
from PIL import Image

# --- SOVEREIGN CORE CONSTANTS ---
INCOMING_DIR = "what-we-fed/incoming_art"
ASSET_DIR = "what-we-fed/assets/creatures"
DATA_FILE = "what-we-fed/data/CombatContent.gd"

PALETTE = {
    "ink_black": (8, 5, 10),
    "deep_violet": (15, 8, 20),
    "blood_ember": (230, 40, 38),
    "mutation_magenta": (209, 41, 189),
    "bond_teal": (61, 219, 189),
    "alert_gold": (245, 199, 76),
    "paper": (245, 240, 230),
    "ruin_shadow": (5, 3, 8),
    "spirit_dust": (166, 148, 184)
}

# --- LORE-TO-DATA MAPPING ---
KEYWORDS = {
    "shadow": {"hp": 0.8, "dmg": 1.2, "def": 0.7, "type": "phantom"},
    "spirit": {"hp": 0.7, "dmg": 1.0, "def": 0.5, "type": "phantom"},
    "hollow": {"hp": 0.9, "dmg": 1.1, "def": 0.8, "type": "hollow"},
    "glass":  {"hp": 0.5, "dmg": 1.8, "def": 0.4, "type": "razor"},
    "shard":  {"hp": 0.6, "dmg": 1.6, "def": 0.6, "type": "razor"},
    "bone":   {"hp": 1.5, "dmg": 0.8, "def": 1.8, "type": "warden"},
    "plated": {"hp": 1.3, "dmg": 0.7, "def": 2.0, "type": "warden"},
    "blood":  {"hp": 1.1, "dmg": 1.4, "def": 0.9, "type": "berserker"},
    "gore":   {"hp": 1.2, "dmg": 1.5, "def": 0.8, "type": "berserker"},
    "venom":  {"hp": 0.9, "dmg": 1.1, "def": 0.9, "type": "stalker"},
}

# --- CORE LOGIC ---

def summon_prompt(lore):
    print(f"\n[INCANTATION] Distilling Lore: \"{lore}\"")
    
    style_block = (
        "16-bit high-quality pixel art. High-contrast 'Manga Monstrosity' aesthetic. "
        "Solid black ink-like outlines with variable line weight. Desaturated 'Interface Wound' color palette: "
        "deep purples, charcoal blacks, and sickly teals with vibrant blood-red highlights. "
        "Sharp, jagged silhouettes. Orthographic 2D side-view only. Flat projection, zero depth. "
        "Solid white background. Zero anti-aliasing."
    )
    
    prompt = f"{style_block} Subject: {lore}. Character sprite posing for a side-view game."
    
    print("-" * 40)
    print("COPY THIS PROMPT INTO CHATGPT/DALL-E:")
    print("-" * 40)
    print(prompt)
    print("-" * 40)
    return prompt

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
    if len(pixel) == 4:
        return closest_color + (pixel[3],)
    return closest_color

def solidify_image(input_path, output_path):
    print(f"[SOLIDIFYING] Crunched into Sovereign Matrix: {output_path}")
    img = Image.open(input_path).convert("RGBA")
    
    # 1. Pixelify (Nearest Neighbor downscale to 64x64)
    img = img.resize((64, 64), Image.NEAREST)
    
    pixels = img.load()
    width, height = img.size
    bg_color = pixels[0, 0]
    
    for y in range(height):
        for x in range(width):
            curr = pixels[x, y]
            # Background removal
            if color_distance(curr[:3], bg_color[:3]) < 40:
                pixels[x, y] = (0, 0, 0, 0)
            # Palette snap
            elif curr[3] > 0:
                pixels[x, y] = snap_to_palette(curr)
                
    img.save(output_path)

def awaken_code(name, lore):
    species_id = name.lower().replace(" ", "_")
    display_name = name.title()
    
    # Deriving stats
    hp, dmg, def_val, c_type = 60.0, 10.0, 2.0, "predator"
    for word in lore.lower().split():
        if word in KEYWORDS:
            hp *= KEYWORDS[word]["hp"]
            dmg *= KEYWORDS[word]["dmg"]
            def_val *= KEYWORDS[word]["def"]
            c_type = KEYWORDS[word]["type"]
            
    print(f"[AWAKENING] Instantiating Entity Data: {display_name} ({c_type})")
    
    entry = f"""	"{species_id}": {{
		"species_id": "{species_id}",
		"display_name": "{display_name}",
		"primary_type": "{c_type}",
		"base_hp": {hp:.1f},
		"base_damage": {dmg:.1f},
		"base_defense": {def_val:.1f},
		"description": "{lore}",
		"sprite_path": "res://assets/creatures/{species_id}/{species_id}_idle.png",
		"battlefield_sprite_path": "res://assets/creatures/{species_id}/{species_id}_idle.png",
		"combat_render": {{
			"scale": 0.12,
			"age_scales": {{"baby": 0.12, "teen": 0.16, "adult": 0.22}},
			"world_offset": Vector2(-110.0, 80.0),
			"z_index": 5
		}}
	}},"""
    
    # We read the data file and insert before the last closing brace of the CREATURES dict
    with open(DATA_FILE, "r") as f:
        content = f.read()
        
    if f'"{species_id}"' in content:
        print(f"  ! Entity '{species_id}' already exists in CombatContent.gd. Skipping code injection.")
        return

    # Find the CREATURES constant and append to its dictionary
    # A simple but risky approach: find the last entry of CREATURES
    # Better: find the "siltgrip" entry (last known entry) and append after it.
    insertion_point = content.find('"siltgrip": {')
    if insertion_point != -1:
        # Find the end of siltgrip's closing brace
        brace_level = 0
        found_start = False
        idx = insertion_point
        while idx < len(content):
            if content[idx] == '{':
                brace_level += 1
                found_start = True
            elif content[idx] == '}':
                brace_level -= 1
                if found_start and brace_level == 0:
                    idx += 1 # Move past the last brace
                    # Add a comma if needed (the template already has one trailing)
                    if content[idx] == ',': idx += 1
                    break
            idx += 1
            
        new_content = content[:idx] + "\n" + entry + content[idx:]
        with open(DATA_FILE, "w") as f:
            f.write(new_content)
        print(f"  -> Added {species_id} to {DATA_FILE}")

def run_watcher():
    print(f"\n[WATCHER] Monitoring {INCOMING_DIR} for new mythical fragments...")
    print("Press Ctrl+C to stop.")
    
    processed = set(os.listdir(INCOMING_DIR))
    
    while True:
        try:
            current = set(os.listdir(INCOMING_DIR))
            new_files = current - processed
            
            for f in new_files:
                if f.endswith(".png"):
                    print(f"\n[DETECTION] New Fragment detected: {f}")
                    name = os.path.splitext(f)[0]
                    # We look for a .txt file with the same name for the lore
                    lore_file = os.path.join(INCOMING_DIR, f"{name}.txt")
                    lore = "A strange, mythical entity."
                    if os.path.exists(lore_file):
                        with open(lore_file, "r") as lf:
                            lore = lf.read().strip()
                    
                    species_id = name.lower().replace(" ", "_")
                    species_dir = os.path.join(ASSET_DIR, species_id)
                    os.makedirs(species_dir, exist_ok=True)
                    
                    input_path = os.path.join(INCOMING_DIR, f)
                    output_path = os.path.join(species_dir, f"{species_id}_idle.png")
                    
                    solidify_image(input_path, output_path)
                    awaken_code(name, lore)
                    
                    processed.add(f)
            
            time.sleep(2)
        except KeyboardInterrupt:
            print("\n[WATCHER] Shutting down.")
            break

if __name__ == "__main__":
    if not os.path.exists(INCOMING_DIR):
        os.makedirs(INCOMING_DIR)
        
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python sovereign_forge.py summon \"Lore description\"")
        print("  python sovereign_forge.py watch")
        sys.exit(1)
        
    cmd = sys.argv[1]
    if cmd == "summon":
        if len(sys.argv) < 3:
            print("Error: Missing lore description.")
            sys.exit(1)
        summon_prompt(sys.argv[2])
    elif cmd == "watch":
        run_watcher()
    else:
        print(f"Unknown command: {cmd}")
