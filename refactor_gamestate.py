import os
import re

replacements = {
    r"GameState\.player_hp": "PlayerState.hp",
    r"GameState\.player_max_hp": "PlayerState.max_hp",
    r"GameState\.player_base_damage": "PlayerState.base_damage",
    r"GameState\.player_defense": "PlayerState.defense",
    r"GameState\.run_path_plan": "RunState.path_plan",
    r"GameState\.run_path_chosen_ids": "RunState.path_chosen_ids",
    r"GameState\.run_in_progress": "RunState.run_in_progress",
    r"GameState\.run_number": "RunState.run_number",
    r"GameState\.is_in_combat": "RunState.is_in_combat",
    r"GameState\.run_stats": "RunStats",
}

for root, dirs, files in os.walk("."):
    for file in files:
        if file.endswith(".gd") and file != "GameState.gd":
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            
            new_content = content
            for pattern, replacement in replacements.items():
                new_content = re.sub(pattern, replacement, new_content)
            
            if new_content != content:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"Updated {path}")
