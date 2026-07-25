extends Node2D

@onready var start_game_panel = $Home/menu_scroll/start_game_panel
@onready var codex_panel = $Home/menu_scroll/codex_panel
@onready var exit_game_panel = $Home/menu_scroll/exit_game_panel

func _ready():
	setup_button(start_game_panel, _on_start_game_pressed)
	setup_button(codex_panel, _on_codex_pressed)
	setup_button(exit_game_panel, _on_exit_game_pressed)

func setup_button(panel: Control, callback: Callable) -> void:
	if not panel:
		return
	
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	panel.mouse_entered.connect(func():
		panel.modulate = Color(1.2, 1.1, 0.8)
	)
	panel.mouse_exited.connect(func():
		panel.modulate = Color(1.0, 1.0, 1.0)
	)
	panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			callback.call()
	)

func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_codex_pressed() -> void:
	print("Codex not implemented yet")
	# Later: get_tree().change_scene_to_file("res://scenes/codex_screen.tscn")

func _on_exit_game_pressed() -> void:
	get_tree().quit()
