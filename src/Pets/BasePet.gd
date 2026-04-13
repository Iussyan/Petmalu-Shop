extends CharacterBody2D

enum State { WILD, SHOP, READY_FOR_ADOPTION }
enum Behavior { WANDER, LOYAL, SKITTISH, LAZY, CURIOUS, PLAYFUL, GRUMPY, MISCHIEVOUS }

# --- Configuration ---
@export var pet_type: String = "Cat"
@export var wild_behavior: Behavior = Behavior.WANDER
@export var shop_behavior: Behavior = Behavior.LOYAL
@export var pet_id: String = "" # Unique ID for world-persistence
@export var move_speed: float = 120.0
@export var low_hunger_threshold: float = 30.0
@export var low_happiness_threshold: float = 30.0

@export_group("Stats Decay Rates")
## Points per second
@export var hunger_decay_rate: float = 0.5 
@export var happiness_decay_rate: float = 0.2
@export var health_decay_rate: float = 1.0 # When starving (hunger = 0)
@export var health_regen_rate: float = 0.5 # When well-fed (hunger > 80)

@export_group("Advanced Sounds")
@export_file("*.wav", "*.mp3", "*.ogg") var sound_walk: String = ""
@export var sound_pool: Array[String] = []
@export var proximity_range: float = 120.0
@export var vocal_min_delay: float = 4.0
@export var vocal_max_delay: float = 10.0

# --- Stats (0-100) ---
var hunger: float = 100.0:
	set(val): hunger = clamp(val, 0, 100)
var health: float = 100.0:
	set(val): health = clamp(val, 0, 100)
var happiness: float = 50.0:
	set(val): happiness = clamp(val, 0, 100)

var current_state = State.WILD

# --- AI Internal State ---
var ai_timer: float = 0.0
var move_dir: Vector2 = Vector2.ZERO
var target_node: Node2D = null
var is_active: bool = true
var pet_custom_name: String = ""

@onready var name_label: Label = $NameLabel
@onready var hunger_bar: ProgressBar = $StatsUI/VBoxContainer/HungerBar
@onready var health_bar: ProgressBar = $StatsUI/VBoxContainer/HealthBar
@onready var happy_bar: ProgressBar = $StatsUI/VBoxContainer/HappyBar
@onready var interact_prompt: Label = $InteractPrompt
@onready var sprite: Sprite2D = $Sprite2D
@onready var walk_player: AudioStreamPlayer2D = $WalkPlayer
@onready var vocal_player: AudioStreamPlayer2D = $VocalPlayer

var _vocal_timer: float = 0.0

func _ready():
	if pet_id != "" and pet_id in GameManager.rescued_wild_pet_ids:
		queue_free()
		return
		
	name_label.text = pet_custom_name if pet_custom_name != "" else pet_type
	interact_prompt.hide()
	
	if current_state == State.WILD:
		$StatsUI.hide()
	
	# Load memory if this is a returning wild pet
	if pet_id != "" and GameManager.wild_pet_memory.has(pet_id):
		var mem = GameManager.wild_pet_memory[pet_id]
		hunger = mem.hunger
		health = mem.health
		happiness = mem.happiness
		pet_custom_name = mem.get("name", "")
		if mem.has("position") and mem.position != null:
			var pos = mem.position
			if pos is String: pos = str_to_var(pos)
			if pos != null:
				global_position = pos
	
	_update_ui()
	_find_player()
	
	if current_state == State.SHOP or current_state == State.READY_FOR_ADOPTION:
		set_collision_layer_value(3, false) # Passable when rescued

func _find_player():
	target_node = get_tree().get_first_node_in_group("player")

func _process(delta):
	if current_state == State.SHOP or current_state == State.READY_FOR_ADOPTION:
		# Deterioration over time using exported rates
		hunger -= hunger_decay_rate * delta
		happiness -= happiness_decay_rate * delta
		
		if hunger <= 0: 
			health -= health_decay_rate * delta
		elif hunger > 80: 
			health += health_regen_rate * delta
			
		_update_ui()
		
		# Check state
		var is_ready = hunger > 80 and happiness > 80 and health > 90
		if is_ready:
			if current_state != State.READY_FOR_ADOPTION:
				current_state = State.READY_FOR_ADOPTION
				_update_interact_prompt()
		else:
			if current_state == State.READY_FOR_ADOPTION:
				current_state = State.SHOP
				_update_interact_prompt()

func _physics_process(delta):
	if not is_active: return
	_update_ai_decisions(delta)
	
	if move_dir != Vector2.ZERO:
		velocity = move_dir * move_speed
		if move_dir.x != 0:
			sprite.flip_h = move_dir.x < 0
	else:
		velocity = Vector2.ZERO
		
	_update_sound_logic(delta)
	move_and_slide()

func _update_sound_logic(delta):
	# Walking sound
	if velocity.length() > 10.0 and sound_walk != "":
		if not walk_player.playing:
			if walk_player.stream == null or walk_player.stream.resource_path != sound_walk:
				walk_player.stream = load(sound_walk)
			walk_player.play()
	else:
		if walk_player.playing:
			walk_player.stop()

	# Proximity sounds
	if not sound_pool.is_empty() and is_instance_valid(target_node):
		var dist = global_position.distance_to(target_node.global_position)
		if dist < proximity_range:
			_vocal_timer -= delta
			if _vocal_timer <= 0:
				_play_random_vocal()
				_vocal_timer = randf_range(vocal_min_delay, vocal_max_delay)
		else:
			# Reset timer slightly so it starts countdown when player enters
			_vocal_timer = min(_vocal_timer, 1.0)

func _play_random_vocal():
	if sound_pool.is_empty(): return
	var sound_path = sound_pool[randi() % sound_pool.size()]
	if sound_path != "":
		vocal_player.stream = load(sound_path)
		vocal_player.pitch_scale = randf_range(0.9, 1.1)
		vocal_player.play()

func _update_ai_decisions(delta):
	if not is_instance_valid(target_node):
		_find_player()
		if not is_instance_valid(target_node):
			move_dir = Vector2.ZERO
			return

	ai_timer -= delta
	var dist = global_position.distance_to(target_node.global_position)
	var dir = global_position.direction_to(target_node.global_position)
	
	var active_mood = _get_current_base_behavior()
	if hunger < low_hunger_threshold: active_mood = Behavior.GRUMPY
	elif happiness < low_happiness_threshold: active_mood = Behavior.SKITTISH
		
	match active_mood:
		Behavior.WANDER:
			if ai_timer <= 0:
				move_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() if randf() > 0.4 else Vector2.ZERO
				ai_timer = randf_range(1.5, 4.0)
		Behavior.LOYAL:
			move_dir = dir if dist < 400 and dist > 60 else Vector2.ZERO
		Behavior.SKITTISH:
			if current_state == State.WILD and dist < 180: move_dir = -dir * 1.5
			elif ai_timer <= 0: move_dir = Vector2.ZERO; ai_timer = 2.0
		Behavior.LAZY:
			if ai_timer <= 0:
				move_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() if randf() > 0.9 else Vector2.ZERO
				ai_timer = randf_range(5.0, 10.0)
		Behavior.CURIOUS:
			move_dir = dir * 0.5 if dist < 300 and dist > 120 else Vector2.ZERO
		Behavior.PLAYFUL:
			if ai_timer <= 0:
				var zooming = randf() > 0.6
				move_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() if zooming else Vector2.ZERO
				move_speed = 250.0 if zooming else 100.0
				ai_timer = randf_range(0.8, 2.0)
		Behavior.GRUMPY:
			move_dir = dir * 1.4 if dist < 220 else Vector2.ZERO
		Behavior.MISCHIEVOUS:
			if dist < 80: move_dir = -dir * 2.0; ai_timer = 0.5
			elif ai_timer <= 0: move_dir = Vector2.ZERO

# --- Actions ---

func _update_ui():
	hunger_bar.value = hunger
	health_bar.value = health
	happy_bar.value = happiness
	modulate = Color(1, 0.5, 0.5) if health < 30 else Color(1, 1, 1)

func _get_current_base_behavior() -> Behavior:
	if current_state == State.WILD:
		return wild_behavior
	return shop_behavior

func _update_interact_prompt():
	if not interact_prompt.visible: return
	if current_state == State.READY_FOR_ADOPTION:
		interact_prompt.text = "[E] Play | [F] Adopt"
	elif current_state == State.WILD:
		interact_prompt.text = "[E] Rescue"
	else:
		interact_prompt.text = "[E] Feed | [G] Treat"

func interact():
	match current_state:
		State.WILD: rescue()
		State.SHOP, State.READY_FOR_ADOPTION:
			if Input.is_action_just_pressed("treat"):
				give_treat()
			else:
				feed(20)
				play(5)

func view_info():
	GameManager.open_popup("res://src/UI/PetInfoPopup.tscn", self)

func adopt():
	if current_state == State.READY_FOR_ADOPTION:
		print("Pet Adopted! Gained reward.")
		GameManager.add_money(250)
		GameManager.add_reputation(60)
		# Clear persistence ID so it doesn't try to remove from wild again
		pet_id = "" 
		queue_free()

func rescue():
	is_active = false
	if has_node("/root/FadeOverlay"):
		get_node("/root/FadeOverlay").fade_out()
		await get_node("/root/FadeOverlay").fade_out_complete
	
	current_state = State.SHOP
	var data = {
		"type": pet_type, 
		"custom_name": pet_custom_name,
		"hunger": hunger, 
		"health": health, 
		"happiness": happiness, 
		"wild_behavior": wild_behavior,
		"shop_behavior": shop_behavior
	}
	GameManager.rescue_pet(data, pet_id)
	queue_free()
	
	if has_node("/root/FadeOverlay"):
		get_node("/root/FadeOverlay").fade_in()

func feed(amount: float = 0.0): 
	var power = amount if amount > 0 else ItemDB.get_power("food")
	if GameManager.inventory.get("food", 0) > 0:
		GameManager.add_inventory("food", -1)
		hunger += power
		_save_to_memory()
	else:
		GameManager.open_dialogue("Me", "Thinking", "I'm out of food... I should buy some at the shop first.")

func give_treat():
	var power = ItemDB.get_power("treat")
	if GameManager.inventory.get("treat", 0) > 0:
		GameManager.add_inventory("treat", -1)
		happiness += power
		hunger += 10 # Small bonus
		_save_to_memory()
	else:
		GameManager.open_dialogue("Me", "Thinking", "I don't have any treats left. Better check the shop!")

func play(amount: float): 
	happiness += amount
	_save_to_memory()

func _exit_tree():
	# Ensure state is saved when leaving the scene (e.g. going into shop)
	if current_state == State.WILD and pet_id != "":
		_save_to_memory()

func _save_to_memory():
	if pet_id != "":
		GameManager.wild_pet_memory[pet_id] = {
			"hunger": hunger,
			"health": health,
			"happiness": happiness,
			"name": pet_custom_name,
			"position": global_position
		}

func get_stats_data() -> Dictionary:
	return {
		"type": pet_type,
		"custom_name": pet_custom_name,
		"hunger": hunger,
		"health": health,
		"happiness": happiness,
		"wild_behavior": wild_behavior,
		"shop_behavior": shop_behavior,
		"position": global_position
	}

func _on_interaction_area_body_entered(body):
	if body.has_method("_update_direction"):
		body.target_pet = self
		interact_prompt.show()
		_update_interact_prompt()

func _on_interaction_area_body_exited(body):
	if body.has_method("_update_direction"):
		if body.target_pet == self: body.target_pet = null
		interact_prompt.hide()
