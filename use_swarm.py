import os
import sys
from labcore.fallback_ai import blackvein_code
from labcore.routing import route_data

# Set model based on custom math
route = route_data("lab", "Refactor CombatScene UI to CombatUIBuilder", None)
agent = route.get("recommended_agent", "openrouter/auto")
model_map = {
    "gemini-cli": "google/gemini-2.5-pro",
    "claude-code": "anthropic/claude-3.5-sonnet",
    "codex": "openai/gpt-4o",
    "copilot": "openai/gpt-4o",
    "blackvein-code": "openrouter/auto",
    "blackvein-critic": "openrouter/auto",
}
os.environ["BLACKVEIN_CODE_MODEL"] = model_map.get(agent, "openrouter/auto")

print(f"Swarm Routing selected model: {os.environ['BLACKVEIN_CODE_MODEL']} via MAP-Elites.")

prompt = """
You are a symbiotic swarm worker. Our mission is to extract the UI proxy nodes out of CombatScene.gd and move them into CombatUIBuilder.gd so CombatScene no longer holds references to UI elements.
Return a diff patch that:
1. Removes the UI `@onready var` nodes from CombatScene.gd
2. Adds those `@onready var` nodes into CombatUIBuilder.gd
3. Changes CombatUIBuilder.gd to use its own variables instead of `scene._some_node`.
Return ONLY the unified diff block.
"""

with open("scenes/combat/CombatScene.gd", "r", encoding="utf-8") as f:
    combat_scene = f.read()

with open("systems/presentation/CombatUIBuilder.gd", "r", encoding="utf-8") as f:
    ui_builder = f.read()

full_prompt = prompt + f"\n\n--- CombatScene.gd ---\n{combat_scene[:5000]}...\n\n--- CombatUIBuilder.gd ---\n{ui_builder[:5000]}..."

res = blackvein_code(full_prompt)
print("\n--- Result from Swarm ---")
print(res.get("content", "No content returned."))
