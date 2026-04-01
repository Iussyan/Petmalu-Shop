extends StaticBody2D
@export_group("Teleportation")
@export_file("*.tscn") var target_scene: String = ""
@export var target_entrance_id: int = 1
@export var spawn_offset: Vector2 = Vector2(0, -60)

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var interactable: Interactable = $Interactable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interactable.Interactable_Activated.connect(on_interactable_activated)
	interactable.Interactable_Deactivated.connect(on_interactable_deactivated)
	
func on_interactable_activated(body: Node2D) -> void:
	animated_sprite_2d.play("open")
	if body.has_method("set_facing_direction"): # It's the player
		body.set("target_door", self)
	
func on_interactable_deactivated(body: Node2D) -> void:
	animated_sprite_2d.play("close")
	if body.has_method("set_facing_direction"): # It's the player
		if body.get("target_door") == self:
			body.set("target_door", null)

func interact():
	if target_scene == "": 
		print("[Door] No target scene configured!")
		return
		
	print("[Door] Entering door to ", target_scene, " target ID ", target_entrance_id)
	
	# Save state for the next scene
	GameManager.target_entrance_id = target_entrance_id
	# Facing direction handled by GameManager standard
	
	# Trigger global transition
	GameManager.change_scene(target_scene)
	
