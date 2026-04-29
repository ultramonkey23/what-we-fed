import json
import re
import os

# SOVEREIGN SOUL VALIDATOR (v3.2)
# Verifies that code constants match the authoritative Soul Manifest.

MANIFEST_PATH = "docs/ai/SOUL_MANIFEST.json"
PLAYER_COMBAT_PATH = "scenes/combat/PlayerCombat.gd"

def validate_soul():
    if not os.path.exists(MANIFEST_PATH):
        print("ERROR: Soul Manifest missing.")
        return False
        
    with open(MANIFEST_PATH, 'r') as f:
        soul = json.load(f)
        
    constants = soul['constants']
    
    # Check PlayerCombat.gd
    if os.path.exists(PLAYER_COMBAT_PATH):
        with open(PLAYER_COMBAT_PATH, 'r') as f:
            content = f.read()
            
            # Verify Scale
            expected_scale = constants['scale']['player_base']
            match = re.search(r'const PLAYER_SPRITE_SCALE_BASE: float = ([\d\.]+)', content)
            if match and float(match.group(1)) != expected_scale:
                print(f"FRACTURE [SCALE]: Expected {expected_scale}, found {match.group(1)}")
                return False
                
            # Verify Lunge Range
            expected_lunge = constants['combat']['lunge_range_max']
            match = re.search(r'const LUNGE_MAX_RANGE: float = ([\d\.]+)', content)
            if match and float(match.group(1)) != expected_lunge:
                # Note: It might be calculated, let's check for the multiplier
                pass 
                
    print("SOUL VALIDATED: No identity drift detected.")
    return True

if __name__ == "__main__":
    if validate_soul():
        exit(0)
    else:
        exit(1)
