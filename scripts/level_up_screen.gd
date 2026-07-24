extends PopupPanel

@onready var health_panel = $level_up_background/health
@onready var defense_panel = $level_up_background/defense
@onready var strength_panel = $level_up_background/strength
@onready var speed_panel = $level_up_background/speed
@onready var learnability_panel = $level_up_background/learnability
@onready var confirm_panel = $level_up_background/confirm
@onready var exit_panel = $level_up_background/exit

var selected_options: Array = []
var selected_panels: Array = []

func _ready():
	create_level_up_options()
	setup_manual_buttons()

func select_option(option: String):
	# If already selected, do nothing or toggle it off
	if selected_options.has(option):
		selected_options.erase(option)
		print("Deselected: ", option)
		return
	
	# Add the new selection
	selected_options.append(option)
	
	# If we now have more than 2, remove the oldest (index 0)
	if selected_options.size() > 2:
		selected_options.pop_front()

func select_panel(option: Node):
	# If already selected, do nothing or toggle it off
	if selected_panels.has(option):
		selected_panels.erase(option)
		print("Deselected: ", option.name)
		return
	
	# Add the new selection
	selected_panels.append(option)
	
	# If we now have more than 2, remove the oldest (index 0)
	if selected_panels.size() > 2:
		selected_panels.pop_front()

func update_selection_highlights():
	var all_panels = [health_panel, defense_panel, strength_panel, speed_panel, learnability_panel]
	var unselected = []
	
	# Find unselected panels
	for panel in all_panels:
		if panel and not selected_panels.has(panel):
			unselected.append(panel)
	
	# Highlight selected ones
	for panel in selected_panels:
		if panel:
			panel.modulate = Color(1.3, 1.1, 0.5)
	
	# Reset unselected ones
	for panel in unselected:
		if panel:
			panel.modulate = Color(1.0, 1.0, 1.0)
	
func create_level_up_options():
	for child in get_children():
		if child.name.begins_with("LevelUpOption"):
			child.queue_free()

	var buttons_tooltip = ["+7 Max Health", "Defense +1", "Strength + 1", "+10 Speed", "Pick one of 2 random unknown abilities to learn"]
	
	var health_label = get_node_or_null("level_up_background/health/health_label")
	if(health_label):
		health_panel.tooltip_text = "+7 Max Health"
	
	var speed_label = get_node_or_null("level_up_background/speed/speed_label")
	if(speed_label):
		speed_panel.tooltip_text = "+10 Speed"

func setup_manual_buttons():
	if health_panel:
		health_panel.mouse_entered.connect(func():
			if not selected_panels.has(health_panel):
				health_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		health_panel.mouse_exited.connect(func():
			if not selected_panels.has(health_panel):
				health_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		health_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_health_pressed()
		)
	
	if defense_panel:
		defense_panel.mouse_entered.connect(func():
			if not selected_panels.has(defense_panel):
				defense_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		defense_panel.mouse_exited.connect(func():
			if not selected_panels.has(defense_panel):
				defense_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		defense_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_defense_pressed()
		)
	
	if confirm_panel:
		confirm_panel.mouse_entered.connect(func():
			if not selected_panels.has(confirm_panel):
				confirm_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		confirm_panel.mouse_exited.connect(func():
			if not selected_panels.has(confirm_panel):
				confirm_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		confirm_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_confirm_pressed()
		)
	
	if strength_panel:
		strength_panel.mouse_entered.connect(func():
			if not selected_panels.has(strength_panel):
				strength_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		strength_panel.mouse_exited.connect(func():
			if not selected_panels.has(strength_panel):
				strength_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		strength_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_strength_pressed()
		)
	
	if speed_panel:
		speed_panel.mouse_entered.connect(func():
			if not selected_panels.has(speed_panel):
				speed_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		speed_panel.mouse_exited.connect(func():
			if not selected_panels.has(speed_panel):
				speed_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		speed_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_speed_pressed()
		)
	
	if learnability_panel:
		learnability_panel.mouse_entered.connect(func():
			if not selected_panels.has(learnability_panel):
				learnability_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		learnability_panel.mouse_exited.connect(func():
			if not selected_panels.has(learnability_panel):
				learnability_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		learnability_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_learnability_pressed()
		)
	
	if exit_panel:
		exit_panel.mouse_entered.connect(func():
			if not selected_panels.has(exit_panel):
				exit_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		exit_panel.mouse_exited.connect(func():
			if not selected_panels.has(exit_panel):
				exit_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		exit_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_exit_pressed()
		)



func _on_health_pressed():
	select_option("Health")
	select_panel(health_panel)
	update_selection_highlights()
	print("health selected")

func _on_defense_pressed():
	select_option("Defense")
	select_panel(defense_panel)
	update_selection_highlights()
	print("defense selected")

func _on_strength_pressed():
	select_option("Strength")
	select_panel(strength_panel)
	update_selection_highlights()
	print("strength selected")

func _on_speed_pressed():
	select_option("Speed")
	select_panel(speed_panel)
	update_selection_highlights()
	print("speed selected")

func _on_learnability_pressed():
	select_option("Learn Ability")
	select_panel(learnability_panel)
	update_selection_highlights()
	print("learn ability selected")

func _on_confirm_pressed():
	if not PlayerData.can_level_up():
		print("Not enough XP! Need ", PlayerData.get_xp_to_next_level(), " XP (have ", PlayerData.current_xp, ")")
		return
	
	if selected_options.size() < 1:
		print("Please select at least one option first!")
		return
	
	var cost = PlayerData.get_xp_to_next_level()
	PlayerData.current_xp -= cost
	PlayerData.level += 1
		
	for option in selected_options:
		match option:
			"Health":
				PlayerData.max_health += 7
				PlayerData.base_max_health += 7
				PlayerData.current_health += 7
				print("Max Health increased by +7")
	
			"Defense":
				PlayerData.defense += 1
				PlayerData.base_defense += 1
				print("Strength increased by +1")
	
			"Strength":
				PlayerData.strength += 1
				PlayerData.base_strength += 1
				print("Strength increased by +1")
		
			"Speed":
				PlayerData.speed += 10
				PlayerData.base_speed += 10
				print("Speed increased by +10")
	
			"Learn Ability":
				PlayerData.pending_ability_choice = true;
	
	print("🎉 Level Up! Now Level ", PlayerData.level)
	
	PlayerData.emit_signal("health_changed", PlayerData.current_health)
	PlayerData.apply_all_trinket_effects()
	queue_free()
	get_tree().change_scene_to_file("res://scenes/camp_screen.tscn")

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://scenes/camp_screen.tscn")
