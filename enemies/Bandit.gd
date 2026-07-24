extends Node

class_name Bandit

signal health_changed(new_hp)
signal intent_changed(intent_text)

var sprite_path: String = "res://images/enemy_art/bandit.png"

var Name: String = "Bandit"
var turn_counter: int = 0
var max_health: int = 29
var current_health: int = 29
var strength: int = 5
var defense: int = 4
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
var xp_value: int = 4

var counter: int = 0

var final_damage: int = 0

func _ready():
	emit_signal("health_changed", current_health)
	emit_signal("intent_changed", "Attack " + str(strength))

func get_current_intent() -> String:
	var cycle = (turn_counter) % 3
	match cycle:
		0: 
			final_damage = CombatManager.calculate_damage_for_enemy_intent(self, strength+counter)
			return "\n🗡️ " + str(final_damage)
		1: 
			final_damage = CombatManager.calculate_damage_for_enemy_intent(self, strength)
			return "\n🗡️ " + str(final_damage) + "\n🛡️ " + str(defense-2)
		2: return "\n🛡️ " + str(defense) + "\n🌀 debuff"
	return "Attack " + str(strength)

func take_turn() -> Dictionary:
	block_this_turn = 0
	var action = {}
	
	match (turn_counter % 3):
		0:  # Turn 1 pattern: Normal Attack
			action = {"type": "attack", "value": strength+counter}
			counter += 1
			print(name, " attacks for ", final_damage, " damage!")
			
		1:  # Turn 2 pattern: Attack + Block
			action = {"type": "attack_block", "value": strength, "block": defense-2}
			print(name, " attacks for ", final_damage, " and gains ", str(defense-2), " block")
			
		2:  # Turn 3 pattern: Block + Buff
			action = {"type": "block_debuff", "block": defense-1, "vulnerable": 2, "bleed": 2}
			print(name, " gains 5 block and +1 Strength")
	
	turn_counter += 1
	
	return action
