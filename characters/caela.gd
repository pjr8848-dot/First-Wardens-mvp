extends Node

class_name Caela

signal ap_changed(new_ap)
#signal health_changed(new_hp)

var max_health: int = 35
var current_health: int = 35
var strength: int = 3
var defense: int = 5
var speed: int = 100
var base_speed: int = 100
var hasted_speed: int = speed*2
var ap: int = 4
var xp: int = 0

var portrait_path: String = "res://images/character_art/Caela_Portrait.png"
var sprite_path: String = "res://images/character_art/Caela_Sprite.png"

#cooldowns
var arcane_energize_cooldown: int = 5
var shield_cooldown: int = 0
var shockwave_cooldown: int = 0
var ensnare_cooldown: int = 0
var haste_cooldown: int = 0
var magic_missile_cooldown: int = 0
var shock_cooldown: int = 0
var fireball_cooldown: int = 0
var arcane_roulette_cooldown: int = 0

var block_this_turn: int = 0   
var arcane_roulette_casting: bool = false
var parry_riposte: bool = false

var vulnerable: int = 0
var burn: int = 0
var hasted: int = 0
var bleed: int = 0
var stunned: int = 0
var ensnared: bool = false
var tripped: int = 0
var weak: int = 0

func add_ap(amount: int):
	ap += amount
	ap = min(4, ap)
	emit_signal("ap_changed", ap)

func start_new_turn():
	block_this_turn = 0
	add_ap(4)
	print("New Turn: Ap maximized")

func basic_attack(_target = null) -> Variant:
	if ap < 1:
		print("Not enough AP to attack")
		return 0
	var damage = strength
	ap = max(0, ap-1)
	print("Basic Attack! Dealt ", damage, " damage and blocks 1")
	return damage

func get_basic_attack_info():
	return "Costs 1 AP and deals " + str(strength-1) + " damage"

func arcane_energize(_target = null):
	if arcane_energize_cooldown > 0:
		print("Cannot Arcane Energize")
		return 0
	arcane_energize_cooldown = 5
	ap += 4
	shield_cooldown = 0
	shockwave_cooldown = 0
	ensnare_cooldown = 0
	magic_missile_cooldown = 0
	shock_cooldown = 0
	haste_cooldown = 0
	fireball_cooldown = 0
	arcane_roulette_cooldown = 0
	print("Arcane Energize regenerated your AP this turn (overcharge possible) and refreshed other abilities cooldowns")

	
func magic_missile(_target = null) -> Dictionary:
	if arcane_roulette_casting:
		arcane_roulette_casting = false
		print("Cast through Arcane Roulette!")
	else:
		if ap < 1 or magic_missile_cooldown > 0:
			print("cannot cast Magic Missile")
			return {}
		ap -=1
		magic_missile_cooldown = 1
	var damage =  1
	return {
		"type": "multi_target",
		"name": "Magic Missile",
		"damage": damage,
		"max_targets": 3,
		"true_damage": true   # ignores block
	}
	
func shield(_target = null) -> int:
	if arcane_roulette_casting:
		arcane_roulette_casting = false
		print("Cast through Arcane Roulette!")
	else:
		if ap < 2 or shield_cooldown >0:
			print("can't use Shield")
			return 0
		ap -= 2
		shield_cooldown = 1
	block_this_turn += (defense+2)
	print("Shield Activated! Blocking ", block_this_turn, " damage this turn")
	return 0

func shockwave(_target = null) -> int:
	if arcane_roulette_casting:
		arcane_roulette_casting = false
		print("Cast through Arcane Roulette!")
	else:
		if ap < 2 or shockwave_cooldown > 0:
			print("Cannot cast Shockwave")
			return 0
		ap -= 2
		shockwave_cooldown = 2
	var damage = max(1, strength +2)
	
	# Push ALL enemies back ~25%
	if get_parent() and "initiative_ticks" in get_parent():
		var parent = get_parent()
		var push = int(250) 
		
		for enemy in parent.enemies:
			if enemy and is_instance_valid(enemy):
				parent.initiative_ticks[enemy] = max(0, parent.initiative_ticks.get(enemy, 0) - push)
		
		print("Shockwave! Dealt ", damage, " to all enemies and pushed them back")
	
	# Update the bar
	if get_parent() and get_parent().has_method("update_initiative_bar"):
		get_parent().update_initiative_bar()
	
	return damage

func ensnare(_target = null) -> int:
	if arcane_roulette_casting:
		arcane_roulette_casting = false
		print("Cast through Arcane Roulette!")
	else:
		if ap < 3 or ensnare_cooldown > 0:
			print("cannot use Ensnare")
			return 0
		ap -= 3
		ensnare_cooldown = 3
	
	var damage = max(1, strength - 2)

	print("ensnare deals ", damage, " to ALL enemies and slow them")
	
	for e in get_parent().enemies:
		if e:
			e.ensnared = true
			e.speed = speed/2
	
	return damage
	
func shock(_target = null) -> int:
	if arcane_roulette_casting:
		arcane_roulette_casting = false
		print("Cast through Arcane Roulette!")
	else:
		if ap < 1:
			print("cannot use Shock")
			return 0
		ap -= 1
		shock_cooldown = 1
	var damage = max(1, (strength +3))

	print("shock deals ", damage)
	
	return damage

func haste(_target = null):
	if arcane_roulette_casting:
		arcane_roulette_casting = false
		print("Cast through Arcane Roulette!")
	else:
		if ap < 3 or haste_cooldown > 0:
			print("Cannot cast Haste")
			return 0
		ap -= 3
		haste_cooldown = 4
	hasted = 2
	
	print("Gained 2 haste, your speed is doubled for the next two turns")

func fireball(_target = null) -> int:
	if arcane_roulette_casting:
		arcane_roulette_casting = false
		print("Cast through Arcane Roulette!")
	else:
		if ap < 4 or fireball_cooldown > 0:
			print("Cannot use Fireball")
			return 0
		ap -= 4
		fireball_cooldown = 3
	var damage = (strength*2)+3
	
	print("Fireball! Dealt ", damage, " and +1 Burn to all targets")
	
	#Burn is applied to all enemies for AoE
	for e in get_parent().enemies:
		if e:
			e.burn +=1
	
	return damage

func arcane_roulette(target) -> Variant:
	if ap <2 or arcane_roulette_cooldown >0:
		print("Cannot cast Arcane Roulette")
		return false
	ap -= 2
	arcane_roulette_cooldown = 4
	
	# Select random ability (skip signature slot 0)
	var eligible = PlayerData.abilities_known.slice(1).filter(func(ab):
		return ab != null and ab.name != "Arcane Roulette"
	)
	if eligible.size() == 0:
		return false
		
	# Prioritize unequipped abilities
	var unequipped = []
	for ab in eligible:
		if not PlayerData.abilities_equipped.has(ab):
			unequipped.append(ab)

	var chosen = null
	if unequipped.size() > 0:
		chosen = unequipped[randi() % unequipped.size()]
	else:
		chosen = eligible[randi() % eligible.size()]
		
	arcane_roulette_casting = true
	# Call the chosen ability and return its result
	if not chosen.has("function"):
		return false

	var inner_result = call(chosen.function, target)
	
	if inner_result is int and inner_result > 0 and chosen.get("aoe", false):
		# Re-use the same logic that combat manager uses
		var current_enemies = get_parent().enemies.duplicate() #if get_parent().has("enemies") else []  # adjust path if needed
		for e in current_enemies:
			if is_instance_valid(e) and e.current_health > 0:
				var damage = get_parent().check_player_damage_conditionals(e, inner_result)
				get_parent().deal_damage(e, damage)   
		arcane_roulette_casting = false
		return true   # tell combat manager it was handled

	return inner_result

#Returns list of all abilities for UI to build buttons dynamically
func get_starting_abilities() -> Array:
	return [
		{
			"name": "Arcane Energize",
			"cost": 0,
			"function": "arcane_energize",
			"cooldown_var": "arcane_energize_cooldown",   # Name of the cooldown variable
			"description": "Arcane Energize, costs 0 AP, has a 5 turn Cooldown that it starts on. Gain +4 AP this turn (can go over your maximum, does not carry over) and resets your other abilities cooldowns"
		},
		{
			"name": "Magic Missile",
			"cost": 1,
			"function": "magic_missile",
			"cooldown_var": "magic_missile_cooldown",
			"description": "Magic Missile, costs 1 AP, has a 1 turn Cooldown. Pick 3 targets (duplicates allowed) dealing 1 true damage to each selected enemy. (True Damage: bypasses block)",
			"max_targets": 3,
			"true_damage": true,
		},
		{
			"name": "Shield",
			"cost": 2,
			"function": "shield",
			"cooldown_var": "shield_cooldown",
			"description": "Shield, costs 2 AP, has a 2 turn Cooldown. Gain " + str(defense+2) + " block"
		},
		{
			"name": "Shockwave",
			"cost": 2,
			"function": "shockwave",
			"cooldown_var": "shockwave_cooldown",
			"aoe": true,
			"description": "Shockwave, costs 2 AP, has a 2 turn Cooldown. Deals " + str(strength+2) + " to all enemies and pushes them back in initiative by 25%"
		}
	]

# Returns list of all abilities for UI to build buttons dynamically
func get_abilities() -> Array:
	return [
		{
			"name": "Arcane Energize",
			"cost": 0,
			"function": "arcane_energize",
			"cooldown_var": "arcane_energize_cooldown",   # Name of the cooldown variable
			"description": "Arcane Energize, costs 0 AP, has a 5 turn Cooldown. Gain +4 AP this turn (can go over your maximum, does not carry over) and resets your other abilities cooldowns"
		},
		{
			"type": "multi_target",
			"name": "Magic Missile",
			"cost": 1,
			"function": "magic_missile",
			"cooldown_var": "magic_missile_cooldown",
			"description": "Magic Missile, costs 1 AP, has a 1 turn Cooldown. Pick 3 targets (duplicates allowed) dealing 1 true damage to each selected enemy. (True Damage: bypasses block)",
			"max_targets": 3,
			"true_damage": true,
		},
		{
			"name": "Shield",
			"cost": 2,
			"function": "shield",
			"cooldown_var": "shield_cooldown",
			"description": "Shield, costs 2 AP, has a 2 turn Cooldown. Gain " + str(defense+2) + " block"
		},
		{
			"name": "Shockwave",
			"cost": 2,
			"function": "shockwave",
			"cooldown_var": "shockwave_cooldown",
			"aoe": true,
			"description": "Shockwave, costs 2 AP, has a 2 turn Cooldown. Deals " + str(strength+2) + " to all enemies and pushes them back in initiative by 25%"
		},
		{
			"name": "Ensnare",
			"cost": 3,
			"function": "ensnare",
			"cooldown_var": "ensnare_cooldown",
			"aoe": true,
			"description": "Ensnare, costs 3 AP, has a 3 turn Cooldown. Deals " + str(strength-2) + " damage to all enemies and slows them (Slow: reduces speed by 1/2 until start of their next turn)"
		},
		{
			"name": "Haste",
			"cost": 3,
			"function": "haste",
			"cooldown_var": "haste_cooldown",
			"description": "Haste, costs 3 AP, has a 4 turn Cooldown. Gain 2 haste, (Haste: doubles your speed, lasts a number of turns equal to the number of haste applied)"
		},
		{
			"name": "Shock",
			"cost": 1,
			"function": "shock",
			"cooldown_var": "shock_cooldown",
			"description": "Shock, costs 1 AP. Deals " + str(strength+2) + " damage"
		},
		{
			"name": "Fireball",
			"cost": 4,
			"function": "fireball",
			"cooldown_var": "fireball_cooldown",
			"aoe": true,
			"description": "Fireball, costs 4 AP, has a 4 turn Cooldown. Deals " + str((strength*2)+3) + " damage and applies 1 burn to all targets"
		},
		{
			"name": "Arcane Roulette",
			"cost": 2,
			"function": "arcane_roulette",
			"cooldown_var": "arcane_roulette_cooldown",
			"description": "Arcane Roulette, costs 2 AP, has a 4 turn Cooldown. Casts a random spell from you're known list, prioritizing spells that are not equipped"
		}
	]



func end_turn():
	arcane_energize_cooldown = max(0, arcane_energize_cooldown-1)
	shield_cooldown = max(0, shield_cooldown-1)
	shockwave_cooldown = max(0, shockwave_cooldown-1)
	ensnare_cooldown = max(0, ensnare_cooldown-1)
	haste_cooldown = max(0, haste_cooldown-1)
	shock_cooldown = max(0, shock_cooldown-1)
	magic_missile_cooldown = max (0, magic_missile_cooldown-1)
	fireball_cooldown = max(0, fireball_cooldown-1)
	arcane_roulette_cooldown = max(0, arcane_roulette_cooldown-1)
	print("================================ Turn ended. ==================================")
