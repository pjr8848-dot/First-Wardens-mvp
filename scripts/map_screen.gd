extends Node2D

var map_nodes: Array[MapNode] = []


func _ready():
	#generate_random_combat_nodes(3)
	generate_act1_nodes()
	update_character_hud()

func update_character_hud():
	var hud = get_node_or_null("CharacterHUD") 
	if hud and hud.has_method("update_hud"):
		hud.update_hud()

func _on_combat_node_pressed(_panel, map_node: MapNode):   # Pass the specific node
	print("Starting combat for node: ", map_node.id)
	MapsData.earn_gold(map_node)
	MapsData.mark_node_defeated(map_node.id)
	MapsData.current_node = map_node
	get_tree().change_scene_to_file("res://scenes/combat_screen.tscn")

func _on_chest_node_pressed(_panel, map_node: MapNode):   # Pass the specific node
	print("Opening treasure from node: ", map_node.id)
	MapsData.mark_node_defeated(map_node.id)
	MapsData.current_node = map_node
	get_tree().change_scene_to_file("res://scenes/treasure_screen.tscn")

func _on_shop_node_pressed(_panel, map_node: MapNode):   # Pass the specific node
	print("Opening shop from node: ", map_node.id)
	MapsData.mark_node_defeated(map_node.id)
	MapsData.current_node = map_node
	get_tree().change_scene_to_file("res://scenes/shop_screen.tscn")

func _on_event_node_pressed(_panel, map_node):
	print("Entering event for node: ", map_node.id)
	var event_data = EventsData.get_event(map_node.event_key)
	var event_key = map_node.event_key
	if EventsData.all_events.has(event_key):
		EventsData.all_events[event_key].completed = true
	MapsData.mark_node_defeated(map_node.id)
	MapsData.current_node = map_node
	# Show the popup
	
	if event_data.get("type") == "treasure":
		#switch to full treasure scene
		get_tree().change_scene_to_file("res://scenes/treasure_screen.tscn")
	elif event_data.get("type") == "shop":
		#switch to full shop scene
		get_tree().change_scene_to_file("res://scenes/shop_screen.tscn")
	elif event_data.get("type") == "combat":
		#switch to full combat scene
		if EventsData.all_events.has(event_key):
			EventsData.all_events[event_key].completed = false
		get_tree().change_scene_to_file("res://scenes/combat_screen.tscn")
	else:
		var event_popup = preload("res://scenes/events_popup.tscn").instantiate()
		add_child(event_popup)
		event_popup.show_event(event_data)
		event_popup.tree_exited.connect(func():
			get_tree().change_scene_to_file("res://scenes/map_screen.tscn")
			print("Event completed → node marked defeated: ", map_node.id)
		)

func _on_camp_node_pressed():
	print("Starting Camp Scene, rests remaining: " + str(PlayerData.rest_count))
	PlayerData.rest_count -= 1
	get_tree().change_scene_to_file("res://scenes/camp_screen.tscn") 

func is_node_unlocked(map_node: MapNode) -> bool:
	if map_node.id == "node_1":
		return true  # First node is always unlocked
	
	# Check if any connected previous node is defeated
	for n in MapsData.nodes:
		if n.connections.has(map_node.id) and MapsData.defeated_nodes.get(n.id, false):
			return true
	return false

func generate_camp_button():
	# Avoid duplicates
	for child in get_children():
		if child.name == "CampButton":
			return
	
	var panel = Panel.new()
	panel.name = "CampButton"
	panel.position = Vector2(1660, 840)
	panel.custom_minimum_size = Vector2(120, 120)
	panel.scale = Vector2(0.5, 0.5)
	
	# Dark gold style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.12, 0.06, 0.45)
	style.border_width_left = 8
	style.border_width_top = 8
	style.border_width_right = 8
	style.border_width_bottom = 8
	style.border_color = Color(0.85, 0.65, 0.25)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	
	#Icon
	var icon = Sprite2D.new()
	icon.texture = load("res://images/ui_art/camp_icon.png")  # ← your file
	icon.scale = Vector2(0.045, 0.045)
	icon.position = Vector2(60, 60)
	panel.add_child(icon)
	
	#Label
	var label = Label.new()
	label.text = "Camp " + str(PlayerData.rest_count) + "/" + str(PlayerData.max_rests)
	label.add_theme_color_override("font_color", Color(0, 0, 0))
	label.position = Vector2(-15, 110)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.scale = Vector2(2, 2)
	panel.add_child(label)
	
	# Hover style (brighter + slight scale)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_entered.connect(func():
		var hover_style = style.duplicate()
		hover_style.border_color = Color(1.0, 0.9, 0.4)  # Bright gold
		hover_style.bg_color = Color(0.35, 0.25, 0.1, 0.95)
		panel.add_theme_stylebox_override("panel", hover_style)
	)
	
	panel.mouse_exited.connect(func():
		panel.add_theme_stylebox_override("panel", style)
	)
	
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_camp_node_pressed()
		)
	
	if(PlayerData.rest_count == 0):
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var slash = Line2D.new()
		slash.width = 5
		slash.default_color = Color(0.9, 0.1, 0.1, 0.9)
		slash.add_point(Vector2(0, 120))
		slash.add_point(Vector2(120, 0))
		panel.add_child(slash)
	
	add_child(panel)

func create_visual_node(map_node: MapNode):
	var panel = Panel.new()
	panel.name = map_node.id
	panel.position = map_node.position
	panel.custom_minimum_size = Vector2(120, 120)
	panel.scale = Vector2(0.5, 0.5)
	
	# Your existing style + hover + click logic stays the same
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.12, 0.06, 0.45)
	style.border_width_left = 8
	style.border_width_top = 8
	style.border_width_right = 8
	style.border_width_bottom = 8
	style.border_color = Color(0.85, 0.65, 0.25)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	
	# Hover
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_entered.connect(func():
		var hover_style = style.duplicate()
		hover_style.border_color = Color(1.0, 0.9, 0.4)
		hover_style.bg_color = Color(0.35, 0.25, 0.1, 0.95)
		panel.add_theme_stylebox_override("panel", hover_style)
	)
	panel.mouse_exited.connect(func():
		panel.add_theme_stylebox_override("panel", style)
	)
	
	# Icon
	var icon = Sprite2D.new()
	if(map_node.type == "combat"):
		icon.texture = load("res://images/ui_art/fight.png")
	elif(map_node.type == "event"):
		icon.texture = load("res://images/ui_art/event.png")
	elif(map_node.type == "chest"):
		icon.texture = load("res://images/ui_art/chest.png")
	elif(map_node.type == "rest"):
		icon.texture = load("res://images/ui_art/restpoint.png")
	elif(map_node.type == "shop"):
		icon.texture = load("res://images/ui_art/shop.png")
	icon.scale = Vector2(0.2, 0.2)
	icon.position = Vector2(60, 60)
	panel.add_child(icon)
	
	# Defeated check
	if MapsData.defeated_nodes.get(map_node.id, false):
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var slash = Line2D.new()
		slash.width = 5
		slash.default_color = Color(0.9, 0.1, 0.1, 0.9)
		slash.add_point(Vector2(0, 120))
		slash.add_point(Vector2(120, 0))
		panel.add_child(slash)
	else:
		var is_unlocked = MapsData.unlocked_nodes.get(map_node.id, false)
		if is_unlocked:
			panel.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					if map_node.type == "combat":
						_on_combat_node_pressed(panel, map_node)
					elif map_node.type == "event":
						_on_event_node_pressed(panel, map_node)
					elif map_node.type == "chest":
						_on_chest_node_pressed(panel, map_node)
					elif map_node.type == "rest":
						MapsData.mark_node_defeated(map_node.id)
						MapsData.current_node = map_node
						PlayerData.rest_count += 1
						_on_camp_node_pressed()
					elif map_node.type == "shop":
						_on_shop_node_pressed(panel, map_node)
			)
		else:
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # locked
			# optional: gray it out
			var gray = StyleBoxFlat.new()
			gray.bg_color = Color(0.3, 0.3, 0.3, 0.6)
			panel.add_theme_stylebox_override("panel", gray)
	
	add_child(panel)

func draw_connections():
	# Remove old connection lines
	for child in get_children():
		if child is Line2D:
			child.queue_free()
	
	for node in MapsData.nodes:
		for conn_id in node.connections:
			var target_node = MapsData.get_node_by_id(conn_id)
			if target_node:
				var line = Line2D.new()
				line.width = 3
				line.default_color = Color(0.1, 0.1, 0.1, 0.9)
				
				# Center points
				var start_pos = node.position + Vector2(60, 30)
				var end_pos = target_node.position + Vector2(0, 30)
				
				line.add_point(start_pos)
				line.add_point(end_pos)
				add_child(line)

func generate_act1_nodes():
	# Clear old visual nodes
	for child in get_children():
		if child.name.begins_with("CombatNode"):
			child.queue_free()
	
	MapsData.generate_act1()
	
	for node in MapsData.nodes:
		create_visual_node(node)
	
	generate_camp_button()
	draw_connections()
