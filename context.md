# Petmalu Shop - Project Context

This document provides a comprehensive overview of the current state of the **Petmalu Shop** project, a Godot 4.3+ game centered around rescuing pets and managing a shop. It serves as a persistent brain for the AI coding assistant.

## 🌟 Core Concept
The player explores various biomes (Forest, Beach, Mountain) to rescue wild pets. Once rescued, pets are brought to the Shop, where the player must care for them (feed, play, treat) until they are healthy and happy enough for adoption. Adoption earns money and reputation, which unlocks new areas and shop levels.

---

## 🏗️ Architecture & Systems

### 1. Autoloads (Singletons)
These nodes persist across scene changes and handle global game state.

#### **GameManager.gd** (`/root/GameManager`)
The central "brain" of the game.
- **Variables**: `money`, `reputation`, `shop_level`, `pets_rescued`, `inventory`, `active_popup`, `rescued_pets_data`, `wild_pet_memory`.
- **Functions**:
    - `add_money(amount)`: Increases money and emits signal.
    - `add_inventory(item, amount)`: Modifies item counts.
    - `buy_item(item, amount, cost)`: Deducts money and adds to inventory if affordable.
    - `add_reputation(amount)`: Increases reputation and checks for level-ups.
    - `rescue_pet(pet_data, world_id)`: Appends pet data to the shop list and marks the world instance as rescued.
    - `change_scene(scene_path)`: Handles the fade-out, scene swap, and fade-in transition.
    - `_check_level_up()`: Calculates level based on reputation (1 level per 100 rep).
    - `_check_unlocks()`: Checks if requirements for Forest/Beach/Mountain are met.
    - `is_area_unlocked(area_name)`: Returns boolean based on level/pet requirements.
    - `open_dialogue(npc_name, role, text, owner_npc)`: Instantiates and displays the `DialoguePopup`.
    - `open_popup(scene_path, extra_data)`: Generic popup opener (Shop, Pet Info, etc.).
    - `close_popup()`: Safely closes the active UI and releases focus.

#### **ItemDB.gd** (`/root/ItemDB`)
The static data repository for all items.
- **Data**: Global `DATA` dictionary defining names, prices, icons, and "power" (effect strength).
- **Functions**:
    - `get_item(id)`: Returns the full dictionary for an item.
    - `get_all_shop_items()`: Filters items where `is_shop_item` is true.
    - `get_power(id)`: Returns the numeric effect value of an item.

#### **FadeOverlay.gd** (`/root/FadeOverlay`)
Handles visual transitions.
- **Functions**:
    - `fade_out()`: Plays the black-out animation.
    - `fade_in()`: Plays the transparent-in animation.

---

## 👥 Entities & Components

### **Player** (`src/Player/player.gd`)
- **Key Functions**:
    - `_physics_process`: Handles 8-way movement and animation selection.
    - `_input`: Unified interaction handler for `interact` (E), `adopt` (F), `treat` (G), and `view_info` (Space).
    - `_ensure_input_action`: Programmatically ensures keybindings exist on first run.
    - `set_facing_direction(dir)`: Forcing direction for cutscenes/spawns.

### **BasePet** (`src/Pets/BasePet.gd`)
- **States**: `WILD`, `SHOP`, `READY_FOR_ADOPTION`.
- **Key Functions**:
    - `_process`: Handles stat decay (hunger, happiness) and status checks.
    - `_update_ai_decisions`: Advanced AI driving behaviors like `WANDER`, `LOYAL`, `SKITTISH`, `GRUMPY`, etc.
    - `interact()`: Context-aware action (Rescue if wild, Care if in shop).
    - `rescue()`: Saves pet data to `GameManager` and removes the world instance.
    - `feed(amount)`, `give_treat()`, `play(amount)`: Modifies stats and saves to memory.
    - `adopt()`: Rewards player and removes pet from game.
    - `_save_to_memory()`: Stores current stats in `GameManager.wild_pet_memory` for persistence.

### **BaseNPC** (`src/NPCs/BaseNPC.gd`)
- **Key Functions**:
    - `interact()`: Cycles through first-time dialogue sequences or random lines.
    - `_on_dialogue_finished()`: Triggered when a dialogue closes (often auto-opens the shop).
    - `_update_ai`: Handles `WANDER`, `FACE_PLAYER`, and waypoint-based `PATROL`.
    - `_update_proximity_vis`: Shows/hides name labels based on player distance.

### **Entrance** (`src/Components/Entrance.gd`)
- **Key Functions**:
    - `_on_body_entered`: Detects player, saves `target_id` to `GameManager`, and triggers scene change.

### 4. UI Components (Embedded Scripts)
Most UI components use scripts embedded directly within their `.tscn` files as `SubResource`.

#### **DialoguePopup.tscn**
- **Functions**:
    - `_ready()`: Plays appearance animations (scale/modulate) and start a pulsing "Hint" tween.
    - `setup(name, role, content)`: Populates the labels with NPC information.

#### **ShopPopup.tscn**
- **Functions**:
    - `_ready()`: Populates the shop grid using `ItemDB.get_all_shop_items()`.
    - `buy_item(item_id)`: Interface-level call to `GameManager.buy_item()`.

#### **PetInfoPopup.tscn**
- **Functions**:
    - `display(pet_node)`: Connects to a pet instance to show real-time stats.

---

## 🛠️ Developer Rules (Summary)
1. **Unique Scene Names**: Always use `%NodeName` for UI path stability.
2. **Godot 4.3 API**: Use `add_theme_constant_override` (singular).
3. **Typing Priority**: Don't close UI via global keys if the user is typing in a `LineEdit`.
4. **Tweening**: Never tween `position` of nodes inside Containers; use `modulate` or `scale` instead.

---

## 📅 Recent Work Focus
- Restructuring the World Map into a 2x2 grid (1600x1600 total).
- Implementing the "NORTHWEST" town quadrant with 8 lots and a town square.
- Refining NPC interactions and Shop/Inventory GUI.
- Ensuring persistent pet stats between world and shop.
