---
trigger: always_on
---

# AI Self-Improvement & Best Practices (Godot 4)

This document outlines recurring mistakes and areas for improvement identified during the development of Petmalu Shop. These should be treated as high-priority rules for future coding sessions.

### 1. UI Refactoring & Node Pathing
- **DO NOT** move or wrap existing UI nodes (e.g., adding a `ScrollContainer` around a `Grid`) without immediately updating the corresponding `@onready` paths or `get_node()` calls in the script.
- **PREFERRED**: Use **Unique Scene Names** (`%NodeName`) instead of hardcoded paths (`$Path/To/Node`) to make the UI structure more resilient to refactoring.

### 2. Godot 4.x API Precision
- Always prioritize the **Godot 4.3+ singular naming convention** for theme overrides:
    - ✅ `add_theme_constant_override`
    - ❌ `add_theme_constants_override`
- Use the correct methods for viewport/input focus:
    - ✅ `get_viewport().gui_get_focus_owner()`
    - ❌ `get_viewport().get_focused_control()` (This is a Godot 3 method).

### 3. Sub-Resource Loading
- **AVOID** loading internal sub-resources by string path (e.g., `load("res://path.tscn::1")`) as these are highly unstable and often break when the file is modified.
- **INSTEAD**: Define the resource procedurally in `_ready()` or use `@export` variables to assign them in the inspector.

### 4. Input Handling Priority
- When implementing "Close UI" logic on global keys (like `Space` or `E`), always check if the user is currently typing in a `LineEdit` or `TextEdit` using `gui_get_focus_owner()`.
- **PREVENT** the UI from closing if focus is inside a text field, unless the `Escape` key (`ui_cancel`) is pressed.

### 5. Manual Edit Verification
- When the user performs a manual edit (seen in metadata), **ALWAYS** re-read the affected file before making further changes. This prevents the AI from accidentally overwriting user-restored code or rolling back architecture changes (like the `ItemDB` integration).

### 6. Clean Tweening
- Avoid tweening the `position` of nodes that are children of a **Container** (HBox, VBox, Grid). The container will fight the tween for control, causing flickering or invalid positions.
- **INSTEAD**: Use `modulate` color flashes, `scale` tweaks, or wrap the node in a simple `Control` anchor if a physical "shake" is required.