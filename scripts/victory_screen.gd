extends PopupPanel

@onready var exit_panel = $victory_background/exit
@onready var gold_label = $victory_background/rewards/gold_label
@onready var xp_label = $victory_background/rewards/xp_label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	xp_label.text = "XP earned: " + str(PlayerData.xp_earned)
	gold_label.text = "Gold gained: " + str(PlayerData.earned_gold)
	
	if exit_panel:
		exit_panel.mouse_entered.connect(func():
			exit_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		exit_panel.mouse_exited.connect(func():
			exit_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		
		exit_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_exit_pressed()
		)

func _on_exit_pressed():
	PlayerData.xp_earned = 0
	PlayerData.earned_gold = 0
	get_tree().change_scene_to_file("res://scenes/map_screen.tscn")
