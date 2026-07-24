extends Node2D

@onready var level_up_popup = null
@onready var learn_ability_popup = null
@onready var character_screen_popup = null
@onready var equip_abilities_popup = null

var rest_used_this_visit: bool = false

func _ready():
	create_camp_options()
	if(PlayerData.pending_ability_choice):
		var learn_ability_scene = preload("res://scenes/learn_abilities_screen.tscn")
		learn_ability_popup = learn_ability_scene.instantiate()
		add_child(learn_ability_popup)
		learn_ability_popup.popup_centered()

func create_camp_options():
	for child in get_children():
		if child.name.begins_with("CampOption"):
			child.queue_free()
	
	var button_positions = [
		Vector2(1450, 680),  # Rest
		Vector2(960, 750),  # Level Up
		Vector2(540, 200),  # Abilities
		Vector2(300, 820)   # Trinkets
	]
	
	var button_texts = ["Rest", "Level Up", "Abilities", "Trinkets"]
	var buttons_tooltip = ["Heal 1/2 your max health", "Level up, it costs " +str(PlayerData.get_xp_to_next_level())+ " xp", "Change you're equipped abilities", "Change your equipped trinkets"]
	var callbacks = [_on_rest_pressed, _on_level_up_pressed, _on_equip_abilities_pressed, _on_equip_trinkets_pressed]
	
	for i in range(4):
		var panel = Panel.new()
		panel.name = "CampOption_" + str(i)
		panel.position = button_positions[i]
		panel.custom_minimum_size = Vector2(160, 100)
		panel.scale = Vector2(1, 1)
		
		# Use your wooden button as background
		var style = StyleBoxTexture.new()
		style.texture = load("res://images/ui_art/woodbutton.png")
		panel.add_theme_stylebox_override("panel", style)
		
		# Text on top
		var label = Label.new()
		label.text = button_texts[i]
		label.add_theme_color_override("font_color", Color(0, 0, 0))  # Black
		label.add_theme_font_size_override("font_size", 28)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(0, 30)
		label.size = Vector2(160, 40)
		panel.tooltip_text = buttons_tooltip[i]
		panel.add_child(label)
		
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_entered.connect(func():
			panel.modulate = Color(1.2, 1.1, 0.8)  # Soft yellow/gold tint
		)
		
		panel.mouse_exited.connect(func():
			panel.modulate = Color(1.0, 1.0, 1.0)
		)
		
		# Clickable
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				callbacks[i].call()
		)
		generate_exit_button()
		add_child(panel)

func generate_exit_button():
	# Avoid duplicates
	for child in get_children():
		if child.name == "ExitButton":
			return
	
	var panel = Panel.new()
	panel.name = "ExitButton"
	panel.position = Vector2(1660, 860)
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
	icon.texture = load("res://images/ui_art/exit.png")  # ← your file
	icon.scale = Vector2(0.04, 0.04)
	icon.position = Vector2(60, 60)
	panel.add_child(icon)
	
	#Label
	var label = Label.new()
	label.text = "Exit"
	label.add_theme_color_override("font_color", Color(0, 0, 0))
	label.position = Vector2(0, -40)
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
			_on_exit_pressed()
	)
	
	add_child(panel)



# Button callbacks
func _on_rest_pressed():
	if rest_used_this_visit:
		return
	
	rest_used_this_visit = true
	
	# Heal 50% of max HP
	var heal_amount = PlayerData.max_health / 2
	PlayerData.current_health = min(PlayerData.max_health, PlayerData.current_health + heal_amount)
	PlayerData.emit_signal("health_changed", PlayerData.current_health)
	print("Rested! Healed ", heal_amount, " HP")
	
	# Gray out the Rest button
	var rest_panel = get_node_or_null("CampOption_0")  # Rest is the first one (index 0)
	if rest_panel:
		rest_panel.modulate = Color(0.5, 0.5, 0.5)
		rest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_level_up_pressed():
	# Instantiate and show as overlay
	var level_up_scene = preload("res://scenes/level_up_screen.tscn")
	level_up_popup = level_up_scene.instantiate()
	add_child(level_up_popup)

func _on_equip_abilities_pressed():
	var equip_abilities_scene = preload("res://scenes/equip_abilities_screen.tscn")
	equip_abilities_popup = equip_abilities_scene.instantiate()
	add_child(equip_abilities_popup)
	equip_abilities_popup.popup_centered()

func _on_equip_trinkets_pressed():
	PlayerData.allow_equipping = true
	var character_screen_scene = preload("res://scenes/character_screen.tscn")
	character_screen_popup = character_screen_scene.instantiate()
	add_child(character_screen_popup)
	character_screen_popup.popup_centered()

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://scenes/map_screen.tscn")
