import re
import os

combat_scene_path = "C:/Users/harin/gamesdevs/What We Fed/what-we-fed/scenes/combat/CombatScene.gd"
combat_ui_builder_path = "C:/Users/harin/gamesdevs/What We Fed/what-we-fed/systems/presentation/CombatUIBuilder.gd"

with open(combat_ui_builder_path, "r", encoding="utf-8") as f:
    builder_content = f.read()

with open(combat_scene_path, "r", encoding="utf-8") as f:
    scene_content = f.read()

# 1. Find all proxy properties in CombatUIBuilder.gd
# Pattern: var _name: Type: \n\tget: return scene._name \n\tset(v): scene._name = v
# Or just get: return scene._name
proxy_vars = []

# Regex to match var declarations with getters/setters returning scene.property
pattern = r'(var\s+([_a-zA-Z0-9]+)\s*(:\s*[_a-zA-Z0-9\[\]]+)?\s*:\n\s*get:\s*return\s*scene\.([_a-zA-Z0-9]+)(?:\n\s*set\(v\):\s*scene\.[_a-zA-Z0-9]+\s*=\s*v)?)'

matches = re.finditer(pattern, builder_content)

ui_variables = set()

for match in matches:
    full_block = match.group(1)
    var_name = match.group(2)
    type_hint = match.group(3) or ""
    scene_prop = match.group(4)
    
    # If the proxy is just passing through to scene.var_name
    if var_name == scene_prop or scene_prop in var_name:
        ui_variables.add(scene_prop)
        # Replace the proxy block with a normal variable
        # But if it's a constant like PRESENTATION_TEXT, don't change it to a var
        if scene_prop.isupper():
            pass # Keep it, or we'll manually add preloads later
        else:
            replacement = f"var {var_name}{type_hint}"
            builder_content = builder_content.replace(full_block, replacement)

# Save CombatUIBuilder.gd
with open(combat_ui_builder_path, "w", encoding="utf-8") as f:
    f.write(builder_content)

# 2. Modify CombatScene.gd
# Remove declarations of these variables
lines = scene_content.split('\n')
new_lines = []

for line in lines:
    is_decl = False
    for ui_var in ui_variables:
        if line.startswith(f"var {ui_var}:") or line.startswith(f"var {ui_var} =") or line.startswith(f"@onready var {ui_var}:") or line.startswith(f"@onready var {ui_var} ="):
            is_decl = True
            break
    
    if is_decl:
        continue # Skip the declaration
    
    # Also replace usages of the ui variable with _ui_builder.ui_var
    # We must be careful to only replace whole words
    mod_line = line
    for ui_var in ui_variables:
        # Don't replace if it's already _ui_builder.ui_var or scene.ui_var
        # We can use regex to replace \bui_var\b as long as it's not preceded by _ui_builder.
        if ui_var.islower() and not ui_var.startswith("_"):
            # skip generic names like 'ui_layer', 'combo_label'
            # we'll handle @onready vars manually
            continue
        
        # Replace \b_ui_var\b with _ui_builder._ui_var
        mod_line = re.sub(r'(?<!_ui_builder\.)(?<!\.)\b' + re.escape(ui_var) + r'\b', f'_ui_builder.{ui_var}', mod_line)
        
    new_lines.append(mod_line)

# Save CombatScene.gd
with open(combat_scene_path, "w", encoding="utf-8") as f:
    f.write("\n".join(new_lines))

print("Extracted UI variables: ", len(ui_variables))
print("Done.")
