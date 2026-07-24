extends Node

var was_not_consumed: bool = false
var aerus_blessing_count: int = 0
var has_venari_blessing: bool = false
var has_rixas_blessing: bool = false
var has_aerus_blessing: bool = false

# Individual effect functions
func swift_foot_bonus():
	PlayerData.speed += 10
	print("Swift Foot Boots equipped: +5 Speed")

func giants_club():
	PlayerData.strength += 2
	PlayerData.speed -= 10
	print("Giant's Club equipped: +2 Strength, -10 Speed")

func energy_ring():
	# This one is checked in the Combat Manager
	print("Energy Ring equipped: +1 AP at start of combat")

func burnheart_charm():
	PlayerData.has_burnheart_charm = true
	print("Burnheart Charm equipped: deal +2 damage to burning enemies")

func heavy_shield():
	PlayerData.has_heavy_shield = true
	PlayerData.speed -= 10
	print("Heavy Shield equipped: -10 speed, gain +2 block at the start of your turn")

func health_stone():
	PlayerData.max_health = PlayerData.max_health +4
	print("Health Stone equipped: Max Health increased by 4")

func aerus_blessing():
	has_aerus_blessing = true
	var bonus = int(PlayerData.base_speed * 0.1)
	PlayerData.speed += bonus
	print("Blessing of Aerus: +", bonus, " Speed (10% of base), after 3 combats, charges and let's you 'jump' from one path to any other path")

func rixas_blessing():
	var bonus = int(PlayerData.level * 2)
	has_rixas_blessing = true
	PlayerData.max_health += bonus
	print("Blessing of Rixas: +", bonus, " Health (2x your level)")

func venari_blessing():
	has_venari_blessing = true
	print("Blessing of Venari: Gain 5% lifesteal on damage dealt, minimum 1 — gain 1 Ap on target kill")

# Apply the effect of an equipped trinket
func apply_trinket_effect(item_id: String):
	var item = get_item_by_id(item_id)
	if item.is_empty():
		return
	
	has_venari_blessing = false
	
	match item.effect:
		"swift_foot_bonus":
			swift_foot_bonus()
		"giants_club":
			giants_club()
		"energy_ring":
			energy_ring()
		"burnheart_charm":
			burnheart_charm()
		"heavy_shield":
			heavy_shield()
		"health_stone":
			health_stone()
		"aerus_blessing":
			aerus_blessing()
		"rixas_blessing":
			rixas_blessing()
		"venari_blessing":
			venari_blessing()
		_:
			print("Unknown effect: ", item.effect)

func use_consumable(item_id: String) -> bool:
	var item = get_item_by_id(item_id)
	if item.is_empty():
		return false
	
	match item.effect:
		"health_stone":
			PlayerData.current_health = min(PlayerData.max_health, PlayerData.current_health + 10)
			print("Healed 10 HP!")
			return true
		"energy_stone":
			if PlayerData.is_in_combat:
				if PlayerData.current_character.has_method("add_ap"):
					PlayerData.current_character.add_ap(3)
				else:
					PlayerData.current_character.ap += 3
				print("Gained 3 AP")
			else:
				was_not_consumed = true
				print("Energy Stone will grant +3 AP if used in combat")
			return true
		"ability_voucher":
			PlayerData.pending_ability_choice = true
			print("Ability Voucher used, enter a camp to learn an ability")
			return true
		"strength_elixir":
			if PlayerData.is_in_combat:
				PlayerData.current_character.strength += 2
				PlayerData.strength += 2
				print("Gained 2 Strength")
			else:
				was_not_consumed = true
				print("Strength Elixir will grant +2 Strength if used in combat")
			return true
		"defense_elixir":
			if PlayerData.is_in_combat:
				PlayerData.current_character.defense += 2
				PlayerData.defense += 2
				print("Gained 2 Defense")
			else:
				was_not_consumed = true
				print("Defense Elixir will grant +2 Defense if used in combat")
			return true
		"speed_elixir":
			if PlayerData.is_in_combat:
				PlayerData.current_character.speed += 20
				PlayerData.speed += 20
				print("Gained 20 Speed")
			else:
				was_not_consumed = true
				print("Speed Elixir will grant +20 Speed if used in combat")
			return true
		# add more consumables later
		_:
			print("Unknown consumable effect")
			return false

# Helper function to find all items in the player's inventory and equipment
func is_item_owned(item_id: String) -> bool:
	return PlayerData.full_inventory.has(item_id) or PlayerData.equipped_trinkets.has(item_id)

# Helper function to find an item by its ID
func get_item_by_id(item_id: String) -> Dictionary:
	for item in all_items:
		if item.id == item_id:
			return item
	return {}  # return empty if not found

func get_random_item() -> Dictionary:
	if all_items.is_empty():
		print("ERROR: No items in Inventory!")
		return {}
	
	var candidates = all_items.filter(func(item): return item.get("type") and not (item.get("unique", false) and is_item_owned(item.id)))
	
	if candidates.is_empty():
		return all_items[randi() % all_items.size()]  # fallback
	
	return candidates[randi() % candidates.size()]

# Returns a random item dictionary from all_items except blessings
func get_random_item_WOblessing() -> Dictionary:
	if all_items.is_empty():
		print("ERROR: No items in Inventory!")
		return {}
	
	var candidates = all_items.filter(func(item):
		return item.get("type") != "Blessing" and \
			not (item.get("unique", false) and is_item_owned(item.id))
	)
	
	if candidates.is_empty():
		return all_items[randi() % all_items.size()]  # fallback
	
	return candidates[randi() % candidates.size()]


# Get random item by type (e.g. only "Trinket")
func get_random_item_of_type(item_type: String) -> Dictionary:
	var filtered = all_items.filter(func(item): return item.get("type") == item_type)
	var candidates = filtered.filter(func(item):
		return not (item.get("unique", false) and is_item_owned(item.id))
	)
	
	if candidates.is_empty():
		if filtered.is_empty():
			return {}
		return filtered[randi() % filtered.size()]  # fallback
	
	return candidates[randi() % candidates.size()]

# Get random item by rarity (e.g. only "Common")
func get_random_item_of_rarity(item_type: String) -> Dictionary:
	var filtered = all_items.filter(func(item): 
		return item.get("rarity") == item_type and item.get("type") != "Blessing"
	)
	var candidates = filtered.filter(func(item):
		return not (item.get("unique", false) and is_item_owned(item.id))
	)
	
	if candidates.is_empty():
		if filtered.is_empty():
			return {}
		return filtered[randi() % filtered.size()]  # fallback
	
	return candidates[randi() % candidates.size()]

# Master list of ALL items in the game
var all_items: Array = [
	{
		"id": "swift_foot_boots",
		"name": "Swift Foot Boots",
		"type": "Trinket",
		"subtype": "Gear",
		"image": "res://images/item_art/swift_foot_boots.png",   # we'll add real images later
		"effect": "swift_foot_bonus",
		"xp_cost": 9,
		"description": "Increases your base Speed by 10.",
		"gold_cost": 91,
		"rarity": "Common",
		"unique": false
	},
	{
		"id": "giants_club",
		"name": "Giant's Club",
		"type": "Trinket",
		"subtype": "Gear",
		"image": "res://images/item_art/giants_club.png",
		"effect": "giants_club",
		"xp_cost": 10,
		"description": "You gain +2 Strength and lose -10 Speed.",
		"gold_cost": 97,
		"rarity": "Common",
		"unique": false
	},
	{
		"id": "energy_ring",
		"name": "Energy Amulet",
		"type": "Trinket",
		"subtype": "Gear",
		"image": "res://images/item_art/energy_ring.png",
		"effect": "energy_ring",
		"xp_cost": 14,
		"description": "Gain +1 AP at the start of combat (can exceed cap)",
		"gold_cost": 136,
		"rarity": "Common",
		"unique": false
	},
	{
		"id": "burnheart_charm",
		"name": "Burn Heart Charm",
		"type": "Trinket",
		"subtype": "Gear",
		"image": "res://images/item_art/burnheart_charm.png",
		"effect": "burnheart_charm",
		"xp_cost": 11,
		"description": "Deal +2 damage to enemies who are burning",
		"gold_cost": 113,
		"rarity": "Common",
		"unique": true
	},
	{
		"id": "heavy_shield",
		"name": "Heavy Shield",
		"type": "Trinket",
		"subtype": "Gear",
		"image": "res://images/item_art/heavy_shield.png",
		"effect": "heavy_shield",
		"xp_cost": 10,
		"description": "You lose -10 Speed, but gain +2 Block at the start of your turn.",
		"gold_cost": 104,
		"rarity": "Common",
		"unique": false
	},
	{
		"id": "health_stone",
		"name": "Health Stone",
		"type": "Consumable",
		"subtype": "Trinket",
		"image": "res://images/item_art/health_stone.png",
		"effect": "health_stone",
		"xp_cost": 5,
		"description": "If Equipped, gain +4 Max Health. If used, heal 10 hp",
		"gold_cost": 64,
		"rarity": "Common",
		"unique": false
	},
	{
		"id": "energy_stone",
		"name": "Energy Stone",
		"type": "Consumable",
		"subtype": "N/A",
		"image": "res://images/item_art/energy_stone.png",
		"effect": "energy_stone",
		"xp_cost": 8,
		"description": "When consumed grants +3 AP, can only be used in combat",
		"gold_cost": 77,
		"rarity": "Common",
		"unique": false
	},
		{
		"id": "ability_voucher",
		"name": "Ability Voucher",
		"type": "Consumable",
		"subtype": "N/A",
		"image": "res://images/item_art/ability_voucher.png",
		"effect": "ability_voucher",
		"xp_cost": 13,
		"description": "When consumed, grants the player an ability unlock upon entering their next camp site",
		"gold_cost": 131,
		"rarity": "Uncommon",
		"unique": true
	},
	{
		"id": "strength_elixir",
		"name": "Strength Elixir",
		"type": "Consumable",
		"subtype": "N/A",
		"image": "res://images/item_art/strength_elixir.png",
		"effect": "strength_elixir",
		"xp_cost": 8,
		"description": "When consumed grants +2 Strength for the fight, can only be used in combat",
		"gold_cost": 83,
		"rarity": "Common",
		"unique": false
	},
	{
		"id": "defense_elixir",
		"name": "Defense Elixir",
		"type": "Consumable",
		"subtype": "N/A",
		"image": "res://images/item_art/defense_elixir.png",
		"effect": "defense_elixir",
		"xp_cost": 9,
		"description": "When consumed grants +2 Defense for the fight, can only be used in combat",
		"gold_cost": 89,
		"rarity": "Common",
		"unique": false
	},
	{
		"id": "speed_elixir",
		"name": "Speed Elixir",
		"type": "Consumable",
		"subtype": "N/A",
		"image": "res://images/item_art/speed_elixir.png",
		"effect": "speed_elixir",
		"xp_cost": 10,
		"description": "When consumed grants +20 Speed for the fight, can only be used in combat",
		"gold_cost": 93,
		"rarity": "Common",
		"unique": false
	},
	#ADD MORE ITEMS HERE:
	#BLESSINGS:
	{
		"id": "aerus_blessing",
		"name": "Blessing of Aerus",
		"type": "Blessing",
		"subtype": "NA",
		"image": "res://images/item_art/blessings/aerus_blessing.png",   # we'll add real images later
		"effect": "aerus_blessing",
		"xp_cost": 54,
		"description": "A blessing granted by the oldest god who holds dominion over the skies. Increases your Speed by 10% and allows you to skip a node on the map, charges up every 3 nodes",
		"gold_cost": 999,
		"rarity": "Legendary",
		"unique": true
	},
	{
		"id": "rixas_blessing",
		"name": "Blessing of Rixas",
		"type": "Blessing",
		"subtype": "NA",
		"image": "res://images/item_art/blessings/rixas_blessing.png",   # we'll add real images later
		"effect": "rixas_blessing",
		"xp_cost": 63,
		"description": "A blessing granted by a young, hot headed god who holds dominion over war. Increases your HP by 2x your level, at the start of your turn during combat increase Strength, Defense or Speed by +1, +1, or +10, respectively",
		"gold_cost": 999,
		"rarity": "Legendary",
		"unique": true
	},
	{
		"id": "venari_blessing",
		"name": "Blessing of Venari",
		"type": "Blessing",
		"subtype": "NA",
		"image": "res://images/item_art/blessings/venari_blessing.png",   # we'll add real images later
		"effect": "venari_blessing",
		"xp_cost": 77,
		"description": "A blessing granted by a vicious, femme fatale goddess whose dominion is hunt and murder. Gain 5% lifesteal, healing for 5% of damage done (minimum 1), and gain 1 AP when killing a target",
		"gold_cost": 999,
		"rarity": "Legendary",
		"unique": true
	},
	
]
