extends Node

class_name Valen

signal ap_changed(new_ap)
#signal health_changed(new_hp)

var max_health: int = 25
var current_health: int = 25
var strength: int = 4
var defense: int = 4
var speed: int = 120
var base_speed: int = 120
var hasted_speed: int = speed*2
var ap: int = 9
var xp: int = 0

var portrait_path: String = "res://images/character_art/Valen_Portrait.png"
var sprite_path: String = "res://images/character_art/Valen_Sprite.png"

#Cooldowns
var precise_strike_cooldown: int = 0
var low_blow_cooldown: int = 0
var phantom_barrage_cooldown: int = 0
var shadow_assault_cooldown: int = 0

var shadow_step_active: bool = false
var next_attack_is_precise: bool = false
var returning_dagger_uses_this_turn = 1

var has_attacked_this_turn: bool = false
var block_this_turn: int = 0   # This is the key variable
var parry_riposte: bool = false

var vulnerable: int = 0
var burn: int = 0
var hasted: int = 0
var bleed: int = 0
var stunned: int = 0
var tripped: int = 0
var ensnared: bool = false
var weak: int = 0

func _ready():
	PlayerData.before_damage_taken.connect(_on_before_damage_taken)

func _on_before_damage_taken(incoming_damage: int):
	if not shadow_step_active:
		return false
	
	var ap_cost = ceil(incoming_damage / float(defense))
	
	if ap >= ap_cost:
		ap -= ap_cost
		print("Shadow Step: Fully dodged ", incoming_damage, " damage")
		return true   # ← Signal that damage should be cancelled
	else:
		var remaining = incoming_damage - (ap * defense)
		ap = 0
		print("Shadow Step: Partial dodge! ", remaining, " damage still hits")
		return false

func add_ap(amount: int):
	if ap >= 9:
		# Already at or over the soft cap — protect excess, don't add more, don't clamp down
		emit_signal("ap_changed", ap)
		return
	
	ap += amount
	ap = min(9, ap)
	emit_signal("ap_changed", ap)

func get_current_ability_cost(ability_name: String) -> int:
	if ability_name == "Returning Dagger":
		return returning_dagger_uses_this_turn
	elif ability_name == "Shadow Assault":
		return ap
	return 0

func apply_crit(damage: int) -> int:
	if next_attack_is_precise:
		next_attack_is_precise = false
		print("PRECISE STRIKE CRITICAL HIT! (2x)")
		add_ap(2)
		return damage * 2
	elif randf() < 0.33:  # 25% chance
		print("CRITICAL HIT!")
		add_ap(2)
		return int(damage * 1.5)
	return damage

func start_new_turn():
	has_attacked_this_turn = false
	parry_riposte = false
	returning_dagger_uses_this_turn = 1
	block_this_turn = 0

func basic_attack(_target = null) -> Variant:
	if has_attacked_this_turn:
		print("Already attacked this turn!")
		return 0
	
	var total_damage = apply_crit(strength)
	
	has_attacked_this_turn = true
	print("Basic Attack! Dealt ", total_damage, " damage.")
	return total_damage

func get_basic_attack_info():
	return "Costs 0 AP, Deals " + str(strength) + " damage. Has a 33% chance of Critical Hit, dealing double damage. Can only attack once per turn."

func shadow_step(_target = null) -> bool:
	shadow_step_active = !shadow_step_active
	if shadow_step_active:
		print("Shadow Step ACTIVATED")
	else:
		print("Shadow Step Activated")
	
	# Refresh the ability buttons so the visual changes
	if get_parent() and get_parent().has_method("setup_ability_buttons"):
		get_parent().setup_ability_buttons()
		
	return shadow_step_active

func returning_dagger(_target = null):
	var cost = returning_dagger_uses_this_turn
	if ap < cost:
		print("Not enough AP to use Returning Dagger (Current Cost: ", cost, ")")
		return 0
	
	ap -= cost
	returning_dagger_uses_this_turn += 1
	
	var total_damage = apply_crit(strength)
	print("Returning Dagger! Cost: ", cost, " | Dealth ", total_damage, " damage")
	
	# Refresh the ability buttons so the visual changes
	if get_parent() and get_parent().has_method("setup_ability_buttons"):
		get_parent().setup_ability_buttons()
	
	return total_damage

func precise_strike(_target = null) -> bool:
	if ap < 5:
		print("Not enough AP for Precise Strike")
		return false
	ap -= 5
	next_attack_is_precise = true
	precise_strike_cooldown = 1
	print("Precise Strike activated! Next attack is guaranteed CRITICAL AND DEALS 2x DAMAGE INSTEAD OF 1.5")
	return true

func low_blow(target = null) -> int:
	if ap < 2:
		print("Not enough AP for Low Blow")
		return 0
	ap -= 2
	var damage = apply_crit(strength+2)
	low_blow_cooldown = 1
	if target:
		target.weak += 1
	print("Low Blow! Dealt ", damage, " + +1 Vulnerable")
	return damage

func lacerate(target = null) -> bool:
	if ap < 3:
		print("Not enough AP for Lacerate")
		return false
	ap -=3
	var damage = apply_crit(strength+1)
	if target:
		damage = get_parent().check_player_damage_conditionals(target, damage)
		get_parent().deal_damage(target, damage)
		target.bleed += 3
		print("Lacerate! Dealt ", damage, " +3 Bleed")
	
	return true

func execute(target = null) -> int:
	if ap < 5:
		print("Not enough AP for Execute")
		return 0
	ap -= 5
	var damage = 0
	if(target.current_health) <= (target.max_health * 0.5):
		damage = apply_crit((strength*3)+2)
		add_ap(1)
		print("Target is low health! Deal extra damage!")
	else:
		damage = apply_crit((strength*2)+1)
	print("Execute! Dealt ", damage)
	return damage

func phantom_barrage(_target = null) -> int:
	if ap < 2 or phantom_barrage_cooldown > 0:
		print("Cannot use Phantom Barrage")
		return 0
	ap -= 2
	phantom_barrage_cooldown = 1
	var damage = apply_crit(strength-1)

	print("Phantom Barrage! Dealt ", damage, " to all enemies")
	
	return damage

func shadow_assault(target = null) -> bool:
	if ap <= 0:
		print("Not enough AP for Shadow Assault")
		return false
	
	var attacks = ap
	ap = 0
	print("SHADOW ASSAULT! Performing ", attacks, " attacks...")
	
	for i in range(1, attacks + 1):
		var damage_this_hit = (strength - 2) + i
		
		# Pick random living enemy
		var valid_targets = get_parent().enemies.filter(func(e): return is_instance_valid(e) and e.current_health > 0)
		if valid_targets.size() == 0:
			print("No more targets left")
			break
		if valid_targets.size() > 0:
			var targets = valid_targets[randi() % valid_targets.size()]
			var final_damage = apply_crit(damage_this_hit)
			
			# Call deal_damage on the parent (Combat Manager)
			final_damage = get_parent().check_player_damage_conditionals(target, final_damage)
			get_parent().deal_damage(targets, final_damage)
			
			print("Shadow Assault hit ", targets.name, " for ", final_damage, " (hit ", i, "/", attacks, ")")
		else:
			print("No valid targets left")
		
		await get_tree().create_timer(0.25).timeout  # small visual pause between hits
	
	# Apply Cooldown and Stunned after the full combo
	shadow_assault_cooldown = 5
	stunned += 2
	end_turn()
	print("Shadow Assault complete — Valen is now Stunned!")
	ap = 0
	# Refresh Ability Button UI
	if get_parent().has_method("setup_ability_buttons"):
		get_parent().setup_ability_buttons()
	
	#Refresh UI
	if get_parent().has_method("update_ui"):
		get_parent().update_ui()
	
	return true

func quick_step(_target = null) -> int:
	if ap < 2:
		print("Not enough Ap for Quick Step")
		return 0
	ap -= 2
	block_this_turn += (defense)

	print("Quick Step activated! Blocking ", block_this_turn, " damage this turn and stepping forward 10% in the initiative")
	
	# Push forward ~10%
	if get_parent() and "initiative_ticks" in get_parent():
		var push = 100
		get_parent().initiative_ticks[self] = max(0, get_parent().initiative_ticks[self] + push)
	
	# Update initiative bar after changing ticks
	if get_parent() and get_parent().has_method("update_initiative_bar"):
		get_parent().update_initiative_bar()
		
	return 0

#Returns list of all abilities for UI to build buttons dynamically
func get_starting_abilities() -> Array:
	return [
		{
			"name": "Shadow Step",
			"cost": 0,
			"function": "shadow_step",
			"description": "Shadow Step, while Shadow Step is toggled, whenever an enemy would deal damage to you, dodge it at the cost of 1 ap per " + str(defense) + " damage dodged"
		},
		{
			"name": "Returning Dagger",
			"cost": returning_dagger_uses_this_turn,
			"function": "returning_dagger",
			"dynamic_cost_func": "get_current_ability_cost",
			"description": "Returning dagger deals " + str(strength) + " damage and it's cost increases by 1 this turn"
		},
		{
			"name": "Precise Strike",
			"cost": 5,
			"cooldown_var": "precise_strike_cooldown",
			"function": "precise_strike",
			"description": "Precise Strike, costs 3 AP, has a 1 turn Cooldown. Your next attack is a gaurunteed critical and the critical hit damage is 2x instead of 1.5x"
		},
		{
			"name": "Phantom Barrage",
			"cost": 2,
			"function": "phantom_barrage",
			"cooldown_var": "phantom_barrage_cooldown",
			"aoe": true,
			"description": "Phantom Barrage, costs 2 AP, has a 1 turn Cooldown. Deal " + str(strength-1) + " damage to all enemies"
		},
	]

# Returns list of all abilities for UI to build buttons dynamically
func get_abilities() -> Array:
	return [
		{
			"name": "Shadow Step",
			"cost": 0,
			"function": "shadow_step",
			"description": "Shadow Step, while Shadow Step is toggled, whenever an enemy would deal damage to you, dodge it at the cost of 1 ap per " + str(defense) + " damage dodged"
		},
		{
			"name": "Returning Dagger",
			"cost": returning_dagger_uses_this_turn,
			"function": "returning_dagger",
			"dynamic_cost_func": "get_current_ability_cost",
			"description": "Returning dagger deals " + str(strength) + " damage and it's cost increases by 1 this turn"
		},
		{
			"name": "Precise Strike",
			"cost": 5,
			"cooldown_var": "precise_strike_cooldown",
			"function": "precise_strike",
			"description": "Precise Strike, costs 3 AP, has a 1 turn Cooldown. Your next attack is a gaurunteed critical and the critical hit damage is 2x instead of 1.5x"
		},
		{
			"name": "Low Blow",
			"cost": 2,
			"cooldown_var": "low_blow_cooldown",
			"function": "low_blow",
			"description": "Low Blow, costs 2 AP, has a 1 turn Cooldown. Deals " + str(strength+2) + " damage and applies 2 weak (Weak: target deals 2/3 damage while weak, decays at start of next turn)"
		},
		{
			"name": "Lacerate",
			"cost": 3,
			"function": "lacerate",
			"description": "Lacerate, costs 3 AP, deals " + str(strength+1) + " damage and applies 3 bleed (Bleed: The next attack against this target triggers the bleed, adding it's stack/value to it's damage and resetting it, decays 1 at the start of turn)"
		},
		{
			"name": "Phantom Barrage",
			"cost": 2,
			"function": "phantom_barrage",
			"cooldown_var": "phantom_barrage_cooldown",
			"aoe": true,
			"description": "Phantom Barrage, costs 2 AP, has a 1 turn Cooldown. Deal " + str(strength-1) + " damage to all enemies"
		},
		{
			"name": "Execute",
			"cost": 5,
			"function": "execute",
			"description": "Execute, costs 5 AP, deals " + str ((strength*2)+1) + " damage. If the target is below 50% hp, deals " + str((strength*3)+2) + " damage instead and generates 1 AP"
		},
		{
			"name": "Shadow Assault",
			"cost": ap,
			"function": "shadow_assault",
			"dynamic_cost_func": "get_current_ability_cost",
			"description": "Costs all current AP, has a 5 turn Cooldown. Attack " + str(ap) + " times, targeting random enemies, dealing " + str(strength-1) + " damage on the first attack, and each subsequent attack dealing +1. Gain +1 Stunned (Stunned: Lose your next turn)"
		},
		{
			"name": "Quick Step",
			"cost": 2,
			"function": "quick_step",
			"description": "Quick Step, costs 2 AP, Gain " + str(defense) + " block"
		}
	]

func end_turn():
	precise_strike_cooldown = max(0, precise_strike_cooldown-1)
	low_blow_cooldown = max(0, low_blow_cooldown-1)
	phantom_barrage_cooldown = max(0, phantom_barrage_cooldown-1)
	shadow_assault_cooldown = max(0, shadow_assault_cooldown-1)
	if next_attack_is_precise:
		add_ap(2)
	else:
		add_ap(1)
	print("================================ Turn ended. +1 AP, AP carried over: ", ap, " ==================================")
