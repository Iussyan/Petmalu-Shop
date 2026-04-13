extends Area2D

## Modular Teleport System Component
## Attach this to an Area2D to create a portal/door.

enum SpawnDirection { UP, DOWN, LEFT, RIGHT }

@export_file("*.tscn") var target_scene: String
@export var my_id: int = 1
@export var target_id: int = 1
@export var spawn_direction: SpawnDirection = SpawnDirection.DOWN
@export var portal_name: String = "Entrance"

var spawn_offset: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("entrances")
	
	# Calculate offset based on direction (1 block = 16px)
	match spawn_direction:
		SpawnDirection.UP: spawn_offset = Vector2(0, -16)
		SpawnDirection.DOWN: spawn_offset = Vector2(0, 16)
		SpawnDirection.LEFT: spawn_offset = Vector2(-16, 0)
		SpawnDirection.RIGHT: spawn_offset = Vector2(16, 0)
		
	collision_layer = 0
	collision_mask = 2 # Player is on layer 2
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# If it's the player (detected by movement method)
	if body.has_method("_update_direction"):
		print("[Entrance] Teleporting from ID ", my_id, " to scene ", target_scene, " target ID ", target_id)
		
		# Save state for the next scene
		GameManager.target_entrance_id = target_id
		GameManager.player_facing_on_spawn = body.last_direction
		
		# Trigger global transition
		GameManager.change_scene(target_scene)
