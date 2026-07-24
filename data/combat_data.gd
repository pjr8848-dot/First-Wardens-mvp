extends Node
class_name CombatData

# Master database of enemy groups
var enemy_groups = {
	"very_easy": ["Mugger"],
	"easy": ["Mugger", "Bandit"],
	"medium": ["Bandit", "Archer", "Trapper"],
	"hard": ["Mugger", "Brute"],
	"very_hard": ["Bandit", "Trapper", "Brute"],
	"extreme": ["Mugger", "Trapper", "Archer", "Brute"],
	"Impossible":["Brute","Brute"],
	"mini_boss": ["MiniBossEmber"],
	"boss": ["BossKrylos"]
}

func spawn_group(group_name: String, combat_manager: Node):
	if not enemy_groups.has(group_name):
		group_name = "easy"  # fallback
	
	var group = enemy_groups[group_name]
	for enemy_type_name in group:
		var enemy_script = load("res://enemies/" + enemy_type_name + ".gd")
		if enemy_script:
			combat_manager.create_enemies(enemy_script)
		else:
			print("Warning: Could not load enemy: ", enemy_type_name)
