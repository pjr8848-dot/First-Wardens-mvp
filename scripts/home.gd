extends Node2D

@onready var thyros_panel = $ThyrosButton
@onready var caela_panel = $CaelaButton
@onready var valen_panel = $ValenButton

func _ready():
	if thyros_panel:
		thyros_panel.gui_input.connect(_on_thyros_panel_clicked)
		thyros_panel.mouse_entered.connect(_on_thyros_mouse_entered)
		thyros_panel.mouse_exited.connect(_on_thyros_mouse_exited)
	
	if caela_panel:
		caela_panel.gui_input.connect(_on_caela_panel_clicked)
		caela_panel.mouse_entered.connect(_on_caela_mouse_entered)
		caela_panel.mouse_exited.connect(_on_caela_mouse_exited)
	
	if valen_panel:
		valen_panel.gui_input.connect(_on_valen_panel_clicked)
		valen_panel.mouse_entered.connect(_on_valen_mouse_entered)
		valen_panel.mouse_exited.connect(_on_valen_mouse_exited)
	
	print("Home Screen Ready - Panel mode")

func _on_thyros_panel_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if $Thyros == null:
			print("ERROR: Thyros node not found!")
			return
		
		PlayerData.set_active_character($Thyros)
		PlayerData.initialize_character(PlayerData.current_character)
		PlayerData.save_character(PlayerData.current_character)
		
		print("Thyros selected as playable character")
		get_tree().change_scene_to_file("res://scenes/shrine_screen.tscn")

func _on_thyros_mouse_entered():
	thyros_panel.modulate = Color(1.2, 1.1, 0.8)

func _on_thyros_mouse_exited():
	thyros_panel.modulate = Color(1.0, 1.0, 1.0)

func _on_caela_panel_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if $Caela == null:
			print("ERROR: Caela node not found!")
			return
		
		PlayerData.set_active_character($Caela)
		PlayerData.initialize_character(PlayerData.current_character)
		PlayerData.save_character(PlayerData.current_character)
		
		print("Caela selected as playable character")
		get_tree().change_scene_to_file("res://scenes/shrine_screen.tscn")

func _on_caela_mouse_entered():
	caela_panel.modulate = Color(1.2, 1.1, 0.8)

func _on_caela_mouse_exited():
	caela_panel.modulate = Color(1.0, 1.0, 1.0)
	
func _on_valen_panel_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if $Valen == null:
			print("ERROR: Valen node not found!")
			return
		
		PlayerData.set_active_character($Valen)
		PlayerData.initialize_character(PlayerData.current_character)
		PlayerData.save_character(PlayerData.current_character)
		
		print("Caela selected as playable character")
		get_tree().change_scene_to_file("res://scenes/shrine_screen.tscn")

func _on_valen_mouse_entered():
	valen_panel.modulate = Color(1.2, 1.1, 0.8)

func _on_valen_mouse_exited():
	valen_panel.modulate = Color(1.0, 1.0, 1.0)
