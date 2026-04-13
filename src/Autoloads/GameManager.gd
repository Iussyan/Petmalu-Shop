extends Node

# Global Shop Stats
var money: int = 100 # Start with some money
var reputation: int = 0
var shop_level: int = 1
var pets_rescued: int = 0

# Biome Unlock Requirements
const DESERT_UNLOCK = {"level": 2, "pets": 5}
const FOREST_UNLOCK = {"level": 3, "pets": 10}
const BEACH_UNLOCK = {"level": 4, "pets": 15}

var rescued_pets_data: Array = []
var rescued_wild_pet_ids: Array[String] = []
var wild_pet_memory: Dictionary = {} # Store stats for wild animals before rescue
var inventory: Dictionary = {"food": 10}

var target_entrance_id: int = -1
var player_facing_on_spawn: String = "down"
var active_popup: CanvasLayer = null # Track the currently open UI
var met_npc_names: Array[String] = [] # Track which NPCs have been met

# Dialogue Settings
var dialogue_typing_speed: float = 40.0 # Characters per second

signal stats_changed(stat_name, new_value)
signal inventory_changed(item, amount)
signal area_unlocked(area_name)
signal dialogue_finished(npc_owner)

func _ready():
	# Load progress on startup
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").load_game()

func add_money(amount: int):
	money += amount
	stats_changed.emit("money", money)
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game()

func add_inventory(item: String, amount: int):
	inventory[item] = int(inventory.get(item, 0)) + amount
	inventory_changed.emit(item, inventory[item])
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game()

func buy_item(item: String, amount: int, cost: int) -> bool:
	if money >= cost:
		money -= cost
		add_inventory(item, amount)
		stats_changed.emit("money", money)
		return true
	return false

func add_reputation(amount: int):
	reputation += amount
	_check_level_up()
	stats_changed.emit("reputation", reputation)

func rescue_pet(pet_data: Dictionary = {}, world_id: String = ""):
	if not pet_data.is_empty():
		rescued_pets_data.append(pet_data)
	if world_id != "":
		rescued_wild_pet_ids.append(world_id)
	
	pets_rescued += 1
	stats_changed.emit("pets_rescued", pets_rescued)
	_check_unlocks()
	
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game()

func change_scene(scene_path: String):
	close_popup() # Clean UI on transition
	if has_node("/root/FadeOverlay"):
		var fade = get_node("/root/FadeOverlay")
		fade.fade_out()
		await fade.fade_out_complete
		get_tree().change_scene_to_file(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)

func _check_level_up():
	var new_level = 1 + floor(float(reputation) / 100.0)
	if new_level > shop_level:
		shop_level = new_level
		stats_changed.emit("shop_level", shop_level)
		_check_unlocks()

func _check_unlocks():
	if is_area_unlocked("Desert"):
		area_unlocked.emit("Desert")
	if is_area_unlocked("Forest"):
		area_unlocked.emit("Forest")
	if is_area_unlocked("Beach"):
		area_unlocked.emit("Beach")

func is_area_unlocked(area_name: String) -> bool:
	match area_name:
		"Desert": return shop_level >= DESERT_UNLOCK.level and pets_rescued >= DESERT_UNLOCK.pets
		"Forest": return shop_level >= FOREST_UNLOCK.level and pets_rescued >= FOREST_UNLOCK.pets
		"Beach": return shop_level >= BEACH_UNLOCK.level and pets_rescued >= BEACH_UNLOCK.pets
		"Town": return true
	return false



func open_dialogue(npc_name_text: String, role: String, text: String, owner_npc: Node = null):
	if active_popup:
		close_popup()
		
	var scene = load("res://src/UI/DialoguePopup.tscn")
	active_popup = scene.instantiate()
	get_tree().root.add_child(active_popup)
	
	if active_popup.has_method("setup"):
		active_popup.setup(npc_name_text, role, text)
	
	# Pass the owner for the hand-off signal
	if "npc_owner" in active_popup:
		active_popup.npc_owner = owner_npc
	
	return active_popup

func open_popup(scene_path: String, extra_data = null):
	if active_popup:
		close_popup()
		
	var scene = load(scene_path)
	if not scene:
		return null
		
	active_popup = scene.instantiate()
	get_tree().root.add_child(active_popup)
	
	if active_popup.has_method("display"):
		active_popup.display(extra_data)
	elif active_popup.has_method("setup"):
		active_popup.setup(extra_data)
		
	return active_popup

func close_popup():
	var current_focus = get_viewport().gui_get_focus_owner()
	if current_focus:
		current_focus.release_focus()
		
	if is_instance_valid(active_popup):
		var owner_npc = active_popup.get("npc_owner") if "npc_owner" in active_popup else null
		active_popup.queue_free()
		active_popup = null
		
		# If it was a dialogue, signal the finished state
		if owner_npc:
			dialogue_finished.emit(owner_npc)
	else:
		active_popup = null

func reset_game_state():
	money = 100
	reputation = 0
	shop_level = 1
	pets_rescued = 0
	rescued_pets_data = []
	rescued_wild_pet_ids = []
	wild_pet_memory = {}
	inventory = {"food": 10}
	met_npc_names = []
	
	# Emit signals to update potential UI listeners
	stats_changed.emit("money", money)
	stats_changed.emit("reputation", reputation)
	stats_changed.emit("shop_level", shop_level)
	stats_changed.emit("pets_rescued", pets_rescued)
