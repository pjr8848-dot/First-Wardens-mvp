extends Node

@onready var current_character: Node = null

@warning_ignore("unused_signal")
signal health_changed(new_health)

@warning_ignore("unused_signal")
signal before_damage_taken(amount: int)
#signal stats_changed

var character_name: String = ""
var current_health: int = 0
var max_health: int = 0
var base_max_health: int = 0
var strength: int = 0
var base_strength: int = 0
var defense: int = 0
var base_defense: int = 0
var speed: int = 0
var base_speed: int = 0
var hasted_speed: int = 0
var ap: int = 0
var level: int = 1

var earned_gold: int = 0
var gold: int = 0

var total_xp: int = 0
var current_xp: int = 0
var xp_earned: int = 0

var has_burnheart_charm: bool = false
var has_heavy_shield: bool = false
var is_in_combat: bool = false
var shrine_count: int = 0

var max_rests: int = 2
var rest_count: int = 2
var refresh_count: int = 0
var pending_ability_choice: bool = false
var portrait_path: String = ""

var act: int = 1
var defeated_node_ids: Array = []
var abilities_known: Array = []
var abilities_equipped: Array = []
var all_abilities: Array = []
var unknown_abilities: Array = []

#inventory
var full_inventory: Array[String] = [] #24 slots
var equipped_trinkets: Array [String] = [] #4 slots
var allow_equipping: bool = false

# Level up costs (index 1 = cost to go from level 1 to 2, etc.)
var level_up_costs = [0, 5, 15, 35, 65, 100]  # index 0 unused

func set_active_character(new_character: Node):
	current_character = new_character

func get_equipped_abilities() -> Array:
	return abilities_equipped

func can_level_up() -> bool:
	return level < level_up_costs.size() - 1 and current_xp >= get_xp_to_next_level()

func get_xp_to_next_level() -> int:
	if level >= level_up_costs.size() - 1:
		return -1  # Max level
	return level_up_costs[level]

func apply_all_trinket_effects():
	#reset stats to base before applying bonuses to prevent bug/infinite boosting stat
	var old_max_health = max_health   # Save before reset
	Inventory.has_venari_blessing = false
	Inventory.has_rixas_blessing = false
	Inventory.has_aerus_blessing = false
	speed = base_speed
	strength = base_strength
	defense = base_defense
	max_health = base_max_health
	
	for item_id in equipped_trinkets:
		if item_id != "":
			Inventory.apply_trinket_effect(item_id)
	
	var health_diff = max_health - old_max_health
	current_health += health_diff
	current_health = clamp(current_health, 0, max_health)

# Add an item to the first empty slot in full inventory
func add_to_inventory(item_id: String) -> bool:
	for i in range(full_inventory.size()):
		if full_inventory[i] == "":
			full_inventory[i] = item_id
			print("Added ", item_id, " to inventory slot ", i)
			return true
	print("Inventory is full!")
	return false


# Equip an item to a specific trinket slot (0-3)
func equip_trinket(item_id: String, slot_index: int) -> bool:
	if slot_index < 0 or slot_index > 3:
		print("Invalid trinket slot")
		return false
	
	# Optional: unequip whatever was there before
	equipped_trinkets[slot_index] = item_id
	print("Equipped ", item_id, " to trinket slot ", slot_index)
	
	apply_all_trinket_effects()   # Refresh stats
	return true

func initialize_character(character: Node):
	current_character = character
	character_name = character.name
	current_health = character.current_health
	max_health = character.max_health
	base_max_health = character.max_health
	strength = character.strength
	base_strength = character.strength
	defense = character.defense
	base_defense = character.defense
	speed = character.speed
	base_speed = character.speed
	hasted_speed = character.speed*2
	ap = character.ap
	portrait_path = character.portrait_path
	abilities_known = character.get_starting_abilities()
	abilities_equipped = character.get_starting_abilities()
	unknown_abilities = get_unknown_abilities()
	all_abilities = character.get_abilities()
	full_inventory.resize(24)
	full_inventory.fill("")
	equipped_trinkets.resize(4)
	equipped_trinkets.fill("")
	#add_to_inventory("swift_foot_boots")
	#add_to_inventory("energy_ring")
	#add_to_inventory("giants_club")
	#add_to_inventory("burnheart_charm")
	#add_to_inventory("heavy_shield")
	#add_to_inventory("health_stone")
	#add_to_inventory("energy_stone")
	#add_to_inventory("ability_voucher")
	#add_to_inventory("strength_elixir")
	#add_to_inventory("defense_elixir")
	#add_to_inventory("speed_elixir")
	apply_all_trinket_effects()
	print("Initialized ", character.name, " with ", abilities_equipped.size(), " abilities")

func learn_new_abilities(new_ability: Dictionary):
	if not abilities_known.has(new_ability):
		abilities_known.append(new_ability)
	if abilities_equipped.size() < 6:
		abilities_equipped.append(new_ability)

func get_unknown_abilities() -> Array:
	unknown_abilities = []
	if all_abilities.size() == 0:
		print("WARNING: all_abilities is empty! Re-initializing...")
		if current_character and current_character.has_method("get_abilities"):
			all_abilities = current_character.get_abilities()
	
	for ability in all_abilities:
		var is_known = false
		for known in abilities_known:
			if known.get("name") == ability.get("name"):
				is_known = true
				break
		if not is_known:
			unknown_abilities.append(ability)
	return unknown_abilities

func save_character(character: Node):
	if character == null:
		return
	current_health = character.current_health
	max_health = character.max_health
	print("Saved data from: ", character_name)

func load_into_character(character: Node):
	if character == null or character_name == "":
		print("No saved data yet - using character's default stats")
		return  # Don't overwrite with empty data on first run

	character.name = character_name
	character.current_health = current_health
	character.max_health = max_health
	character.strength = strength
	character.speed = speed
	character.defense = defense
	character.hasted_speed = hasted_speed
	character.base_speed = base_speed
	print("Loaded data into: ", character.name)

# Returns true if the player has the item ANYWHERE (inventory or equipped)
func has_item(item_id: String) -> bool:
	if item_id == "":
		return false
	
	# Check inventory bags
	for item in full_inventory:
		if item == item_id:
			return true
	
	# Check equipped trinkets
	for equipped_id in equipped_trinkets:
		if equipped_id == item_id:
			return true
	
	return false

# Returns true ONLY if the item is currently equipped
func is_item_equipped(item_id: String) -> bool:
	if item_id == "":
		return false
	return equipped_trinkets.has(item_id)


func mark_node_defeated(node_name: String):
	if not defeated_node_ids.has(node_name):
		defeated_node_ids.append(node_name)

func is_node_defeated(node_name: String) -> bool:
	return defeated_node_ids.has(node_name)
