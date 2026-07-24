extends Node
class_name MapData

# This will hold all the map layouts / progression data

var defeated_nodes: Dictionary = {}
var unlocked_nodes: Dictionary = {"node_1":true} #first node is always unlocked
var current_node: MapNode = null

var current_act: int = 1
var nodes: Array[MapNode] = []

func generate_act1():
	nodes.clear()
	
	var node1 = MapNode.new("node_1", Vector2(240, 500), "combat")
	node1.enemy_group = "very_easy"
	node1.connections = ["node_2"]
	
	var node2 = MapNode.new("node_2", Vector2(330, 495), "event")
	node2.event_key = ""
	node2.connections = ["node_3"]
	
	var node3 = MapNode.new("node_3", Vector2(420, 505), "combat")
	node3.enemy_group = "easy"
	node3.connections = ["node_4"]
	
	var node4 = MapNode.new("node_4", Vector2(510, 490), "rest")
	node4.connections = ["node_5"]
	
	var node5 = MapNode.new("node_5", Vector2(600, 495), "combat")
	node5.enemy_group = "medium"
	node5.connections = ["node_6"]
	
	var node6 = MapNode.new("node_6", Vector2(690, 490), "chest")
	node6.connections = ["node_7"]
	
	var node7 = MapNode.new("node_7", Vector2(780, 500), "combat")
	node7.enemy_group = "hard"
	node7.connections = ["node_8"]

	var node8 = MapNode.new("node_8", Vector2(870, 495), "shop")
	node8.connections = ["node_9"]
	
	var node9 = MapNode.new("node_9", Vector2(960, 510), "event")
	node9.event_key = ""
	node9.connections = ["node_10"]
	
	var node10 = MapNode.new("node_10", Vector2(1050, 505), "event")
	node10.event_key = ""
	node10.connections = ["node_11"]
	
	var node11 = MapNode.new("node_11", Vector2(1140, 495), "combat")
	node11.enemy_group = "very_hard"

	
	nodes = [node1, node2, node3, node4, node5, node6, node7, node8, node9, node10, node11]

func mark_node_defeated(node_id: String):
	defeated_nodes[node_id] = true
	
	#Apply Aerus Blessing
	Inventory.aerus_blessing_count = min(Inventory.aerus_blessing_count +1, 3)
	
	
	#the below should unlock the next node after completing the current node
	var node = get_node_by_id(node_id)
	if node:
		for conn_id in node.connections:
			unlocked_nodes[conn_id] = true
	print("Marked node defeated: ", node_id)

func earn_gold(map_node: MapNode):
	var group = map_node.enemy_group
	var gold = 0
	
	match group:
		"very_easy":
			gold = randi_range(1, 5)
		"easy":
			gold = randi_range(3, 10)
		"medium":
			gold = randi_range(8, 15)
		"hard":
			gold = randi_range(12, 20)
		_:
			gold = randi_range(5, 12)  # default
	
	PlayerData.earned_gold = gold
	PlayerData.gold += PlayerData.earned_gold
	print("Earned ", gold, " gold from ", group, " combat!")

func get_node_by_id(node_id: String) -> MapNode:
	for node in nodes:
		if node.id == node_id:
			return node
	return null
