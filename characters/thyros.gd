extends Node

class_name Thyros

signal ap_changed(new_ap)
#signal health_changed(new_hp)

var max_health: int = 45
var current_health: int = 45
var strength: int = 5
var defense: int = 4
var speed: int = 100
var base_speed: int = 100
var hasted_speed: int = speed*2
var ap: int = 0
var xp: int = 0

var portrait_path: String = "res://images/character_art/Thyros_Portrait.png"
var sprite_path: String = "res://images/character_art/Thyros_Sprite.png"

#Cooldowns
var flame_lash_cooldown: int = 0
var spinning_slash_cooldown: int = 0
var flame_sweep_cooldown: int = 0

var split_blade_active: bool = false
var has_attacked_this_turn: bool = false
var block_this_turn: int = 0   
var parry_riposte: bool = false
var blazing_inferno_active: bool = false

var vulnerable: int = 0
var burn: int = 0
var hasted: int = 0
var bleed: int = 0
var stunned: int = 0
var tripped: int = 0
var ensnared: bool = false
var weak: int = 0

func add_ap(amount: int):
	ap += amount
	ap = min(9, ap)
	emit_signal("ap_changed", ap)

func start_new_turn():
	has_attacked_this_turn = false
	parry_riposte = false
	block_this_turn = 0
	add_ap(1)
	emit_signal("ap_changed", ap)
	print("New Turn:  +1 AP")
	
	#Blazing Inferno logic
	if blazing_inferno_active:
		var valid_targets = get_parent().enemies.filter(func(e): 
			return is_instance_valid(e) and e.current_health > 0
	)
	
		for target in valid_targets:
			var damage = (strength-2)
			get_parent().deal_true_damage(target, damage)
			print("Blazing Inferno active, deal ", damage, " damage to all enemies at the start of your turn")
	
	return true

func basic_attack(target = null) -> Variant:
	if has_attacked_this_turn:
		print("Already attacked this turn!")
		return 0

	if split_blade_active and target:
		CombatManager.deal_damage(target, strength)
		add_ap(1)
		
		if is_instance_valid(target) and target.current_health > 0:
			CombatManager.deal_damage(target, strength)
			add_ap(1)
		
		has_attacked_this_turn = true
		return true
			
	add_ap(1)
	has_attacked_this_turn = true
	#emit_signal("ap_changed", ap)
	print("Basic Attack! Dealt ", strength, " damage.")
	return strength

func get_basic_attack_info():
	return "Costs 0 AP, Gain +1 AP on attack. Deals " + str(strength) + " damage. Can only attack once per turn."

func flame_lash(_target = null) -> int:
	if ap < 3 or flame_lash_cooldown > 0:
		print("Cannot use Flame Lash")
		return 0
	ap -= 3
	flame_lash_cooldown = 2
	#emit_signal("ap_changed", ap)
	var damage = (strength+1) + PlayerData.level
	
	print("FLAME LASH! Dealt ", damage, " and +1 Burn to all targets")
	
	#Burn is applied to all enemies for AoE
	for e in get_parent().enemies:
		if e:
			e.burn +=1
	
	return damage

func searing_rend(target = null) -> int:
	if ap < 2:
		print("Not enough AP for Searing Rend")
		return 0
	ap -= 2
	#emit_signal("ap_changed", ap)
	var damage = strength
	if(split_blade_active):
		damage = damage*2
	if target:
		target.burn += 1
		target.vulnerable += 1
		if(target.vulnerable == 1):
			damage = int(damage * .6667)
	print("Searing Rend! Dealt ", damage, " + +1 Vulnerable and + 1 Burn")
	return damage
	
func deflect(_target = null) -> int:
	if ap < 1:
		print("Not enough Ap for Deflect")
		return 0
	ap -= 1
	if(split_blade_active):
		block_this_turn += (defense-1)
	else:
		block_this_turn += (defense)
	#emit_signal("ap_changed", ap)
	print("Deflect activated! Blocking ", block_this_turn, " damage this turn")
	return 0
	
	
func parry_and_riposte(_target = null) -> int:
	if ap < 3:
		print("Not enough AP for Parry & Riposte")
		return 0
	ap -= 3
	if(split_blade_active):
		block_this_turn += (defense+1)
	else:
		block_this_turn += (defense+2)
	parry_riposte = true
	emit_signal("ap_changed", ap)
	print("Parry & Riposte activated! Blocking ", block_this_turn, " damage this turn")
	return 0

func activate_split_blade(_target = null):
	if ap < 5:
		print("Not enough AP for Split Blade")
		return false
	ap -= 5
	split_blade_active = true
	emit_signal("ap_changed", ap)
	print("SPLIT BLADE ACTIVATED PERMANENTLY!")
	return true

func lunging_strike(target) -> Variant:
	if ap < 1:
		print("Not enough AP for Lunging Strike")
		return 0
	
	ap -= 1
	emit_signal("ap_changed", ap)
	
	var damage = max(1, strength -3)
	var cm = get_tree().get_first_node_in_group("combat_manager")
	
	if split_blade_active and target and cm:
		cm.deal_damage(target, damage)
		_do_lunging_push()
	
		if is_instance_valid(target) and target.current_health > 0:
			_do_lunging_push()
			print("LUNGING STRIKE! Dealt ", damage, " and surged forward!")
			return damage
	
	_do_lunging_push()
	print("LUNGING STRIKE! Dealt ", damage, " and surged forward!")
	return damage

func _do_lunging_push():
	# Push forward ~10%
	if get_parent() and "initiative_ticks" in get_parent():
		var push = 100
		get_parent().initiative_ticks[self] = max(0, get_parent().initiative_ticks[self] + push)
	
	# Update initiative bar after changing ticks
	if get_parent() and get_parent().has_method("update_initiative_bar"):
		get_parent().update_initiative_bar()

func spinning_slash(_target = null) -> int:
	if ap < 2 or spinning_slash_cooldown > 0:
		print("Cannot use Spinning Slash")
		return 0
	ap -= 2
	emit_signal("ap_changed", ap)
	spinning_slash_cooldown = 1
	var damage = strength
	
	for e in get_parent().enemies:
		if is_instance_valid(e) and e.current_health > 0:
			CombatManager.deal_damage(e, damage)
	
	print("SPINNING SLASH! Dealt ", damage, " to ALL enemies")
	
	if(split_blade_active):
		for e in get_parent().enemies:
			if is_instance_valid(e) and e.current_health > 0:
				CombatManager.deal_damage(e, damage)
		print("SPINNING SLASH! Dealt ", damage, " to ALL enemies (x2)")
	
	return true

func flame_sweep(_target = null) -> int:
	if ap < 4 or flame_sweep_cooldown > 0:
		print("Cannot use Flame Sweep")
		return 0
	ap -= 4
	flame_sweep_cooldown = 2
	emit_signal("ap_changed", ap)
	var damage = strength
	
	# Push ALL enemies back ~50%
	if get_parent() and "initiative_ticks" in get_parent():
		var parent = get_parent()
		
		for enemy in parent.enemies:
			if enemy and is_instance_valid(enemy):
				parent.initiative_ticks[enemy] -= 500
			
		
		print("Flame Sweep! Dealt ", damage, " to all enemies, applying 1 burn and tripped")
		
	# Update the bar
	if get_parent() and get_parent().has_method("update_initiative_bar"):
		get_parent().update_initiative_bar()
	
	for e in get_parent().enemies:
		if e:
			e.burn +=1
			e.tripped = true
	
	return damage

func blazing_inferno(_target = null) -> bool:
	if ap < 4:
		print("Cannot use Blazing Inferno")
		return false
	ap -= 4
	blazing_inferno_active = true
	return true

#Returns list of all abilities for UI to build buttons dynamically
func get_starting_abilities() -> Array:
	return [
		{
			"name": "Split Blades",
			"cost": 5,
			"function": "activate_split_blade",
			"extra_text": " - Permanent",
			"description": "Split Blade, costs 5 AP, Splits Blades, reducing defense by 1. Makes all attacks using his blades strike twice"
		},
				{
			"name": "Deflect",
			"cost": 1,
			"function": "deflect",
			"description": "Deflect, costs 1 AP, Gain " + str(defense-1) + " block"
		},
		{
			"name": "Flame Lash",
			"cost": 3,
			"function": "flame_lash",
			"cooldown_var": "flame_lash_cooldown",   # Name of the cooldown variable
			"aoe": true,
			"description": "Flame Lash, costs 3 AP, has a 3 turn Cooldown. Deal " + str((strength+1) + PlayerData.level) + " damage to all enemies and applies 1 burn (Burn: deals damage equal to burn count at the start of turn, can be blocked, does not decay)"
		},
		{
			"name": "Searing Rend",
			"cost": 2,
			"function": "searing_rend",
			"description": "Flame Sweep, costs 4 AP. Deals " + str(strength) + " damage to a single target and applies 1 burn and 1 vulnerable (Vulnerable: target takes 1.5x damage while vulnerable, decays at start of next turn)"
		},
		{
			"name":"Lunging Strike",
			"cost": 1,
			"function": "lunging_strike",
			"description": "Lunging Strike, costs 1 AP. Deal " + str(strength-3) + " damage and surge forward in initiative by 10%"
		},
	]

# Returns list of all abilities for UI to build buttons dynamically
func get_abilities() -> Array:
	return [
		{
			"name": "Split Blades",
			"cost": 5,
			"function": "activate_split_blade",
			"extra_text": " - Permanent",
			"description": "Split Blade, costs 5 AP, Splits Blades, reducing defense by 1. Makes all attacks using his blades strike twice, effectively doubling their damage"
		},
		{
			"name": "Flame Lash",
			"cost": 3,
			"function": "flame_lash",
			"cooldown_var": "flame_lash_cooldown",   # Name of the cooldown variable
			"aoe": true,
			"description": "Flame Lash, costs 3 AP, has a 3 turn Cooldown. Deal " + str(strength) + " damage to all enemies and applies 1 burn (Burn: deals damage equal to burn count at the start of turn, can be blocked, does not decay)"
		},
		{
			"name": "Searing Rend",
			"cost": 2,
			"function": "searing_rend",
			"description": "Searing Rend, costs 2 AP. Deals " + str(strength) + " damage to a single target and applies 1 burn and 1 vulnerable (Vulnerable: target takes 1.5x damage while vulnerable, decays at start of next turn)"
		},
		{
			"name": "Flame Sweep",
			"cost": 4,
			"function": "flame_sweep",
			"cooldown_var": "flame_sweep_cooldown",
			"aoe": true,
			"description": "Flame Sweep, costs 4 AP. Deals " + str(strength+3) + " damage to all targets and applies 1 burn and tripped (Trip: target initiative is pushed back 50% and their speed is reduced by 10%)"
		},
		{
			"name": "Parry & Riposte",
			"cost": 3,
			"function": "parry_and_riposte",
			"description": "Parry & Riposte, costs 3 AP. Gain " + str(defense+2) + " Block and applies Riposte (Riposte: if you fully block an attack, retaliates with a basic attack)"
		},
		{
			"name": "Deflect",
			"cost": 1,
			"function": "deflect",
			"description": "Deflect, costs 1 AP, Gain " + str(defense-1) + " block"
		},
		{
			"name":"Lunging Strike",
			"cost": 1,
			"function": "lunging_strike",
			"description": "Lunging Strike, costs 1 AP. Deal " + str(strength-3) + " damage and surge forward in initiative by 10%"
		},
		{
			"name": "Spinning Slash",
			"cost": 2,
			"function": "spinning_slash",
			"cooldown_var": "spinning_slash_cooldown",
			"aoe": true,
			"description": "Spinning Slash, costs 2 AP, has a 1 turn Cooldown. Deal " + str(strength) + " damage to all enemies"
		},
		{
			"name": "Blazing Inferno",
			"cost": 4,
			"function": "blazing_inferno",
			"extra_text": " - Permanent",
			"description": "Blazing Inferno, costs 4 AP.  Blazing Inferno deals " + str(strength-2) + " true damage to all enemies at the start of your turn."
		}
	]



func end_turn():
	flame_lash_cooldown = max(0, flame_lash_cooldown-1)
	spinning_slash_cooldown = max(0,spinning_slash_cooldown-1)
	flame_sweep_cooldown = max(0, flame_sweep_cooldown-1)
	print("================================ Turn ended. AP carried over: ", ap, " ==================================")
