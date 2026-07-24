extends Node

class_name Trapper

signal health_changed(new_hp)
signal intent_changed(intent_text)

var sprite_path: String = "res://images/enemy_art/trapper.png"

var Name: String = "Trapper"
var turn_counter: int = 0
var max_health: int = 25
var current_health: int = 25
var strength: int = 1
var defense: int = 6
var buff: int = 0 
var speed: int = 80
var base_speed: int = 80
var hasted_speed: int = 160
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

var counter: int = 0

var final_damage: int = 0

func _ready():
	emit_signal("health_changed", current_health)
	emit_signal("intent_changed", "Attack " + str(strength))

func get_current_intent() -> String:
	var cycle = (turn_counter) % 3
	final_damage = CombatManager.calculate_damage_for_enemy_intent(self, strength)
	match cycle:
		0: return "\n🗡️ " + str(final_damage) + "\n🌀 debuff"
		1: return "\n⚡ +2 Haste" + "\n🛡️ " + str(defense)
		2: return "\n🗡️ " + str(final_damage) + " Pushback"
	return "Attack " + str(strength)

func take_turn() -> Dictionary:
	block_this_turn = 0
	var action = {}
	
	match (turn_counter % 3):
		0:  # Turn 1 pattern: Normal Attack
			action = {"type": "attack_debuff", "value": strength, "tripped": 2}
			print(name, " attacks for ", final_damage, " damage and applies 2 turns of tripped")
			
		1:  # Turn 2 pattern: Attack + Block
			action = {"type": "haste_block", "block": defense, "hasted": 3}
			print(name, " hastes themselves for 2 turns and blocks for ", defense)
			
		2:  # Turn 3 pattern: attack and debuff
			action = {"type": "attack_debuff", "value": strength, "ensnared": true}
			if get_parent() and "initiative_ticks" in get_parent() and get_parent().current_character:
				var push = 250  
				var parent = get_parent()
				var player = parent.current_character
				parent.initiative_ticks[player] = max(0, parent.initiative_ticks[player] - push)
				print(name, " pushed the player back by ", push, " ticks!")
	
				if parent.has_method("update_initiative_bar"):
					parent.update_initiative_bar()
			print(name, " attacks for ", final_damage, " damage, applying ensnared and pushing ", get_parent().current_character.name, " back 25% in initiative")
	
	turn_counter += 1
	
	return action
