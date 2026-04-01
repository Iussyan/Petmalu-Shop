extends Area2D

## Modular Teleport System Component
## Attach this to an Area2D to create a portal/door.

@export_file("*.tscn") var target_scene: String
@export var my_id: int = 1
@export var target_id: int = 1
@export var spawn_offset: Vector2 = Vector2(0, 80)
@export var portal_name: String = "Entrance"

func _ready():
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
