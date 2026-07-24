extends PopupPanel

@onready var option1_panel = $learn_ability_background/option1
@onready var option2_panel = $learn_ability_background/option2
@onready var confirm_panel = $learn_ability_background/confirm
@onready var refresh_panel = $learn_ability_background/refresh
@onready var exit_panel = $learn_ability_background/exit

var selected_option: String = ""   
var selected_panel = null
var option1Name: String = ""
var option2Name: String = ""
var option1: Dictionary 
var option2: Dictionary 

func _ready():
	popup_centered()
	setup_manual_buttons()
	create_ability_options()

func create_ability_options():
	var option1_label = get_node_or_null("learn_ability_background/option1/option1_label")
	var option2_label = get_node_or_null("learn_ability_background/option2/option2_label")
	
	var unknown = PlayerData.get_unknown_abilities()
	
	if unknown.size() < 1:
		print ("no new abilities for you to unlock")
		return
	elif unknown.size() == 1:
		option1 = unknown[0]
		option2 = unknown [0]
		print("only 1 ability left to learn!")
	elif unknown.size() == 2:
		option1 = unknown[0]
		option2 = unknown[1]
		print("only 2 abilities left to learn!")
	else:
		unknown.shuffle()
		option1 = unknown[0]
		option2 = unknown[1]
	
	option1Name = option1.name
	option2Name = option2.name
	
	option1_label = get_node_or_null("learn_ability_background/option1/option1_label")
	if option1_label:
		option1_label.text = option1Name
		option1_panel.tooltip_text = str(option1.description)
		option1_label.add_theme_color_override("font_color", Color(0, 0, 0))  # Black
		option1_label.add_theme_font_size_override("font_size", 16)
		option1_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		option1_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		option1_label.position = Vector2(25, 35)
		option1_label.size = Vector2(160, 40)
		option1_label.scale = Vector2(.7, .7)

	option2_label = get_node_or_null("learn_ability_background/option2/option2_label")
	if option2_label:
		option2_label.text = option2Name
		option2_panel.tooltip_text = str(option2.description)
		option2_label.add_theme_color_override("font_color", Color(0, 0, 0))  # Black
		option2_label.add_theme_font_size_override("font_size", 16)
		option2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		option2_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		option2_label.position = Vector2(25, 35)
		option2_label.size = Vector2(160, 40)
		option2_label.scale = Vector2(.7, .7)

	var refresh_label = get_node_or_null("learn_ability_background/refresh/refresh_label")
	if refresh_label:
		refresh_label.text = "Refreshed: " + str(PlayerData.refresh_count) + "\nCosts " + str(PlayerData.refresh_count+1) + " xp"
		refresh_label.add_theme_color_override("font_color", Color(0, 0, 0))
		refresh_label.position = Vector2(-8, 50)
		refresh_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		refresh_label.scale = Vector2(.7, .7)
	


func setup_manual_buttons():
	if option1_panel:
		option1_panel.mouse_entered.connect(func():
			if option1_panel != selected_panel:
				option1_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		option1_panel.mouse_exited.connect(func():
			if option1_panel != selected_panel:
				option1_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		option1_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_option1_pressed()
		)
	
	if option2_panel:
		option2_panel.mouse_entered.connect(func():
			if option2_panel != selected_panel:
				option2_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		option2_panel.mouse_exited.connect(func():
			if option2_panel != selected_panel:
				option2_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		option2_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_option2_pressed()
		)
	
	if confirm_panel:
		confirm_panel.mouse_entered.connect(func():
			if confirm_panel != selected_panel:
				confirm_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		confirm_panel.mouse_exited.connect(func():
			if confirm_panel != selected_panel:
				confirm_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		confirm_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_confirm_pressed()
		)
	
	if refresh_panel:
		refresh_panel.mouse_entered.connect(func():
			if refresh_panel != selected_panel:
				refresh_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		refresh_panel.mouse_exited.connect(func():
			if refresh_panel != selected_panel:
				refresh_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		refresh_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_refresh_pressed()
		)
	
	if exit_panel:
		exit_panel.mouse_entered.connect(func():
			if exit_panel != selected_panel:
				exit_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		exit_panel.mouse_exited.connect(func():
			if exit_panel != selected_panel:
				exit_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		exit_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_exit_pressed()
		)
	

func _on_option1_pressed():
	if selected_panel:
		selected_panel.modulate = Color(1.0, 1.0, 1.0)
	selected_option = option1Name
	selected_panel = option1_panel
	option1_panel.modulate = Color(1.3, 1.1, 0.5)
	print(option1Name + " selected")

func _on_option2_pressed():
	if selected_panel:
		selected_panel.modulate = Color(1.0, 1.0, 1.0)
	selected_option = option2Name
	selected_panel = option2_panel
	option2_panel.modulate = Color(1.3, 1.1, 0.5)
	print(option2Name + " selected")

func _on_refresh_pressed():
	if selected_panel:
		selected_panel.modulate = Color(1.0, 1.0, 1.0)
	selected_option = "Refresh"
	selected_panel = refresh_panel
	refresh_panel.modulate = Color(1.3, 1.1, 0.5)
	print("refresh selected")

func _on_confirm_pressed():
	if selected_option == "":
		print("Please select an option first!")
		return
	
	match selected_option:
		option1Name:
			PlayerData.learn_new_abilities(option1)
			print("🎉Congratulations! You have learned the " + selected_option + " ability!")
			PlayerData.emit_signal("health_changed", PlayerData.current_health)
			PlayerData.refresh_count = 0
			queue_free()
		
		option2Name:
			PlayerData.learn_new_abilities(option2)
			print("🎉Congratulations! You have learned the " + selected_option + " ability!")
			PlayerData.emit_signal("health_changed", PlayerData.current_health)
			PlayerData.refresh_count = 0
			queue_free()
		
		"Refresh":
			if PlayerData.refresh_count >= 5:
				print("you have refreshed too many times, please select another option")
				return
			else:
				if(PlayerData.refresh_count+1)>PlayerData.current_xp:
					print("you do not have enough Xp to refresh")
					return
				PlayerData.refresh_count += 1
				PlayerData.current_xp -= PlayerData.refresh_count
				PlayerData.emit_signal("health_changed", PlayerData.current_health)
				create_ability_options()
				print("You have refreshed your card select options")
				
	PlayerData.pending_ability_choice = false
	PlayerData.emit_signal("health_changed", PlayerData.current_health)

func _on_exit_pressed():
	PlayerData.pending_ability_choice = false
	PlayerData.emit_signal("health_changed", PlayerData.current_health)
	queue_free()
