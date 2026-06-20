# 🧬 Combat UI Extraction: The Spine & Muscle Separation

*Architectural Critique & Evolutionary Plan by True Scholar & Blackvein*

In accordance with the **Organ Evolution Prime Law**, we must separate the pure nervous system (combat logic/math) from the sensory display (HUD). Right now, `CombatScene.gd` is acting as a monolithic God Object, tangling pure game state with raw UI instantiation. 

We will apply the **Slime Assimilation** and **Spider Web Survival** doctrines to create a decoupled MVP (Model-View-Presenter) architecture tailored for Godot 4.

## ⚖️ Philosophical Alignment

> **"Combat HUD = Urgency | Management Screens = Comprehension"**

*   **Urgency (The Combat HUD):** The HUD must react instantly to the Event Bus without blocking the main thread. We cannot afford to run `Node.new()` or `add_child()` during a heavy combat sequence. We will use **Pre-allocation (Object Pooling)**. The UI nodes must be physically spawned before the fight begins and simply toggled or tweened via signals.
*   **Comprehension (The Management Screens):** For rewards, route selection, and DNA manipulation, time is paused. Here, we *can* afford to use heavy programmatic loops to build rich, dynamic, information-dense displays on demand.

---

## 🔪 Surgical Migration Plan (5-Step Execution)

### Phase 1: Establish the Signal Spine (Completed)
We already have `CombatBus.gd`, `JuiceBus.gd`, and `MetaBus.gd` functioning as the central nervous system. 

### Phase 2: Scaffold the Presenter Node (`CombatUIBuilder`)
We will create a new independent Node: `CombatUIBuilder.gd`. This node will sit under the `$UI` CanvasLayer.
*   It will hold **no combat logic**.
*   It will **listen** to the `CombatBus` and `JuiceBus` passively (Spider Web Survival).
*   It will be the sole owner of `_build_hud_containers()`, `_setup_ui()`, and `_build_meter_shell()`.

### Phase 3: Sever the Monolith's Tendons
In `CombatScene.gd`, we will delete all `@onready` references to UI elements and strip out the 1,000+ lines of UI generation code. 
*   When a player takes damage, `CombatScene.gd` will simply calculate the math and emit: `CombatBus.player_took_damage.emit(amount)`. It will not know or care how the health bar is drawn.

### Phase 4: Extract and Encapsulate (The 1,000 Line Migration)
The programmatic UI generation currently choking `CombatScene.gd` will be moved into `CombatUIBuilder.gd`. 
We will categorize the builder into two distinct pipelines:
1.  **The Urgency Pipeline:** Builds the Combat Meter, HP Bars, and Combo Counters. These will be pre-instantiated in `_ready()` and pooled.
2.  **The Comprehension Pipeline:** Builds the DNA Reward screens, Upgrades, and Route Selection. These will remain fully dynamic and only build when invoked.

### Phase 5: The Physarum Optimization (Tweening & Pooling)
To ensure the "Combat-clean" mandate:
*   Floating damage text and impact FX will be handled by a pre-allocated array of 50 hidden nodes. 
*   We will replace heavy `_process` visual updates with `create_tween().tween_property()` for buttery smooth, asynchronous visual feedback.

---

### Actionable Next Step
If you approve this architectural blueprint, I will execute **Phase 2 & Phase 3**. I will create `systems/CombatUIBuilder.gd`, migrate the 1,000 lines of UI builder code out of `CombatScene.gd`, and wire it directly into the `CombatHUDPresenter`.
