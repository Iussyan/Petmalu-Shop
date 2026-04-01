extends CharacterBody2D

@export var speed: float = 250.0

var last_direction: String = "down"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var target_pet = null
var target_npc = null
var target_door = null

func _ready() -> void:
	# Programmatically add WASD and interact support
	_ensure_input_action("ui_left", KEY_A)
	_ensure_input_action("ui_right", KEY_D)
	_ensure_input_action("ui_up", KEY_W)
	_ensure_input_action("ui_down", KEY_S)
	_ensure_input_action("interact", KEY_E)
	_ensure_input_action("adopt", KEY_F)
	_ensure_input_action("treat", KEY_G)
	_ensure_input_action("view_info", KEY_SPACE)

func _input(event: InputEvent) -> void:
	# Priority 1: Closing any open Popups/UI
	if event.is_action_pressed("view_info") or event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		if GameManager.active_popup:
			# Check if we are currently typing in a text field
			var focus = get_viewport().gui_get_focus_owner()
			var is_typing = focus is LineEdit or focus is TextEdit
			
			# If typing, only close if user presses Escape (ui_cancel)
			if is_typing and not event.is_action_pressed("ui_cancel"):
				return
				
			GameManager.close_popup()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("interact"):
		if target_npc and target_npc.has_method("interact"):
			target_npc.interact()
		elif target_pet and target_pet.has_method("interact"):
			target_pet.interact()
		elif target_door and target_door.has_method("interact"):
			target_door.interact()
			
	if event.is_action_pressed("adopt"):
		if target_pet and target_pet.has_method("adopt"):
			target_pet.adopt()
			
	if event.is_action_pressed("treat"):
		if target_pet and target_pet.has_method("interact"):
			target_pet.interact()
			
	if event.is_action_pressed("view_info"):
		if target_npc and target_npc.has_method("interact"):
			target_npc.interact() # NPCs show dialogue/shop on Space too
		elif target_pet and target_pet.has_method("view_info"):
			target_pet.view_info()

func _ensure_input_action(action: String, key_code: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		
	var events = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey and event.keycode == key_code:
			return # Already exists
	
	var new_event = InputEventKey.new()
	new_event.keycode = key_code
	InputMap.action_add_event(action, new_event)

func _physics_process(_delta: float) -> void:
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_vector != Vector2.ZERO:
		velocity = input_vector * speed
		_update_direction(input_vector)
		animation_player.play("walk_" + last_direction)
	else:
		velocity = Vector2.ZERO
		animation_player.play("idle_" + last_direction)
	
	move_and_slide()

func _update_direction(input_vector: Vector2) -> void:
	if abs(input_vector.x) > abs(input_vector.y):
		last_direction = "right" if input_vector.x > 0 else "left"
	else:
		last_direction = "down" if input_vector.y > 0 else "up"

func set_facing_direction(dir: String):
	if dir in ["up", "down", "left", "right"]:
		last_direction = dir
		if has_node("AnimationPlayer"):
			$AnimationPlayer.play("idle_" + last_direction)
