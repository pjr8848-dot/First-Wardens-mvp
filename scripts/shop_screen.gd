extends Node

@onready var exit_panel = $shop_background/exit_panel
@onready var sell_background = $shop_background/sell_background
@onready var sell_vbox = $shop_background/sell_background/sell_vbox
@onready var sell_panel = $shop_background/sell_panel
@onready var sell_exit_panel = $shop_background/sell_background/sell_exit_panel
@onready var gold_label = $shop_background/gold_panel/gold_label

var consumable_slots = []
var consumable_labels = []
var equippable_slots = []
var equippable_labels = []
var sell_panels = []
var sell_labels = []

func _ready() -> void:
	hide_sell_inventory()
	close_sell_inventory()
	set_up_exit()
	
	# === Gold Label ===
	gold_label.add_theme_font_size_override("font_size", 24)
	gold_label.add_theme_constant_override("outline_size", 2)
	gold_label.add_theme_color_override("font_outline_color", Color(.3, 0.7, .1))
	update_gold()
	
	collect_sell_slots()
	collect_slots()
	collect_labels()
	populate_shop()

func update_gold():
	gold_label.text = ":  " + str(PlayerData.gold)

func hide_sell_inventory():
	sell_background.visible = false
	sell_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	sell_panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			sell_background.visible = true
			sell_vbox.mouse_filter = Control.MOUSE_FILTER_STOP
			populate_sell_inventory()
	)
	


func close_sell_inventory():
	if sell_exit_panel:
		sell_exit_panel.mouse_entered.connect(func():
				sell_exit_panel.modulate = Color(1.2, 1.1, 0.8)
		)
		sell_exit_panel.mouse_exited.connect(func():
				exit_panel.modulate = Color(1.0, 1.0, 1.0)
		)
		sell_exit_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				sell_background.visible = false
				sell_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		)

func set_up_exit():
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
	get_tree().change_scene_to_file("res://scenes/map_screen.tscn")

func collect_slots():
	# Collect consumable labels (top row)
	for i in range(1, 6):
		var lbl = get_node_or_null("shop_background/consumables" + str(i))
		if lbl:
			consumable_slots.append(lbl)

# Collect equippable labels (bottom row)
	for i in range(1, 4):
		var lbl = get_node_or_null("shop_background/equippable" + str(i))
		if lbl:
			equippable_slots.append(lbl)

func collect_labels():
	# Consumable labels
	for i in range(1, 6):
		var lbl = get_node_or_null("shop_background/consumables" + str(i) + "/consumables" + str(i) + "_label")
		if lbl:
			consumable_labels.append(lbl)
	
	# Equippable labels
	for i in range(1, 4):
		var lbl = get_node_or_null("shop_background/equippable" + str(i) + "/equippable" + str(i) + "_label")
		if lbl:
			equippable_labels.append(lbl)

func collect_sell_slots():
	sell_panels.clear()
	sell_labels.clear()
	
	for i in range(1, 25):
		var panel_path = "shop_background/sell_background/sell_vbox/sell_hbox" + str((i-1)/8 + 1) + "/sell" + str(i) 
		var label_path = panel_path + "/sell" + str(i) + "_label"
		
		var panel = get_node_or_null(panel_path)
		var label = get_node_or_null(label_path)
		
		if panel:
			sell_panels.append(panel)
		if label:
			sell_labels.append(label)
	
	print("Collected ", sell_panels.size(), " sell panels and ", sell_labels.size(), " sell labels")

func populate_shop():
	var used_consumables = []
	var used_equippables = []
	
	# Consumables
	for i in range(consumable_slots.size()):
		var panel = consumable_slots[i]
		var label = consumable_labels[i]
		var item = Inventory.get_random_item_of_type("Consumable")
		
		while item.name in used_consumables and used_consumables.size() < 10: 
			item = Inventory.get_random_item_of_type("Consumable")
		
		if not item.is_empty():
			var gold = item.get("gold_cost", 0)
			label.text = str(gold) + "g"
			panel.tooltip_text = item.name + ": " + item.get("description", "")
			
			var texture_path = item.get("image", "")
			if texture_path != "":
				var style = StyleBoxTexture.new()
				style.texture = load(texture_path)
				panel.add_theme_stylebox_override("panel", style)
		var current_item = item
		panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				buy_item(panel, current_item)
		)
	
	# Equippables
	for i in range(equippable_slots.size()):
		var panel = equippable_slots[i]
		var label = equippable_labels[i]
		var item = Inventory.get_random_item_of_type("Trinket")
		
		while item.name in used_equippables and used_equippables.size() < 10:  # avoid infinite loop
			item = Inventory.get_random_item_of_type("Trinket")
	
		if not item.is_empty():
			var gold = item.get("gold_cost", 0)
			label.text = str(gold) + "g"
			panel.tooltip_text = item.name + ": " + item.get("description", "")
			
			var texture_path = item.get("image", "")
			if texture_path != "":
				var style = StyleBoxTexture.new()
				style.texture = load(texture_path)
				panel.add_theme_stylebox_override("panel", style)
		var current_item = item
		panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				buy_item(panel, current_item)
		)

func populate_sell_inventory():
	for i in range(24):
		if i >= sell_panels.size():
			break
			
		var panel = sell_panels[i]
		var label = sell_labels[i]
		
		# Force clear any previous image
		var empty_style = StyleBoxFlat.new()
		empty_style.bg_color = Color(0, 0, 0, 0)
		panel.add_theme_stylebox_override("panel", empty_style)
		
		# RESET the slot first (important!)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.modulate = Color(1, 1, 1, 1)  # full bright
		panel.add_theme_stylebox_override("panel", empty_style)
		
		var item_id = PlayerData.full_inventory[i]
		
		# Clear slot first
		panel.add_theme_stylebox_override("panel", null)
		if label:
			label.text = ""
			panel.tooltip_text = ""
		
		if item_id != "":
			var item = Inventory.get_item_by_id(item_id)
			if not item.is_empty():
				# Image on panel
				var texture_path = item.get("image", "")
				if texture_path != "":
					var texture = load(texture_path)
					if texture:
						var style = StyleBoxTexture.new()
						style.texture = texture
						panel.add_theme_stylebox_override("panel", style)
				
				# Label with sell price (40%)
				var sell_price = int(item.get("gold_cost", 0) * 0.4)
				label.text =  str(sell_price) + "g"
				panel.tooltip_text = item.name + ": " + item.get("description", "")
				
		var current_index = i  # capture index
		panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				sell_item(panel, current_index)
		)

func buy_item(slot, item):
	if item == null or PlayerData.gold < item.get("gold_cost", 0):
		print("Not enough gold!")
		return
	
	# Deduct gold
	PlayerData.gold -= item.get("gold_cost", 0)
	update_gold()
	
	# Add to inventory
	PlayerData.add_to_inventory(item.id)
	
	var label = slot.get_child(0)
	if label:
		label.text = ""
	
	# Clear the slot
	slot.tooltip_text = ""
	slot.add_theme_stylebox_override("panel", null)  # remove image
	
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.modulate = Color(0.5, 0.5, 0.5, 0.5)
	
	print("Purchased: ", item.name)
	populate_sell_inventory()

func sell_item(panel, index: int):
	var item_id = PlayerData.full_inventory[index]
	if item_id == "":
		return
	
	var item = Inventory.get_item_by_id(item_id)
	if item.is_empty():
		return
	
	var sell_price = int(item.get("gold_cost", 0) * 0.4)
	
	# Give gold
	PlayerData.gold += sell_price
	update_gold()
	
	# Remove from inventory
	PlayerData.full_inventory[index] = ""
	
	# Clear UI
	panel.add_theme_stylebox_override("panel", null)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate = Color(0.5, 0.5, 0.5, 0.5)
	
	var label = sell_labels[index]
	if label:
		label.text = ""
		label.tooltip_text = ""
	
	print("Sold: ", item.name, " for ", sell_price, "g")
