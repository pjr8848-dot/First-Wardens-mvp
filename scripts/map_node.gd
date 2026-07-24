extends Node
class_name MapNode

# This holds all the data for one node on the map
var id: String = ""
var position: Vector2 = Vector2.ZERO
var type: String = "combat"      # "combat", "event", "shop", "rest", "boss"
var unlocked: bool = false
var defeated: bool = false
var event_key: String = ""
var enemy_group: String = "easy" # "easy", "medium", "hard", etc.
var connections: Array = []      # list of node ids it connects to

func _init(new_id: String, new_pos: Vector2, new_type: String = "combat"):
	id = new_id
	position = new_pos
	type = new_type
	unlocked = true  # first nodes start unlocked
