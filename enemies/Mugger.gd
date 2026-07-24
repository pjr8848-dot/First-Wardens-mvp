extends Node

class_name Mugger

signal health_changed(new_hp)
signal intent_changed(intent_text)

var sprite_path: String = "res://images/enemy_art/mugger.png"

var Name: String = "Mugger"
var turn_counter: int = 0
var max_health: int = 23
var current_health: int = 23
var strength: int = 3
var defense: int = 3
var buff: int = 0 
var speed: int = 90
var base_speed: int = 90
var hasted_speed: int = 180
var block_this_turn: int = 0
var burn: int = 0
var bleed: int = 0
var stunned: int = 0
var tripped: int = 0
var ensnared: bool = false
var hasted: int = 0
var vulnerable: int = 0
var weak: int = 0
var xp_value: int = 3

var counter: int = 2

var final_damage: int = 0

func _ready():
	emit_signal("health_changed", current_health)
	emit_signal("intent_changed", "Attack " + str(strength))

func get_current_intent() -> String:
	var cycle = (turn_counter) % 3
	final_damage = CombatManager.calculate_damage_for_enemy_intent(self, strength+buff)
	match cycle:
		0: return "\n🗡️ " + str(final_damage)
		1: return "\n🗡️ " + str(final_damage) + "\n🛡️ " + str(defense)
		2: return "\n🛡️ " + str(defense+1) + "\n⚡ +1 STR"
	return "Attack " + str(strength)

func take_turn() -> Dictionary:
	block_this_turn = 0
	var action = {}
	
	match (turn_counter % 3):
		0:  # Turn 1 pattern: Normal Attack
			action = {"type": "attack", "value": strength+buff}
			print(name, " attacks for ", final_damage, " damage!")
			
		1:  # Turn 2 pattern: Attack + Block
			action = {"type": "attack_block", "value": strength+buff, "block": defense}
			print(name, " attacks for ", final_damage, " and gains 3 block")
			
		2:  # Turn 3 pattern: Block + Buff
			action = {"type": "block_buff", "block": defense+1, "buff": buff}
			print(name, " gains 5 block and +1 Strength")
			buff += 1  # permanent buff for this enemy
	
	turn_counter += 1
	
	return action
