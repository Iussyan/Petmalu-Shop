extends Node

# SaveManager - Handles game persistence via JSON
# This file handles saving money, shop progress, and rescued pets.

const SAVE_PATH = "user://savegame.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game():
	var save_data = {
		"stats": {
			"money": GameManager.money,
			"reputation": GameManager.reputation,
			"shop_level": GameManager.shop_level,
			"pets_rescued": GameManager.pets_rescued
		},
		"pets": GameManager.rescued_pets_data,
		"wild_ids": GameManager.rescued_wild_pet_ids,
		"memory": GameManager.wild_pet_memory,
		"inventory": GameManager.inventory,
		"npc_history": GameManager.met_npc_names
	}
	
	var save_text = JSON.stringify(save_data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(save_text)
		file.close()
		print("[SaveManager] Game Saved successfully.")
	else:
		push_error("[SaveManager] Failed to create save file!")

func load_game():
	if not has_save(): 
		print("[SaveManager] No save file found to load.")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: return
	
	var json_text = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("[SaveManager] Save data is corrupted!")
		return
		
	# Restore Stats
	if data.has("stats"):
		var stats = data.stats
		GameManager.money = stats.get("money", 100)
		GameManager.reputation = stats.get("reputation", 0)
		GameManager.shop_level = stats.get("shop_level", 1)
		GameManager.pets_rescued = stats.get("pets_rescued", 0)
		
	# Restore Lists and Objects
	GameManager.rescued_pets_data = data.get("pets", [])
	
	# Handle typed arrays correctly for Godot 4
	var raw_wild_ids = data.get("wild_ids", [])
	GameManager.rescued_wild_pet_ids.clear()
	for id in raw_wild_ids:
		GameManager.rescued_wild_pet_ids.append(str(id))
		
	GameManager.wild_pet_memory = data.get("memory", {})
	
	var raw_inv = data.get("inventory", {"food": 10})
	GameManager.inventory.clear()
	for key in raw_inv:
		GameManager.inventory[key] = int(raw_inv[key])
	
	var raw_npc_history = data.get("npc_history", [])
	GameManager.met_npc_names.clear()
	for n in raw_npc_history:
		GameManager.met_npc_names.append(str(n))
	
	print("[SaveManager] Game Loaded successfully.")
	
	# Signal state refresh
	GameManager.stats_changed.emit("money", GameManager.money)
	GameManager.stats_changed.emit("reputation", GameManager.reputation)
	GameManager.stats_changed.emit("shop_level", GameManager.shop_level)

func delete_save():
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveManager] Save deleted.")
