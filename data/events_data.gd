extends Node

# Master list of all events
var all_events = {
	"broken_bridge": {
		"description": "You come across a wide, raging river. It appears treacherous. The bridge ahead has collapsed. How do you approach the crossing.",
		"act": 1,
		"completed": false,
		"choice1_text": "Ford the river",
		"choice1_tooltip": "Try to Ford the river. Riskier option, gain 5 xp. 50% chance to take 10 damage or 50% chance to find something in the water as you cross.",
		"choice2_text": "Jump across",
		"choice2_tooltip": "Try to Jump across the broken bridge. Safer option, gain 10 xp. 12% chance to take 5 damage.",
		"outcomes": [
			{"xp": 5, "effect": "risk", "damage": 10, "damage_chance": 0.5, "item": 1, "item_chance": 0.5},
			{"xp": 10, "effect": "risk", "damage": 5,  "damaeg_chance": 0.12}
		]
	},	
	"treasure_chest": {
		"type": "treasure",
		"act": 1,
		"completed": false
	},
	"shop": {
		"type": "shop",
		"act": 1,
		"completed": false
	},
	"combat":{
		"type": "combat",
		"act":1,
		"completed": false
	}
	# Add more events here easily
}

# Helper to get a random event (or by key)
func get_event(key: String = "") -> Dictionary:
	if key != "" and all_events.has(key):
		return all_events[key]
	
	# Filter available events for current act that are not completed
	var available = []
	for k in all_events.keys():
		var e = all_events[k]
		if e.get("act", 1) == PlayerData.act and not e.get("completed", false):
			available.append(k)
	
	if available.is_empty():
		print("No available events for Act ", PlayerData.act)
		return {}
	
	var random_key = available[randi() % available.size()]
	return all_events[random_key]
