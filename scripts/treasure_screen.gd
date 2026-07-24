extends Node2D

@onready var chest_button = $treasure_background/treasure_chest
@onready var item_panel = $treasure_background/treasure_chest/item
@onready var exit_panel = $treasure_background/exit

var received_item = null

func _ready():
	item_panel.visible = false
	chest_button.pressed.connect(_on_chest_opened)
	
	item_panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_item_clicked()
		)
	
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

func _on_item_clicked():
	if received_item == null:
		return
	
	PlayerData.add_to_inventory(received_item.id)
	print("Added to inventory: ", received_item.name)
	
	# Hide the item panel
	item_panel.visible = false
	item_panel.add_theme_stylebox_override("panel", null)  # remove texture

func _on_chest_opened():
	if received_item != null:
		return  # already opened
	
	# Get random item
	received_item = Inventory.get_random_item()
	if received_item.is_empty():
		print("No items available!")
		return
	
	var item_name = received_item.get("name", "Unknown Item")
	var item_desc = received_item.get("description", "")
	
	# Show the item
	item_panel.tooltip_text = str(item_name) + " " + str(item_desc)
	
	var texture_path = received_item.get("image", "")
	if texture_path != "":
		var style = StyleBoxTexture.new()
		style.texture = load(texture_path)
		item_panel.add_theme_stylebox_override("panel", style)
	
	item_panel.visible = true
	
	if chest_button.texture_pressed:
		chest_button.texture_normal = chest_button.texture_pressed
		chest_button.texture_hover = chest_button.texture_pressed
		chest_button.texture_disabled = chest_button.texture_pressed
	
	
	PlayerData.gold = randi_range(79, 109)
	chest_button.disabled = true

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://scenes/map_screen.tscn")
