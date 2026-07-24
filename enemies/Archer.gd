extends Node

class_name Archer

signal health_changed(new_hp)
signal intent_changed(intent_text)

var sprite_path: String = "res://images/enemy_art/Archer.png"

var Name: String = "Archer"
var turn_counter: int = 0
var max_health: int = 27
var current_health: int = 27
var strength: int = 5
var defense: int = 3
var buff: int = 0 
var speed: int = 100
var base_speed: int = 100
var hasted_speed: int = 200
var block_this_turn: int = 0
var burn: int = 0
var bleed: int = 0
var stunned: int = 0
var tripped: int = 0
var ensnared: bool = false
var hasted: int = 0
var vulnerable: int = 0
var weak: int = 0
var xp_value: int = 5

var counter: int = 2

var final_damage: int = 0

func _ready():
	emit_signal("health_changed", current_health)
	emit_signal("intent_changed", "Attack " + str(strength))

func get_current_intent() -> String:
	var cycle = (turn_counter) % 3
	match cycle:
		#Defend and surge forward 15%
		0: 
			return "\n🛡️ " + str(defense) + " + Surge"
		#Defend and attack
		1:  
			final_damage = CombatManager.calculate_damage_for_enemy_intent(self, strength)
			return "\n🗡️ " + str(final_damage) + "\n🛡️ " + str(defense)
		2:  
			final_damage = CombatManager.calculate_damage_for_enemy_intent(self, strength-2)
			return "\n🗡️ " + str(final_damage) + "x" + str(counter)
	return "Attack " + str(strength)

func take_turn() -> Dictionary:
	block_this_turn = 0
	var action = {}
	
	match (turn_counter % 3):
		0:  # Turn 1 pattern: Surging Block
			action = {"type": "block_surge", "block": defense}
			print(name, " blocks for ", defense)
			
			# Push self forward in initiative
			if get_parent() and "initiative_ticks" in get_parent():
				var push = 150
				get_parent().initiative_ticks[self] = max(0, get_parent().initiative_ticks[self] + push)
				print(name, " surged forward by ", push, " ticks!")
		
				if get_parent().has_method("update_initiative_bar"):
					get_parent().update_initiative_bar()
			
		1:  # Turn 2 pattern: Attack + Block
			action = {"type": "attack_block", "value": strength, "block": defense}
			print(name, " attacks for ", final_damage, " and gains 3 block")
			
		2:  # Turn 3 pattern: multi-attack
			action = {"type": "multi_hit", "value": strength-2, "count": counter}
			print(name, " will multi-hit ", action.count, " times for ", action.value, " each")
			counter += 1  
	
	turn_counter += 1
	
	return action
