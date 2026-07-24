extends Node2D

@onready var name_label = $NameLabel
@onready var health_bar = $HealthBar
@onready var hp_number_label = $HPNumberLabel
@onready var xp_label = $XPLabel
@onready var character_panel = $CharacterPanel
@onready var gold_label = $GoldPanel/GoldLabel
@onready var character_screen_popup = null

func _ready():
	if PlayerData.has_signal("health_changed"):
		PlayerData.health_changed.connect(_on_health_changed)
	update_hud()

func _on_health_changed(_new_health):
	update_hud()

func update_hud():
	if PlayerData.character_name != "":
		name_label.text = PlayerData.character_name
	else:
		name_label.text = "ERROR"
		
	# === Name Label Styling ===
	name_label.add_theme_font_size_override("font_size", 32)        
	name_label.add_theme_constant_override("outline_size", 4)      
	name_label.add_theme_color_override("font_outline_color", Color(0.9, 0.7, 0.2)) 
		
	# === HP Number Label ===
	hp_number_label.add_theme_font_size_override("font_size", 24)
	hp_number_label.add_theme_constant_override("outline_size", 2)
	hp_number_label.add_theme_color_override("font_outline_color", Color(.9, 0.3, .3))
	
	# === XP Number Label ===
	xp_label.add_theme_font_size_override("font_size", 24)
	xp_label.add_theme_constant_override("outline_size", 2)
	xp_label.add_theme_color_override("font_outline_color", Color(.3, 0.7, .1))
	
	# === Gold Label ===
	gold_label.add_theme_font_size_override("font_size", 24)
	gold_label.add_theme_constant_override("outline_size", 2)
	gold_label.add_theme_color_override("font_outline_color", Color(.3, 0.7, .1))
	
	# Color the Health Bar
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.9, 0.15, 0.15)   
	health_bar.add_theme_stylebox_override("fill", fill_style)
	fill_style.corner_radius_top_left = 8
	fill_style.corner_radius_top_right = 8
	fill_style.corner_radius_bottom_left = 8
	fill_style.corner_radius_bottom_right = 8
	fill_style.border_width_left = 1
	fill_style.border_width_top = 1.5
	fill_style.border_width_right = 1
	fill_style.border_width_bottom = 1.5
	fill_style.border_color = Color(0, 0, 0)   # Gold outline
	var bg_style = StyleBoxFlat.new()							# Dark background for the empty part
	bg_style.bg_color = Color(0.15, 0.15, 0.15)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	health_bar.add_theme_stylebox_override("background", bg_style)
	health_bar.scale = Vector2(1.3,1)
	
	# Health Bar + Numbers
	health_bar.max_value = PlayerData.max_health
	health_bar.value = PlayerData.current_health
	hp_number_label.text = "HP: " + str(PlayerData.current_health) + "/" + str(PlayerData.max_health)
	xp_label.text = "Level: " + str(PlayerData.level) + "      XP: " + str(PlayerData.current_xp)
	gold_label.text = ":  " + str(PlayerData.gold)
	
	if character_panel:
		character_panel.mouse_entered.connect(func():
				character_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		character_panel.mouse_exited.connect(func():
				character_panel.modulate = Color(1.0, 1.0, 1.0)
	)
		character_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_character_pressed()
	)
	
	
func _on_character_pressed():
	var character_screen_scene = preload("res://scenes/character_screen.tscn")
	character_screen_popup = character_screen_scene.instantiate()
	add_child(character_screen_popup)
	character_screen_popup.popup_centered()
	
	
