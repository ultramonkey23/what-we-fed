import re
import os

combat_ui_builder_path = "C:/Users/harin/gamesdevs/What We Fed/what-we-fed/systems/presentation/CombatUIBuilder.gd"

with open(combat_ui_builder_path, "r", encoding="utf-8") as f:
    content = f.read()

# Remove .scene. from nodes that were proxy variables
content = content.replace(".scene.add_child", ".add_child")
content = content.replace(".scene.get_node", ".get_node")

# Inject node lookups at the top of _setup_ui
lookups = """func _setup_ui() -> void:
	ui_layer = scene.get_node("UI")
	combo_label = scene.get_node("UI/ComboLabel")
	style_label = scene.get_node("UI/StyleLabel")
	hp_bar = scene.get_node("UI/HPBar")
	stamina_bar = scene.get_node("UI/StaminaBar")
	ultimate_label = scene.get_node("UI/UltimateLabel")
	controls_label = scene.get_node("UI/ControlsLabel")
	result_label = scene.get_node("UI/ResultLabel")
	flash_overlay = scene.get_node("FlashOverlay")
	combat_meter = scene.get_node("CombatMeter")
"""

content = content.replace("func _setup_ui() -> void:", lookups)

with open(combat_ui_builder_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed CombatUIBuilder.gd syntax!")
