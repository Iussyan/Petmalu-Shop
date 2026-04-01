extends Node

# --- Central Item Database ---
# Edit this dictionary to customize EVERY item in your game instantly.
# This affects the Shop UI, the Inventory, and the Pet effects.

const DATA = {
	"food": {
		"id": "food",
		"name": "Standard Kibble",
		"price": 10,
		"icon": "🥖",
		"desc": "Restores 5 Hunger",
		"power": 5.0,
		"type": "food",
		"is_shop_item": true
	},
	"treat": {
		"id": "treat",
		"name": "Yummy Treat",
		"price": 20,
		"icon": "🍬",
		"desc": "Restores 20 Happiness",
		"power": 20.0,
		"type": "treat",
		"is_shop_item": true
	},
	"medicine": {
		"id": "medicine",
		"name": "Health Tonic",
		"price": 75,
		"icon": "🍶",
		"desc": "Restores 40 Health",
		"power": 40.0,
		"type": "medicine",
		"is_shop_item": true
	}
}

func get_item(id: String) -> Dictionary:
	if DATA.has(id):
		return DATA[id]
	return {}

func get_all_shop_items() -> Array:
	var list = []
	for key in DATA:
		if DATA[key].get("is_shop_item", false):
			list.append(DATA[key])
	return list

func get_power(id: String) -> float:
	var item = get_item(id)
	return item.get("power", 0.0)
