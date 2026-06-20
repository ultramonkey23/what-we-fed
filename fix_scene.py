import re

scene_path = "C:/Users/harin/gamesdevs/What We Fed/what-we-fed/scenes/combat/CombatScene.gd"

with open(scene_path, "r", encoding="utf-8") as f:
    content = f.read()

vars_to_replace = [
    "stamina_bar",
    "hp_bar",
    "ultimate_label",
    "controls_label",
    "combat_meter",
    "ui_layer",
    "result_label",
    "combo_label",
    "style_label",
    "flash_overlay"
]

for var in vars_to_replace:
    # Replace the variable name with _ui_builder.var ONLY if it's not preceded by a dot or _ui_builder.
    # and not part of another word
    pattern = r'(?<!_ui_builder\.)(?<!\.)\b' + re.escape(var) + r'\b'
    content = re.sub(pattern, f'_ui_builder.{var}', content)

with open(scene_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed CombatScene.gd missing prefixes!")
