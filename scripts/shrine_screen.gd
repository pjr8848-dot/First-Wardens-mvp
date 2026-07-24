extends Node

@onready var exit_panel = $exit_panel
@onready var blessing1_panel = $blessing1_panel
@onready var blessing1_label = $blessing1_panel/blessing1_label
@onready var blessing2_panel = $blessing2_panel
@onready var blessing2_label = $blessing2_panel/blessing2_label
@onready var blessing3_panel = $blessing3_panel
@onready var blessing3_label = $blessing3_panel/blessing3_label

var selected_blessing = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerData.shrine_count += 1
	
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
	
	if PlayerData.shrine_count == 1:
		populate_first_shrine()
	#else:
		#populate_normal_shrine()   IMPLEMENT LATER

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://scenes/map_screen.tscn")

func populate_first_shrine():
	var blessing_slots = [
		{"panel": blessing1_panel, "label": blessing1_label},
		{"panel": blessing2_panel, "label": blessing2_label},
		{"panel": blessing3_panel, "label": blessing3_label}
	]
	
	var used_blessings = []
	
	for slot in blessing_slots:
		var panel = slot.panel
		var label = slot.label
		
		# Get a random blessing
		var blessing = Inventory.get_random_item_of_type("Blessing")
		
		# Avoid duplicates
		while blessing.id in used_blessings and used_blessings.size() < 10:
			blessing = Inventory.get_random_item_of_type("Blessing")
		
		if not blessing.is_empty():
			used_blessings.append(blessing.id)
			
			# Set XP cost to 0 for first shrine
			var display_xp = 0
			
			label.text = str(display_xp) + " XP"
			
			# Tooltip with name + description
			panel.tooltip_text = blessing.name + ": " + blessing.get("description", "")
			
			# Set image
			var texture_path = blessing.get("image", "")
			if texture_path != "":
				var style = StyleBoxTexture.new()
				style.texture = load(texture_path)
				panel.add_theme_stylebox_override("panel", style)
			
			# Connect click
			var current_blessing = blessing
			panel.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					select_blessing(current_blessing)
			)

func select_blessing(blessing: Dictionary):
	if selected_blessing != null:
		return  # already chose one
	
	selected_blessing = blessing
	
	PlayerData.equip_trinket(blessing.id, 0)
	
	print("Player chose blessing: " + blessing.name)
	
	# Go back to map after choosing
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/map_screen.tscn")
