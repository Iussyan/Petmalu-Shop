extends CharacterBody2D

enum Behavior { IDLE, WANDER, FACE_PLAYER, PATROL }
enum InteractionType { SHOP, DIALOGUE, QUEST }

@export var npc_name: String = "Shopkeeper"
@export var npc_role: String = "Merchant"
@export var is_passable: bool = false
@export var behavior: Behavior = Behavior.IDLE
@export var interaction_type: InteractionType = InteractionType.SHOP
@export var move_speed: float = 80.0
@export var wander_radius: float = 150.0
@export var display_range: float = 200.0

@export_multiline var first_time_sequence: String = "" # Comma-separated: "Hello, How are you?"
@export_multiline var random_dialogues: String = "" # Comma-separated: "Nice day!, Cold today."
@export var patrol_points: Array[NodePath] = []
@export var patrol_stop_time: float = 1.5  # Seconds to wait at each point

var ai_timer: float = 0.0
var dialogue_timer: float = 0.0
var move_dir: Vector2 = Vector2.ZERO
var start_pos: Vector2
var target_node: Node2D = null

var _sequence_index: int = 0
var _is_met: bool = false
var _patrol_nodes: Array[Node2D] = []
var _patrol_index: int = 0
var _patrol_waiting: bool = false
var _patrol_wait_timer: float = 0.0
var _is_showing_dialogue: bool = false

@onready var sprite = $Sprite2D
@onready var name_label = $NameLabel
@onready var role_label = $RoleLabel
@onready var interact_prompt = $InteractPrompt
@onready var anim_player = $AnimationPlayer

var last_direction: String = "down"

func _ready():
	start_pos = global_position
	# Check if met via GameManager
	_is_met = GameManager.met_npc_names.has(npc_name)

	name_label.text = npc_name
	role_label.text = npc_role
	interact_prompt.hide()
	GameManager.dialogue_finished.connect(_on_dialogue_finished)
	if is_passable:
		set_collision_layer_value(3, false) # Disable bit 2 (Layer 3/NPCs)

	target_node = get_tree().get_first_node_in_group("player")
	
	for path in patrol_points:
		var n = get_node_or_null(path)
		if n: _patrol_nodes.append(n)


# ─── Label & UI Setup ────────────────────────────────────────────────────────

func _setup_labels():
	# Pixel-perfect rendering: disable filtering so text isn't blurry
	# Use a bitmap / pixel font assigned in the inspector.
	# These settings prevent Godot from smoothing the label texture.
	for label in [name_label, role_label, interact_prompt]:
		if label is Label:
			label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			# Prevent label from inheriting parent's smooth scaling
			label.use_parent_material = false


# NPCs now use the global DialoguePopup system.


# ─── Physics ─────────────────────────────────────────────────────────────────

func _physics_process(delta):
	_update_ai(delta)
	_update_proximity_vis()

	if move_dir != Vector2.ZERO:
		velocity = move_dir * move_speed
	else:
		velocity = Vector2.ZERO

	_update_animations()
	move_and_slide()

func _update_animations():
	if velocity.length() > 0.1:
		# Determine primary direction
		if abs(velocity.x) > abs(velocity.y):
			last_direction = "left" if velocity.x < 0 else "right"
		else:
			last_direction = "up" if velocity.y < 0 else "down"
		
		anim_player.play("walk_" + last_direction)
	else:
		anim_player.play("idle_" + last_direction)


# ─── AI ──────────────────────────────────────────────────────────────────────

func _update_ai(delta):
	ai_timer -= delta

	match behavior:
		Behavior.IDLE:
			move_dir = Vector2.ZERO

		Behavior.WANDER:
			if ai_timer <= 0:
				if global_position.distance_to(start_pos) > wander_radius:
					move_dir = global_position.direction_to(start_pos)
				else:
					move_dir = (
						Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
						if randf() > 0.5 else Vector2.ZERO
					)
				ai_timer = randf_range(2.0, 5.0)

		Behavior.FACE_PLAYER:
			move_dir = Vector2.ZERO
			if is_instance_valid(target_node):
				var dir = global_position.direction_to(target_node.global_position)
				if abs(dir.x) > abs(dir.y):
					last_direction = "left" if dir.x < 0 else "right"
				else:
					last_direction = "up" if dir.y < 0 else "down"

		Behavior.PATROL:
			_update_patrol(delta)


func _update_patrol(delta):
	# No points defined — stay idle
	if _patrol_nodes.is_empty():
		move_dir = Vector2.ZERO
		return

	# Waiting at a waypoint
	if _patrol_waiting:
		move_dir = Vector2.ZERO
		_patrol_wait_timer -= delta
		if _patrol_wait_timer <= 0:
			_patrol_waiting = false
			# Advance to next point
			_patrol_index = (_patrol_index + 1) % _patrol_nodes.size()
		return

	var target_point: Node2D = _patrol_nodes[_patrol_index]
	if not is_instance_valid(target_point):
		_patrol_index = (_patrol_index + 1) % _patrol_nodes.size()
		return

	var dist = global_position.distance_to(target_point.global_position)

	if dist < 6.0:
		# Arrived — wait before moving to next
		move_dir = Vector2.ZERO
		_patrol_waiting = true
		_patrol_wait_timer = patrol_stop_time
	else:
		move_dir = global_position.direction_to(target_point.global_position)


# ─── Proximity Labels ─────────────────────────────────────────────────────────

func _update_proximity_vis():
	if is_instance_valid(target_node):
		var dist = global_position.distance_to(target_node.global_position)
		var is_near = dist < display_range
		name_label.visible = is_near
		role_label.visible = is_near
	else:
		name_label.hide()
		role_label.hide()


# ─── Dialogue ────────────────────────────────────────────────────────────────

func _update_dialogue(_delta):
	pass


# ─── Interaction ─────────────────────────────────────────────────────────────

func interact():
	# Sync state: if nothing is open globally, we aren't showing dialogue locally
	if GameManager.active_popup == null:
		_is_showing_dialogue = false

	# If dialogue is already showing, close it first
	if _is_showing_dialogue:
		GameManager.close_popup()
		return

	var lines_intro = first_time_sequence.split(",") if first_time_sequence != "" else PackedStringArray()
	var lines_random = random_dialogues.split(",") if random_dialogues != "" else PackedStringArray()
	
	var text_to_show = ""
	var _just_finished_intro = false
	
	if not _is_met and lines_intro.size() > 0:
		text_to_show = lines_intro[_sequence_index].strip_edges()
		_sequence_index += 1
		if _sequence_index >= lines_intro.size():
			_is_met = true
			_just_finished_intro = true
			GameManager.met_npc_names.append(npc_name)
	elif lines_random.size() > 0:
		text_to_show = lines_random[randi() % lines_random.size()].strip_edges()
	else:
		text_to_show = "Hello there!"
		
	GameManager.open_dialogue(npc_name, npc_role, text_to_show, self)
	_is_showing_dialogue = true

func _on_dialogue_finished(owner_node):
	if owner_node == self:
		_is_showing_dialogue = false
		# Auto-open shop if we are a merchant and player is still here
		if interaction_type == InteractionType.SHOP and interact_prompt.visible:
			GameManager.open_popup("res://src/UI/ShopPopup.tscn")

func show_dialogue(text: String):
	GameManager.open_dialogue(npc_name, npc_role, text)


func _on_interaction_area_body_entered(body):
	if body.has_method("_update_direction"):
		body.target_npc = self
		interact_prompt.show()


func _on_interaction_area_body_exited(body):
	if body.has_method("_update_direction"):
		if body.target_npc == self:
			body.target_npc = null
		interact_prompt.hide()
