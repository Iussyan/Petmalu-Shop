extends StaticBody2D

enum TargetRoom {
	MANUAL,
	SHOP,
	TOWN,
	DESERT,
	FOREST,
	BEACH
}

enum SpawnDirection { UP, DOWN, LEFT, RIGHT }

const PRESET_SCENES = {
	TargetRoom.SHOP: "res://src/Worlds/Shop.tscn",
	TargetRoom.TOWN: "res://src/Worlds/Main.tscn",
	TargetRoom.DESERT: "res://src/Worlds/Desert.tscn",
	TargetRoom.FOREST: "res://src/Worlds/Forest.tscn",
	TargetRoom.BEACH: "res://src/Worlds/Beach.tscn"
}

@export_group("Teleportation")
@export var target_room: TargetRoom = TargetRoom.MANUAL
@export var target_scene: String = ""
@export var my_id: int = 1
@export var target_entrance_id: int = 1
@export var spawn_direction: SpawnDirection = SpawnDirection.DOWN

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable: Interactable = $Interactable
@onready var door_audio: AudioStreamPlayer2D = $DoorAudio
@onready var interaction_prompt: PanelContainer = $InteractionPrompt

@export_group("Audio")
@export_file("*.wav", "*.ogg", "*.mp3") var open_sound: String = "res://assets/Audio/SFX/door_open.mp3"
@export_file("*.wav", "*.ogg", "*.mp3") var close_sound: String = "res://assets/Audio/SFX/door_close.mp3"

@export_group("UI")
@export var show_prompt: bool = true
@export var prompt_text: String = "[E] Enter"

var current_player: Node2D = null
var spawn_offset: Vector2 = Vector2.ZERO
var prompt_tween: Tween

func _ready() -> void:
	add_to_group("entrances")
	
	# Setup UI
	interaction_prompt.modulate.a = 0.0
	var label = interaction_prompt.get_node_or_null("Label")
	if label: label.text = prompt_text
	
	# Calculate offset based on direction (1 block = 16px)
	match spawn_direction:
		SpawnDirection.UP: spawn_offset = Vector2(0, -16)
		SpawnDirection.DOWN: spawn_offset = Vector2(0, 16)
		SpawnDirection.LEFT: spawn_offset = Vector2(-16, 0)
		SpawnDirection.RIGHT: spawn_offset = Vector2(16, 0)
		
	interactable.Interactable_Activated.connect(on_interactable_activated)
	interactable.Interactable_Deactivated.connect(on_interactable_deactivated)
	animated_sprite_2d.play("default")

func on_interactable_activated(body: Node2D) -> void:
	if not body.is_in_group("player"): return 
	
	current_player = body
	if body.has_method("set_facing_direction"):
		body.set("target_door", self)
		
	# Show Prompt
	if show_prompt:
		if prompt_tween: prompt_tween.kill()
		prompt_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		prompt_tween.tween_property(interaction_prompt, "modulate:a", 1.0, 0.25)
		prompt_tween.tween_property(interaction_prompt, "scale", Vector2.ONE, 0.25).from(Vector2(0.8, 0.8))

func on_interactable_deactivated(body: Node2D) -> void:
	if body == current_player:
		current_player = null
		if body.has_method("set_facing_direction"):
			if body.get("target_door") == self:
				body.set("target_door", null)
				
		# Hide Prompt
		if prompt_tween: prompt_tween.kill()
		prompt_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		prompt_tween.tween_property(interaction_prompt, "modulate:a", 0.0, 0.2)

func interact():
	if not current_player: return
	
	var scene_to_load = target_scene
	if target_room != TargetRoom.MANUAL:
		scene_to_load = PRESET_SCENES.get(target_room, "")
		
	if scene_to_load == "": 
		print("[Door] No target scene configured!")
		return

	# 1. Lock Player and Hide Prompt
	if current_player.has_method("lock_input"):
		current_player.lock_input(true)
	
	if prompt_tween: prompt_tween.kill()
	interaction_prompt.modulate.a = 0.0
	
	# 2. Open Animation & Sound
	animated_sprite_2d.play("open")
	_play_door_sound(open_sound)
	
	# 3. Glide Player forward
	# Small delay to sync with animation
	await get_tree().create_timer(0.2).timeout
	
	if not current_player: return
	
	var tween = get_tree().create_tween()
	var target_pos = global_position # Move to center of door
	
	tween.tween_property(current_player, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(current_player, "modulate:a", 0.0, 0.4)
	
	await tween.finished
	
	# 4. Close Animation & Sound
	animated_sprite_2d.play("default")
	_play_door_sound(close_sound)
	await get_tree().create_timer(0.2).timeout
	
	# 5. Execute Teleport Logic (Entrance.gd principle)
	print("[Door] Entering ", TargetRoom.keys()[target_room], " at ", scene_to_load)
	GameManager.target_entrance_id = target_entrance_id
	if current_player.get("last_direction"):
		GameManager.player_facing_on_spawn = current_player.last_direction
	
	# Trigger transition
	GameManager.change_scene(scene_to_load)

func _play_door_sound(path: String):
	if FileAccess.file_exists(path):
		var stream = load(path)
		if stream and door_audio:
			door_audio.stream = stream
			door_audio.play()
	
