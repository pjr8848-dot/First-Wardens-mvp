extends Node

class_name Brute

signal health_changed(new_hp)
signal intent_changed(intent_text)

var sprite_path: String = "res://images/enemy_art/brute.png"

var Name: String = "Brute"
var turn_counter: int = 0
var max_health: int = 87
var current_health: int = 87
var strength: int = 8
var defense: int = 5
var buff: int = 0 
var tough: int = 0
var speed: int = 100
var base_speed: int = 100
var hasted_speed: int = 220
var block_this_turn: int = 0
var burn: int = 0
var bleed: int = 0
var stunned: int = 0
var tripped: int = 0
var ensnared: bool = false
var hasted: int = 0
var vulnerable: int = 0
var weak: int = 0
var xp_value: int = 11

var counter: int = 2

var final_damage: int = 0

func _ready():
	emit_signal("health_changed", current_health)
	emit_signal("intent_changed", "Attack " + str(strength))

func get_current_intent() -> String:
	var cycle = (turn_counter) % 4
	match cycle:
		0: return "\n⚡+" + str(buff+1) + "STR"
		1: 
			final_damage = CombatManager.calculate_damage_for_enemy_intent(self, strength)
			return "\n🗡️ " + str(final_damage) + "\n🌀 debuff"
		2: return "\n🛡️ " + str(defense+1) + "\n⚡ +" + str(tough+1) + " DEF"
		3: 
			final_damage = CombatManager.calculate_damage_for_enemy_intent(self, strength-2)
			return "\n🗡️ " + str(final_damage) + "x" + str(counter)
	return "Attack " + str(strength)

func take_turn() -> Dictionary:
	block_this_turn = 0
	var action = {}
	
	match (turn_counter % 4):
		0:  # Turn 1 pattern: Normal Attack
			action = {"type": "buff", "buff": buff}
			buff +=1
			print(name, " buffs themselves for +", buff, " Strength")
			
		1:  # Turn 2 pattern: Attack + debuff
			action = {"type": "attack_debuff", "value": strength, "vulnerable": 2, "ensnared": true}
			if get_parent() and "initiative_ticks" in get_parent() and get_parent().current_character:
				var push = 333  
				var parent = get_parent()
				var player = parent.current_character
				parent.initiative_ticks[player] = max(0, parent.initiative_ticks[player] - push)
				print(name, " pushed the player back by ", push, " ticks!")
	
				if parent.has_method("update_initiative_bar"):
					parent.update_initiative_bar()
			print(name, " attacks for ", final_damage, " crushing you flat, dealing 2 vulnerable, ensnaring ", get_parent().current_character.name, "and pushing back 33% in intiative" )
			
		2:  # Turn 3 pattern: Block + Buff
			action = {"type": "block_buff", "block": defense+1, "tough": tough}
			tough +=1
			print(name, " gains ", str(defense+1), " block and +", str(tough), " Defense")
	
		3:  # Turn 4 pattern: multi-attack
			action = {"type": "multi_hit", "value": strength-2, "count": counter}
			print(name, " will multi-hit ", action.count, " times for ", action.value, " each")
			counter += 1  
	
	turn_counter += 1
	
	return action
