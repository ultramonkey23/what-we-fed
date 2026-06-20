import os

path = r"C:\Users\harin\gamesdevs\What We Fed\what-we-fed\autoloads\GameState.gd"
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
in_proxy_section = False
for line in lines:
    if line.strip() == "# API Proxies for backward compatibility":
        in_proxy_section = True
        new_lines.append("# --- DEPRECATED API PROXIES --- \n")
        new_lines.append("# These proxies are deprecated. Call the modular Autoloads directly (e.g., PlayerState, RunState).\n")
        continue
    
    if in_proxy_section and line.startswith("func get_power_level"):
        in_proxy_section = False # End of proxy section
    
    if in_proxy_section and line.startswith("var "):
        new_lines.append("# DEPRECATED\n")
        new_lines.append(line)
    else:
        new_lines.append(line)

with open(path, "w", encoding="utf-8") as f:
    f.writelines(new_lines)
print("GameState.gd updated")
